import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/collaboration_invitation.dart';

/// Repository untuk mengelola Collaboration Invitations
/// Path: /artifacts/{appId}/public/data/invitations
class InvitationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String appId;

  InvitationRepository({required this.appId});

  /// Path untuk invitations collection
  CollectionReference get _invitationsCollection {
    return _firestore
        .collection('artifacts')
        .doc(appId)
        .collection('public')
        .doc('data')
        .collection('invitations');
  }

  // ==================== CRUD OPERATIONS ====================

  /// Create new invitation
  Future<String> createInvitation(CollaborationInvitation invitation) async {
    final docRef = await _invitationsCollection.add(invitation.toFirestore());
    print('✅ Invitation created: ${docRef.id}');
    return docRef.id;
  }

  /// Get invitation by ID
  Future<CollaborationInvitation?> getInvitation(String invitationId) async {
    final doc = await _invitationsCollection.doc(invitationId).get();
    if (!doc.exists) return null;
    return CollaborationInvitation.fromFirestore(doc);
  }

  /// Update invitation
  Future<void> updateInvitation(
    String invitationId,
    Map<String, dynamic> updates,
  ) async {
    await _invitationsCollection.doc(invitationId).update(updates);
    print('✅ Invitation updated: $invitationId');
  }

  /// Delete invitation
  Future<void> deleteInvitation(String invitationId) async {
    await _invitationsCollection.doc(invitationId).delete();
    print('✅ Invitation deleted: $invitationId');
  }

  // ==================== QUERIES ====================

  /// Stream invitations for a specific email (for current user)
  Stream<List<CollaborationInvitation>> streamInvitationsForEmail(
    String email,
  ) {
    return _invitationsCollection
        .where('inviteeEmail', isEqualTo: email)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CollaborationInvitation.fromFirestore(doc))
          .toList();
    });
  }

  /// Get pending invitations for email
  Future<List<CollaborationInvitation>> getPendingInvitationsForEmail(
    String email,
  ) async {
    final snapshot = await _invitationsCollection
        .where('inviteeEmail', isEqualTo: email)
        .where('status', isEqualTo: 'pending')
        .get();

    return snapshot.docs
        .map((doc) => CollaborationInvitation.fromFirestore(doc))
        .toList();
  }

  /// Get invitations for a project (sent by owner)
  Future<List<CollaborationInvitation>> getInvitationsForProject(
    String projectId,
  ) async {
    final snapshot = await _invitationsCollection
        .where('projectId', isEqualTo: projectId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => CollaborationInvitation.fromFirestore(doc))
        .toList();
  }

  /// Stream invitations for a project
  Stream<List<CollaborationInvitation>> streamInvitationsForProject(
    String projectId,
  ) {
    return _invitationsCollection
        .where('projectId', isEqualTo: projectId)
        .snapshots()
        .map((snapshot) {
      final invitations = snapshot.docs
          .map((doc) => CollaborationInvitation.fromFirestore(doc))
          .toList();
      
      // Sort by createdAt descending
      invitations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return invitations;
    });
  }

  /// Accept invitation
  Future<void> acceptInvitation(String invitationId, String userId) async {
    await updateInvitation(invitationId, {
      'status': 'accepted',
      'acceptedAt': Timestamp.now(),
      'inviteeUserId': userId,
    });
    print('✅ Invitation accepted by user: $userId');
  }

  /// Reject invitation
  Future<void> rejectInvitation(String invitationId) async {
    await updateInvitation(invitationId, {
      'status': 'rejected',
      'rejectedAt': Timestamp.now(),
    });
    print('✅ Invitation rejected');
  }

  /// Check if email already invited to project
  Future<bool> isEmailAlreadyInvited(String projectId, String email) async {
    final snapshot = await _invitationsCollection
        .where('projectId', isEqualTo: projectId)
        .where('inviteeEmail', isEqualTo: email)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// Get invitation count for user
  Future<int> getPendingInvitationCount(String email) async {
    final snapshot = await _invitationsCollection
        .where('inviteeEmail', isEqualTo: email)
        .where('status', isEqualTo: 'pending')
        .get();

    return snapshot.docs.length;
  }
}
