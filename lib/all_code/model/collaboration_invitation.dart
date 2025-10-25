import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Model untuk Collaboration Invitation
/// Disimpan di: /artifacts/{appId}/public/data/invitations/{invitationId}
class CollaborationInvitation extends Equatable {
  final String id;
  final String projectId; // Project yang diundang
  final String projectName; // Nama project untuk display
  final String ownerId; // Yang mengundang
  final String ownerName; // Nama owner untuk display
  final String inviteeEmail; // Email yang diundang
  final String? inviteeUserId; // UserId jika sudah terdaftar (nullable)
  final DateTime createdAt;
  final DateTime? acceptedAt; // Null jika belum di-accept
  final DateTime? rejectedAt; // Null jika belum di-reject
  final InvitationStatus status;

  const CollaborationInvitation({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.ownerId,
    required this.ownerName,
    required this.inviteeEmail,
    this.inviteeUserId,
    required this.createdAt,
    this.acceptedAt,
    this.rejectedAt,
    this.status = InvitationStatus.pending,
  });

  /// Check if invitation is pending
  bool get isPending => status == InvitationStatus.pending;

  /// Check if invitation is accepted
  bool get isAccepted => status == InvitationStatus.accepted;

  /// Check if invitation is rejected
  bool get isRejected => status == InvitationStatus.rejected;

  /// Convert from Firestore document
  factory CollaborationInvitation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CollaborationInvitation(
      id: doc.id,
      projectId: data['projectId'] as String? ?? '',
      projectName: data['projectName'] as String? ?? 'Untitled Project',
      ownerId: data['ownerId'] as String? ?? '',
      ownerName: data['ownerName'] as String? ?? 'Unknown',
      inviteeEmail: data['inviteeEmail'] as String? ?? '',
      inviteeUserId: data['inviteeUserId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      acceptedAt: (data['acceptedAt'] as Timestamp?)?.toDate(),
      rejectedAt: (data['rejectedAt'] as Timestamp?)?.toDate(),
      status: InvitationStatus.values.firstWhere(
        (e) => e.toString() == 'InvitationStatus.${data['status']}',
        orElse: () => InvitationStatus.pending,
      ),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'projectId': projectId,
      'projectName': projectName,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'inviteeEmail': inviteeEmail,
      if (inviteeUserId != null) 'inviteeUserId': inviteeUserId,
      'createdAt': Timestamp.fromDate(createdAt),
      if (acceptedAt != null) 'acceptedAt': Timestamp.fromDate(acceptedAt!),
      if (rejectedAt != null) 'rejectedAt': Timestamp.fromDate(rejectedAt!),
      'status': status.toString().split('.').last,
    };
  }

  /// Copy with method
  CollaborationInvitation copyWith({
    String? id,
    String? projectId,
    String? projectName,
    String? ownerId,
    String? ownerName,
    String? inviteeEmail,
    String? inviteeUserId,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? rejectedAt,
    InvitationStatus? status,
  }) {
    return CollaborationInvitation(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      inviteeEmail: inviteeEmail ?? this.inviteeEmail,
      inviteeUserId: inviteeUserId ?? this.inviteeUserId,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        projectName,
        ownerId,
        ownerName,
        inviteeEmail,
        inviteeUserId,
        createdAt,
        acceptedAt,
        rejectedAt,
        status,
      ];
}

/// Invitation status enum
enum InvitationStatus {
  pending,
  accepted,
  rejected,
}
