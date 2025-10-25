import 'package:custom_flutter_painter/flutter_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For keyboard shortcuts
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'dart:math';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

import '../model/project.dart' as mvp;
import '../model/layer.dart' as mvp;
import '../model/store_listing.dart';
import '../data_api/project_repository.dart';
import '../data_api/layer_repository.dart';
import '../data_api/store_listing_repository.dart';
import '../widgets/ui_helpers.dart';
import 'sticker_dialog.dart'; // For sticker selection

/// Multi-layer canvas page dengan integrasi MVP
/// Mendukung private & shared projects dengan real-time collaboration
class LayerPaintPage extends StatefulWidget {
  final String? projectId; // Null = create new project
  final bool isShared; // Private or shared project
  final String? projectName; // Project name for new project
  final int? canvasWidth; // Canvas width for new project
  final int? canvasHeight; // Canvas height for new project

  const LayerPaintPage({
    Key? key,
    this.projectId,
    this.isShared = false,
    this.projectName,
    this.canvasWidth,
    this.canvasHeight,
  }) : super(key: key);

  @override
  _LayerPaintPageState createState() => _LayerPaintPageState();
}

class _LayerPaintPageState extends State<LayerPaintPage> {
  // Controllers & State
  late PainterController controller;
  late TransformationController transformationController;
  final FocusNode textFocusNode = FocusNode();
  ui.Image? backgroundImage;

  // Repositories
  late ProjectRepository projectRepo;
  late LayerRepository layerRepo;
  late StoreListingRepository listingRepo;

  // Current data
  mvp.Project? currentProject;
  List<mvp.Layer> layers = [];
  int selectedLayerIndex = 0;

  // Multi-layer rendering - Map of layer ID to rendered image
  Map<String, ui.Image?> layerImages = {};

  // Real-time collaboration
  List<String> activeCollaborators = []; // List of user IDs currently editing
  Map<String, DateTime> collaboratorPresence = {}; // Track last activity

  // Loading states
  bool isLoading = true;
  bool isSaving = false;

  // Incremental save optimization  
  List<Map<String, dynamic>>? _lastSavedStrokes;

  // User
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final String appId = 'muraloka_v1'; // Replace with your app ID

  // Canvas settings
  Color canvasBackgroundColor = Colors.white;
  bool isMirrorHorizontal = false;
  bool isMirrorVertical = false;

  // Toolbar visibility
  bool isToolbarVisible = true;

  // Brush style
  String currentBrushStyle = 'solid'; // solid, dashed, dotted

  // Canvas rotation
  double canvasRotation = 0.0; // Rotation angle in degrees (0, 90, 180, 270)
  
  // ✅ Gesture rotation for 2-finger rotate
  double gestureRotation = 0.0; // Free rotation angle from gesture (in radians)
  double lastGestureRotation = 0.0; // Track last rotation value

  // Minimap
  bool showMinimap = false;

  // Pan tool state
  bool isPanToolActive = false;

  // Blur tool state
  bool isBlurToolActive = false;
  double blurIntensity = 5.0; // Blur radius (1.0 - 20.0)

  // Layer multi-select state
  bool isMultiSelectMode = false;
  Set<String> selectedLayersForMerge = {}; // Changed from Set<int> to Set<String> (use layer IDs)

  // Paint settings
  Paint shapePaint = Paint()
    ..strokeWidth = 5
    ..color = Colors.red
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  // Sticker images
  static const List<String> stickerImageLinks = [
    "https://i.imgur.com/btoI5OX.png",
    "https://i.imgur.com/Fhttxlh.png",
    "https://i.imgur.com/XNTVJZs.png",
    "https://i.imgur.com/HFTtdqy.png",
    "https://i.imgur.com/DcIqEA6.png",
    "https://i.imgur.com/snJOcEz.png",
    "https://i.imgur.com/b61cnhi.png",
    "https://i.imgur.com/FkDFzYe.png",
    "https://i.imgur.com/P310x7d.png",
    "https://i.imgur.com/5AHZpua.png",
    "https://i.imgur.com/tmvJY4r.png",
    "https://i.imgur.com/PdVfGkV.png",
    "https://i.imgur.com/1PRzwBf.png",
    "https://i.imgur.com/VeeMfBS.png",
  ];

  @override
  void initState() {
    super.initState();

    // Initialize repositories
    projectRepo = ProjectRepository(appId: appId);
    layerRepo = LayerRepository(appId: appId);
    listingRepo = StoreListingRepository(appId: appId);

    // Initialize transformation controller for InteractiveViewer
    // Set initial scale to 1.0 (no auto-scaling to fit screen)
    transformationController = TransformationController();

    // Initialize controller
    controller = PainterController(
      settings: PainterSettings(
        text: TextSettings(
          focusNode: textFocusNode,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red,
            fontSize: 18,
          ),
        ),
        freeStyle: const FreeStyleSettings(color: Colors.red, strokeWidth: 5),
        shape: ShapeSettings(paint: shapePaint),
        scale: const ScaleSettings(enabled: true, minScale: 1, maxScale: 5),
      ),
    );

    // Add listener for auto-save when drawing changes
    controller.addListener(_onCanvasChanged);

    textFocusNode.addListener(() => setState(() {}));

    // Load or create project
    _initializeProject();
  }

  /// Called when canvas changes - auto save with debounce
  Timer? _saveDebounceTimer;
  void _onCanvasChanged() {
    // Cancel previous timer
    _saveDebounceTimer?.cancel();

    // Schedule save after 1 second of inactivity (reduced from 2s for better UX)
    _saveDebounceTimer = Timer(const Duration(seconds: 1), () {
      if (mounted && currentProject != null && layers.isNotEmpty) {
        print('🔄 Auto-saving canvas changes...');
        _saveCurrentLayer();
      }
    });
  }

  @override
  void dispose() {
    _saveDebounceTimer?.cancel();
    controller.removeListener(_onCanvasChanged);
    controller.dispose();
    transformationController.dispose();
    textFocusNode.dispose();
    super.dispose();
  }

  /// Initialize project: load existing or create new
  Future<void> _initializeProject() async {
    try {
      if (widget.projectId != null) {
        // Load existing project
        await _loadProject(widget.projectId!);
      } else {
        // Create new project
        await _createNewProject();
      }
    } catch (e) {
      _showError('Failed to initialize project: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// Load existing project and its layers
  Future<void> _loadProject(String projectId) async {
    // Load project
    final project = widget.isShared
        ? await projectRepo.getSharedProject(projectId)
        : await projectRepo.getPrivateProject(currentUserId, projectId);

    if (project == null) {
      throw Exception('Project not found');
    }

    // Check access permission
    if (widget.isShared && !project.hasAccess(currentUserId)) {
      throw Exception('You do not have access to this project');
    }

    setState(() {
      currentProject = project;
      // Load background color from project
      if (project.backgroundColor != null) {
        canvasBackgroundColor = Color(project.backgroundColor!);
      }
    });

    // Start real-time layer streaming (for shared projects)
    if (widget.isShared) {
      _startLayerStreaming(projectId);
      _trackPresence(projectId);
    } else {
      // Load layers once for private projects
      final loadedLayers = await layerRepo.getPrivateLayers(
        currentUserId,
        projectId,
      );
      setState(() => layers = loadedLayers);
    }

    // Load first layer's strokes if available
    if (layers.isNotEmpty) {
      _loadLayerToCanvas(layers[selectedLayerIndex]);
    }
  }

  /// Start real-time streaming for shared project layers
  void _startLayerStreaming(String projectId) {
    layerRepo.streamSharedLayers(projectId).listen((updatedLayers) {
      // Check if we have real updates
      bool hasChanges = false;
      
      if (layers.length != updatedLayers.length) {
        hasChanges = true;
      } else {
        // Check if current layer strokes have changed
        for (int i = 0; i < layers.length; i++) {
          if (layers[i].strokes.length != updatedLayers[i].strokes.length) {
            hasChanges = true;
            break;
          }
        }
      }

      if (hasChanges) {
        print('🔄 Real-time update: Layers changed, reloading canvas...');
        
        setState(() {
          layers = updatedLayers;
          // Ensure selected index is valid
          if (selectedLayerIndex >= layers.length) {
            selectedLayerIndex = layers.isEmpty ? 0 : layers.length - 1;
          }
        });

        // Reload canvas with updated layer data (REAL-TIME COLLABORATION)
        if (layers.isNotEmpty && selectedLayerIndex < layers.length) {
          _loadLayerToCanvas(layers[selectedLayerIndex]);
        }
      }
    });
  }

  /// Track user presence in shared project
  Future<void> _trackPresence(String projectId) async {
    if (!widget.isShared) return;

    // Add current user to collaborators if not already added
    if (currentProject != null &&
        !currentProject!.collaboratorIds.contains(currentUserId) &&
        !currentProject!.isOwner(currentUserId)) {
      try {
        await projectRepo.addCollaborator(projectId, currentUserId);
      } catch (e) {
        print('Failed to add as collaborator: $e');
      }
    }

    // Update presence timestamp
    _updatePresenceTimestamp(projectId);

    // Periodic presence updates (every 30 seconds)
    Stream.periodic(const Duration(seconds: 30)).listen((_) {
      if (mounted) {
        _updatePresenceTimestamp(projectId);
      }
    });
  }

  /// Update presence timestamp in Firestore
  Future<void> _updatePresenceTimestamp(String projectId) async {
    try {
      await projectRepo.updateSharedProject(projectId, {
        'activeCollaborators.$currentUserId': Timestamp.now(),
      });
    } catch (e) {
      print('Failed to update presence: $e');
    }
  }

  /// Create new private project
  Future<void> _createNewProject() async {
    final newProject = mvp.Project(
      id: '', // Will be auto-generated
      ownerId: currentUserId,
      name:
          widget.projectName ??
          'Untitled Project ${DateTime.now().millisecondsSinceEpoch}',
      isPublic: false,
      collaboratorIds: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      canvasWidth: widget.canvasWidth ?? 1920,
      canvasHeight: widget.canvasHeight ?? 1080,
    );

    // Save to Firestore
    final projectId = await projectRepo.createPrivateProject(
      newProject,
      currentUserId,
    );

    // Create default layer
    final defaultLayer = mvp.Layer(
      id: '',
      name: 'Layer 1',
      isVisible: true,
      opacity: 1.0,
      strokes: const [],
      zIndex: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final layerId = await layerRepo.createPrivateLayer(
      currentUserId,
      projectId,
      defaultLayer,
    );

    setState(() {
      currentProject = newProject.copyWith(id: projectId);
      layers = [defaultLayer.copyWith(id: layerId)];
      selectedLayerIndex = 0;
    });
  }

  /// Load layer's strokes to canvas
  Future<void> _loadLayerToCanvas(mvp.Layer layer) async {
    print('📥 Loading layer "${layer.name}" to canvas...');

    // Load strokes from layer data
    if (layer.strokes.isNotEmpty) {
      _loadStrokesToCanvas(layer.strokes);
      print('✅ Layer loaded with ${layer.strokes.length} strokes');
    } else {
      // Clear canvas if layer has no strokes
      controller.clearDrawables();
      print('ℹ️ Layer is empty - cleared canvas');
    }

    // Update background layer images
    await _updateLayerImages();
  }

  /// Switch to a different layer (save current, load new)
  Future<void> _switchToLayer(int newIndex) async {
    if (newIndex == selectedLayerIndex) return;
    if (newIndex < 0 || newIndex >= layers.length) return;

    print('🔄 Switching from layer $selectedLayerIndex to $newIndex');

    // Cancel any pending auto-save timer
    _saveDebounceTimer?.cancel();

    // Force save current layer before switching
    await _saveCurrentLayer();

    // Update selected index
    setState(() {
      selectedLayerIndex = newIndex;
    });

    // Load new layer
    await _loadLayerToCanvas(layers[newIndex]);

    print('✅ Switched to ${layers[newIndex].name}');
  }

  /// Save current layer's strokes dengan optimasi incremental
  Future<void> _saveCurrentLayer() async {
    if (currentProject == null || layers.isEmpty) return;

    // Prevent concurrent saves
    if (isSaving) {
      print('⏳ Save already in progress, waiting...');
      // Wait for current save to complete
      await Future.delayed(const Duration(milliseconds: 100));
      if (isSaving) return; // Still saving, skip
    }
    
    setState(() => isSaving = true);

    try {
      // Get current layer
      final currentLayer = layers[selectedLayerIndex];

      // Convert controller's drawables to stroke data
      final strokeData = _convertDrawablesToStrokes();

      // OPTIMIZATION: Only save if data actually changed
      if (_lastSavedStrokes != null && 
          _strokesEqual(strokeData, _lastSavedStrokes!)) {
        print('ℹ️ No changes detected, skipping save');
        setState(() => isSaving = false);
        return;
      }

      // Calculate data size for monitoring
      final dataSize = strokeData.length;
      final shouldCompress = dataSize > 100; // Compress if >100 strokes

      Map<String, dynamic> updateData = {
        'updatedAt': Timestamp.now(),
      };

      // Use compressed or raw data
      if (shouldCompress) {
        // For large datasets, use compressed JSON string
        updateData['strokes'] = strokeData; // Firestore handles compression
        updateData['strokeCount'] = dataSize;
        print('📦 Saving $dataSize strokes (large dataset)');
      } else {
        updateData['strokes'] = strokeData;
        print('💾 Saving $dataSize strokes');
      }

      // Update layer in Firestore with batch write for better performance
      if (widget.isShared) {
        await layerRepo.updateSharedLayer(
          currentProject!.id, 
          currentLayer.id, 
          updateData,
        );
      } else {
        await layerRepo.updatePrivateLayer(
          currentUserId,
          currentProject!.id,
          currentLayer.id,
          updateData,
        );
      }

      // Update tracking state (untuk future optimizations)
      _lastSavedStrokes = List.from(strokeData);

      // Auto-generate thumbnail if there's content (async, don't await)
      if (strokeData.isNotEmpty) {
        _autoGenerateThumbnail();
      }

      // Save completed
      print('✅ Layer saved: ${currentLayer.name} ($dataSize strokes)');
    } catch (e) {
      print('❌ Save failed: $e');
      _showError('Failed to save: $e');
    } finally {
      setState(() => isSaving = false);
    }
  }

  /// Compare two stroke arrays for equality (shallow comparison)
  bool _strokesEqual(List<Map<String, dynamic>> a, List<Map<String, dynamic>> b) {
    if (a.length != b.length) return false;
    
    // Quick check: compare lengths and last few strokes
    if (a.isEmpty) return true;
    
    // Compare first and last strokes as heuristic
    if (a.first.toString() != b.first.toString()) return false;
    if (a.last.toString() != b.last.toString()) return false;
    
    return true;
  }

  /// Render all layers to image (used for thumbnail and export)
  /// This ensures what you see = what you export
  Future<ui.Image> _renderAllLayersToImage(Size size) async {
    print('🎨 Rendering all layers to image...');
    
    // Create a picture recorder to draw all layers
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // 1. Draw background color
    final bgPaint = Paint()..color = canvasBackgroundColor;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      bgPaint,
    );

    // 2. Apply canvas transformations (rotation and mirror)
    // Save canvas state before transforming
    canvas.save();
    
    // Translate to center for rotation/mirror
    canvas.translate(size.width / 2, size.height / 2);
    
    // Apply rotation
    if (canvasRotation != 0) {
      canvas.rotate(canvasRotation * 3.14159 / 180); // Convert degrees to radians
    }
    
    // Apply mirror
    canvas.scale(
      isMirrorHorizontal ? -1.0 : 1.0,
      isMirrorVertical ? -1.0 : 1.0,
    );
    
    // Translate back
    canvas.translate(-size.width / 2, -size.height / 2);

    // 3. Draw all visible layers sorted by zIndex
    final sortedLayers = List<mvp.Layer>.from(layers)
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    int totalStrokesRendered = 0;
    
    for (int i = 0; i < sortedLayers.length; i++) {
      final layer = sortedLayers[i];
      if (!layer.isVisible) continue;

      // ✅ FIX: Jika ini adalah layer yang sedang aktif, render drawable dari controller juga
      final isCurrentLayer = (selectedLayerIndex < layers.length && 
                              layers[selectedLayerIndex].id == layer.id);
      
      // Draw saved strokes from layer
      for (final strokeData in layer.strokes) {
        try {
          final drawableType = strokeData['drawableType'] as String?;
          
          if (drawableType == 'freeStyle') {
            // Render free-hand stroke
            final points = strokeData['points'] as List<dynamic>? ?? [];
            if (points.isEmpty) continue;

            final path = Path();
            for (var i = 0; i < points.length; i++) {
              final point = points[i] as Map<String, dynamic>;
              final x = (point['x'] as num).toDouble();
              final y = (point['y'] as num).toDouble();

              if (i == 0) {
                path.moveTo(x, y);
              } else {
                path.lineTo(x, y);
              }
            }

            final color = strokeData['color'] as int? ?? 0xFF000000;
            final strokeWidth = (strokeData['strokeWidth'] as num?)?.toDouble() ?? 2.0;

            final strokePaint = Paint()
              ..color = Color(color).withOpacity(layer.opacity)
              ..strokeWidth = strokeWidth
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round
              ..style = PaintingStyle.stroke;

            canvas.drawPath(path, strokePaint);
            totalStrokesRendered++;
          } else if (drawableType == 'text') {
            // Render text WITH STROKE OUTLINE for better visibility
            final text = strokeData['text'] as String;
            final position = Offset(
              (strokeData['position']['x'] as num).toDouble(),
              (strokeData['position']['y'] as num).toDouble(),
            );
            final fontSize = (strokeData['fontSize'] as num?)?.toDouble() ?? 18;
            final color = Color(strokeData['color'] as int? ?? 0xFF000000);
            final fontWeight = FontWeight.values[strokeData['fontWeight'] as int? ?? FontWeight.normal.index];

            // Render text with stroke outline for better contrast
            _renderTextWithStroke(
              canvas: canvas,
              text: text,
              position: position,
              fontSize: fontSize,
              color: color.withOpacity(layer.opacity),
              fontWeight: fontWeight,
            );
            totalStrokesRendered++;
          } else if (drawableType == 'shape') {
            // Render shape
            final color = Color(strokeData['color'] as int? ?? 0xFF000000);
            final strokeWidth = (strokeData['strokeWidth'] as num?)?.toDouble() ?? 2.0;
            final paintStyle = PaintingStyle.values[strokeData['style'] as int? ?? 1];
            final position = Offset(
              (strokeData['position']['x'] as num).toDouble(),
              (strokeData['position']['y'] as num).toDouble(),
            );

            final shapePaint = Paint()
              ..color = color.withOpacity(layer.opacity)
              ..strokeWidth = strokeWidth
              ..style = paintStyle
              ..strokeCap = StrokeCap.values[strokeData['strokeCap'] as int? ?? StrokeCap.round.index]
              ..strokeJoin = StrokeJoin.values[strokeData['strokeJoin'] as int? ?? StrokeJoin.round.index];

            // For now, draw a simple marker at position
            // Full shape recreation would require shape factory
            canvas.drawCircle(position, strokeWidth * 2, shapePaint);
            totalStrokesRendered++;
          }
        } catch (e) {
          print('⚠️ Failed to render stroke: $e');
          continue;
        }
      }
      
      // ✅ RENDER CURRENT UNSAVED DRAWABLES (dari controller)
      if (isCurrentLayer && controller.value.drawables.isNotEmpty) {
        print('🎨 Rendering ${controller.value.drawables.length} unsaved drawables from current layer...');
        
        for (final drawable in controller.value.drawables) {
          try {
            if (drawable is FreeStyleDrawable) {
              // Render FreeStyle drawable langsung
              final path = Path();
              for (var i = 0; i < drawable.path.length; i++) {
                final point = drawable.path[i];
                if (i == 0) {
                  path.moveTo(point.dx, point.dy);
                } else {
                  path.lineTo(point.dx, point.dy);
                }
              }

              final strokePaint = Paint()
                ..color = drawable.color.withOpacity(layer.opacity)
                ..strokeWidth = drawable.strokeWidth
                ..strokeCap = StrokeCap.round
                ..strokeJoin = StrokeJoin.round
                ..style = PaintingStyle.stroke;

              canvas.drawPath(path, strokePaint);
              totalStrokesRendered++;
            } else if (drawable is TextDrawable) {
              // Render text drawable WITH STROKE OUTLINE
              _renderTextWithStroke(
                canvas: canvas,
                text: drawable.text,
                position: drawable.position,
                fontSize: drawable.style.fontSize ?? 18,
                color: (drawable.style.color ?? Colors.black).withOpacity(layer.opacity),
                fontWeight: drawable.style.fontWeight ?? FontWeight.normal,
              );
              totalStrokesRendered++;
            } else if (drawable is ShapeDrawable) {
              // Render shape drawable (basic rendering)
              final shapePaint = Paint()
                ..color = drawable.paint.color.withOpacity(layer.opacity)
                ..strokeWidth = drawable.paint.strokeWidth
                ..style = drawable.paint.style
                ..strokeCap = drawable.paint.strokeCap
                ..strokeJoin = drawable.paint.strokeJoin;

              // Simple circle marker for shapes
              canvas.drawCircle(drawable.position, drawable.paint.strokeWidth * 2, shapePaint);
              totalStrokesRendered++;
            }
          } catch (e) {
            print('⚠️ Failed to render drawable: $e');
            continue;
          }
        }
      }
    }

    // Restore canvas state after transformations
    canvas.restore();

    print('✅ Rendered $totalStrokesRendered strokes from ${sortedLayers.length} layers (including unsaved)');
    print('   Rotation: $canvasRotation°, Mirror H: $isMirrorHorizontal, Mirror V: $isMirrorVertical');

    // 4. Convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );

    return image;
  }

  /// Render single layer to image for background display
  Future<ui.Image?> _renderLayerToImage(mvp.Layer layer, Size size) async {
    if (layer.strokes.isEmpty) return null;
    
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Draw all strokes in the layer
      for (final strokeData in layer.strokes) {
        try {
          final drawableType = strokeData['drawableType'] as String?;
          
          if (drawableType == 'freeStyle') {
            // Render free-hand stroke
            final points = strokeData['points'] as List<dynamic>? ?? [];
            if (points.isEmpty) continue;

            final path = Path();
            for (var i = 0; i < points.length; i++) {
              final point = points[i] as Map<String, dynamic>;
              final x = (point['x'] as num).toDouble();
              final y = (point['y'] as num).toDouble();

              if (i == 0) {
                path.moveTo(x, y);
              } else {
                path.lineTo(x, y);
              }
            }

            final color = strokeData['color'] as int? ?? 0xFF000000;
            final strokeWidth = (strokeData['strokeWidth'] as num?)?.toDouble() ?? 2.0;

            final strokePaint = Paint()
              ..color = Color(color).withOpacity(layer.opacity)
              ..strokeWidth = strokeWidth
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round;

            canvas.drawPath(path, strokePaint);
          } else if (drawableType == 'text') {
            // Render text WITH STROKE OUTLINE
            final text = strokeData['text'] as String? ?? '';
            final color = Color(strokeData['color'] as int? ?? 0xFF000000);
            final fontSize = (strokeData['fontSize'] as num?)?.toDouble() ?? 18.0;
            final position = Offset(
              (strokeData['position']['x'] as num).toDouble(),
              (strokeData['position']['y'] as num).toDouble(),
            );

            _renderTextWithStroke(
              canvas: canvas,
              text: text,
              position: position,
              fontSize: fontSize,
              color: color.withOpacity(layer.opacity),
              fontWeight: FontWeight.bold,
            );
          } else if (drawableType == 'shape') {
            // Render shape
            final color = Color(strokeData['color'] as int? ?? 0xFF000000);
            final strokeWidth = (strokeData['strokeWidth'] as num?)?.toDouble() ?? 2.0;
            final position = Offset(
              (strokeData['position']['x'] as num).toDouble(),
              (strokeData['position']['y'] as num).toDouble(),
            );

            final shapePaint = Paint()
              ..color = color.withOpacity(layer.opacity)
              ..strokeWidth = strokeWidth
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round;

            canvas.drawCircle(position, strokeWidth * 2, shapePaint);
          }
        } catch (e) {
          print('⚠️ Failed to render stroke in layer ${layer.name}: $e');
          continue;
        }
      }

      // Convert to image
      final picture = recorder.endRecording();
      final image = await picture.toImage(
        size.width.toInt(),
        size.height.toInt(),
      );

      return image;
    } catch (e) {
      print('❌ Failed to render layer ${layer.name}: $e');
      return null;
    }
  }

  /// Update layer images for all non-active visible layers
  Future<void> _updateLayerImages() async {
    if (currentProject == null) return;

    final canvasSize = Size(
      currentProject!.canvasWidth.toDouble(),
      currentProject!.canvasHeight.toDouble(),
    );

    // Render all layers except the active one
    for (int i = 0; i < layers.length; i++) {
      if (i == selectedLayerIndex) {
        // Active layer is rendered by FlutterPainter, skip
        layerImages[layers[i].id] = null;
        continue;
      }

      if (!layers[i].isVisible) {
        // Hidden layer, skip rendering
        layerImages[layers[i].id] = null;
        continue;
      }

      // Render layer to image
      final image = await _renderLayerToImage(layers[i], canvasSize);
      layerImages[layers[i].id] = image;
    }

    setState(() {}); // Update UI to show rendered layers
  }

  /// Auto-generate thumbnail in background (non-blocking)
  /// Renders ALL layers to create complete preview
  Future<void> _autoGenerateThumbnail() async {
    try {
      print('📸 Auto-generating thumbnail from all layers...');
      
      final canvasSize = Size(
        currentProject!.canvasWidth.toDouble(),
        currentProject!.canvasHeight.toDouble(),
      );

      // Use unified rendering method
      final fullImage = await _renderAllLayersToImage(canvasSize);

      final byteData = await fullImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        await _updateProjectThumbnail(byteData.buffer.asUint8List());
        print('📸 Thumbnail auto-generated successfully');
      }
    } catch (e) {
      print('⚠️ Failed to auto-generate thumbnail: $e');
      // Don't show error to user - this is background task
    }
  }

  /// Convert PainterController drawables to our stroke format
  List<Map<String, dynamic>> _convertDrawablesToStrokes() {
    // Get all drawables from controller
    final drawables = controller.value.drawables;

    print('🔄 Converting ${drawables.length} drawables to stroke data...');

    // Convert to our format with FULL DATA
    final strokeData = <Map<String, dynamic>>[];

    for (var drawable in drawables) {
      try {
        Map<String, dynamic> strokeMap = {
          'type': drawable.runtimeType.toString(),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };

        // Simpan data berdasarkan tipe drawable
        if (drawable is FreeStyleDrawable) {
          // Free-hand drawing (pen/eraser strokes)
          strokeMap['drawableType'] = 'freeStyle';
          strokeMap['color'] = drawable.color.value;
          strokeMap['strokeWidth'] = drawable.strokeWidth;

          // Simpan path points
          final points = <Map<String, dynamic>>[];
          for (var i = 0; i < drawable.path.length; i++) {
            final offset = drawable.path[i];
            points.add({'x': offset.dx, 'y': offset.dy});
          }
          strokeMap['points'] = points;

          print(
            '  📏 FreeStyle: ${points.length} points, color: ${drawable.color}',
          );
        } else if (drawable is TextDrawable) {
          // Text
          strokeMap['drawableType'] = 'text';
          strokeMap['text'] = drawable.text;
          strokeMap['position'] = {
            'x': drawable.position.dx,
            'y': drawable.position.dy,
          };
          strokeMap['fontSize'] = drawable.style.fontSize ?? 18;
          strokeMap['fontWeight'] =
              drawable.style.fontWeight?.index ?? FontWeight.normal.index;
          strokeMap['color'] =
              drawable.style.color?.value ?? Colors.black.value;

          print('  📝 Text: "${drawable.text}"');
        } else if (drawable is ShapeDrawable) {
          // Shape (line, rectangle, circle, etc) - SAVE COMPLETE DATA
          strokeMap['drawableType'] = 'shape';
          strokeMap['color'] = drawable.paint.color.value;
          strokeMap['strokeWidth'] = drawable.paint.strokeWidth;
          strokeMap['style'] = drawable.paint.style.index; // 0=fill, 1=stroke
          strokeMap['strokeCap'] = drawable.paint.strokeCap.index;
          strokeMap['strokeJoin'] = drawable.paint.strokeJoin.index;
          
          // Save shape type
          strokeMap['shapeType'] = drawable.runtimeType.toString();
          
          // Save position
          strokeMap['position'] = {
            'x': drawable.position.dx,
            'y': drawable.position.dy,
          };

          print('  🔷 Shape: ${drawable.runtimeType} at (${drawable.position.dx.toStringAsFixed(1)}, ${drawable.position.dy.toStringAsFixed(1)})');
        }

        strokeData.add(strokeMap);
      } catch (e) {
        print('  ❌ Error converting drawable: $e');
      }
    }

    print('✅ Converted ${strokeData.length} strokes successfully');
    return strokeData;
  }

  /// Convert stroke data back to drawables and load to canvas
  Future<void> _loadStrokesToCanvas(List<Map<String, dynamic>> strokes) async {
    if (strokes.isEmpty) {
      print('ℹ️ No strokes to load');
      return;
    }

    print('🔄 Loading ${strokes.length} strokes to canvas...');

    // Clear current drawables first
    controller.clearDrawables();

    // Build list of drawables to add
    final List<Drawable> drawablesToAdd = [];

    for (var strokeMap in strokes) {
      try {
        final drawableType = strokeMap['drawableType'] as String?;

        if (drawableType == 'freeStyle') {
          // Recreate FreeStyle drawable
          final color = Color(strokeMap['color'] as int);
          final strokeWidth = (strokeMap['strokeWidth'] as num).toDouble();
          final points = (strokeMap['points'] as List)
              .map(
                (p) => Offset(
                  (p['x'] as num).toDouble(),
                  (p['y'] as num).toDouble(),
                ),
              )
              .toList();

          // Add to list
          drawablesToAdd.add(
            FreeStyleDrawable(
              color: color,
              strokeWidth: strokeWidth,
              path: points,
            ),
          );

          print('  ✅ Loaded FreeStyle: ${points.length} points');
        } else if (drawableType == 'text') {
          // Recreate Text drawable
          final text = strokeMap['text'] as String;
          final position = Offset(
            (strokeMap['position']['x'] as num).toDouble(),
            (strokeMap['position']['y'] as num).toDouble(),
          );
          final fontSize = (strokeMap['fontSize'] as num?)?.toDouble() ?? 18;
          final color = Color(strokeMap['color'] as int? ?? Colors.black.value);

          drawablesToAdd.add(
            TextDrawable(
              text: text,
              position: position,
              style: TextStyle(
                fontSize: fontSize,
                color: color,
                fontWeight:
                    FontWeight.values[strokeMap['fontWeight'] as int? ??
                        FontWeight.normal.index],
              ),
            ),
          );

          print('  ✅ Loaded Text: "$text"');
        } else if (drawableType == 'shape') {
          // Shapes are stored but require redraw due to library limitations
          // The data is preserved for future rendering
          print('  ⚠️ Shape data saved (display requires redraw)');
        }
      } catch (e, stackTrace) {
        print('  ❌ Error loading stroke: $e');
        print('Stack trace: $stackTrace');
      }
    }

    // Add all drawables at once by replacing the controller's value
    if (drawablesToAdd.isNotEmpty) {
      // Create new PainterController value with loaded drawables
      final newValue = controller.value.copyWith(drawables: drawablesToAdd);
      controller.value = newValue;
    }

    print('✅ Loaded ${drawablesToAdd.length} strokes to canvas');

    // Refresh canvas
    if (mounted) {
      setState(() {});
    }
  }

  /// Add new layer
  Future<void> _addNewLayer() async {
    if (currentProject == null) {
      _showError('No project loaded');
      return;
    }

    try {
      print('📝 Creating new layer...');
      print('Project ID: ${currentProject!.id}');
      print('User ID: $currentUserId');
      print('Is Shared: ${widget.isShared}');
      print('Current layers: ${layers.length}');

      final newLayer = mvp.Layer(
        id: '',
        name: 'Layer ${layers.length + 1}',
        isVisible: true,
        opacity: 1.0,
        strokes: const [],
        zIndex: layers.length,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      String layerId;
      if (widget.isShared) {
        print('Creating shared layer...');
        layerId = await layerRepo.createSharedLayer(
          currentProject!.id,
          newLayer,
        );
      } else {
        print('Creating private layer...');
        layerId = await layerRepo.createPrivateLayer(
          currentUserId,
          currentProject!.id,
          newLayer,
        );
      }

      print('✅ Layer created with ID: $layerId');

      setState(() {
        layers.add(newLayer.copyWith(id: layerId));
        selectedLayerIndex = layers.length - 1;
        print('Layer added to list. Total layers: ${layers.length}');
      });

      controller.clearDrawables();
      
      // Update layer images to include the new layer rendering
      await _updateLayerImages();
      
      _showSuccess('New layer "${newLayer.name}" added');
    } catch (e, stackTrace) {
      print('❌ Error adding layer: $e');
      print('Stack trace: $stackTrace');

      // Specific error messages
      if (e.toString().contains('PERMISSION_DENIED')) {
        _showError('Permission denied. Please check Firebase rules.');
      } else if (e.toString().contains('not-found')) {
        _showError('Project not found in database.');
      } else {
        _showError('Failed to add layer: ${e.toString().split(':').last}');
      }
    }
  }

  /// Delete current layer
  Future<void> _deleteCurrentLayer() async {
    if (currentProject == null || layers.length <= 1) {
      _showError('Cannot delete the last layer');
      return;
    }

    // Check ownership
    if (!currentProject!.isOwner(currentUserId)) {
      _showError('Only owner can delete layers');
      return;
    }

    // Show confirmation dialog
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Delete Layer',
      message:
          'Are you sure you want to delete "${layers[selectedLayerIndex].name}"? This action cannot be undone.',
      confirmText: 'Delete',
      isDangerous: true,
    );

    if (!confirmed) return;

    try {
      final layerToDelete = layers[selectedLayerIndex];

      if (widget.isShared) {
        await layerRepo.deleteSharedLayer(currentProject!.id, layerToDelete.id);
      } else {
        await layerRepo.deletePrivateLayer(
          currentUserId,
          currentProject!.id,
          layerToDelete.id,
        );
      }

      setState(() {
        layers.removeAt(selectedLayerIndex);
        
        // Adjust selected index - ensure it's within valid range
        if (layers.isEmpty) {
          // Should not happen due to check above, but just in case
          selectedLayerIndex = 0;
        } else if (selectedLayerIndex >= layers.length) {
          selectedLayerIndex = layers.length - 1;
        }

        // Reorder z-index setelah delete
        for (int i = 0; i < layers.length; i++) {
          layers[i] = layers[i].copyWith(zIndex: layers.length - i);
        }
        
        // Clear deleted layer image cache
        layerImages.remove(layerToDelete.id);
      });

      // Update z-index di Firestore untuk semua layer yang tersisa
      try {
        for (final layer in layers) {
          if (widget.isShared) {
            await layerRepo.updateSharedLayer(
              currentProject!.id,
              layer.id,
              {'zIndex': layer.zIndex},
            );
          } else {
            await layerRepo.updatePrivateLayer(
              currentUserId,
              currentProject!.id,
              layer.id,
              {'zIndex': layer.zIndex},
            );
          }
        }
        print('✅ Layer z-index reordered after deletion');
      } catch (e) {
        print('⚠️ Failed to update z-index after delete: $e');
      }

      // Only load layer if layers is not empty
      if (layers.isNotEmpty && selectedLayerIndex >= 0 && selectedLayerIndex < layers.length) {
        await _loadLayerToCanvas(layers[selectedLayerIndex]);
      }
      
      _showSuccess('Layer deleted successfully');
    } catch (e) {
      _showError('Failed to delete layer: $e');
    }
  }

  /// Rename layer
  Future<void> _renameLayer(int index) async {
    if (currentProject == null || index < 0 || index >= layers.length) return;
    
    final layer = layers[index];
    final controller = TextEditingController(text: layer.name);
    
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Layer'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 30,
          decoration: const InputDecoration(
            labelText: 'Layer Name',
            hintText: 'Enter new name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(context, value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context, name);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    
    if (newName != null && newName != layer.name) {
      try {
        // Update layer name in state
        setState(() {
          layers[index] = layers[index].copyWith(name: newName);
        });
        
        // Update in Firestore
        if (widget.isShared) {
          await layerRepo.updateSharedLayer(
            currentProject!.id,
            layer.id,
            {'name': newName},
          );
        } else {
          await layerRepo.updatePrivateLayer(
            currentUserId,
            currentProject!.id,
            layer.id,
            {'name': newName},
          );
        }
        
        _showSuccess('Layer renamed to "$newName"');
      } catch (e) {
        _showError('Failed to rename layer: $e');
        // Revert on error
        setState(() {
          layers[index] = layers[index].copyWith(name: layer.name);
        });
      }
    }
  }

  /// Delete layer by index (not currently selected)
  Future<void> _deleteLayer(int index) async {
    if (currentProject == null || index < 0 || index >= layers.length) return;

    // Prevent deleting the last layer
    if (layers.length <= 1) {
      _showError('Cannot delete the last layer');
      return;
    }

    // Check ownership
    if (!currentProject!.isOwner(currentUserId)) {
      _showError('Only owner can delete layers');
      return;
    }

    try {
      final layerToDelete = layers[index];

      // Delete from Firestore
      if (widget.isShared) {
        await layerRepo.deleteSharedLayer(currentProject!.id, layerToDelete.id);
      } else {
        await layerRepo.deletePrivateLayer(
          currentUserId,
          currentProject!.id,
          layerToDelete.id,
        );
      }

      setState(() {
        layers.removeAt(index);
        
        // Adjust selected index if needed
        if (index < selectedLayerIndex) {
          selectedLayerIndex--;
        } else if (index == selectedLayerIndex) {
          // If we deleted the selected layer, select the previous one
          if (selectedLayerIndex > 0) {
            selectedLayerIndex--;
          } else if (layers.isNotEmpty) {
            selectedLayerIndex = 0;
          }
        }
        
        // Ensure selectedLayerIndex is within valid range
        if (layers.isEmpty) {
          selectedLayerIndex = 0;
        } else if (selectedLayerIndex >= layers.length) {
          selectedLayerIndex = layers.length - 1;
        }

        // Reorder z-index
        for (int i = 0; i < layers.length; i++) {
          layers[i] = layers[i].copyWith(zIndex: layers.length - i);
        }
        
        // Clear deleted layer image cache
        layerImages.remove(layerToDelete.id);
      });

      // Update z-index in Firestore
      try {
        for (final layer in layers) {
          if (widget.isShared) {
            await layerRepo.updateSharedLayer(currentProject!.id, layer.id, {
              'zIndex': layer.zIndex,
            });
          } else {
            await layerRepo.updatePrivateLayer(
              currentUserId,
              currentProject!.id,
              layer.id,
              {'zIndex': layer.zIndex},
            );
          }
        }
        print('✅ Layer deleted and z-index updated');
      } catch (e) {
        print('⚠️ Failed to update z-index after delete: $e');
      }

      // Load the newly selected layer to canvas
      if (layers.isNotEmpty && selectedLayerIndex >= 0 && selectedLayerIndex < layers.length) {
        await _loadLayerToCanvas(layers[selectedLayerIndex]);
      }

      _showSuccess('Layer deleted successfully');
    } catch (e) {
      _showError('Failed to delete layer: $e');
    }
  }

  /// Toggle layer visibility
  Future<void> _toggleLayerVisibility(int index) async {
    if (currentProject == null) return;

    final layer = layers[index];
    final newVisibility = !layer.isVisible;

    try {
      // Update di Firestore
      if (widget.isShared) {
        await layerRepo.updateSharedLayer(currentProject!.id, layer.id, {
          'isVisible': newVisibility,
        });
      } else {
        await layerRepo.updatePrivateLayer(
          currentUserId,
          currentProject!.id,
          layer.id,
          {'isVisible': newVisibility},
        );
      }

      setState(() {
        layers[index] = layer.copyWith(isVisible: newVisibility);
      });

      // Update layer images to reflect visibility changes
      await _updateLayerImages();

      print('✅ Layer visibility toggled: ${layer.name} = $newVisibility');
      _showSuccess('Layer ${newVisibility ? "shown" : "hidden"}');
    } catch (e) {
      print('❌ Failed to toggle visibility: $e');
      _showError('Failed to toggle visibility: $e');
    }
  }

  /// Merge selected layers by their IDs
  Future<void> _mergeSelectedLayers(List<String> layerIds) async {
    if (currentProject == null || layerIds.length < 2) {
      _showError('Please select at least 2 layers to merge');
      return;
    }

    // Check ownership
    if (!currentProject!.isOwner(currentUserId)) {
      _showError('Only owner can merge layers');
      return;
    }

    try {
      // Convert layer IDs to indices
      final List<int> layerIndices = [];
      for (final id in layerIds) {
        final index = layers.indexWhere((layer) => layer.id == id);
        if (index != -1) {
          layerIndices.add(index);
        }
      }
      
      if (layerIndices.length < 2) {
        _showError('Please select at least 2 valid layers to merge');
        return;
      }

      // Sort indices descending to merge from top to bottom
      layerIndices.sort((a, b) => b.compareTo(a));

      // Combine all strokes from selected layers
      List<Map<String, dynamic>> mergedStrokes = [];
      String mergedName = 'Merged Layer';

      for (int index in layerIndices) {
        if (index < layers.length) {
          mergedStrokes.addAll(layers[index].strokes);
          if (layerIndices.first == index) {
            mergedName = layers[index].name;
          }
        }
      }

      // Create new merged layer
      final mergedLayer = mvp.Layer(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: '$mergedName (Merged)',
        zIndex: layers.length + 1,
        strokes: mergedStrokes,
        isVisible: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add merged layer to Firestore
      final mergedLayerId = widget.isShared
          ? await layerRepo.createSharedLayer(currentProject!.id, mergedLayer)
          : await layerRepo.createPrivateLayer(
              currentUserId,
              currentProject!.id,
              mergedLayer,
            );

      // Update layer with new ID from Firestore
      final finalMergedLayer = mergedLayer.copyWith(id: mergedLayerId);

      // Delete old layers (in reverse order to maintain indices)
      for (int index in layerIndices) {
        final layerToDelete = layers[index];
        if (widget.isShared) {
          await layerRepo.deleteSharedLayer(
            currentProject!.id,
            layerToDelete.id,
          );
        } else {
          await layerRepo.deletePrivateLayer(
            currentUserId,
            currentProject!.id,
            layerToDelete.id,
          );
        }
      }

      setState(() {
        // Remove deleted layers
        for (int index in layerIndices) {
          layers.removeAt(index);
        }
        // Add merged layer with Firestore ID
        layers.add(finalMergedLayer);
        // Reorder z-index
        for (int i = 0; i < layers.length; i++) {
          layers[i] = layers[i].copyWith(zIndex: layers.length - i);
        }
        selectedLayerIndex = layers.length - 1; // Select merged layer
      });

      _loadLayerToCanvas(finalMergedLayer);
      _showSuccess('Layers merged successfully');
    } catch (e) {
      print('❌ Failed to merge layers: $e');
      _showError('Failed to merge layers: $e');
    }
  }

  /// Show layer panel
  void _showLayerPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isMultiSelectMode
                        ? 'Select Layers (${selectedLayersForMerge.length})'
                        : 'Layers (${layers.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      // ✅ COMING SOON: Multi-layer feature disabled for MVP
                      if (!isMultiSelectMode) ...[
                        // Merge mode button - DISABLED
                        Opacity(
                          opacity: 0.3,
                          child: IconButton(
                            icon: const Icon(
                              PhosphorIcons.selection_all,
                              color: Colors.grey,
                              size: 24,
                            ),
                            tooltip: 'Coming Soon',
                            onPressed: null, // Disabled
                          ),
                        ),
                        // Add layer button - DISABLED
                        Opacity(
                          opacity: 0.3,
                          child: IconButton(
                            icon: const Icon(
                              PhosphorIcons.plus_circle,
                              color: Colors.grey,
                              size: 28,
                            ),
                            tooltip: 'Coming Soon',
                            onPressed: null, // Disabled
                          ),
                        ),
                      ],
                      if (isMultiSelectMode) ...[
                        // Cancel selection
                        TextButton(
                          onPressed: () {
                            setState(() {
                              isMultiSelectMode = false;
                              selectedLayersForMerge.clear();
                            });
                          },
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        // Merge button - DISABLED
                        Opacity(
                          opacity: 0.3,
                          child: ElevatedButton.icon(
                            icon: const Icon(PhosphorIcons.git_merge, size: 18),
                            label: const Text('Merge'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            onPressed: null, // Disabled
                          ),
                        ),
                      ],
                      if (!isMultiSelectMode)
                        IconButton(
                          icon: const Icon(PhosphorIcons.x, color: Colors.grey),
                          onPressed: () => Navigator.pop(context),
                        ),
                    ],
                  ),
                ],
              ),
              // ✅ Coming Soon Banner
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Multi-layer features (Add, Delete, Merge) coming soon! Currently using single layer mode.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Layers list
              Expanded(
                child: layers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              PhosphorIcons.stack,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No layers yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              icon: const Icon(PhosphorIcons.plus),
                              label: const Text('Add Layer'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              onPressed: () async {
                                await _addNewLayer();
                                if (mounted) Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      )
                    : ReorderableListView.builder(
                        itemCount: layers.length,
                        onReorder: (oldIndex, newIndex) async {
                          // Save current layer before reordering
                          await _saveCurrentLayer();
                          
                          setState(() {
                            if (newIndex > oldIndex) newIndex -= 1;
                            final item = layers.removeAt(oldIndex);
                            layers.insert(newIndex, item);
                            // Update z-index untuk semua layer
                            for (int i = 0; i < layers.length; i++) {
                              layers[i] = layers[i].copyWith(
                                zIndex: layers.length - i,
                              );
                            }
                            // Update selected index
                            if (selectedLayerIndex == oldIndex) {
                              selectedLayerIndex = newIndex;
                            } else if (selectedLayerIndex > oldIndex &&
                                selectedLayerIndex <= newIndex) {
                              selectedLayerIndex--;
                            } else if (selectedLayerIndex < oldIndex &&
                                selectedLayerIndex >= newIndex) {
                              selectedLayerIndex++;
                            }
                          });

                          // Update z-index di Firestore untuk setiap layer
                          try {
                            for (final layer in layers) {
                              if (widget.isShared) {
                                await layerRepo.updateSharedLayer(
                                  currentProject!.id,
                                  layer.id,
                                  {'zIndex': layer.zIndex},
                                );
                              } else {
                                await layerRepo.updatePrivateLayer(
                                  currentUserId,
                                  currentProject!.id,
                                  layer.id,
                                  {'zIndex': layer.zIndex},
                                );
                              }
                            }
                            _showSuccess('Layer order updated');
                          } catch (e) {
                            _showError('Failed to update layer order: $e');
                          }
                        },
                        itemBuilder: (context, index) {
                          final layer = layers[index];
                          final isSelected = index == selectedLayerIndex;
                          final isChecked = selectedLayersForMerge.contains(
                            layer.id, // Use layer ID instead of index
                          );

                          return Card(
                            key: ValueKey(layer.id),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            elevation: isSelected ? 4 : 1,
                            color: isMultiSelectMode && isChecked
                                ? Colors.orange.shade50
                                : (isSelected
                                      ? Colors.blue.shade50
                                      : Colors.white),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isMultiSelectMode && isChecked
                                    ? Colors.orange
                                    : (isSelected
                                          ? Colors.blue
                                          : Colors.grey.shade300),
                                width: isMultiSelectMode && isChecked
                                    ? 2
                                    : (isSelected ? 2 : 1),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              leading: SizedBox(
                                width: isMultiSelectMode ? 40 : 80,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isMultiSelectMode)
                                      Checkbox(
                                        value: isChecked,
                                        activeColor: Colors.orange,
                                        onChanged: (val) {
                                          setState(() {
                                            if (val == true) {
                                              selectedLayersForMerge.add(layer.id); // Use layer ID
                                            } else {
                                              selectedLayersForMerge.remove(
                                                layer.id, // Use layer ID
                                              );
                                            }
                                          });
                                        },
                                      )
                                    else ...[
                                      Icon(
                                        PhosphorIcons.dots_six,
                                        size: 20,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: Icon(
                                          layer.isVisible
                                              ? PhosphorIcons.eye
                                              : PhosphorIcons.eye_slash,
                                          size: 20,
                                          color: layer.isVisible
                                              ? Colors.blue
                                              : Colors.grey,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _toggleLayerVisibility(index);
                                          });
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              title: GestureDetector(
                                onDoubleTap: () {
                                  // Double tap to rename layer
                                  _renameLayer(index);
                                },
                                child: Text(
                                  layer.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Colors.blue.shade900
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              subtitle: Text(
                                'Z-index: ${layer.zIndex}${isSelected ? " • Active" : ""}',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected
                                      ? Colors.blue.shade700
                                      : Colors.grey.shade600,
                                ),
                              ),
                              trailing: isMultiSelectMode
                                  ? null
                                  : SizedBox(
                                      width: 140, // Increased width for edit + delete buttons
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          if (isSelected)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Text(
                                                'ACTIVE',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          const SizedBox(width: 4),
                                          // Edit/Rename button
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(
                                              minWidth: 32,
                                              minHeight: 32,
                                            ),
                                            icon: const Icon(
                                              PhosphorIcons.pencil_simple,
                                              size: 16,
                                              color: Colors.blue,
                                            ),
                                            tooltip: 'Rename layer (or double-tap layer name)',
                                            onPressed: () {
                                              _renameLayer(index);
                                            },
                                          ),
                                          const SizedBox(width: 4),
                                          // ✅ Delete button - DISABLED (Coming Soon)
                                          if (layers.length > 1)
                                            Opacity(
                                              opacity: 0.3,
                                              child: IconButton(
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(
                                                  minWidth: 32,
                                                  minHeight: 32,
                                                ),
                                                icon: const Icon(
                                                  PhosphorIcons.trash,
                                                  size: 18,
                                                  color: Colors.grey,
                                                ),
                                                tooltip: 'Coming Soon',
                                                onPressed: null, // Disabled
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                              onTap: isMultiSelectMode
                                  ? () {
                                      setState(() {
                                        if (isChecked) {
                                          selectedLayersForMerge.remove(layer.id); // Use layer ID
                                        } else {
                                          selectedLayersForMerge.add(layer.id); // Use layer ID
                                        }
                                      });
                                    }
                                  : () async {
                                      Navigator.pop(context);
                                      await _switchToLayer(index);
                                      _showSuccess('Switched to ${layer.name}');
                                    },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    showErrorSnackbar(context, message);
  }

  void _showSuccess(String message) {
    showSuccessSnackbar(context, message);
  }

  /// Sell to Marketplace - OWNER ONLY (MVP Requirement)
  Future<void> _sellToMarketplace() async {
    if (currentProject == null) {
      _showError('No project loaded');
      return;
    }

    // Check ownership - CRITICAL MVP REQUIREMENT
    if (!currentProject!.isOwner(currentUserId)) {
      _showError('Only project owner can sell to marketplace');
      return;
    }

    try {
      // Show dialog to input title and price
      String? title;
      double? price;

      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) {
          final titleController = TextEditingController(text: currentProject!.name);
          final priceController = TextEditingController();
          
          return AlertDialog(
            title: const Text('Sell to Marketplace'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'Enter artwork title',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price (IDR)',
                    hintText: 'Enter price',
                    prefixText: 'Rp ',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.isEmpty) {
                    _showError('Please enter title');
                    return;
                  }
                  if (priceController.text.isEmpty) {
                    _showError('Please enter price');
                    return;
                  }
                  Navigator.pop(context, {
                    'title': titleController.text,
                    'price': double.tryParse(priceController.text),
                  });
                },
                child: const Text('Publish'),
              ),
            ],
          );
        },
      );

      if (result == null) return;

      title = result['title'] as String;
      price = result['price'] as double?;

      if (price == null || price <= 0) {
        _showError('Invalid price');
        return;
      }

      // Save current state and generate thumbnail first
      await _saveCurrentLayer();
      
      // Show loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Create store listing using StoreListing model
      final listing = StoreListing(
        id: '', // Will be generated by Firestore
        title: title,
        projectId: currentProject!.id,
        ownerId: currentUserId,
        price: price,
        description: 'Digital artwork created with Muraloka',
        thumbnailBase64: currentProject!.thumbnailBase64,
        totalSold: 0,
        averageRating: 0.0,
        totalReviews: 0,
        tags: ['digital-art', 'muraloka'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );

      await listingRepo.createListing(listing);

      // Hide loading
      if (mounted) Navigator.of(context).pop();

      // Show success
      _showSuccess('✅ Published to marketplace!');
      
      print('✅ Project published to marketplace: $title at Rp $price');
    } catch (e) {
      // Hide loading
      if (mounted) Navigator.of(context).pop();
      
      print('❌ Sell to marketplace error: $e');
      _showError('Failed to publish: $e');
    }
  }

  /// Export canvas sebagai gambar
  Future<void> _exportCanvas() async {
    try {
      // Debug log
      print('🎨 Export canvas started...');
      print('Project: ${currentProject?.name}');
      
      // ✅ SAVE ALL CHANGES: Save current layer AND update project
      print('💾 Saving all changes before export...');
      
      // 1. Save current layer strokes
      await _saveCurrentLayer();
      
      // 2. Generate and update project thumbnail
      final thumbnailSize = Size(400, 300); // Thumbnail size
      final thumbnailImage = await _renderAllLayersToImage(thumbnailSize);
      final thumbnailBytes = await thumbnailImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (thumbnailBytes != null) {
        await _updateProjectThumbnail(thumbnailBytes.buffer.asUint8List());
      }
      
      // Wait a moment for Firestore to update
      await Future.delayed(const Duration(milliseconds: 800));
      print('✅ All changes saved, total layers: ${layers.length}');
      
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Exporting canvas...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      print(
        'Canvas size: ${currentProject?.canvasWidth}x${currentProject?.canvasHeight}',
      );
      print('Background color: $canvasBackgroundColor');

      // Export full canvas directly (removed dialog)
      Uint8List pngBytes;

      // Export full canvas - USE SAME RENDERING AS DISPLAY
      final size = Size(
        (currentProject?.canvasWidth ?? 1920).toDouble(),
        (currentProject?.canvasHeight ?? 1080).toDouble(),
      );

      print('Rendering with size: $size');
      
      // Use unified rendering method (same as thumbnail and display)
      final ui.Image image = await _renderAllLayersToImage(size);

      print('✅ Image rendered: ${image.width}x${image.height}');

      // Convert to PNG bytes
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) {
        print('❌ Failed to convert to bytes');
        _showError('Gagal mengkonversi gambar');
        return;
      }

      pngBytes = byteData.buffer.asUint8List();

      print('✅ Image converted to bytes: ${pngBytes.length} bytes');

      // Tampilkan dialog save/share
      await _showSaveShareDialog(pngBytes);
    } catch (e) {
      print('❌ Export error: $e');
      _showError('Gagal export canvas: $e');
    }
  }

  /// Calculate bounding box of all drawable content
  Rect? _calculateContentBounds() {
    if (controller.value.drawables.isEmpty) return null;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    bool hasContent = false;

    // For simplicity, calculate bounds based on controller's transform
    // This is a rough approximation - ideally we'd iterate through all drawables
    // but the API might not expose individual points easily

    // Get canvas size as fallback
    final canvasWidth = (currentProject?.canvasWidth ?? 1920).toDouble();
    final canvasHeight = (currentProject?.canvasHeight ?? 1080).toDouble();

    // For now, use a simplified approach: check if any drawables exist
    // and use a percentage of canvas as bounds (can be refined later)
    if (controller.value.drawables.isNotEmpty) {
      // This is a simplified version - assumes content is roughly centered
      // TODO: Implement proper drawable bounds iteration when API is available
      minX = canvasWidth * 0.1;
      minY = canvasHeight * 0.1;
      maxX = canvasWidth * 0.9;
      maxY = canvasHeight * 0.9;
      hasContent = true;
    }

    if (!hasContent) return null;

    // Add padding around content
    const padding = 20.0;
    return Rect.fromLTRB(
      max(0.0, minX - padding),
      max(0.0, minY - padding),
      min(canvasWidth, maxX + padding),
      min(canvasHeight, maxY + padding),
    );
  }

  /// Export canvas with cropping to content bounds
  Future<Uint8List> _exportCroppedCanvas(Rect contentBounds) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw background
    if (canvasBackgroundColor != Colors.white) {
      final paint = Paint()..color = canvasBackgroundColor;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, contentBounds.width, contentBounds.height),
        paint,
      );
    }

    // Translate to crop origin
    canvas.translate(-contentBounds.left, -contentBounds.top);

    // Draw all drawables
    for (final drawable in controller.value.drawables) {
      drawable.draw(canvas, Size(contentBounds.right, contentBounds.bottom));
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      contentBounds.width.toInt(),
      contentBounds.height.toInt(),
    );

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
  /// Dialog untuk memilih cara export
  /// Dialog untuk memilih cara export
  Future<void> _showSaveShareDialog(Uint8List imageBytes) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Canvas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(PhosphorIcons.floppy_disk),
              title: const Text('Simpan ke Gallery'),
              subtitle: const Text('Simpan ke folder Pictures/Muraloka'),
              onTap: () {
                Navigator.pop(context);
                _saveToGallery(imageBytes);
              },
            ),
            ListTile(
              leading: const Icon(PhosphorIcons.folder),
              title: const Text('Pilih Folder'),
              subtitle: const Text('Pilih lokasi penyimpanan'),
              onTap: () {
                Navigator.pop(context);
                _saveToCustomFolder(imageBytes);
              },
            ),
            ListTile(
              leading: const Icon(PhosphorIcons.share_network),
              title: const Text('Share'),
              subtitle: const Text('Bagikan ke aplikasi lain'),
              onTap: () {
                Navigator.pop(context);
                _shareImage(imageBytes);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  /// Update project thumbnail dengan canvas yang di-render
  Future<void> _updateProjectThumbnail(Uint8List imageBytes) async {
    if (currentProject == null) return;

    try {
      // Generate thumbnail dengan ukuran lebih kecil (400px width)
      final codec = await ui.instantiateImageCodec(
        imageBytes,
        targetWidth: 400,
      );
      final frame = await codec.getNextFrame();
      final thumbnail = await frame.image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (thumbnail == null) return;

      final thumbnailBase64 = base64Encode(thumbnail.buffer.asUint8List());

      // Update project dengan thumbnail baru
      final updatedProject = currentProject!.copyWith(
        thumbnailBase64: thumbnailBase64,
        updatedAt: DateTime.now(),
      );

      if (widget.isShared) {
        await projectRepo.updateSharedProject(currentProject!.id, {
          'thumbnailBase64': thumbnailBase64,
          'updatedAt': Timestamp.now(),
        });
      } else {
        // Update private project
        await projectRepo.updatePrivateProject(
          currentUserId,
          currentProject!.id,
          {'thumbnailBase64': thumbnailBase64},
        );
      }

      setState(() {
        currentProject = updatedProject;
      });

      // Update marketplace listing if exists
      await _updateMarketplaceListing(currentProject!.id, null, thumbnailBase64);

      print('✅ Thumbnail updated successfully');
    } catch (e) {
      print('⚠️ Failed to update thumbnail: $e');
      // Don't show error to user, this is not critical
    }
  }

  /// Update marketplace listing when project thumbnail is updated
  Future<void> _updateMarketplaceListing(
    String projectId,
    String? newTitle,
    String? newThumbnail,
  ) async {
    try {
      // Check if this project has marketplace listing
      final listings = await listingRepo.getListingsByProject(projectId);
      
      if (listings.isNotEmpty) {
        // Update all listings for this project
        for (final listing in listings) {
          final updates = <String, dynamic>{};
          
          if (newTitle != null) {
            updates['title'] = newTitle;
            print('📝 Updating marketplace title to: $newTitle');
          }
          
          if (newThumbnail != null && newThumbnail.isNotEmpty) {
            updates['thumbnailBase64'] = newThumbnail;
            print('📸 Updating marketplace thumbnail');
          }
          
          if (updates.isNotEmpty) {
            await listingRepo.updateListing(listing.id, updates);
            print('✅ Marketplace listing updated');
          }
        }
      }
    } catch (e) {
      print('⚠️ Failed to update marketplace listing: $e');
      // Don't show error to user - this is background task
    }
  }

  /// Simpan ke gallery (Pictures/Muraloka) dengan Android 13+ support
  Future<void> _saveToGallery(Uint8List imageBytes) async {
    try {
      print('📁 Saving to gallery...');

      // Update project thumbnail
      await _updateProjectThumbnail(imageBytes);

      // Request permission berdasarkan Android version
      if (Platform.isAndroid) {
        // Android 13+ (API 33+) tidak butuh storage permission untuk media files
        // Android 12 dan kebawah masih butuh storage permission
        final androidInfo = await _getAndroidVersion();

        if (androidInfo < 33) {
          // Android 12 and below - need storage permission
          var status = await Permission.storage.status;
          print('Storage permission status: $status');

          if (!status.isGranted) {
            print('Requesting storage permission...');
            status = await Permission.storage.request();

            if (!status.isGranted) {
              if (status.isPermanentlyDenied) {
                _showError(
                  'Storage permission ditolak permanen.\nBuka Settings untuk memberikan akses.',
                );
                await openAppSettings();
              } else {
                _showError(
                  'Storage permission diperlukan untuk menyimpan gambar',
                );
              }
              return;
            }
          }
          print('Storage permission granted');
        } else {
          // Android 13+ - request photos permission
          var status = await Permission.photos.status;
          print('Photos permission status: $status');

          if (!status.isGranted && !status.isLimited) {
            print('Requesting photos permission...');
            status = await Permission.photos.request();

            if (!status.isGranted && !status.isLimited) {
              if (status.isPermanentlyDenied) {
                _showError(
                  'Photos permission ditolak permanen.\nBuka Settings untuk memberikan akses.',
                );
                await openAppSettings();
              } else {
                _showError(
                  'Photos permission diperlukan untuk menyimpan gambar',
                );
              }
              return;
            }
          }
          print('Photos permission granted or limited');
        }
      }

      // Dapatkan directory Pictures
      Directory? directory;
      if (Platform.isAndroid) {
        // Gunakan path yang lebih reliable
        directory = Directory('/storage/emulated/0/Pictures/Muraloka');
        print('Target directory: ${directory.path}');
      } else if (Platform.isIOS) {
        // iOS - simpan ke app documents
        directory = await getApplicationDocumentsDirectory();
        directory = Directory('${directory.path}/Muraloka');
      } else {
        // Desktop
        directory = await getApplicationDocumentsDirectory();
        directory = Directory('${directory.path}/Muraloka');
      }

      // Buat folder jika belum ada
      if (!await directory.exists()) {
        print('Creating directory: ${directory.path}');
        await directory.create(recursive: true);
      }

      // Buat nama file dengan timestamp dan nama project
      final projectName =
          currentProject?.name.replaceAll(RegExp(r'[^\w\s-]'), '') ?? 'canvas';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${projectName}_$timestamp.png';
      final filePath = '${directory.path}/$fileName';

      print('Saving file to: $filePath');

      // Simpan file
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      print('✅ File saved successfully');
      print('File size: ${imageBytes.length} bytes');

      // Show success non-intrusive message
      _showSuccess('Gambar berhasil disimpan: $fileName');
    } catch (e, stackTrace) {
      print('❌ Error saving to gallery: $e');
      print('Stack trace: $stackTrace');
      _showError('Gagal menyimpan gambar: ${e.toString()}');
    }
  }

  /// Get Android SDK version
  Future<int> _getAndroidVersion() async {
    if (!Platform.isAndroid) return 0;

    try {
      // Android SDK version bisa didapat dari Platform
      // Tapi karena tidak ada API langsung, kita assume Android 13+ jika package tersedia
      // Alternatif: gunakan device_info_plus package
      return 33; // Default assume Android 13+ untuk modern devices
    } catch (e) {
      return 30; // Fallback ke Android 11
    }
  }

  /// Simpan ke folder custom dengan file picker
  Future<void> _saveToCustomFolder(Uint8List imageBytes) async {
    try {
      print('📂 Opening file picker...');

      // Update project thumbnail
      await _updateProjectThumbnail(imageBytes);

      // Generate default filename
      final projectName =
          currentProject?.name.replaceAll(RegExp(r'[^\w\s-]'), '') ?? 'canvas';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final suggestedName = '${projectName}_$timestamp.png';

      // Platform-specific handling: on mobile, use directory picker and write bytes ourselves
      if (Platform.isAndroid || Platform.isIOS) {
        final selectedDir = await FilePicker.platform.getDirectoryPath(
          dialogTitle: 'Pilih folder untuk menyimpan gambar',
        );

        if (selectedDir == null) {
          print('User cancelled directory picker');
          return;
        }

        String outputPath = '$selectedDir/$suggestedName';
        if (!outputPath.toLowerCase().endsWith('.png'))
          outputPath = '$outputPath.png';

        final file = File(outputPath);
        await file.writeAsBytes(imageBytes);

        print('✅ File saved to custom location (mobile): $outputPath');
        _showSuccess('Gambar berhasil disimpan: ${file.path.split('/').last}');
      } else {
        // Desktop & other platforms: use saveFile which returns a path
        String? outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Simpan Gambar',
          fileName: suggestedName,
          type: FileType.custom,
          allowedExtensions: ['png'],
        );

        if (outputPath == null) {
          print('User cancelled file picker');
          return;
        }

        if (!outputPath.toLowerCase().endsWith('.png'))
          outputPath = '$outputPath.png';

        final file = File(outputPath);
        await file.writeAsBytes(imageBytes);

        print('✅ File saved to custom location (desktop): $outputPath');
        _showSuccess('Gambar berhasil disimpan: ${file.path.split('/').last}');
      }
    } catch (e, stackTrace) {
      print('❌ Error saving to custom folder: $e');
      print('Stack trace: $stackTrace');
      _showError('Gagal menyimpan gambar: ${e.toString()}');
    }
  }

  /// Share image ke aplikasi lain (WhatsApp, Instagram, etc)
  Future<void> _shareImage(Uint8List imageBytes) async {
    try {
      print('🔄 Starting share process...');

      // Update project thumbnail
      await _updateProjectThumbnail(imageBytes);

      // Buat file temporary
      final tempDir = await getTemporaryDirectory();
      print('📁 Temp directory: ${tempDir.path}');

      final fileName =
          'muraloka_${currentProject?.name ?? 'artwork'}_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);

      print('💾 Writing file to: $filePath');
      await file.writeAsBytes(imageBytes);
      print('✅ File written successfully (${imageBytes.length} bytes)');

      // Verify file exists
      final exists = await file.exists();
      print('📂 File exists: $exists');

      if (!exists) {
        throw Exception('File was not created');
      }

      // ✅ IMPROVED: Better share text and subject
      final projectName = currentProject?.name ?? 'My Artwork';
      final shareText = '🎨 Check out my artwork "$projectName" created with Muraloka!\n\nMuraloka - Digital Art Made Easy';
      
      // Share with multiple apps support (WhatsApp, Instagram, Twitter, etc)
      print('📤 Initiating share...');
      final result = await Share.shareXFiles(
        [XFile(filePath, mimeType: 'image/png')],
        subject: 'Muraloka Artwork: $projectName',
        text: shareText,
      );

      print('✅ Share completed with result: ${result.status}');

      // Show success message
      if (mounted) {
        _showSuccess('Share dialog opened! Select your app (WhatsApp, Instagram, etc)');
      }
    } catch (e, stackTrace) {
      print('❌ Share error: $e');
      print('Stack trace: $stackTrace');
      _showError('Gagal share: ${e.toString()}');
    }
  }

  /// Show invite collaborator dialog (owner only)
  Future<void> _showInviteCollaboratorDialog() async {
    if (currentProject == null || !currentProject!.isOwner(currentUserId)) {
      _showError('Only owner can invite collaborators');
      return;
    }

    if (!widget.isShared) {
      _showError('Project must be shared to add collaborators');
      return;
    }

    final emailController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite Collaborator'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter collaborator\'s User ID:'),
            const SizedBox(height: 8),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                hintText: 'User ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Note: The user must be registered in the system.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final userId = emailController.text.trim();
              if (userId.isNotEmpty) {
                Navigator.pop(context, userId);
              }
            },
            child: const Text('Invite'),
          ),
        ],
      ),
    );

    if (result != null) {
      _inviteCollaborator(result);
    }
  }

  /// Invite collaborator to project
  Future<void> _inviteCollaborator(String userId) async {
    if (currentProject == null) return;

    try {
      await projectRepo.addCollaborator(currentProject!.id, userId);
      _showSuccess('Collaborator invited');

      // Refresh project data
      if (widget.projectId != null) {
        await _loadProject(widget.projectId!);
      }
    } catch (e) {
      _showError('Failed to invite: $e');
    }
  }

  /// Show active collaborators list
  void _showActiveCollaborators() {
    if (currentProject == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Active Collaborators'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(PhosphorIcons.crown, color: Colors.amber),
              title: Text('Owner: ${currentProject!.ownerId}'),
              subtitle: currentProject!.ownerId == currentUserId
                  ? const Text('You')
                  : null,
            ),
            const Divider(),
            if (currentProject!.collaboratorIds.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No collaborators yet'),
              )
            else
              ...currentProject!.collaboratorIds.map((collaboratorId) {
                final isCurrentUser = collaboratorId == currentUserId;
                return ListTile(
                  leading: const Icon(PhosphorIcons.user),
                  title: Text(collaboratorId),
                  subtitle: isCurrentUser ? const Text('You') : null,
                  trailing:
                      currentProject!.isOwner(currentUserId) && !isCurrentUser
                      ? IconButton(
                          icon: const Icon(
                            PhosphorIcons.trash,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _removeCollaborator(collaboratorId);
                          },
                        )
                      : null,
                );
              }).toList(),
          ],
        ),
        actions: [
          if (currentProject!.isOwner(currentUserId))
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showInviteCollaboratorDialog();
              },
              icon: const Icon(PhosphorIcons.plus),
              label: const Text('Invite'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Remove collaborator from project (owner only)
  Future<void> _removeCollaborator(String collaboratorId) async {
    if (currentProject == null || !currentProject!.isOwner(currentUserId)) {
      _showError('Only owner can remove collaborators');
      return;
    }

    try {
      await projectRepo.removeCollaborator(currentProject!.id, collaboratorId);
      _showSuccess('Collaborator removed');

      // Refresh project data
      if (widget.projectId != null) {
        await _loadProject(widget.projectId!);
      }
    } catch (e) {
      _showError('Failed to remove: $e');
    }
  }

  /// Show color picker dialog (generic - can be used for any color selection)
  Future<Color?> _showColorPickerDialog(BuildContext context, {required Color initialColor}) async {
    Color pickerColor = initialColor;

    final result = await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Warna'),
        content: SingleChildScrollView(
          child: ColorPicker(
            color: pickerColor,
            onColorChanged: (Color color) {
              pickerColor = color;
            },
            width: 40,
            height: 40,
            borderRadius: 8,
            spacing: 4,
            runSpacing: 4,
            wheelDiameter: 200,
            heading: Text(
              'Pilih warna',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            subheading: Text(
              'Pilih warna yang diinginkan',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            pickersEnabled: const <ColorPickerType, bool>{
              ColorPickerType.both: false,
              ColorPickerType.primary: true,
              ColorPickerType.accent: true,
              ColorPickerType.bw: false,
              ColorPickerType.custom: false,
              ColorPickerType.wheel: true,
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, pickerColor),
            child: const Text('Pilih'),
          ),
        ],
      ),
    );

    return result;
  }

  /// Add sticker from dialog
  Future<void> _addSticker() async {
    final imageLink = await showDialog<String>(
      context: context,
      builder: (context) => const SelectStickerImageDialog(
        imagesLinks: stickerImageLinks,
      ),
    );

    if (imageLink == null) return;

    try {
      // Deactivate drawing mode
      if (controller.freeStyleMode != FreeStyleMode.none) {
        setState(() {
          controller.freeStyleMode = FreeStyleMode.none;
        });
      }

      // Load image from network
      final image = await NetworkImage(imageLink).image;
      
      // Add image to canvas
      controller.addImage(
        image,
        const Size(100, 100), // Default size for stickers
      );

      // Trigger autosave after adding sticker
      _onCanvasChanged();

      print('✅ Sticker added successfully');
    } catch (e) {
      print('❌ Failed to add sticker: $e');
      _showError('Failed to add sticker: $e');
    }
  }

  /// Show color picker dialog
  Future<void> _showColorPicker() async {
    Color pickerColor = controller.freeStyleColor;

    final result = await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Warna'),
        content: SingleChildScrollView(
          child: ColorPicker(
            color: pickerColor,
            onColorChanged: (Color color) {
              pickerColor = color;
            },
            width: 40,
            height: 40,
            borderRadius: 8,
            spacing: 4,
            runSpacing: 4,
            wheelDiameter: 200,
            heading: Text(
              'Pilih warna brush',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            subheading: Text(
              'Pilih warna yang diinginkan',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            pickersEnabled: const <ColorPickerType, bool>{
              ColorPickerType.both: false,
              ColorPickerType.primary: true,
              ColorPickerType.accent: true,
              ColorPickerType.bw: false,
              ColorPickerType.custom: false,
              ColorPickerType.wheel: true,
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, pickerColor),
            child: const Text('Pilih'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        controller.freeStyleColor = result;
      });
    }
  }

  /// Show stroke width picker
  Future<void> _showStrokeWidthPicker() async {
    double currentWidth = controller.freeStyleStrokeWidth;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Ukuran Brush'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ukuran: ${currentWidth.toStringAsFixed(1)} px',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Slider(
                value: currentWidth,
                min: 1.0,
                max: 50.0,
                divisions: 49,
                label: currentWidth.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() {
                    currentWidth = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Preview
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Container(
                    width: currentWidth * 2,
                    height: currentWidth * 2,
                    decoration: BoxDecoration(
                      color: controller.freeStyleColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                this.setState(() {
                  controller.freeStyleStrokeWidth = currentWidth;
                });
                Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  /// Show canvas background color picker
  Future<void> _showCanvasBackgroundPicker() async {
    Color pickerColor = canvasBackgroundColor;

    final result = await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Background Color'),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Quick colors only
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildQuickColorButton(Colors.white, 'White'),
                  _buildQuickColorButton(Colors.black, 'Black'),
                  _buildQuickColorButton(Colors.grey.shade200, 'Gray'),
                  _buildQuickColorButton(Colors.blue.shade50, 'Blue'),
                  _buildQuickColorButton(Colors.yellow.shade50, 'Yellow'),
                  _buildQuickColorButton(Colors.green.shade50, 'Green'),
                  _buildQuickColorButton(Colors.red.shade50, 'Red'),
                  _buildQuickColorButton(Colors.purple.shade50, 'Purple'),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              // Custom color picker - compact
              StatefulBuilder(
                builder: (context, setDialogState) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Custom Color',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    ColorPicker(
                      color: pickerColor,
                      onColorChanged: (Color color) {
                        setDialogState(() {
                          pickerColor = color;
                        });
                      },
                      width: 35,
                      height: 35,
                      borderRadius: 4,
                      spacing: 3,
                      runSpacing: 3,
                      wheelDiameter: 160,
                      enableShadesSelection: false,
                      pickersEnabled: const <ColorPickerType, bool>{
                        ColorPickerType.both: false,
                        ColorPickerType.primary: false,
                        ColorPickerType.accent: false,
                        ColorPickerType.bw: false,
                        ColorPickerType.custom: false,
                        ColorPickerType.wheel: true,
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, pickerColor),
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      setState(() {
        canvasBackgroundColor = result;
      });
      
      // Save background color to database
      await _saveBackgroundColor(result);
      
      // Trigger autosave for canvas changes
      _onCanvasChanged();
    }
  }

  /// Save background color to database
  Future<void> _saveBackgroundColor(Color color) async {
    if (currentProject == null) return;

    try {
      final updates = {
        'backgroundColor': color.value,
        'updatedAt': Timestamp.now(),
      };

      if (widget.isShared) {
        await projectRepo.updateSharedProject(
          currentProject!.id,
          updates,
        );
      } else {
        await projectRepo.updatePrivateProject(
          currentUserId,
          currentProject!.id,
          updates,
        );
      }

      // Update local project object
      final updatedProject = currentProject!.copyWith(
        backgroundColor: color.value,
        updatedAt: DateTime.now(),
      );
      setState(() => currentProject = updatedProject);
      
      print('Background color saved: ${color.value}');
    } catch (e) {
      print('Error saving background color: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save background color: $e')),
        );
      }
    }
  }

  /// Build quick color button for canvas background
  Widget _buildQuickColorButton(Color color, String label) {
    final isSelected = canvasBackgroundColor == color;
    return InkWell(
      onTap: () {
        Navigator.pop(context, color);
      },
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade400,
            width: isSelected ? 3 : 2,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.4),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color.computeLuminance() > 0.5
                  ? Colors.black87
                  : Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  /// Toggle horizontal mirror
  void _toggleMirrorHorizontal() {
    setState(() {
      isMirrorHorizontal = !isMirrorHorizontal;
    });
  }

  /// Toggle vertical mirror
  void _toggleMirrorVertical() {
    setState(() {
      isMirrorVertical = !isMirrorVertical;
    });
  }

  /// Rotate canvas 90° counter-clockwise (left)
  void _rotateLeft() {
    setState(() {
      canvasRotation = (canvasRotation - 90) % 360;
      if (canvasRotation < 0) canvasRotation += 360;
    });
  }

  /// Rotate canvas 90° clockwise (right)
  void _rotateRight() {
    setState(() {
      canvasRotation = (canvasRotation + 90) % 360;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const CustomLoadingIndicator(message: 'Preparing your canvas...'),
      );
    }

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        // Zoom In: Ctrl + Plus atau Ctrl + =
        const SingleActivator(LogicalKeyboardKey.equal, control: true): _zoomIn,
        const SingleActivator(LogicalKeyboardKey.add, control: true): _zoomIn,
        // Zoom Out: Ctrl + Minus
        const SingleActivator(LogicalKeyboardKey.minus, control: true): _zoomOut,
        // Reset to 1:1: Ctrl + 1
        const SingleActivator(LogicalKeyboardKey.digit1, control: true): _resetCanvasView,
      },
      child: Focus(
        autofocus: true,
        child: WillPopScope(
          onWillPop: () async {
            // Save before exiting when back button is pressed
            await _saveCurrentLayer();
            return true; // Allow pop
          },
          child: Scaffold(
      appBar: AppBar(
        title: Text(currentProject?.name ?? 'Canvas'),
        automaticallyImplyLeading: false, // Remove back button
        leading: IconButton(
          icon: const Icon(PhosphorIcons.list, size: 24),
          tooltip: 'Menu',
          onPressed: () {
            // Store scaffold context before showing modal
            final scaffoldContext = context;
            
            showModalBottomSheet(
              context: context,
              builder: (context) => Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(PhosphorIcons.arrow_left),
                      title: const Text('Exit Canvas'),
                      subtitle: const Text('Return to Projects'),
                      onTap: () async {
                        Navigator.pop(context); // Close menu
                        
                        // Save before exiting
                        await _saveCurrentLayer();
                        
                        // Exit canvas page using scaffold context
                        if (mounted) Navigator.of(scaffoldContext).pop();
                      },
                    ),
                    ListTile(
                      leading: const Icon(PhosphorIcons.floppy_disk),
                      title: const Text('Save Project'),
                      subtitle: const Text('Save all changes'),
                      onTap: () {
                        Navigator.pop(context);
                        _saveCurrentLayer();
                      },
                    ),
                    ListTile(
                      leading: const Icon(PhosphorIcons.download_simple),
                      title: const Text('Export Canvas'),
                      subtitle: const Text('Save as image'),
                      onTap: () {
                        Navigator.pop(context);
                        _exportCanvas();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        actions: [
          // Toolbar toggle - dengan visual feedback
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: !isToolbarVisible
                  ? Colors.blue.shade50
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(
                isToolbarVisible ? PhosphorIcons.eye_slash : PhosphorIcons.eye,
                size: 20,
                color: !isToolbarVisible ? Colors.blue : null,
              ),
              onPressed: () {
                setState(() {
                  isToolbarVisible = !isToolbarVisible;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isToolbarVisible ? 'Toolbar shown' : 'Toolbar hidden',
                      style: const TextStyle(color: Colors.white),
                    ),
                    duration: const Duration(milliseconds: 800),
                    backgroundColor: Colors.black87,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.only(
                      bottom: 80,
                      left: 16,
                      right: 16,
                    ),
                  ),
                );
              },
              tooltip: isToolbarVisible ? 'Hide Toolbar' : 'Show Toolbar',
            ),
          ),
          const VerticalDivider(width: 1, indent: 12, endIndent: 12),
          // Save button
          IconButton(
            icon: isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(PhosphorIcons.floppy_disk),
            onPressed: isSaving ? null : _saveCurrentLayer,
            tooltip: 'Save',
            iconSize: 20,
          ),
          // Export canvas - ONLY OWNER (MVP Requirement)
          if (currentProject != null && currentProject!.isOwner(currentUserId))
            IconButton(
              icon: const Icon(PhosphorIcons.download_simple),
              onPressed: _exportCanvas,
              tooltip: 'Export Canvas (Owner Only)',
              iconSize: 20,
            ),
          // Sell to Marketplace - ONLY OWNER (MVP Requirement)
          if (currentProject != null && currentProject!.isOwner(currentUserId))
            IconButton(
              icon: const Icon(PhosphorIcons.storefront),
              onPressed: _sellToMarketplace,
              tooltip: 'Sell to Marketplace (Owner Only)',
              iconSize: 20,
            ),
          const VerticalDivider(width: 1, indent: 12, endIndent: 12),
          // Layer panel
          IconButton(
            icon: const Icon(PhosphorIcons.stack),
            onPressed: _showLayerPanel,
            tooltip: 'Layers',
            iconSize: 20,
          ),
          // Collaborators (only for shared projects)
          if (widget.isShared)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(PhosphorIcons.users_three),
                  onPressed: _showActiveCollaborators,
                  iconSize: 20,
                ),
                // Active collaborator badge
                if (currentProject != null &&
                    currentProject!.collaboratorIds.isNotEmpty)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        '${currentProject!.collaboratorIds.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          // View options dropdown
          PopupMenuButton<String>(
            icon: const Icon(PhosphorIcons.eye, size: 20),
            tooltip: 'View',
            onSelected: (String value) {
              if (value == 'background') {
                _showCanvasBackgroundPicker();
              } else if (value == 'mirror_h') {
                _toggleMirrorHorizontal();
              } else if (value == 'mirror_v') {
                _toggleMirrorVertical();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'background',
                child: ListTile(
                  leading: Icon(
                    PhosphorIcons.paint_bucket,
                    color: canvasBackgroundColor,
                    size: 20,
                  ),
                  title: const Text('Background Color'),
                  dense: true,
                ),
              ),
              PopupMenuItem<String>(
                value: 'mirror_h',
                child: ListTile(
                  leading: Icon(
                    PhosphorIcons.arrows_left_right,
                    color: isMirrorHorizontal ? Colors.blue : null,
                    size: 20,
                  ),
                  title: const Text('Mirror Horizontal'),
                  trailing: isMirrorHorizontal
                      ? const Icon(PhosphorIcons.check, size: 16)
                      : null,
                  dense: true,
                ),
              ),
              PopupMenuItem<String>(
                value: 'mirror_v',
                child: ListTile(
                  leading: Icon(
                    PhosphorIcons.arrows_down_up,
                    color: isMirrorVertical ? Colors.blue : null,
                    size: 20,
                  ),
                  title: const Text('Mirror Vertical'),
                  trailing: isMirrorVertical
                      ? const Icon(PhosphorIcons.check, size: 16)
                      : null,
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main canvas with rotation - UNLIMITED ZOOM & FULL CANVAS SIZE
          // ✅ TODO: 2-finger rotation gesture will be added in next update
          Container(
            color: Colors.grey.shade300,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final canvasWidth = (currentProject?.canvasWidth ?? 1920)
                    .toDouble();
                final canvasHeight = (currentProject?.canvasHeight ?? 1080)
                    .toDouble();

                return InteractiveViewer(
                  transformationController: transformationController,
                  boundaryMargin: EdgeInsets.all(
                    max(canvasWidth, canvasHeight) * 2.0, // Increased to 2x for better pan freedom
                  ), // Allow panning beyond canvas edges
                  minScale: 0.01, // Zoom out sangat jauh (100x zoom out)
                  maxScale: 50.0, // Zoom in sangat detail (50x zoom in)
                  constrained: false, // CRITICAL: Allow canvas larger than screen
                  panEnabled: true, // Always enable pan for better UX
                  scaleEnabled: true, // Always allow pinch zoom
                  alignment: Alignment.center,
                  child: Container(
                    // Container wrapper untuk memastikan transform tidak overflow
                    width: canvasWidth,
                    height: canvasHeight,
                    alignment: Alignment.center,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..rotateZ(
                          canvasRotation * 3.14159 / 180,
                        ) // Convert degrees to radians
                        ..scale(
                          isMirrorHorizontal ? -1.0 : 1.0,
                          isMirrorVertical ? -1.0 : 1.0,
                        ),
                      child: Container(
                        width: canvasWidth,
                        height: canvasHeight,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey.shade800,
                            width: 2,
                          ),
                          color: canvasBackgroundColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Render all visible layers sorted by zIndex (lowest first)
                            ...() {
                              // Create list of layer widgets
                              final layerWidgets = <Widget>[];
                              
                              // Sort layers by zIndex
                              final sortedIndices = List.generate(layers.length, (i) => i)
                                ..sort((a, b) => layers[a].zIndex.compareTo(layers[b].zIndex));

                              for (final index in sortedIndices) {
                                final layer = layers[index];
                                if (!layer.isVisible) continue;

                                final isActiveLayer = index == selectedLayerIndex;

                                // Active layer uses FlutterPainter (editable)
                                if (isActiveLayer) {
                                  layerWidgets.add(
                                    // When pan tool is active, ignore FlutterPainter gestures
                                    // This allows InteractiveViewer to handle pan/zoom
                                    IgnorePointer(
                                      ignoring: isPanToolActive,
                                      child: FlutterPainter(controller: controller),
                                    ),
                                  );
                                } else {
                                  // Non-active layers show rendered image (read-only)
                                  final layerImage = layerImages[layer.id];
                                  if (layerImage != null) {
                                    layerWidgets.add(
                                      Opacity(
                                        opacity: layer.opacity,
                                        child: RawImage(
                                          image: layerImage,
                                          width: canvasWidth,
                                          height: canvasHeight,
                                          fit: BoxFit.fill,
                                        ),
                                      ),
                                    );
                                  }
                                }
                              }

                              return layerWidgets;
                            }(),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Minimap overlay - lebih kecil
          if (showMinimap)
            Positioned(
              bottom: isToolbarVisible ? 80 : 16, // Increased from 70 to 80
              right: 16,
              child: Container(
                width: 120,
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 2),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(
                    children: [
                      // Minimap canvas preview
                      Center(
                        child: Transform.scale(
                          scale: 0.055,
                          child: Container(
                            width: (currentProject?.canvasWidth ?? 1920)
                                .toDouble(),
                            height: (currentProject?.canvasHeight ?? 1080)
                                .toDouble(),
                            color: canvasBackgroundColor,
                            child: IgnorePointer(
                              child: FlutterPainter(controller: controller),
                            ),
                          ),
                        ),
                      ),
                      // Minimap label
                      Positioned(
                        top: 2,
                        left: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            'Map',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // 🎥 Floating Collaborator Avatars (Zoom-like) - ONLY FOR SHARED PROJECTS
          if (widget.isShared && currentProject != null)
            Positioned(
              top: 16,
              right: 16,
              child: _buildFloatingCollaboratorAvatars(),
            ),
          // Zoom level display - bottom left
          Positioned(
            bottom: isToolbarVisible ? 80 : 16,
            left: 16,
            child: AnimatedBuilder(
              animation: transformationController,
              builder: (context, child) {
                final zoom = transformationController.value.getMaxScaleOnAxis();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        PhosphorIcons.magnifying_glass,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${(zoom * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: isToolbarVisible ? null : 0,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isToolbarVisible ? 1.0 : 0.0,
          child: isToolbarVisible
              ? SafeArea(bottom: true, child: _buildToolbar())
              : const SizedBox.shrink(),
        ),
      ),
        ), // Close Scaffold
        ), // Close WillPopScope
      ), // Close Focus
    ); // Close CallbackShortcuts
  }

  Widget _buildToolbar() {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, _, __) => Container(
        constraints: const BoxConstraints(minHeight: 64),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.grey.shade50],
          ),
          border: Border(
            top: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // GROUP 1: Navigation & View Tools
              _buildModernToolGroup(
                label: 'View',
                icon: PhosphorIcons.eye,
                children: [
                  _buildModernToolButton(
                    icon: PhosphorIcons.hand,
                    label: 'Pan',
                    isActive: isPanToolActive,
                    onPressed: _togglePanTool,
                  ),
                  _buildModernToolButton(
                    icon: PhosphorIcons.arrows_counter_clockwise,
                    label: '1:1',
                    onPressed: _resetCanvasView,
                  ),
                  // Zoom popup menu
                  Tooltip(
                    message: 'Zoom',
                    child: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'in') _zoomIn();
                        if (value == 'out') _zoomOut();
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'in',
                          child: Row(
                            children: const [
                              Icon(PhosphorIcons.magnifying_glass_plus, size: 18),
                              SizedBox(width: 8),
                              Text('Zoom In'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'out',
                          child: Row(
                            children: const [
                              Icon(PhosphorIcons.magnifying_glass_minus, size: 18),
                              SizedBox(width: 8),
                              Text('Zoom Out'),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade800
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade700
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              PhosphorIcons.magnifying_glass,
                              size: 18,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_drop_down,
                              size: 16,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Rotate popup menu
                  Tooltip(
                    message: 'Rotate',
                    child: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'left') _rotateLeft();
                        if (value == 'right') _rotateRight();
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'left',
                          child: Row(
                            children: const [
                              Icon(PhosphorIcons.arrow_counter_clockwise, size: 18),
                              SizedBox(width: 8),
                              Text('Rotate Left'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'right',
                          child: Row(
                            children: const [
                              Icon(PhosphorIcons.arrow_clockwise, size: 18),
                              SizedBox(width: 8),
                              Text('Rotate Right'),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade800
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade700
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              PhosphorIcons.arrows_clockwise,
                              size: 18,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_drop_down,
                              size: 16,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              _buildModernDivider(),

              // GROUP 2: Drawing Tools
              _buildModernToolGroup(
                label: 'Draw',
                icon: PhosphorIcons.pencil,
                children: [
                  _buildModernToolButton(
                    icon: PhosphorIcons.pencil_simple,
                    label: 'Pen',
                    isActive:
                        controller.freeStyleMode == FreeStyleMode.draw &&
                        !isBlurToolActive,
                    onPressed: () {
                      setState(() {
                        isPanToolActive = false;
                        isBlurToolActive = false;
                        controller.freeStyleMode =
                            controller.freeStyleMode != FreeStyleMode.draw
                            ? FreeStyleMode.draw
                            : FreeStyleMode.none;
                      });
                    },
                  ),
                  _buildModernToolButton(
                    icon: PhosphorIcons.eraser,
                    label: 'Erase',
                    isActive: controller.freeStyleMode == FreeStyleMode.erase,
                    onPressed: () {
                      setState(() {
                        isPanToolActive = false;
                        isBlurToolActive = false;
                        
                        if (controller.freeStyleMode != FreeStyleMode.erase) {
                          // Enable erase mode: use background color with current opacity
                          controller.freeStyleMode = FreeStyleMode.erase;
                          // Store current color to restore later
                          controller.freeStyleColor = canvasBackgroundColor.withOpacity(
                            controller.freeStyleColor.opacity, // Keep current opacity
                          );
                        } else {
                          // Disable erase mode
                          controller.freeStyleMode = FreeStyleMode.none;
                        }
                      });
                    },
                  ),
                  _buildModernToolButton(
                    icon: PhosphorIcons.drop_half_bottom,
                    label: 'Blur',
                    isActive: isBlurToolActive,
                    onPressed: _toggleBlurTool,
                  ),
                ],
              ),
              _buildModernDivider(),

              // GROUP 3: Brush Properties (Modern)
              _buildModernToolGroup(
                label: 'Brush',
                icon: PhosphorIcons.paint_brush,
                children: [
                  // Color picker with better design
                  Tooltip(
                    message: 'Color',
                    child: InkWell(
                      onTap: _showColorPicker,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 36,
                        height: 36,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: controller.freeStyleColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          PhosphorIcons.palette,
                          size: 16,
                          color:
                              controller.freeStyleColor.computeLuminance() > 0.5
                              ? Colors.black54
                              : Colors.white70,
                        ),
                      ),
                    ),
                  ),
                  // Size button with value
                  _buildModernToolButton(
                    icon: PhosphorIcons.circle,
                    label: '${controller.freeStyleStrokeWidth.toInt()}px',
                    onPressed: _showStrokeWidthPicker,
                  ),
                  // Opacity button
                  _buildModernToolButton(
                    icon: PhosphorIcons.drop,
                    label: 'Opacity',
                    onPressed: _showBrushOpacityPicker,
                  ),
                ],
              ),
              _buildModernDivider(),

              // GROUP 4: Shapes & Content
              _buildModernToolGroup(
                label: 'Add',
                icon: PhosphorIcons.plus_circle,
                children: [
                  _buildModernToolButton(
                    icon: PhosphorIcons.text_aa,
                    label: 'Text',
                    isActive: textFocusNode.hasFocus,
                    onPressed: () {
                      setState(() {
                        if (controller.freeStyleMode != FreeStyleMode.none) {
                          controller.freeStyleMode = FreeStyleMode.none;
                        }
                        controller.addText();
                      });
                      // Trigger autosave after adding text
                      _onCanvasChanged();
                    },
                  ),
                  // Sticker button
                  _buildModernToolButton(
                    icon: PhosphorIcons.sticker,
                    label: 'Sticker',
                    onPressed: _addSticker,
                  ),
                  // Shapes menu button
                  Tooltip(
                    message: 'Shapes',
                    child: PopupMenuButton<ShapeFactory?>(
                      padding: EdgeInsets.zero,
                      offset: const Offset(0, -10),
                      onSelected: (shape) {
                        if (shape != null) {
                          setState(() {
                            controller.shapeFactory = shape;
                          });
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          enabled: false,
                          height: 30,
                          child: Text(
                            'Select Shape',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const PopupMenuDivider(height: 1),
                        PopupMenuItem(
                          value: LineFactory(),
                          height: 40,
                          child: Row(
                            children: [
                              Icon(
                                PhosphorIcons.line_segment,
                                size: 18,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Line',
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: ArrowFactory(),
                          height: 40,
                          child: Row(
                            children: [
                              Icon(
                                PhosphorIcons.arrow_right,
                                size: 18,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Arrow',
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: RectangleFactory(),
                          height: 40,
                          child: Row(
                            children: [
                              Icon(
                                PhosphorIcons.rectangle,
                                size: 18,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Rectangle',
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: OvalFactory(),
                          height: 40,
                          child: Row(
                            children: [
                              Icon(
                                PhosphorIcons.circle,
                                size: 18,
                                color: Colors.purple,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Circle',
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              PhosphorIcons.polygon,
                              size: 20,
                              color: Colors.grey.shade700,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Shape',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              _buildModernDivider(),

              // GROUP 4.5: Text Editing (shown when text is active)
              if (textFocusNode.hasFocus) ...[
                _buildModernToolGroup(
                  label: 'Text',
                  icon: PhosphorIcons.text_aa,
                  children: [
                    // Font Size Slider
                    Container(
                      width: 150,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Size',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                '${(controller.textStyle.fontSize ?? 18).toInt()}px',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: controller.textStyle.fontSize ?? 18,
                            min: 10,
                            max: 120,
                            divisions: 110,
                            activeColor: Colors.blue,
                            inactiveColor: Colors.grey.shade300,
                            onChanged: (value) {
                              setState(() {
                                controller.textSettings = controller.textSettings.copyWith(
                                  textStyle: controller.textStyle.copyWith(fontSize: value),
                                );
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    // Text Color Picker
                    Tooltip(
                      message: 'Text Color',
                      child: InkWell(
                        onTap: () async {
                          final color = await _showColorPickerDialog(
                            context,
                            initialColor: controller.textStyle.color ?? Colors.black,
                          );
                          if (color != null) {
                            setState(() {
                              controller.textSettings = controller.textSettings.copyWith(
                                textStyle: controller.textStyle.copyWith(color: color),
                              );
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: controller.textStyle.color ?? Colors.black,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade400, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            PhosphorIcons.palette,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                _buildModernDivider(),
              ],

              // GROUP 5: Actions (Undo/Redo/Clear)
              _buildModernToolGroup(
                label: 'Actions',
                icon: PhosphorIcons.sparkle,
                children: [
                  _buildModernToolButton(
                    icon: PhosphorIcons.arrow_counter_clockwise,
                    label: 'Undo',
                    onPressed: controller.canUndo
                        ? () => setState(() => controller.undo())
                        : () {},
                    activeColor: controller.canUndo ? Colors.blue : Colors.grey,
                  ),
                  _buildModernToolButton(
                    icon: PhosphorIcons.arrow_clockwise,
                    label: 'Redo',
                    onPressed: controller.canRedo
                        ? () => setState(() => controller.redo())
                        : () {},
                    activeColor: controller.canRedo ? Colors.blue : Colors.grey,
                  ),
                  _buildModernToolButton(
                    icon: PhosphorIcons.trash,
                    label: 'Clear',
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Clear Canvas?'),
                          content: const Text(
                            'Are you sure you want to clear all drawings?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        setState(() {
                          controller.clearDrawables();
                        });
                        // Trigger autosave after clearing canvas
                        _onCanvasChanged();
                      }
                    },
                    activeColor: Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show brush opacity picker
  Future<void> _showBrushOpacityPicker() async {
    // Get current opacity from color
    double currentOpacity = controller.freeStyleColor.opacity;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Brush Opacity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Opacity: ${(currentOpacity * 100).toInt()}%',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Slider(
                value: currentOpacity,
                min: 0.1,
                max: 1.0,
                divisions: 9,
                label: '${(currentOpacity * 100).toInt()}%',
                onChanged: (value) {
                  setState(() {
                    currentOpacity = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Preview
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: controller.freeStyleColor.withOpacity(
                        currentOpacity,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                this.setState(() {
                  controller.freeStyleColor = controller.freeStyleColor
                      .withOpacity(currentOpacity);
                });
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  /// Toggle pan tool
  void _togglePanTool() {
    setState(() {
      isPanToolActive = !isPanToolActive;
      if (isPanToolActive) {
        // Disable other drawing tools
        controller.freeStyleMode = FreeStyleMode.none;
        isBlurToolActive = false;
      }
    });
  }

  /// Reset canvas view to 1:1 scale (show actual canvas size, centered)
  void _resetCanvasView() {
    final canvasWidth = (currentProject?.canvasWidth ?? 1920).toDouble();
    final canvasHeight = (currentProject?.canvasHeight ?? 1080).toDouble();
    
    // Get screen size
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height - 200; // Account for toolbar
    
    // Calculate offset to center canvas at 1:1 scale
    // Center point of screen
    final centerScreenX = screenWidth / 2;
    final centerScreenY = screenHeight / 2;
    
    // Center point of canvas
    final centerCanvasX = canvasWidth / 2;
    final centerCanvasY = canvasHeight / 2;
    
    // Translation to center canvas on screen
    final translateX = centerScreenX - centerCanvasX;
    final translateY = centerScreenY - centerCanvasY;
    
    // Reset transformation to 1:1 scale (no scale, just center)
    transformationController.value = Matrix4.identity()
      ..translate(translateX, translateY);
    
    _showSuccess('Canvas 1:1 - Actual Size');
  }

  /// Zoom in canvas (increase scale by 20%) with smooth animation
  void _zoomIn() {
    final currentMatrix = transformationController.value.clone();
    final currentScale = currentMatrix.getMaxScaleOnAxis();
    
    // Maximum zoom in: 50x
    if (currentScale >= 50.0) {
      _showError('Maximum zoom reached');
      return;
    }
    
    final newScale = min(currentScale * 1.2, 50.0); // Increase by 20%
    final scaleChange = newScale / currentScale;
    
    // Get screen center
    final screenSize = MediaQuery.of(context).size;
    final centerX = screenSize.width / 2;
    final centerY = (screenSize.height - 200) / 2;
    
    // Scale from center point
    final matrix = Matrix4.identity()
      ..translate(centerX, centerY)
      ..scale(scaleChange)
      ..translate(-centerX, -centerY)
      ..multiply(currentMatrix);
    
    // Smooth animation
    _animateZoom(matrix);
    // Removed notification - zoom level shown in bottom display
  }

  /// Animate zoom transformation smoothly
  void _animateZoom(Matrix4 targetMatrix) {
    final startMatrix = transformationController.value.clone();
    const duration = Duration(milliseconds: 200); // Smooth 200ms animation
    final startTime = DateTime.now();
    
    Timer.periodic(const Duration(milliseconds: 16), (timer) { // ~60 FPS
      final elapsed = DateTime.now().difference(startTime);
      final t = (elapsed.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
      
      if (t >= 1.0) {
        transformationController.value = targetMatrix;
        timer.cancel();
        return;
      }
      
      // Ease-out cubic interpolation for smooth feel
      final progress = (1 - pow(1 - t, 3)).toDouble();
      
      // Interpolate between start and target matrix
      transformationController.value = _lerpMatrix4(startMatrix, targetMatrix, progress);
    });
  }
  
  /// Linear interpolation between two Matrix4
  Matrix4 _lerpMatrix4(Matrix4 a, Matrix4 b, double t) {
    final result = Matrix4.zero();
    for (int i = 0; i < 16; i++) {
      result.storage[i] = a.storage[i] + (b.storage[i] - a.storage[i]) * t;
    }
    return result;
  }

  /// Zoom out canvas (decrease scale by 20%) with smooth animation
  void _zoomOut() {
    final currentMatrix = transformationController.value.clone();
    final currentScale = currentMatrix.getMaxScaleOnAxis();
    
    // Minimum zoom out: 0.01x
    if (currentScale <= 0.01) {
      _showError('Minimum zoom reached');
      return;
    }
    
    final newScale = max(currentScale / 1.2, 0.01); // Decrease by 20%
    final scaleChange = newScale / currentScale;
    
    // Get screen center
    final screenSize = MediaQuery.of(context).size;
    final centerX = screenSize.width / 2;
    final centerY = (screenSize.height - 200) / 2;
    
    // Scale from center point
    final matrix = Matrix4.identity()
      ..translate(centerX, centerY)
      ..scale(scaleChange)
      ..translate(-centerX, -centerY)
      ..multiply(currentMatrix);
    
    // Smooth animation
    _animateZoom(matrix);
    // Removed notification - zoom level shown in bottom display
  }

  /// Toggle blur tool
  void _toggleBlurTool() {
    setState(() {
      isBlurToolActive = !isBlurToolActive;
      if (isBlurToolActive) {
        isPanToolActive = false;
        
        // Use draw mode with current selected color but semi-transparent
        // This creates blur by overlaying semi-transparent color over existing strokes
        controller.freeStyleMode = FreeStyleMode.draw;
        
        // Note: Don't change color or stroke width here
        // User can select any color and size they want for blur
        // The blur effect comes from drawing with semi-transparent color
        // If user wants to change blur color, they change it via color picker
        // If user wants to change blur size, they change it via size picker
        
        _showSuccess('Blur tool activated - Select color & size for blur effect');
      } else {
        // When deactivating blur tool, return to normal mode
        controller.freeStyleMode = FreeStyleMode.none;
        _showSuccess('Blur tool deactivated');
      }
    });
  }

  // ==================== MODERN TOOLBAR HELPERS ====================

  /// Build modern tool group with label
  Widget _buildModernToolGroup({
    required String label,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Group label with icon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 10, color: Colors.grey.shade600),
                const SizedBox(width: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          // Tools row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: children
                .map(
                  (child) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: child,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  /// 🎥 Build Floating Collaborator Avatars (Zoom-like)
  /// Shows all users currently in the project room with their photos
  Widget _buildFloatingCollaboratorAvatars() {
    if (currentProject == null) return const SizedBox.shrink();

    // Get all collaborator IDs including owner
    final allUsers = <String>[
      currentProject!.ownerId,
      ...currentProject!.collaboratorIds,
    ];

    // Remove duplicates and current user (show others only)
    final otherUsers = allUsers
        .where((uid) => uid != currentUserId)
        .toSet()
        .toList();

    if (otherUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                PhosphorIcons.users_three,
                color: Colors.white,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                '${otherUsers.length} ${otherUsers.length == 1 ? 'Collaborator' : 'Collaborators'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Avatars
          ...otherUsers.map((userId) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .get(),
                  builder: (context, snapshot) {
                    String? photoURL;
                    String displayName = 'User';
                    
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final userData = snapshot.data!.data() as Map<String, dynamic>?;
                        photoURL = userData?['photoURL'];
                        displayName = userData?['displayName'] ?? 'User';
                      }
                    }

                    return Tooltip(
                      message: displayName,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.greenAccent,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.greenAccent.withOpacity(0.5),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.grey[800],
                          backgroundImage: photoURL != null 
                              ? NetworkImage(photoURL)
                              : null,
                          child: photoURL == null
                              ? Text(
                                  displayName.isNotEmpty 
                                      ? displayName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              )),
        ],
      ),
    );
  }

  /// Helper method to render text with stroke outline
  /// This ensures text is readable on both dark and light backgrounds
  void _renderTextWithStroke({
    required Canvas canvas,
    required String text,
    required Offset position,
    required double fontSize,
    required Color color,
    required FontWeight fontWeight,
  }) {
    // Calculate stroke color (opposite brightness)
    final isLightColor = color.computeLuminance() > 0.5;
    final strokeColor = isLightColor ? Colors.black : Colors.white;
    
    // Create text span with stroke
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = fontSize * 0.08 // 8% of fontSize for outline thickness
          ..color = strokeColor.withOpacity(0.7),
      ),
    );

    // Paint stroke (outline) first
    final strokePainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    strokePainter.layout();
    strokePainter.paint(canvas, position);

    // Create text span for fill
    final fillSpan = TextSpan(
      text: text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      ),
    );

    // Paint fill (text color) on top
    final fillPainter = TextPainter(
      text: fillSpan,
      textDirection: TextDirection.ltr,
    );
    fillPainter.layout();
    fillPainter.paint(canvas, position);
  }

  /// Build modern divider with gradient
  Widget _buildModernDivider() {
    return Container(
      width: 2,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.grey.shade300,
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  /// Build modern tool button with better feedback
  Widget _buildModernToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
    Color? activeColor,
  }) {
    final buttonColor = activeColor ?? Colors.blue;

    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? buttonColor.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isActive
                    ? buttonColor.withOpacity(0.4)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive ? buttonColor : Colors.grey.shade700,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive ? buttonColor : Colors.grey.shade600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
