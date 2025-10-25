import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Model untuk Project (Private & Shared) sesuai MVP
class Project extends Equatable {
  final String id;
  final String ownerId;
  final String name;
  final bool isPublic; // false = private, true = shared
  final List<String> collaboratorIds;
  final List<String> pendingInvitations; // Email/userId yang diundang tapi belum accept
  final String? roomCode; // 6-digit code untuk join collaboration
  final DateTime createdAt;
  final DateTime updatedAt;
  final int canvasWidth;
  final int canvasHeight;
  final String? thumbnailBase64; // Optional thumbnail
  final int? backgroundColor; // Background color sebagai int (Color.value)
  final bool autoSaveEnabled; // Auto-save setiap perubahan
  final bool isInMarketplace; // Apakah project sudah di-share ke marketplace

  const Project({
    required this.id,
    required this.ownerId,
    required this.name,
    this.isPublic = false,
    this.collaboratorIds = const [],
    this.pendingInvitations = const [],
    this.roomCode,
    required this.createdAt,
    required this.updatedAt,
    this.canvasWidth = 1920,
    this.canvasHeight = 1080,
    this.thumbnailBase64,
    this.backgroundColor,
    this.autoSaveEnabled = true,
    this.isInMarketplace = false,
  });

  /// Check if user is owner - CRITICAL for MVP ownership control
  bool isOwner(String userId) => ownerId == userId;

  /// Check if user is collaborator
  bool isCollaborator(String userId) => collaboratorIds.contains(userId);

  /// Check if user has access (owner or collaborator)
  bool hasAccess(String userId) => isOwner(userId) || isCollaborator(userId);

  /// Convert from Firestore document
  factory Project.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Project(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      name: data['name'] ?? 'Untitled Project',
      isPublic: data['isPublic'] ?? false,
      collaboratorIds: List<String>.from(data['collaboratorIds'] ?? []),
      pendingInvitations: List<String>.from(data['pendingInvitations'] ?? []),
      roomCode: data['roomCode'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      canvasWidth: data['canvasWidth'] ?? 1920,
      canvasHeight: data['canvasHeight'] ?? 1080,
      thumbnailBase64: data['thumbnailBase64'],
      backgroundColor: data['backgroundColor'],
      autoSaveEnabled: data['autoSaveEnabled'] ?? true,
      isInMarketplace: data['isInMarketplace'] ?? false,
    );
  }

  /// Convert from map
  factory Project.fromMap(Map<String, dynamic> map, String id) {
    return Project(
      id: id,
      ownerId: map['ownerId'] ?? '',
      name: map['name'] ?? 'Untitled Project',
      isPublic: map['isPublic'] ?? false,
      collaboratorIds: List<String>.from(map['collaboratorIds'] ?? []),
      pendingInvitations: List<String>.from(map['pendingInvitations'] ?? []),
      roomCode: map['roomCode'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      canvasWidth: map['canvasWidth'] ?? 1920,
      canvasHeight: map['canvasHeight'] ?? 1080,
      thumbnailBase64: map['thumbnailBase64'],
      backgroundColor: map['backgroundColor'],
      autoSaveEnabled: map['autoSaveEnabled'] ?? true,
      isInMarketplace: map['isInMarketplace'] ?? false,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'name': name,
      'isPublic': isPublic,
      'collaboratorIds': collaboratorIds,
      'pendingInvitations': pendingInvitations,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'canvasWidth': canvasWidth,
      'canvasHeight': canvasHeight,
      'autoSaveEnabled': autoSaveEnabled,
      'isInMarketplace': isInMarketplace,
      if (roomCode != null) 'roomCode': roomCode,
      if (thumbnailBase64 != null) 'thumbnailBase64': thumbnailBase64,
      if (backgroundColor != null) 'backgroundColor': backgroundColor,
    };
  }

  /// Copy with method
  Project copyWith({
    String? id,
    String? ownerId,
    String? name,
    bool? isPublic,
    List<String>? collaboratorIds,
    List<String>? pendingInvitations,
    String? roomCode,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? canvasWidth,
    int? canvasHeight,
    String? thumbnailBase64,
    int? backgroundColor,
    bool? autoSaveEnabled,
    bool? isInMarketplace,
  }) {
    return Project(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      isPublic: isPublic ?? this.isPublic,
      collaboratorIds: collaboratorIds ?? this.collaboratorIds,
      pendingInvitations: pendingInvitations ?? this.pendingInvitations,
      roomCode: roomCode ?? this.roomCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      canvasWidth: canvasWidth ?? this.canvasWidth,
      canvasHeight: canvasHeight ?? this.canvasHeight,
      thumbnailBase64: thumbnailBase64 ?? this.thumbnailBase64,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      autoSaveEnabled: autoSaveEnabled ?? this.autoSaveEnabled,
      isInMarketplace: isInMarketplace ?? this.isInMarketplace,
    );
  }

  /// Convert ke Map untuk Firestore
  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'name': name,
      'isPublic': isPublic,
      'collaboratorIds': collaboratorIds,
      'pendingInvitations': pendingInvitations,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'canvasWidth': canvasWidth,
      'canvasHeight': canvasHeight,
      'thumbnailBase64': thumbnailBase64,
      'autoSaveEnabled': autoSaveEnabled,
      'isInMarketplace': isInMarketplace,
      if (roomCode != null) 'roomCode': roomCode,
      if (backgroundColor != null) 'backgroundColor': backgroundColor,
    };
  }

  @override
  List<Object?> get props => [
        id,
        ownerId,
        name,
        isPublic,
        collaboratorIds,
        pendingInvitations,
        roomCode,
        createdAt,
        updatedAt,
        canvasWidth,
        canvasHeight,
        thumbnailBase64,
        backgroundColor,
        autoSaveEnabled,
        isInMarketplace,
      ];
}
