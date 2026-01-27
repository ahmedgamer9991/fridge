import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Eyeventory/core/errors/exceptions.dart';
import 'package:Eyeventory/models/inventory_item.dart';

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
      final docRef = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('items')
          .add({
            'name': name,
            'quantity': quantity,
            'unit': unit,
            'category': category,
            'expiryDate':
                expiryDate, // Firestore handles DateTime directly or needs Timestamp?
            // Firestore SDK handles DateTime by converting to Timestamp automatically usually,
            // but for consistency with existing code (if any), explicit Timestamp might be safer if we read it as Timestamp.
            // However, .add() supports DateTime.
            'imageUrl': imageUrl,
            'notes': notes,
            'status': 'Fresh', // Default status
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
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
        .collection('users')
        .doc(user.uid)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<List<InventoryItem>> getItems() {
    return getItemsStream().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Calculate status dynamically (ignoring stored 'Fresh'/'Expiring Soon' to allow auto-updates)
        // We pass the whole data map so _calculateStatus can respect 'Spoiled' if manually set
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
      // Calculate status if needed, or rely on item.status
      // For now, we trust the item's status or let backend rules handle it.
      // But we should probably remove 'id' and update 'updatedAt'
      final Map<String, dynamic> data = item.toMap();
      data.remove('id');
      data['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('users')
          .doc(user.uid)
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
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('items')
          .doc(itemId)
          .delete();
    } on FirebaseException catch (e) {
      throw Exception('Failed to delete item: ${e.message}');
    }
  }

  // Stream<Map<String, dynamic>?> getItemById(String itemId) {
  //   final User? user = _auth.currentUser;
  //   if (user == null) {
  //     throw Exception('No authenticated user');
  //   }

  //   return _firestore
  //       .collection('users')
  //       .doc(user.uid)
  //       .collection('items')
  //       .doc(itemId)
  //       .snapshots()
  //       .map((snapshot) {
  //         if (!snapshot.exists) return null;
  //         final data = snapshot.data()!;
  //         return {...data, 'id': snapshot.id, 'status': _calculateStatus(data)};
  //       });
  // }

  Future<InventoryItem> getItem(String itemId) async {
    final User? user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
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
    if (daysUntilExpiry < 0) return 'Spoiled';
    if (daysUntilExpiry <= 3) return 'Expiring Soon';

    // 4. If time-wise it's Fresh, check if user manually marked as Spoiled
    if (currentStatus == 'Spoiled') return 'Spoiled';

    return 'Fresh';
  }
}
