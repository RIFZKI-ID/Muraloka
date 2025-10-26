import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Model untuk listing di marketplace
/// Disimpan di: /artifacts/{appId}/public/data/store_listings/{listingId}
class StoreListing extends Equatable {
  final String id;
  final String title;
  final String projectId; // Reference ke project yang dijual
  final String ownerId; // Pemilik yang menjual
  final String ownerName; // Nama creator/pemilik
  final double price;
  final String? description;
  final String? thumbnailBase64; // Thumbnail untuk preview
  final int totalSold; // Total penjualan
  final double averageRating; // Rating rata-rata (0-5)
  final int totalReviews; // Jumlah review
  final List<String> tags; // Tags untuk search & kategorisasi
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive; // Status listing (aktif/tidak aktif)

  const StoreListing({
    required this.id,
    required this.title,
    required this.projectId,
    required this.ownerId,
    this.ownerName = 'Unknown Creator', // Default for backward compatibility, akan di-set saat create listing
    required this.price,
    this.description,
    this.thumbnailBase64,
    this.totalSold = 0,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  /// Cek apakah user adalah pemilik listing
  bool isOwner(String userId) {
    return ownerId == userId;
  }

  /// Convert dari Firestore DocumentSnapshot
  factory StoreListing.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StoreListing(
      id: doc.id,
      title: data['title'] as String? ?? '',
      projectId: data['projectId'] as String? ?? '',
      ownerId: data['ownerId'] as String? ?? '',
      ownerName: data['ownerName'] as String? ?? 'Unknown Creator',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      description: data['description'] as String?,
      thumbnailBase64: data['thumbnailBase64'] as String?,
      totalSold: data['totalSold'] as int? ?? 0,
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: data['totalReviews'] as int? ?? 0,
      tags: (data['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  /// Convert dari Map
  factory StoreListing.fromMap(Map<String, dynamic> data, String id) {
    return StoreListing(
      id: id,
      title: data['title'] as String? ?? '',
      projectId: data['projectId'] as String? ?? '',
      ownerId: data['ownerId'] as String? ?? '',
      ownerName: data['ownerName'] as String? ?? 'Unknown Creator',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      description: data['description'] as String?,
      thumbnailBase64: data['thumbnailBase64'] as String?,
      totalSold: data['totalSold'] as int? ?? 0,
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: data['totalReviews'] as int? ?? 0,
      tags: (data['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  /// Convert ke Map untuk Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'projectId': projectId,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'price': price,
      'description': description,
      'thumbnailBase64': thumbnailBase64,
      'totalSold': totalSold,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  /// Copy dengan perubahan
  StoreListing copyWith({
    String? id,
    String? title,
    String? projectId,
    String? ownerId,
    String? ownerName,
    double? price,
    String? description,
    String? thumbnailBase64,
    int? totalSold,
    double? averageRating,
    int? totalReviews,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return StoreListing(
      id: id ?? this.id,
      title: title ?? this.title,
      projectId: projectId ?? this.projectId,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      price: price ?? this.price,
      description: description ?? this.description,
      thumbnailBase64: thumbnailBase64?? this.thumbnailBase64,
      totalSold: totalSold ?? this.totalSold,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        projectId,
        ownerId,
        ownerName,
        price,
        description,
        thumbnailBase64,
        totalSold,
        averageRating,
        totalReviews,
        tags,
        createdAt,
        updatedAt,
        isActive,
      ];
}
