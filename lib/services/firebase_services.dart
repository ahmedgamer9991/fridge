import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Eyeventory/core/errors/exceptions.dart';
import 'package:Eyeventory/models/inventory_item.dart';
import 'package:Eyeventory/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FirebaseServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> signIn(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);
      return userCredential.user!.uid;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        throw AuthException('Invalid email or password');
      } else if (e.code == 'network-request-failed') {
        throw NetworkException();
      }
      throw ServerException('Login failed: ${e.message}');
    } catch (e) {
      if (e is AppException) rethrow; // Allow AppExceptions to bubble up
      throw ServerException('An unexpected error occurred during login');
    }
  }

  Future<String> createAccount(
    String email,
    String password,
    String name,
    String role,
  ) async {
    try {
      // 1. Create auth user
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      final User? user = userCredential.user;

      if (user != null) {
        // 2. Create user document in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'name': name,
          'email': email,
          'role': role, // 'home' or 'store'
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 3. Create default fridge document (Delegated to getActiveFridgeId fallback to prevent race condition)
        return user.uid;
      } else {
        throw AuthException('User user creation returned null');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw AuthException('This email is already in use by another account.');
      } else if (e.code == 'invalid-email') {
        throw AuthException('The email address is invalid.');
      } else if (e.code == 'weak-password') {
        throw AuthException('The password is too weak.');
      } else if (e.code == 'network-request-failed') {
        throw NetworkException();
      }
      throw ServerException('Registration failed: ${e.message}');
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
        'An unexpected error occurred during registration.',
      );
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final User? user = _auth.currentUser;
    if (user == null) return null;

    try {
      final DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      return doc.exists ? doc.data() as Map<String, dynamic> : null;
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        // Offline
        throw NetworkException();
      }
      throw ServerException('Failed to fetch user profile: ${e.message}');
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw ServerException('Failed to sign out: $e');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw AuthException('No account found for this email address.');
      } else if (e.code == 'invalid-email') {
        throw AuthException('Please enter a valid email address.');
      } else if (e.code == 'network-request-failed') {
        throw NetworkException();
      }
      throw ServerException('Password reset failed: ${e.message}');
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
        'An unexpected error occurred during password reset.',
      );
    }
  }

  Future<void> sendEmailVerification() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      return; // Should likely not happen here if we just signed up, but good to be safe
    }

    try {
      await user.sendEmailVerification();
    } on FirebaseException catch (e) {
      if (e.code == 'network-request-failed') {
        throw NetworkException();
      }
      throw ServerException('Failed to send verification email: ${e.message}');
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
        'An unexpected error occurred sending verification email.',
      );
    }
  }

  Future<void> refreshUserStream() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      try {
        await user.getIdToken(true);
        await user.reload();
      } catch (e) {
        // Silent failure on refresh often okay, but can log or throw if critical
        // throw NetworkException('Failed to refresh user session.');
        // debugPrint("Failed to refresh user stream: $e");
      }
    }
  }

  Stream<User?> get idTokenChanges => _auth.idTokenChanges();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<bool> isEmailVerified() async {
    final User? user = _auth.currentUser;
    if (user == null) return false;

    try {
      await user.reload();
      return _auth.currentUser?.emailVerified ?? false;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') {
        throw NetworkException();
      }
      throw ServerException(e.message ?? 'Failed to check verification status');
    } catch (e) {
      throw ServerException('An unexpected error occurred: $e');
    }
  }

  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw AuthException('No authenticated user session found.');
    }

    try {
      await _firestore.collection('users').doc(user.uid).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') throw NetworkException();
      throw ServerException('Failed to update profile: ${e.message}');
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('An unexpected error occurred updating profile.');
    }
  }

  static String? activeFridgeId;

  Future<String> getActiveFridgeId() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user session found');
    }

    final prefs = await SharedPreferences.getInstance();
    String? fridgeId = prefs.getString('active_fridge_id_${user.uid}');
    
    if (fridgeId == null) {
      final QuerySnapshot query = await _firestore
          .collection('fridges')
          .where('authorizedUsers', arrayContains: user.uid)
          .get();
          
      if (query.docs.isNotEmpty) {
        fridgeId = query.docs.first.id;
        await prefs.setString('active_fridge_id_${user.uid}', fridgeId);
      } else {
        String ownerName = 'Owner';
        String role = 'home';
        try {
          final profile = await getUserProfile();
          if (profile != null) {
            if (profile['name'] != null) {
              ownerName = profile['name'];
            }
            if (profile['role'] != null) {
              role = profile['role'];
            }
          } else if (user.displayName != null) {
            ownerName = user.displayName!;
          }
        } catch (_) {}
        fridgeId = await createDefaultFridgeForUser(user.uid, ownerName, role: role);
      }
    }
    activeFridgeId = fridgeId;
    return fridgeId;
  }

  Future<String> createDefaultFridgeForUser(String userId, String userName, {String role = 'home'}) async {
    final prefs = await SharedPreferences.getInstance();
    final DocumentReference docRef = await _firestore.collection('fridges').add({
      'name': role == 'store' ? 'My Store' : 'My Fridge',
      'type': role,
      'ownerId': userId,
      'authorizedUsers': [userId],
      'membersMetadata': {
        userId: {
          'name': userName.isEmpty ? 'Owner' : userName,
          'role': 'owner',
        }
      },
      'status': 'online',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    await prefs.setString('active_fridge_id_$userId', docRef.id);
    activeFridgeId = docRef.id;
    return docRef.id;
  }

  Future<void> updateFridgeName(String newName) async {
    final User? user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user session found');

    try {
      final fridgeId = await getActiveFridgeId();
      
      // Update in Firestore
      await _firestore.collection('fridges').doc(fridgeId).update({
        'name': newName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update in local SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fridge_name_${user.uid}', newName);
    } catch (e) {
      throw Exception('Failed to update fridge name: $e');
    }
  }

  Future<String> getFridgeName() async {
    final User? user = _auth.currentUser;
    if (user == null) return 'My Fridge';

    try {
      // Try local SharedPreferences first
      final prefs = await SharedPreferences.getInstance();
      final localName = prefs.getString('fridge_name_${user.uid}');
      if (localName != null) return localName;

      // Otherwise, fetch from Firestore
      final fridgeId = await getActiveFridgeId();
      final doc = await _firestore.collection('fridges').doc(fridgeId).get();
      if (doc.exists) {
        final data = doc.data();
        final name = data?['name'] as String?;
        if (name != null) {
          // Cache it locally
          await prefs.setString('fridge_name_${user.uid}', name);
          return name;
        }
      }
    } catch (_) {}
    return 'My Fridge';
  }

  Future<String> addItem({
    required String name,
    required String quantity,
    required String unit,
    required String category,
    DateTime? expiryDate,
    String? imageUrl,
    String? notes,
  }) async {
    final User? user = _auth.currentUser;
    if (user == null) throw AuthException('No authenticated user');

    try {
      final fridgeId = await getActiveFridgeId();
      final docRef = await _firestore
          .collection('fridges')
          .doc(fridgeId)
          .collection('items')
          .add({
            'name': name,
            'source': 'manual',
            'shelfId': 'A',
            'shelfName': 'Top Shelf',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'userOverrides': {
              'quantity': quantity,
              'unit': unit,
              'category': category,
              'status': 'Fresh',
              'expiryDate': expiryDate,
              'imageUrl': imageUrl,
              'notes': notes,
              'createdBy': user.uid,
            }
          });
      return docRef.id;
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') throw NetworkException();
      throw ServerException('Failed to add item: ${e.message}');
    } catch (e) {
      throw ServerException('An unexpected error occurred while adding item.');
    }
  }

  Stream<QuerySnapshot> getItemsStream() {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }
    return _firestore
        .collection('fridges')
        .doc(activeFridgeId ?? 'default')
        .collection('items')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<List<InventoryItem>> getItems() {
    return getItemsStream().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        String status = _calculateStatus(data);
        // Inject computed status into userOverrides so fromMap() picks it up
        // (fromMap reads userOverrides['status'] first, which would otherwise
        //  be the hardcoded 'Fresh' from addItem())
        final userOverrides = Map<String, dynamic>.from(
          data['userOverrides'] as Map<String, dynamic>? ?? {},
        );
        userOverrides['status'] = status;
        final modelData = {...data, 'userOverrides': userOverrides};
        return InventoryItem.fromMap(modelData, doc.id);
      }).toList();
    });
  }

  Future<void> updateItem(InventoryItem item) async {
    final User? user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    try {
      final fridgeId = await getActiveFridgeId();
      final Map<String, dynamic> data = item.toMap();
      data.remove('id');
      data['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('fridges')
          .doc(fridgeId)
          .collection('items')
          .doc(item.id)
          .update(data);
    } on FirebaseException catch (e) {
      throw Exception('Failed to update item: ${e.message}');
    }
  }

  Future<void> deleteItem(String itemId) async {
    final User? user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    try {
      final fridgeId = await getActiveFridgeId();
      await _firestore
          .collection('fridges')
          .doc(fridgeId)
          .collection('items')
          .doc(itemId)
          .delete();
    } on FirebaseException catch (e) {
      throw Exception('Failed to delete item: ${e.message}');
    }
  }

  Future<String> createCustomFridge(String name, {String type = 'store'}) async {
    final User? user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user session found');

    String userName = 'Owner';
    try {
      final profile = await getUserProfile();
      if (profile != null && profile['name'] != null) {
        userName = profile['name'];
      }
    } catch (_) {}

    final DocumentReference docRef = await _firestore.collection('fridges').add({
      'name': name,
      'type': type,
      'ownerId': user.uid,
      'authorizedUsers': [user.uid],
      'membersMetadata': {
        user.uid: {
          'name': userName,
          'role': 'owner',
        }
      },
      'status': 'online',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  Stream<List<InventoryItem>> getItemsForFridge(String fridgeId) {
    return _firestore
        .collection('fridges')
        .doc(fridgeId)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            String status = _calculateStatus(data);
            final userOverrides = Map<String, dynamic>.from(
              data['userOverrides'] as Map<String, dynamic>? ?? {},
            );
            userOverrides['status'] = status;
            final modelData = {...data, 'userOverrides': userOverrides};
            return InventoryItem.fromMap(modelData, doc.id);
          }).toList();
        });
  }

  Future<InventoryItem> getItem(String itemId) async {
    final User? user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final fridgeId = await getActiveFridgeId();
    final doc = await _firestore
        .collection('fridges')
        .doc(fridgeId)
        .collection('items')
        .doc(itemId)
        .get();

    if (!doc.exists) throw Exception('Item not found');

    final data = doc.data()!;
    String status = _calculateStatus(data);
    final userOverrides = Map<String, dynamic>.from(
      data['userOverrides'] as Map<String, dynamic>? ?? {},
    );
    userOverrides['status'] = status;
    final modelData = {...data, 'userOverrides': userOverrides};

    return InventoryItem.fromMap(modelData, doc.id);
  }

  // Helper method to calculate status from raw Firestore document data.
  // Resolves fields from nested userOverrides/detected maps (matching fromMap).
  String _calculateStatus(Map<String, dynamic> data) {
    final userOverrides = data['userOverrides'] as Map<String, dynamic>? ?? {};
    final detected = data['detected'] as Map<String, dynamic>? ?? {};

    // Resolve current status from nested structure
    final currentStatus = userOverrides['status'] as String? ??
        detected['freshness'] as String? ??
        data['status'] as String?;

    // Resolve expiry date from nested structure
    final expiryDate = (userOverrides['expiryDate'] as Timestamp?)?.toDate() ??
        (detected['expiryDate'] as Timestamp?)?.toDate() ??
        (data['expiryDate'] as Timestamp?)?.toDate();

    if (expiryDate == null) {
      // If no date, check if manually marked as Spoiled
      return (currentStatus == 'Spoiled') ? 'Spoiled' : 'Fresh';
    }

    // Normalize dates to midnight for accurate day comparison
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);

    final daysUntilExpiry = expiry.difference(today).inDays;

    // Time-based Logic
    if (daysUntilExpiry < 0) {
      return 'Spoiled';
    }
    if (daysUntilExpiry <= kDefaultExpiryThreshold.toInt()) {
      return 'Expiring Soon';
    }

    // If time-wise it's Fresh, check if user manually marked as Spoiled
    if (currentStatus == 'Spoiled') {
      return 'Spoiled';
    }

    return 'Fresh';
  }
}

final firebaseServicesProvider = Provider<FirebaseServices>((ref) {
  return FirebaseServices();
});

final authChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseServicesProvider).authStateChanges;
});

final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final authState = ref.watch(authChangesProvider);
  final user = authState.value;
  if (user == null) return null;
  return ref.watch(firebaseServicesProvider).getUserProfile();
});

class ActiveFridgeNotifier extends StateNotifier<AsyncValue<String?>> {
  final Ref ref;
  ActiveFridgeNotifier(this.ref) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    state = const AsyncValue.loading();
    try {
      final fridgeId = await ref.read(firebaseServicesProvider).getActiveFridgeId();
      state = AsyncValue.data(fridgeId);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> setActiveFridge(String fridgeId) async {
    state = const AsyncValue.loading();
    try {
      final user = ref.read(authChangesProvider).value;
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('active_fridge_id_${user.uid}', fridgeId);
      }
      FirebaseServices.activeFridgeId = fridgeId;
      state = AsyncValue.data(fridgeId);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final activeFridgeIdProvider = StateNotifierProvider<ActiveFridgeNotifier, AsyncValue<String?>>((ref) {
  ref.watch(authChangesProvider);
  return ActiveFridgeNotifier(ref);
});

final inventoryItemsProvider = StreamProvider<List<InventoryItem>>((ref) {
  final activeFridgeIdAsync = ref.watch(activeFridgeIdProvider);
  return activeFridgeIdAsync.when(
    data: (fridgeId) {
      if (fridgeId == null) return const Stream.empty();
      FirebaseServices.activeFridgeId = fridgeId;
      return ref.watch(firebaseServicesProvider).getItems();
    },
    loading: () => const Stream.empty(),
    error: (error, stack) => const Stream.empty(),
  );
});

final inventoryItemByIdProvider = Provider.family<InventoryItem?, String>((ref, itemId) {
  final itemsAsync = ref.watch(inventoryItemsProvider);
  return itemsAsync.whenOrNull(
    data: (items) {
      try {
        return items.firstWhere((item) => item.id == itemId);
      } catch (_) {
        return null;
      }
    },
  );
});

class FridgeNameNotifier extends StateNotifier<String> {
  final Ref ref;
  Timer? _debounceTimer;

  FridgeNameNotifier(this.ref) : super('My Home Fridge') {
    _init();
  }

  Future<void> _init() async {
    try {
      final name = await ref.read(firebaseServicesProvider).getFridgeName();
      state = name;
    } catch (_) {}
  }

  void updateName(String newName) {
    // 1. Update state immediately (optimistic UI update) so local widgets update instantly
    state = newName;

    // 2. Debounce the network/database write to Firestore
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () async {
      try {
        await ref.read(firebaseServicesProvider).updateFridgeName(newName);
      } catch (e) {
        // Silent error fallback or logging
        // debugPrint('Failed to save fridge name to Firestore: $e');
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final fridgeNameProvider = StateNotifierProvider<FridgeNameNotifier, String>((ref) {
  ref.watch(authChangesProvider);
  return FridgeNameNotifier(ref);
});

final userFridgesProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final authState = ref.watch(authChangesProvider);
  final user = authState.value;
  if (user == null) return const Stream.empty();
  
  return FirebaseFirestore.instance
      .collection('fridges')
      .where('authorizedUsers', arrayContains: user.uid)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();
      });
});

final fridgeItemsProvider = StreamProvider.family<List<InventoryItem>, String>((ref, fridgeId) {
  return ref.watch(firebaseServicesProvider).getItemsForFridge(fridgeId);
});
