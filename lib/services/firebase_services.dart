import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fridge/models/inventory_item.dart';

class FirebaseServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> signIn(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);
      return userCredential.user!.uid;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        throw Exception('Invalid email or password');
      }
      rethrow;
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
        throw Exception('User creation failed');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('Email already in use');
      } else if (e.code == 'invalid-email') {
        throw Exception('Invalid email');
      } else if (e.code == 'weak-password') {
        throw Exception('Password too weak');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final User? user = _auth.currentUser;
    if (user == null) return null;

    final DocumentSnapshot doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();
    return doc.exists ? doc.data() as Map<String, dynamic> : null;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No account found for this email');
      } else if (e.code == 'invalid-email') {
        throw Exception('Invalid email address');
      }
      rethrow;
    }
  }

  Future<void> sendEmailVerification() async {
    final User? user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    try {
      await user.sendEmailVerification();
    } on FirebaseException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('User account not found');
      } else if (e.code == 'invalid-email') {
        throw Exception('Email address is invalid');
      }
      rethrow;
    }
  }

  Future<void> refreshUserStream() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      // Force token refresh to trigger idTokenChanges stream
      await user.getIdToken(true);
      // Reload strictly to ensure properties are up to date
      await user.reload();
    }
  }

  Stream<User?> get idTokenChanges => _auth.idTokenChanges();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<bool> isEmailVerified() async {
    final User? user = _auth.currentUser;
    if (user == null) return false;

    await user.reload();

    return user.emailVerified;
  }

  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    final User? user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    try {
      await _firestore.collection('users').doc(user.uid).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw Exception('Failed to update profile: ${e.message}');
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
    if (user == null) throw Exception('No authenticated user');

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
      throw Exception('Failed to add item: ${e.message}');
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
