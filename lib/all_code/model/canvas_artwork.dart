import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Model untuk Canvas Artwork
class CanvasArtwork extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String imageDataBase64; // Canvas image dalam format base64
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata; // Optional metadata (size, format, etc)

  const CanvasArtwork({
    required this.id,
    required this.userId,
    required this.title,
    required this.imageDataBase64,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  /// Convert from Firestore document
  factory CanvasArtwork.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CanvasArtwork(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? 'Untitled',
      imageDataBase64: data['imageDataBase64'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert from map
  factory CanvasArtwork.fromMap(Map<String, dynamic> map, String id) {
    return CanvasArtwork(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? 'Untitled',
      imageDataBase64: map['imageDataBase64'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'imageDataBase64': imageDataBase64,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'imageDataBase64': imageDataBase64,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  /// Copy with method untuk update
  CanvasArtwork copyWith({
    String? id,
    String? userId,
    String? title,
    String? imageDataBase64,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return CanvasArtwork(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      imageDataBase64: imageDataBase64 ?? this.imageDataBase64,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        imageDataBase64,
        createdAt,
        updatedAt,
        metadata,
      ];
}
