import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<String> addItem(Map<String, dynamic> itemData) async {
    final User? user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    try {
      final docRef = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('items')
          .add({
            ...itemData,
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

  Stream<List<Map<String, dynamic>>> getItemsWithStatus() {
    return getItemsStream().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // final expiryDate = (data['expiryDate'] as Timestamp?)?.toDate();
        String status = data["status"] ?? _calculateStatus(data);

        // if (expiryDate != null) {
        //   final now = DateTime.now();
        //   final daysUntilExpiry = expiryDate.difference(now).inDays;

        //   if (daysUntilExpiry <= 0) {
        //     status = 'Spoiled';
        //   } else if (daysUntilExpiry <= 3) {
        //     status = 'Expiring Soon';
        //   }
        // }

        return {...data, 'id': doc.id, 'status': status};
      }).toList();
    });
  }

  Future<void> updateItem(String itemId, Map<String, dynamic> updates) async {
    final User? user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('items')
          .doc(itemId)
          .update({...updates, 'updatedAt': FieldValue.serverTimestamp()});
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

  Future<Map<String, dynamic>> getItemById(String itemId) async {
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
    return {
      ...data,
      'id': doc.id,
      'status':
          data["status"] ?? _calculateStatus(data), // Reuse your status logic
    };
  }

  // Helper method to calculate status (reuse your existing logic)
  String _calculateStatus(Map<String, dynamic> data) {
    if (data["status"] != null) return data["status"];
    final expiryDate = (data['expiryDate'] as Timestamp?)?.toDate();
    if (expiryDate == null) return 'Fresh';

    final now = DateTime.now();
    final daysUntilExpiry = expiryDate.difference(now).inDays;

    if (daysUntilExpiry <= 0) return 'Spoiled'; // todo expired
    if (daysUntilExpiry <= 3) return 'Expiring Soon';
    return 'Fresh';
  }
}
