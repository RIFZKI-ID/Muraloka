import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/layer.dart';

/// Repository untuk mengelola Layer (subcollection dari Project)
/// Path: /artifacts/{appId}/users/{userId}/projects/{projectId}/layers (private)
/// Path: /artifacts/{appId}/public/data/projects_shared/{projectId}/layers (shared)
class LayerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String appId;

  LayerRepository({required this.appId});

  /// Path untuk layers di private project
  CollectionReference _privateLayersCollection(
    String userId,
    String projectId,
  ) {
    return _firestore
        .collection('artifacts')
        .doc(appId)
        .collection('users')
        .doc(userId)
        .collection('projects')
        .doc(projectId)
        .collection('layers');
  }

  /// Path untuk layers di shared project
  CollectionReference _sharedLayersCollection(String projectId) {
    return _firestore
        .collection('artifacts')
        .doc(appId)
        .collection('public')
        .doc('data')
        .collection('projects_shared')
        .doc(projectId)
        .collection('layers');
  }

  // ==================== PRIVATE PROJECT LAYERS ====================

  /// Create layer in private project
  Future<String> createPrivateLayer(
    String userId,
    String projectId,
    Layer layer,
  ) async {
    final docRef =
        await _privateLayersCollection(userId, projectId).add(layer.toMap());
    return docRef.id;
  }

  /// Get layer by ID from private project
  Future<Layer?> getPrivateLayer(
    String userId,
    String projectId,
    String layerId,
  ) async {
    final doc =
        await _privateLayersCollection(userId, projectId).doc(layerId).get();
    if (!doc.exists) return null;
    return Layer.fromFirestore(doc);
  }

  /// Update layer in private project
  Future<void> updatePrivateLayer(
    String userId,
    String projectId,
    String layerId,
    Map<String, dynamic> updates,
  ) async {
    await _privateLayersCollection(userId, projectId).doc(layerId).update({
      ...updates,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Delete layer from private project
  Future<void> deletePrivateLayer(
    String userId,
    String projectId,
    String layerId,
  ) async {
    await _privateLayersCollection(userId, projectId).doc(layerId).delete();
  }

  /// Stream all layers from private project (ordered by zIndex)
  Stream<List<Layer>> streamPrivateLayers(String userId, String projectId) {
    return _privateLayersCollection(userId, projectId)
        .orderBy('zIndex')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Layer.fromFirestore(doc)).toList());
  }

  /// Get all layers from private project
  Future<List<Layer>> getPrivateLayers(String userId, String projectId) async {
    final snapshot = await _privateLayersCollection(userId, projectId)
        .orderBy('zIndex')
        .get();
    return snapshot.docs.map((doc) => Layer.fromFirestore(doc)).toList();
  }

  // ==================== SHARED PROJECT LAYERS ====================

  /// Create layer in shared project
  Future<String> createSharedLayer(
    String projectId,
    Layer layer, {
    required String ownerId,
    required List<String> collaboratorIds,
  }) async {
    final layerData = {
      ...layer.toMap(),
      'ownerId': ownerId,
      'collaboratorIds': collaboratorIds,
    };
    final docRef = await _sharedLayersCollection(projectId).add(layerData);
    return docRef.id;
  }

  /// Get layer by ID from shared project
  Future<Layer?> getSharedLayer(String projectId, String layerId) async {
    final doc = await _sharedLayersCollection(projectId).doc(layerId).get();
    if (!doc.exists) return null;
    return Layer.fromFirestore(doc);
  }

  /// Update layer in shared project
  Future<void> updateSharedLayer(
    String projectId,
    String layerId,
    Map<String, dynamic> updates,
  ) async {
    await _sharedLayersCollection(projectId).doc(layerId).update({
      ...updates,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Delete layer from shared project
  Future<void> deleteSharedLayer(String projectId, String layerId) async {
    await _sharedLayersCollection(projectId).doc(layerId).delete();
  }

  /// Stream all layers from shared project (ordered by zIndex)
  Stream<List<Layer>> streamSharedLayers(String projectId) {
    return _sharedLayersCollection(projectId)
        .orderBy('zIndex')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Layer.fromFirestore(doc)).toList());
  }

  /// Get all layers from shared project
  Future<List<Layer>> getSharedLayers(String projectId) async {
    final snapshot =
        await _sharedLayersCollection(projectId).orderBy('zIndex').get();
    return snapshot.docs.map((doc) => Layer.fromFirestore(doc)).toList();
  }

  // ==================== HELPER METHODS ====================

  /// Add stroke to layer (append to strokes array)
  Future<void> addStrokeToLayer(
    String projectId,
    String layerId,
    Map<String, dynamic> stroke, {
    bool isPrivate = false,
    String? userId,
  }) async {
    final collection = isPrivate && userId != null
        ? _privateLayersCollection(userId, projectId)
        : _sharedLayersCollection(projectId);

    await collection.doc(layerId).update({
      'strokes': FieldValue.arrayUnion([stroke]),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Clear all strokes from layer
  Future<void> clearLayerStrokes(
    String projectId,
    String layerId, {
    bool isPrivate = false,
    String? userId,
  }) async {
    final collection = isPrivate && userId != null
        ? _privateLayersCollection(userId, projectId)
        : _sharedLayersCollection(projectId);

    await collection.doc(layerId).update({
      'strokes': [],
      'updatedAt': Timestamp.now(),
    });
  }

  /// Update layer visibility
  Future<void> toggleLayerVisibility(
    String projectId,
    String layerId,
    bool isVisible, {
    bool isPrivate = false,
    String? userId,
  }) async {
    final collection = isPrivate && userId != null
        ? _privateLayersCollection(userId, projectId)
        : _sharedLayersCollection(projectId);

    await collection.doc(layerId).update({
      'isVisible': isVisible,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Update layer z-index (untuk reordering)
  Future<void> updateLayerZIndex(
    String projectId,
    String layerId,
    int newZIndex, {
    bool isPrivate = false,
    String? userId,
  }) async {
    final collection = isPrivate && userId != null
        ? _privateLayersCollection(userId, projectId)
        : _sharedLayersCollection(projectId);

    await collection.doc(layerId).update({
      'zIndex': newZIndex,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Batch update z-indexes for multiple layers (reordering)
  Future<void> reorderLayers(
    String projectId,
    Map<String, int> layerZIndexMap, {
    bool isPrivate = false,
    String? userId,
  }) async {
    final batch = _firestore.batch();
    final collection = isPrivate && userId != null
        ? _privateLayersCollection(userId, projectId)
        : _sharedLayersCollection(projectId);

    layerZIndexMap.forEach((layerId, zIndex) {
      batch.update(collection.doc(layerId), {
        'zIndex': zIndex,
        'updatedAt': Timestamp.now(),
      });
    });

    await batch.commit();
  }

  /// Duplicate layer
  Future<String> duplicateLayer(
    String projectId,
    String layerId, {
    bool isPrivate = false,
    String? userId,
    String? ownerId,
    List<String>? collaboratorIds,
  }) async {
    // Get original layer
    final Layer? originalLayer = isPrivate && userId != null
        ? await getPrivateLayer(userId, projectId, layerId)
        : await getSharedLayer(projectId, layerId);

    if (originalLayer == null) {
      throw Exception('Layer not found');
    }

    // Create copy with new timestamps
    final copiedLayer = originalLayer.copyWith(
      id: '', // Will be auto-generated
      name: '${originalLayer.name} (Copy)',
      zIndex: originalLayer.zIndex + 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Create new layer
    if (isPrivate && userId != null) {
      return await createPrivateLayer(userId, projectId, copiedLayer);
    } else {
      // For shared layers, require ownerId and collaboratorIds
      if (ownerId == null || collaboratorIds == null) {
        throw ArgumentError(
            'ownerId and collaboratorIds are required for shared layers');
      }
      return await createSharedLayer(
        projectId,
        copiedLayer,
        ownerId: ownerId,
        collaboratorIds: collaboratorIds,
      );
    }
  }

  // ==================== OPTIMIZATION METHODS ====================

  /// Update layer with batch write (for better performance)
  Future<void> updateLayerBatch(
    String projectId,
    String layerId,
    Map<String, dynamic> updates, {
    bool isPrivate = false,
    String? userId,
  }) async {
    final batch = _firestore.batch();
    final collection = isPrivate && userId != null
        ? _privateLayersCollection(userId, projectId)
        : _sharedLayersCollection(projectId);

    batch.update(collection.doc(layerId), {
      ...updates,
      'updatedAt': Timestamp.now(),
    });

    await batch.commit();
  }

  /// Check layer data size and recommend optimization
  Future<Map<String, dynamic>> analyzeLayerSize(
    String projectId,
    String layerId, {
    bool isPrivate = false,
    String? userId,
  }) async {
    final layer = isPrivate && userId != null
        ? await getPrivateLayer(userId, projectId, layerId)
        : await getSharedLayer(projectId, layerId);

    if (layer == null) {
      return {'error': 'Layer not found'};
    }

    final strokeCount = layer.strokes.length;
    final estimatedSize = strokeCount * 100; // Rough estimate: 100 bytes per stroke

    return {
      'strokeCount': strokeCount,
      'estimatedSizeBytes': estimatedSize,
      'estimatedSizeKB': (estimatedSize / 1024).toStringAsFixed(2),
      'needsOptimization': strokeCount > 1000, // >1000 strokes = optimize
      'recommendation': strokeCount > 1000
          ? 'Consider using stroke batching or compression'
          : 'Current size is optimal',
    };
  }
}
