import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/store_listing.dart';

/// Repository untuk mengelola Store Listings di Firestore
/// Path: /artifacts/{appId}/public/data/store_listings
class StoreListingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String appId;

  StoreListingRepository({required this.appId});

  /// Path untuk store listings
  CollectionReference get _listingsCollection {
    return _firestore
        .collection('artifacts')
        .doc(appId)
        .collection('public')
        .doc('data')
        .collection('store_listings');
  }

  // ==================== CRUD OPERATIONS ====================

  /// Create store listing (only owner can create)
  Future<String> createListing(StoreListing listing) async {
    final docRef = await _listingsCollection.add(listing.toMap());
    return docRef.id;
  }

  /// Get listing by ID
  Future<StoreListing?> getListing(String listingId) async {
    final doc = await _listingsCollection.doc(listingId).get();
    if (!doc.exists) return null;
    return StoreListing.fromFirestore(doc);
  }

  /// Update listing (only owner can update)
  Future<void> updateListing(
    String listingId,
    Map<String, dynamic> updates,
  ) async {
    await _listingsCollection.doc(listingId).update({
      ...updates,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Delete listing (only owner can delete)
  Future<void> deleteListing(String listingId) async {
    await _listingsCollection.doc(listingId).delete();
  }

  // ==================== QUERIES ====================

  /// Stream all active listings
  Stream<List<StoreListing>> streamActiveListings() {
    // Query without orderBy, then sort client-side (fallback for missing index)
    return _listingsCollection
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final listings = snapshot.docs
              .map((doc) => StoreListing.fromFirestore(doc))
              .toList();
          
          // Sort client-side by createdAt descending
          listings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          return listings;
        })
        .handleError((error) {
          print('⚠️ Store listings stream error (likely missing index): $error');
          print('💡 Deploy indexes with: firebase deploy --only firestore:indexes');
          return <StoreListing>[];
        });
  }

  /// Get active listings with pagination
  Future<List<StoreListing>> getActiveListingsPaginated({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      // Try with orderBy first
      Query query = _listingsCollection
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => StoreListing.fromFirestore(doc))
          .toList();
    } catch (e) {
      // Fallback: Query without orderBy, sort client-side
      print('⚠️ Index not found, using client-side sorting for pagination');
      
      final snapshot = await _listingsCollection
          .where('isActive', isEqualTo: true)
          .limit(limit)
          .get();
      
      final listings = snapshot.docs
          .map((doc) => StoreListing.fromFirestore(doc))
          .toList();
      
      listings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return listings;
    }
  }

  /// Get listings by owner
  Future<List<StoreListing>> getListingsByOwner(String ownerId) async {
    final snapshot = await _listingsCollection
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => StoreListing.fromFirestore(doc))
        .toList();
  }

  /// Get listings by project ID
  Future<List<StoreListing>> getListingsByProject(String projectId) async {
    final snapshot = await _listingsCollection
        .where('projectId', isEqualTo: projectId)
        .get();

    return snapshot.docs
        .map((doc) => StoreListing.fromFirestore(doc))
        .toList();
  }

  /// Stream listings by owner
  Stream<List<StoreListing>> streamListingsByOwner(String ownerId) {
    // Query without orderBy, then sort client-side (fallback for missing index)
    return _listingsCollection
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
          final listings = snapshot.docs
              .map((doc) => StoreListing.fromFirestore(doc))
              .toList();
          
          // Sort client-side by createdAt descending
          listings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          return listings;
        })
        .handleError((error) {
          print('⚠️ Owner listings stream error (likely missing index): $error');
          print('💡 Deploy indexes with: firebase deploy --only firestore:indexes');
          return <StoreListing>[];
        });
  }

  /// Search listings by title
  Future<List<StoreListing>> searchListings(String query) async {
    // Firestore doesn't support full-text search, using prefix matching
    final snapshot = await _listingsCollection
        .where('isActive', isEqualTo: true)
        .orderBy('title')
        .startAt([query])
        .endAt([query + '\uf8ff'])
        .get();

    return snapshot.docs
        .map((doc) => StoreListing.fromFirestore(doc))
        .toList();
  }

  /// Search listings by tag
  Future<List<StoreListing>> searchByTag(String tag) async {
    final snapshot = await _listingsCollection
        .where('isActive', isEqualTo: true)
        .where('tags', arrayContains: tag)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => StoreListing.fromFirestore(doc))
        .toList();
  }

  /// Get popular listings (sorted by totalSold)
  Future<List<StoreListing>> getPopularListings({int limit = 10}) async {
    final snapshot = await _listingsCollection
        .where('isActive', isEqualTo: true)
        .orderBy('totalSold', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => StoreListing.fromFirestore(doc))
        .toList();
  }

  /// Get top rated listings (sorted by averageRating)
  Future<List<StoreListing>> getTopRatedListings({int limit = 10}) async {
    final snapshot = await _listingsCollection
        .where('isActive', isEqualTo: true)
        .where('totalReviews', isGreaterThan: 0) // Only show rated items
        .orderBy('totalReviews')
        .orderBy('averageRating', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => StoreListing.fromFirestore(doc))
        .toList();
  }

  /// Get listings by price range
  Future<List<StoreListing>> getListingsByPriceRange({
    required double minPrice,
    required double maxPrice,
  }) async {
    final snapshot = await _listingsCollection
        .where('isActive', isEqualTo: true)
        .where('price', isGreaterThanOrEqualTo: minPrice)
        .where('price', isLessThanOrEqualTo: maxPrice)
        .orderBy('price')
        .get();

    return snapshot.docs
        .map((doc) => StoreListing.fromFirestore(doc))
        .toList();
  }

  // ==================== SALES & RATINGS ====================

  /// Increment total sold count (called after successful purchase)
  Future<void> incrementTotalSold(String listingId) async {
    await _listingsCollection.doc(listingId).update({
      'totalSold': FieldValue.increment(1),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Update rating (after user submits review)
  Future<void> updateRating(
    String listingId,
    double newAverageRating,
    int totalReviews,
  ) async {
    await _listingsCollection.doc(listingId).update({
      'averageRating': newAverageRating,
      'totalReviews': totalReviews,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Toggle listing active status
  Future<void> toggleListingStatus(String listingId, bool isActive) async {
    await _listingsCollection.doc(listingId).update({
      'isActive': isActive,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Add tags to listing
  Future<void> addTags(String listingId, List<String> tags) async {
    await _listingsCollection.doc(listingId).update({
      'tags': FieldValue.arrayUnion(tags),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Remove tags from listing
  Future<void> removeTags(String listingId, List<String> tags) async {
    await _listingsCollection.doc(listingId).update({
      'tags': FieldValue.arrayRemove(tags),
      'updatedAt': Timestamp.now(),
    });
  }

  // ==================== ANALYTICS ====================

  /// Get total active listings count
  Future<int> getTotalActiveListingsCount() async {
    final snapshot =
        await _listingsCollection.where('isActive', isEqualTo: true).count().get();
    return snapshot.count ?? 0;
  }

  /// Get total sales revenue for owner
  Future<double> getTotalRevenue(String ownerId) async {
    final snapshot = await _listingsCollection
        .where('ownerId', isEqualTo: ownerId)
        .get();

    double totalRevenue = 0;
    for (var doc in snapshot.docs) {
      final listing = StoreListing.fromFirestore(doc);
      totalRevenue += listing.price * listing.totalSold;
    }

    return totalRevenue;
  }

  /// Get owner's total sales count
  Future<int> getOwnerTotalSales(String ownerId) async {
    final snapshot = await _listingsCollection
        .where('ownerId', isEqualTo: ownerId)
        .get();

    int totalSales = 0;
    for (var doc in snapshot.docs) {
      final listing = StoreListing.fromFirestore(doc);
      totalSales += listing.totalSold;
    }

    return totalSales;
  }
}
