import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service untuk sync user profile dari Firebase Auth ke Firestore
/// Ini memastikan semua user memiliki dokumen di collection 'users'
/// dengan field: uid, displayName, email, photoURL
class UserProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sync current user profile ke Firestore
  /// Dipanggil setelah login berhasil
  Future<void> syncCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('⚠️ No user logged in, skipping profile sync');
      return;
    }

    await syncUserProfile(user);
  }

  /// Sync specific user profile ke Firestore
  Future<void> syncUserProfile(User user) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      
      // Check if user document already exists
      final snapshot = await userDoc.get();
      
      // Data yang akan di-save/update
      final userData = {
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? user.email?.split('@')[0] ?? 'User',
        'photoURL': user.photoURL,
        'lastLogin': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!snapshot.exists) {
        // Create new user document
        userData['createdAt'] = FieldValue.serverTimestamp();
        userData['collaborations'] = [];
        userData['myProjects'] = [];
        userData['purchasedItems'] = [];
        
        await userDoc.set(userData);
        print('✅ Created user profile for: ${user.email}');
      } else {
        // Update existing user document (only update displayName, photoURL, lastLogin)
        await userDoc.update({
          'displayName': userData['displayName'],
          'photoURL': userData['photoURL'],
          'lastLogin': userData['lastLogin'],
          'updatedAt': userData['updatedAt'],
        });
        print('✅ Updated user profile for: ${user.email}');
      }
    } catch (e) {
      print('❌ Failed to sync user profile: $e');
      // Don't throw error - profile sync is non-critical
    }
  }

  /// Get user profile from Firestore
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('❌ Failed to get user profile: $e');
      return null;
    }
  }

  /// Stream user profile
  Stream<DocumentSnapshot> streamUserProfile(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }

  /// Update user display name
  Future<void> updateDisplayName(String userId, String displayName) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'displayName': displayName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Updated display name for user: $userId');
    } catch (e) {
      print('❌ Failed to update display name: $e');
      throw Exception('Failed to update display name');
    }
  }

  /// Update user photo URL
  Future<void> updatePhotoURL(String userId, String photoURL) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'photoURL': photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Updated photo URL for user: $userId');
    } catch (e) {
      print('❌ Failed to update photo URL: $e');
      throw Exception('Failed to update photo URL');
    }
  }
}
