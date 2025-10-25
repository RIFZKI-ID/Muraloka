import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:muraloka/all_code/model/canvas_artwork.dart';

/// ORM untuk Canvas Artwork dengan Firestore
class CanvasArtworkRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _collection = 'canvas_artworks';

  /// Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Create new canvas artwork
  Future<String?> create({
    required String title,
    required String imageDataBase64,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final artwork = CanvasArtwork(
        id: '', // Will be set by Firestore
        userId: _currentUserId!,
        title: title,
        imageDataBase64: imageDataBase64,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        metadata: metadata,
      );

      final docRef = await _firestore
          .collection(_collection)
          .add(artwork.toFirestore());

      return docRef.id;
    } catch (e) {
      print('Error creating canvas artwork: $e');
      return null;
    }
  }

  /// Get artwork by ID
  Future<CanvasArtwork?> getById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();

      if (!doc.exists) {
        return null;
      }

      return CanvasArtwork.fromFirestore(doc);
    } catch (e) {
      print('Error getting canvas artwork: $e');
      return null;
    }
  }

  /// Get all artworks for current user
  Future<List<CanvasArtwork>> getAllByCurrentUser() async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Try with orderBy first (requires Firestore index)
      try {
        final querySnapshot = await _firestore
            .collection(_collection)
            .where('userId', isEqualTo: _currentUserId)
            .orderBy('createdAt', descending: true)
            .get();

        return querySnapshot.docs
            .map((doc) => CanvasArtwork.fromFirestore(doc))
            .toList();
      } catch (indexError) {
        // Fallback: Query without orderBy, then sort client-side
        print('⚠️ Firestore index not found, using client-side sorting');
        print('💡 Create index: https://console.firebase.google.com/project/muraloka-apps/firestore/indexes');
        
        final querySnapshot = await _firestore
            .collection(_collection)
            .where('userId', isEqualTo: _currentUserId)
            .get();

        final artworks = querySnapshot.docs
            .map((doc) => CanvasArtwork.fromFirestore(doc))
            .toList();
        
        // Sort client-side by createdAt descending
        artworks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        return artworks;
      }
    } catch (e) {
      print('Error getting user artworks: $e');
      return [];
    }
  }

  /// Get artworks with pagination
  Future<List<CanvasArtwork>> getAllByCurrentUserPaginated({
    int limit = 10,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      Query query = _firestore
          .collection(_collection)
          .where('userId', isEqualTo: _currentUserId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => CanvasArtwork.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting paginated artworks: $e');
      return [];
    }
  }

  /// Stream all artworks for current user (real-time updates)
  Stream<List<CanvasArtwork>> streamAllByCurrentUser() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    // Try with orderBy, fallback to client-side sorting if index doesn't exist
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: _currentUserId)
        .snapshots()
        .map((snapshot) {
          final artworks = snapshot.docs
              .map((doc) => CanvasArtwork.fromFirestore(doc))
              .toList();
          
          // Sort client-side by createdAt descending
          artworks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          return artworks;
        })
        .handleError((error) {
          print('⚠️ Stream error (likely missing Firestore index): $error');
          print('💡 Deploy indexes with: firebase deploy --only firestore:indexes');
          return <CanvasArtwork>[];
        });
  }

  /// Update artwork
  Future<bool> update(CanvasArtwork artwork) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      if (artwork.userId != _currentUserId) {
        throw Exception('Unauthorized: Cannot update other user\'s artwork');
      }

      final updatedArtwork = artwork.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_collection)
          .doc(artwork.id)
          .update(updatedArtwork.toFirestore());

      return true;
    } catch (e) {
      print('Error updating canvas artwork: $e');
      return false;
    }
  }

  /// Update artwork title only
  Future<bool> updateTitle(String id, String newTitle) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection(_collection).doc(id).update({
        'title': newTitle,
        'updatedAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      print('Error updating title: $e');
      return false;
    }
  }

  /// Delete artwork
  Future<bool> delete(String id) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Verify ownership before deleting
      final artwork = await getById(id);
      if (artwork == null) {
        throw Exception('Artwork not found');
      }

      if (artwork.userId != _currentUserId) {
        throw Exception('Unauthorized: Cannot delete other user\'s artwork');
      }

      await _firestore.collection(_collection).doc(id).delete();

      return true;
    } catch (e) {
      print('Error deleting canvas artwork: $e');
      return false;
    }
  }

  /// Delete all artworks for current user
  Future<bool> deleteAllByCurrentUser() async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final batch = _firestore.batch();
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: _currentUserId)
          .get();

      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      return true;
    } catch (e) {
      print('Error deleting all artworks: $e');
      return false;
    }
  }

  /// Search artworks by title
  Future<List<CanvasArtwork>> searchByTitle(String searchTerm) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: _currentUserId)
          .orderBy('title')
          .startAt([searchTerm])
          .endAt(['$searchTerm\uf8ff'])
          .get();

      return querySnapshot.docs
          .map((doc) => CanvasArtwork.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error searching artworks: $e');
      return [];
    }
  }

  /// Get artwork count for current user
  Future<int> getCountByCurrentUser() async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: _currentUserId)
          .count()
          .get();

      return querySnapshot.count ?? 0;
    } catch (e) {
      print('Error getting artwork count: $e');
      return 0;
    }
  }

  /// Get recent artworks (last N days)
  Future<List<CanvasArtwork>> getRecentArtworks({int days = 7}) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final startDate = DateTime.now().subtract(Duration(days: days));

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: _currentUserId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => CanvasArtwork.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting recent artworks: $e');
      return [];
    }
  }
}
