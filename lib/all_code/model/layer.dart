import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Model untuk Layer dalam Project
class Layer extends Equatable {
  final String id;
  final String name;
  final bool isVisible;
  final double opacity;
  final List<Map<String, dynamic>> strokes; // List of stroke data
  final int zIndex;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Layer({
    required this.id,
    required this.name,
    this.isVisible = true,
    this.opacity = 1.0,
    this.strokes = const [],
    required this.zIndex,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert from Firestore document
  factory Layer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Layer(
      id: doc.id,
      name: data['name'] ?? 'Layer',
      isVisible: data['isVisible'] ?? true,
      opacity: (data['opacity'] ?? 1.0).toDouble(),
      strokes: List<Map<String, dynamic>>.from(data['strokes'] ?? []),
      zIndex: data['zIndex'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert from map
  factory Layer.fromMap(Map<String, dynamic> map, String id) {
    return Layer(
      id: id,
      name: map['name'] ?? 'Layer',
      isVisible: map['isVisible'] ?? true,
      opacity: (map['opacity'] ?? 1.0).toDouble(),
      strokes: List<Map<String, dynamic>>.from(map['strokes'] ?? []),
      zIndex: map['zIndex'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'isVisible': isVisible,
      'opacity': opacity,
      'strokes': strokes,
      'zIndex': zIndex,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Copy with method
  Layer copyWith({
    String? id,
    String? name,
    bool? isVisible,
    double? opacity,
    List<Map<String, dynamic>>? strokes,
    int? zIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Layer(
      id: id ?? this.id,
      name: name ?? this.name,
      isVisible: isVisible ?? this.isVisible,
      opacity: opacity ?? this.opacity,
      strokes: strokes ?? this.strokes,
      zIndex: zIndex ?? this.zIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert ke Map untuk Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isVisible': isVisible,
      'opacity': opacity,
      'strokes': strokes,
      'zIndex': zIndex,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        isVisible,
        opacity,
        strokes,
        zIndex,
        createdAt,
        updatedAt,
      ];
}
