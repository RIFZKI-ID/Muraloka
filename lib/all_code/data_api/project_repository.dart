import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/project.dart';

/// Repository untuk mengelola Project di Firestore
/// Mendukung private projects dan shared projects
class ProjectRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String appId;

  ProjectRepository({required this.appId});

  /// Path untuk private projects: /artifacts/{appId}/users/{userId}/projects
  CollectionReference _privateProjectsCollection(String userId) {
    return _firestore
        .collection('artifacts')
        .doc(appId)
        .collection('users')
        .doc(userId)
        .collection('projects');
  }

  /// Path untuk shared projects: /artifacts/{appId}/public/data/projects_shared
  CollectionReference get _sharedProjectsCollection {
    return _firestore
        .collection('artifacts')
        .doc(appId)
        .collection('public')
        .doc('data')
        .collection('projects_shared');
  }

  // ==================== PRIVATE PROJECTS ====================

  /// Create private project
  Future<String> createPrivateProject(Project project, String userId) async {
    final docRef = await _privateProjectsCollection(userId).add(project.toMap());
    return docRef.id;
  }

  /// Read private project by ID
  Future<Project?> getPrivateProject(String userId, String projectId) async {
    final doc = await _privateProjectsCollection(userId).doc(projectId).get();
    if (!doc.exists) return null;
    return Project.fromFirestore(doc);
  }

  /// Update private project
  Future<void> updatePrivateProject(
    String userId,
    String projectId,
    Map<String, dynamic> updates,
  ) async {
    await _privateProjectsCollection(userId).doc(projectId).update({
      ...updates,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Delete private project (only owner can do this)
  Future<void> deletePrivateProject(String userId, String projectId) async {
    await _privateProjectsCollection(userId).doc(projectId).delete();
  }

  /// Stream private projects for user
  Stream<List<Project>> streamPrivateProjects(String userId) {
    return _privateProjectsCollection(userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Project.fromFirestore(doc)).toList());
  }

  /// Get private projects with pagination
  Future<List<Project>> getPrivateProjectsPaginated(
    String userId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _privateProjectsCollection(userId)
        .orderBy('updatedAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Project.fromFirestore(doc)).toList();
  }

  // ==================== SHARED PROJECTS ====================

  /// Share project to public collection
  Future<String> shareProject(Project project) async {
    final docRef = await _sharedProjectsCollection.add(project.toMap());
    return docRef.id;
  }

  /// Read shared project by ID
  Future<Project?> getSharedProject(String projectId) async {
    final doc = await _sharedProjectsCollection.doc(projectId).get();
    if (!doc.exists) return null;
    return Project.fromFirestore(doc);
  }

  /// Update shared project (only for collaborators)
  Future<void> updateSharedProject(
    String projectId,
    Map<String, dynamic> updates,
  ) async {
    await _sharedProjectsCollection.doc(projectId).update({
      ...updates,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Delete shared project (only owner can do this)
  Future<void> deleteSharedProject(String projectId) async {
    await _sharedProjectsCollection.doc(projectId).delete();
  }

  /// Add collaborator to project
  Future<void> addCollaborator(String projectId, String collaboratorId) async {
    await _sharedProjectsCollection.doc(projectId).update({
      'collaboratorIds': FieldValue.arrayUnion([collaboratorId]),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Remove collaborator from project (owner only) - ENHANCED VERSION
  Future<void> removeCollaborator(
    String projectId,
    String collaboratorId, {
    String? ownerId, // Optional untuk validation
  }) async {
    // If ownerId provided, validate ownership
    if (ownerId != null) {
      final project = await getSharedProject(projectId);
      if (project != null && !project.isOwner(ownerId)) {
        throw Exception('Only owner can remove collaborators');
      }
    }

    await _sharedProjectsCollection.doc(projectId).update({
      'collaboratorIds': FieldValue.arrayRemove([collaboratorId]),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Stream shared projects
  Stream<List<Project>> streamSharedProjects() {
    return _sharedProjectsCollection
        .where('isPublic', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Project.fromFirestore(doc)).toList());
  }

  /// Stream projects where user is collaborator
  Stream<List<Project>> streamCollaborativeProjects(String userId) {
    return _sharedProjectsCollection
        .where('collaboratorIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Project.fromFirestore(doc)).toList());
  }

  /// Search shared projects by name
  Future<List<Project>> searchSharedProjects(String query) async {
    // Firestore doesn't support full-text search, so we use prefix matching
    final snapshot = await _sharedProjectsCollection
        .where('isPublic', isEqualTo: true)
        .orderBy('name')
        .startAt([query])
        .endAt([query + '\uf8ff'])
        .get();

    return snapshot.docs.map((doc) => Project.fromFirestore(doc)).toList();
  }

  /// Get shared projects with pagination
  Future<List<Project>> getSharedProjectsPaginated({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _sharedProjectsCollection
        .where('isPublic', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Project.fromFirestore(doc)).toList();
  }

  // ==================== HELPER METHODS ====================

  /// Move private project to shared (untuk collaboration)
  Future<String> moveToShared(String userId, String projectId) async {
    // Get private project
    final project = await getPrivateProject(userId, projectId);
    if (project == null) {
      throw Exception('Project not found');
    }

    // Create in shared collection
    final sharedId = await shareProject(project.copyWith(isPublic: true));

    // Delete from private collection
    await deletePrivateProject(userId, projectId);

    return sharedId;
  }

  /// Move shared project back to private (stop collaboration)
  Future<String> moveToPrivate(String userId, String sharedProjectId) async {
    // Get shared project
    final project = await getSharedProject(sharedProjectId);
    if (project == null) {
      throw Exception('Project not found');
    }

    // Only owner can move to private
    if (!project.isOwner(userId)) {
      throw Exception('Only owner can move project to private');
    }

    // Create in private collection
    final privateId = await createPrivateProject(
      project.copyWith(isPublic: false, collaboratorIds: []),
      userId,
    );

    // Delete from shared collection
    await deleteSharedProject(sharedProjectId);

    return privateId;
  }

  // ==================== COLLABORATION FEATURES ====================

  /// Generate unique 6-digit room code
  String _generateRoomCode() {
    final random = DateTime.now().millisecondsSinceEpoch % 1000000;
    return random.toString().padLeft(6, '0');
  }

  /// Generate and set room code for project (owner only)
  Future<String> generateRoomCode(String projectId, String userId,
      {bool isShared = true}) async {
    final project = isShared
        ? await getSharedProject(projectId)
        : await getPrivateProject(userId, projectId);

    if (project == null) {
      throw Exception('Project not found');
    }

    if (!project.isOwner(userId)) {
      throw Exception('Only owner can generate room code');
    }

    // Generate unique room code
    String roomCode;
    bool isUnique = false;
    int attempts = 0;

    while (!isUnique && attempts < 10) {
      roomCode = _generateRoomCode();

      // Check if code already exists
      final existing = await _sharedProjectsCollection
          .where('roomCode', isEqualTo: roomCode)
          .limit(1)
          .get();

      if (existing.docs.isEmpty) {
        isUnique = true;

        // Update project dengan room code
        if (isShared) {
          await updateSharedProject(projectId, {'roomCode': roomCode});
        } else {
          await updatePrivateProject(userId, projectId, {'roomCode': roomCode});
        }

        return roomCode;
      }

      attempts++;
    }

    throw Exception('Failed to generate unique room code');
  }

  /// Join project using room code
  Future<Project?> joinProjectByRoomCode(
      String roomCode, String userId) async {
    try {
      Project? project;
      String? projectId;
      bool isShared = false;

      // Search in shared projects first
      final sharedQuery = await _sharedProjectsCollection
          .where('roomCode', isEqualTo: roomCode)
          .limit(1)
          .get();

      if (sharedQuery.docs.isNotEmpty) {
        final doc = sharedQuery.docs.first;
        project = Project.fromFirestore(doc);
        projectId = doc.id;
        isShared = true;
      } else {
        // Search in private projects (all users)
        // Note: This requires a collection group query
        final privateQuery = await _firestore
            .collectionGroup('projects')
            .where('roomCode', isEqualTo: roomCode)
            .limit(1)
            .get();

        if (privateQuery.docs.isEmpty) {
          throw Exception('Invalid room code or project not found');
        }

        final doc = privateQuery.docs.first;
        project = Project.fromFirestore(doc);
        projectId = doc.id;
        isShared = false;
      }

      // Check if user is already owner
      if (project.isOwner(userId)) {
        return project; // Already owner, just return project
      }

      // Check if user is already collaborator
      if (project.isCollaborator(userId)) {
        return project; // Already collaborator, just return project
      }

      // Add user to collaborators
      final updatedCollaborators = [...project.collaboratorIds, userId];

      // Update in appropriate collection
      if (isShared) {
        await updateSharedProject(projectId, {
          'collaboratorIds': updatedCollaborators,
        });
      } else {
        // For private projects, need to share it first
        // Move to shared collection
        final sharedId = await shareProject(project.copyWith(isPublic: true));
        
        // Then add collaborator to the newly shared project
        await updateSharedProject(sharedId, {
          'collaboratorIds': updatedCollaborators,
        });
        
        projectId = sharedId; // Update to use shared project ID
        isShared = true; // Update flag since we moved it
      }

      // Return updated project
      return project.copyWith(
        collaboratorIds: updatedCollaborators,
        isPublic: isShared,
      );
    } catch (e) {
      print('Error joining project: $e');
      throw Exception('Failed to join project: $e');
    }
  }

  /// Get all collaborators info (placeholder - would need user repository)
  Future<List<String>> getCollaboratorIds(String projectId,
      {bool isShared = true}) async {
    final doc = isShared
        ? await _sharedProjectsCollection.doc(projectId).get()
        : null;

    if (doc == null || !doc.exists) {
      return [];
    }

    final data = doc.data() as Map<String, dynamic>;
    return List<String>.from(data['collaboratorIds'] ?? []);
  }

  /// Revoke room code (owner only) - prevent new people from joining
  Future<void> revokeRoomCode(String projectId, String userId,
      {bool isShared = true}) async {
    final project = isShared
        ? await getSharedProject(projectId)
        : await getPrivateProject(userId, projectId);

    if (project == null) {
      throw Exception('Project not found');
    }

    if (!project.isOwner(userId)) {
      throw Exception('Only owner can revoke room code');
    }

    // Remove room code
    if (isShared) {
      await updateSharedProject(projectId, {
        'roomCode': FieldValue.delete(),
      });
    } else {
      await updatePrivateProject(userId, projectId, {
        'roomCode': FieldValue.delete(),
      });
    }
  }
}
