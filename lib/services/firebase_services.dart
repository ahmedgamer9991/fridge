import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Eyeventory/core/errors/exceptions.dart';
import 'package:Eyeventory/models/inventory_item.dart';
import 'package:Eyeventory/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

        // 3. Create default fridge document
        await createDefaultFridgeForUser(user.uid, name);

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
    final prefs = await SharedPreferences.getInstance();
    String? fridgeId = prefs.getString('active_fridge_id');
    
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user session found');
    }

    if (fridgeId == null) {
      final QuerySnapshot query = await _firestore
          .collection('fridges')
          .where('authorizedUsers', arrayContains: user.uid)
          .get();
          
      if (query.docs.isNotEmpty) {
        fridgeId = query.docs.first.id;
        await prefs.setString('active_fridge_id', fridgeId);
      } else {
        fridgeId = await createDefaultFridgeForUser(user.uid, user.displayName ?? 'My Fridge');
      }
    }
    activeFridgeId = fridgeId;
    return fridgeId;
  }

  Future<String> createDefaultFridgeForUser(String userId, String userName) async {
    final prefs = await SharedPreferences.getInstance();
    final DocumentReference docRef = await _firestore.collection('fridges').add({
      'name': 'My Fridge',
      'type': 'home',
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
    
    await prefs.setString('active_fridge_id', docRef.id);
    activeFridgeId = docRef.id;
    return docRef.id;
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
        final modelData = {...data, 'status': status};
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
    final modelData = {...data, 'status': status};

    return InventoryItem.fromMap(modelData, doc.id);
  }

  // Helper method to calculate status (reuse your existing logic)
  String _calculateStatus(Map<String, dynamic> data) {
    // 1. Check if manually marked with a final status
    final currentStatus = data["status"];
    if (currentStatus == 'Consumed' || currentStatus == 'Thrown Away') {
      return currentStatus;
    }

    final expiryDate = (data['expiryDate'] as Timestamp?)?.toDate();
    if (expiryDate == null) {
      // If no date, check if manually marked as Spoiled
      return (currentStatus == 'Spoiled') ? 'Spoiled' : 'Fresh';
    }

    // 2. Normalize dates to midnight for accurate day comparison
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);

    final daysUntilExpiry = expiry.difference(today).inDays;

    // 3. Time-based Logic
    if (daysUntilExpiry < 0) {
      return 'Spoiled';
    }
    if (daysUntilExpiry <= kDefaultExpiryThreshold.toInt()) {
      return 'Expiring Soon';
    }

    // 4. If time-wise it's Fresh, check if user manually marked as Spoiled
    if (currentStatus == 'Spoiled') {
      return 'Spoiled';
    }

    return 'Fresh';
  }
}
