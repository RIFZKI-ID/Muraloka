import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:muraloka/constant/constant.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../model/project.dart' as mvp;
import '../data_api/project_repository.dart';
import '../data_api/store_listing_repository.dart';
import '../widgets/ui_helpers.dart';
import '../widgets/animated_widgets.dart';
import 'layer_paint_page.dart';

/// Projects gallery page showing private and shared projects
class ProjectsGalleryPage extends StatefulWidget {
  const ProjectsGalleryPage({Key? key}) : super(key: key);

  @override
  _ProjectsGalleryPageState createState() => _ProjectsGalleryPageState();
}

class _ProjectsGalleryPageState extends State<ProjectsGalleryPage> {
  late ProjectRepository projectRepo;
  late StoreListingRepository listingRepo;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final String appId = 'muraloka_v1';

  @override
  void initState() {
    super.initState();
    projectRepo = ProjectRepository(appId: appId);
    listingRepo = StoreListingRepository(appId: appId);
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Canvas size presets
  final List<Map<String, dynamic>> canvasSizePresets = [
    {'name': '🖼️ Square 1:1 (1080x1080)', 'width': 1080, 'height': 1080},
    {'name': '📱 Instagram Post (1080x1080)', 'width': 1080, 'height': 1080},
    {'name': '📱 Instagram Story (1080x1920)', 'width': 1080, 'height': 1920},
    {'name': '🖥️ HD 16:9 (1920x1080)', 'width': 1920, 'height': 1080},
    {'name': '🖥️ Full HD (1920x1080)', 'width': 1920, 'height': 1080},
    {'name': '📺 4K UHD (3840x2160)', 'width': 3840, 'height': 2160},
    {'name': '🎨 A4 Portrait (2480x3508)', 'width': 2480, 'height': 3508},
    {'name': '🎨 A4 Landscape (3508x2480)', 'width': 3508, 'height': 2480},
    {'name': '🖼️ Square HD (2048x2048)', 'width': 2048, 'height': 2048},
    {'name': '📱 Mobile (1080x1920)', 'width': 1080, 'height': 1920},
    {'name': '💻 Desktop (1920x1080)', 'width': 1920, 'height': 1080},
    {'name': '🎭 Widescreen (2560x1440)', 'width': 2560, 'height': 1440},
    {'name': '✏️ Custom Size', 'width': 1920, 'height': 1080},
  ];

  /// Create new project dialog
  Future<void> _showCreateProjectDialog() async {
    final nameController = TextEditingController();
    final widthController = TextEditingController(text: '1920');
    final heightController = TextEditingController(text: '1080');

    String selectedPreset = canvasSizePresets[4]['name']; // Default: Full HD
    bool isCustomSize = false;

    // Use ThemeManager from constant.dart
    final theme = ThemeManager.of(context);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Create New Project',
            style: TextStyle(color: theme.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Project Name',
                    hintText: 'Enter project name',
                    prefixIcon: Icon(Icons.edit),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Canvas Size',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    underline: const SizedBox(),
                    value: selectedPreset,
                    items: canvasSizePresets.map((preset) {
                      return DropdownMenuItem<String>(
                        value: preset['name'],
                        child: Text(
                          preset['name'],
                          style: TextStyle(color: theme.textPrimary),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedPreset = value!;
                        final preset = canvasSizePresets.firstWhere(
                          (p) => p['name'] == value,
                        );
                        widthController.text = preset['width'].toString();
                        heightController.text = preset['height'].toString();
                        isCustomSize = value.contains('Custom');
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                if (isCustomSize || selectedPreset.contains('Custom'))
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: widthController,
                          decoration: const InputDecoration(
                            labelText: 'Width (px)',
                            prefixIcon: Icon(Icons.width_full),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('×', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: heightController,
                          decoration: const InputDecoration(
                            labelText: 'Height (px)',
                            prefixIcon: Icon(Icons.height),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.aspect_ratio, color: theme.primary),
                        const SizedBox(width: 8),
                        Text(
                          '${widthController.text} × ${heightController.text} px',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.primary,
                          ),
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
              child: Text(
                'Cancel',
                style: TextStyle(color: theme.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'name': nameController.text.isEmpty
                      ? 'Untitled Project'
                      : nameController.text,
                  'width': int.tryParse(widthController.text) ?? 1920,
                  'height': int.tryParse(heightController.text) ?? 1080,
                });
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      _createNewProject(result);
    }
  }

  /// Create new project and navigate to canvas
  Future<void> _createNewProject(Map<String, dynamic> projectData) async {
    try {
      // Navigate to canvas with project data (will be created in LayerPaintPage)
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LayerPaintPage(
              projectId: null, // Null = create new project
              isShared: false,
              projectName: projectData['name'],
              canvasWidth: projectData['width'],
              canvasHeight: projectData['height'],
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Failed to navigate to canvas: $e');
    }
  }

  /// Rename project
  Future<void> _renameProject(mvp.Project project, bool isShared) async {
    if (!project.isOwner(currentUserId)) {
      _showError('Only owner can rename projects');
      return;
    }

    final nameController = TextEditingController(text: project.name);

    // Theme-aware colors
    final theme = ThemeManager.of(context);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Rename Project',
          style: TextStyle(color: theme.textPrimary),
        ),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'New Project Name',
            hintText: 'Enter new name',
            prefixIcon: Icon(Icons.edit),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Project name cannot be empty')),
                );
                return;
              }
              Navigator.pop(context, name);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != project.name) {
      try {
        // 1. Update project name in Firestore
        final updates = {
          'name': newName,
          'updatedAt': DateTime.now(),
        };

        if (isShared) {
          await projectRepo.updateSharedProject(project.id, updates);
        } else {
          await projectRepo.updatePrivateProject(
            currentUserId,
            project.id,
            updates,
          );
        }

        // 2. Update marketplace listing if exists
        await _updateMarketplaceListing(project.id, newName, project.thumbnailBase64);

        setState(() {}); // Refresh list
        _showSuccess('Project renamed to "$newName"');
      } catch (e) {
        _showError('Failed to rename: $e');
      }
    }
  }

  /// Update marketplace listing when project is renamed or thumbnail updated
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

  /// Show project preview with full-size thumbnail
  Future<void> _showProjectPreview(mvp.Project project) async {
    if (project.thumbnailBase64 == null) {
      _showError('No preview available. Please draw something first.');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            // Preview Image
            Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              project.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Image
                    Flexible(
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Image.memory(
                          base64Decode(project.thumbnailBase64!),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    // Footer with info
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildInfoChip(
                            PhosphorIcons.frame_corners,
                            '${project.canvasWidth} × ${project.canvasHeight}',
                          ),
                          _buildInfoChip(
                            PhosphorIcons.calendar,
                            _formatDate(project.updatedAt),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Builder(
      builder: (context) {
        final theme = ThemeManager.of(context);
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: theme.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: theme.textSecondary),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Delete project (owner only)
  Future<void> _deleteProject(mvp.Project project, bool isShared) async {
    if (!project.isOwner(currentUserId)) {
      _showError('Only owner can delete projects');
      return;
    }

    final confirm = await showConfirmationDialog(
      context,
      title: 'Delete Project',
      message:
          'Are you sure you want to delete "${project.name}"? This action cannot be undone.',
      confirmText: 'Delete',
      isDangerous: true,
    );

    if (confirm) {
      try {
        if (isShared) {
          await projectRepo.deleteSharedProject(project.id);
        } else {
          await projectRepo.deletePrivateProject(currentUserId, project.id);
        }
        setState(() {}); // Refresh list
        _showSuccess('Project deleted');
      } catch (e) {
        _showError('Failed to delete: $e');
      }
    }
  }

  /// Share project to public
  Future<void> _shareProject(mvp.Project project) async {
    if (!project.isOwner(currentUserId)) {
      _showError('Only owner can share projects');
      return;
    }

    try {
      await projectRepo.moveToShared(currentUserId, project.id);
      setState(() {}); // Refresh list
      _showSuccess('Project shared');
    } catch (e) {
      _showError('Failed to share: $e');
    }
  }

  /// Unshare project (move back to private)
  Future<void> _unshareProject(mvp.Project project) async {
    if (!project.isOwner(currentUserId)) {
      _showError('Only owner can unshare projects');
      return;
    }

    try {
      await projectRepo.moveToPrivate(currentUserId, project.id);
      setState(() {}); // Refresh list
      _showSuccess('Project moved to private');
    } catch (e) {
      _showError('Failed to unshare: $e');
    }
  }

  /// Share project to marketplace - creates StoreListing and removes from My Projects
  Future<void> _shareToMarketplace(mvp.Project project) async {
    if (!project.isOwner(currentUserId)) {
      _showError('Only owner can share to marketplace');
      return;
    }

    if (project.thumbnailBase64 == null) {
      _showError('Please save the project with artwork first');
      return;
    }

    try {
      // Show dialog to input title, description, and price
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => _ShareToMarketplaceDialog(
          projectName: project.name,
        ),
      );

      if (result == null) return; // User cancelled

      final title = result['title'] as String;
      final description = result['description'] as String?;
      final price = result['price'] as double;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final theme = ThemeManager.of(context);
          
          return AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                Text(
                  'Sharing to marketplace...',
                  style: TextStyle(color: theme.textPrimary),
                ),
              ],
            ),
          );
        },
      );

      // Get owner display name with priority: Firestore > FirebaseAuth > Email > Fallback
      final currentUser = FirebaseAuth.instance.currentUser;
      String ownerName = 'Unknown Creator'; // Final fallback
      
      print('🔍 Fetching owner name for userId: $currentUserId');
      
      // Try to get from Firestore first (most reliable)
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('artifacts')
            .doc(appId)
            .collection('users')
            .doc(currentUserId)
            .get();
        
        print('📄 Firestore user doc exists: ${userDoc.exists}');
        
        if (userDoc.exists) {
          final data = userDoc.data();
          print('📦 Firestore user data: $data');
          
          if (data != null) {
            if (data['displayName'] != null && (data['displayName'] as String).isNotEmpty) {
              ownerName = data['displayName'] as String;
              print('✅ Got displayName from Firestore: "$ownerName"');
            } else if (data['name'] != null && (data['name'] as String).isNotEmpty) {
              // Try 'name' field as alternative
              ownerName = data['name'] as String;
              print('✅ Got name from Firestore: "$ownerName"');
            }
          }
        }
      } catch (e) {
        print('⚠️ Failed to fetch from Firestore: $e');
      }
      
      // If still Unknown Creator, try FirebaseAuth
      if (ownerName == 'Unknown Creator' && currentUser != null) {
        print('🔍 Firestore didn\'t provide name, trying FirebaseAuth...');
        print('👤 FirebaseAuth displayName: "${currentUser.displayName}"');
        print('📧 FirebaseAuth email: "${currentUser.email}"');
        
        if (currentUser.displayName != null && currentUser.displayName!.trim().isNotEmpty) {
          ownerName = currentUser.displayName!.trim();
          print('✅ Got displayName from FirebaseAuth: "$ownerName"');
        } else if (currentUser.email != null) {
          // Extract username from email (before @)
          final emailUsername = currentUser.email!.split('@')[0];
          // Capitalize first letter
          ownerName = emailUsername[0].toUpperCase() + emailUsername.substring(1);
          print('✅ Extracted name from email: "$ownerName"');
        }
      }

      print('📝 Final owner name: "$ownerName"');

      // Create StoreListing in Firestore
      final listingData = {
        'title': title,
        'projectId': project.id,
        'ownerId': currentUserId,
        'ownerName': ownerName,
        'price': price,
        'description': description,
        'thumbnailBase64': project.thumbnailBase64,
        'totalSold': 0,
        'averageRating': 0.0,
        'totalReviews': 0,
        'tags': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      };

      print('📦 Creating marketplace listing for project: ${project.id} by $ownerName');
      
      await FirebaseFirestore.instance
          .collection('artifacts')
          .doc(appId)
          .collection('public')
          .doc('data')
          .collection('store_listings')
          .add(listingData);

      print('✅ Listing created, updating project...');
      
      // Update project to mark as in marketplace
      // Handle both private and shared projects
      DocumentReference projectRef;
      
      if (project.isPublic) {
        // Shared/collaborative project
        print('📂 Updating shared project: ${project.id}');
        projectRef = FirebaseFirestore.instance
            .collection('artifacts')
            .doc(appId)
            .collection('public')
            .doc('data')
            .collection('projects_shared')
            .doc(project.id);
      } else {
        // Private project
        print('📂 Updating private project: ${project.id}');
        projectRef = FirebaseFirestore.instance
            .collection('artifacts')
            .doc(appId)
            .collection('users')
            .doc(currentUserId)
            .collection('projects')
            .doc(project.id);
      }
      
      print('🔍 Checking if project exists at: ${projectRef.path}');
      
      // Check if document exists first
      final projectDoc = await projectRef.get();
      if (!projectDoc.exists) {
        throw Exception('Project not found in Firestore.\nPath: ${projectRef.path}\nProject ID: ${project.id}\nisPublic: ${project.isPublic}');
      }
      
      print('✅ Project found, updating...');
      
      await projectRef.update({
        'isInMarketplace': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Project updated successfully');
      
      Navigator.pop(context); // Close loading

      if (mounted) {
        _showSuccess('Project shared to marketplace successfully!');
        // Refresh the list
        setState(() {});
      }
    } on FirebaseException catch (e) {
      print('❌ Firebase error: ${e.code} - ${e.message}');
      Navigator.pop(context); // Close loading if still open
      _showError('Firebase error: ${e.message}');
    } catch (e, stackTrace) {
      print('❌ Failed to share to marketplace: $e');
      print('Stack trace: $stackTrace');
      Navigator.pop(context); // Close loading if still open
      _showError('Failed to share to marketplace: $e');
    }
  }

  /// Share project artwork as image file (WhatsApp, Instagram, etc)
  Future<void> _shareProjectArtwork(mvp.Project project) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final theme = ThemeManager.of(context);
          
          return AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                Text(
                  'Preparing artwork...',
                  style: TextStyle(color: theme.textPrimary),
                ),
              ],
            ),
          );
        },
      );

      // Get thumbnail image bytes
      if (project.thumbnailBase64 == null) {
        Navigator.pop(context); // Close loading
        _showError('No artwork to share');
        return;
      }

      final Uint8List imageBytes = base64Decode(project.thumbnailBase64!);
      
      // Create temporary file
      final tempDir = await getTemporaryDirectory();
      final fileName = 'muraloka_${project.name}_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      // Close loading
      Navigator.pop(context);

      // Share with text
      final shareText = '🎨 Check out my artwork "${project.name}" created with Muraloka!\n\nMuraloka - Digital Art Made Easy';
      
      final result = await Share.shareXFiles(
        [XFile(filePath, mimeType: 'image/png')],
        subject: 'Muraloka Artwork: ${project.name}',
        text: shareText,
      );

      if (mounted) {
        if (result.status == ShareResultStatus.success) {
          _showSuccess('Artwork shared successfully!');
        }
      }
    } catch (e) {
      Navigator.pop(context); // Close loading if still open
      _showError('Failed to share artwork: $e');
    }
  }

  // ==================== COLLABORATION FEATURES ====================

  /// Show generate/display room code dialog
  Future<void> _showRoomCodeDialog(mvp.Project project) async {
    if (!project.isOwner(currentUserId)) {
      _showError('Only owner can manage room code');
      return;
    }

    String? roomCode = project.roomCode;

    // If no room code, generate one
    if (roomCode == null) {
      try {
        roomCode = await projectRepo.generateRoomCode(
          project.id,
          currentUserId,
          isShared: project.isPublic,
        );
        setState(() {}); // Refresh to show updated room code
      } catch (e) {
        _showError('Failed to generate room code: $e');
        return;
      }
    }

    await showDialog(
      context: context,
      builder: (dialogContext) {
        final theme = ThemeManager.of(dialogContext);
        
        return AlertDialog(
          title: Row(
            children: [
              Icon(PhosphorIcons.users_three, color: theme.primary),
              const SizedBox(width: 12),
              const Text('Room Code'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Share this code with others to collaborate:',
                style: TextStyle(fontSize: 14, color: theme.textSecondary),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.primary, width: 2),
                ),
                child: Center(
                  child: Text(
                    roomCode!,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                      fontFamily: 'monospace',
                      color: theme.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(PhosphorIcons.users, size: 16, color: theme.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    '${project.collaboratorIds.length} collaborator(s)',
                    style: TextStyle(fontSize: 12, color: theme.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                // Copy to clipboard
                await Clipboard.setData(ClipboardData(text: roomCode!));
                _showSuccess('Room code copied to clipboard');
              },
              icon: const Icon(PhosphorIcons.copy),
              label: const Text('Copy Code'),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showCollaboratorsDialog(project);
              },
              icon: const Icon(PhosphorIcons.users_three),
              label: const Text('Manage'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  /// Show dialog requiring user to join via room code
  Future<void> _showRoomCodeRequiredDialog(mvp.Project project) async {
    final theme = ThemeManager.of(context);
    
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(PhosphorIcons.lock_key, color: theme.warning),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Collaboration Mode Active'),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This project is in collaboration mode and can only be accessed using the room code.',
                style: TextStyle(color: theme.textSecondary),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.warning.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(PhosphorIcons.info, color: theme.warning, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'How to access:',
                          style: TextStyle(
                            color: theme.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Go to "My Projects" tab\n'
                      '2. Find this project and tap "Share"\n'
                      '3. Copy the room code\n'
                      '4. Use "Join Collaboration" to enter',
                      style: TextStyle(color: theme.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Room Code: ${project.roomCode}',
                style: TextStyle(
                  color: theme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: project.roomCode!));
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: const Text('Room code copied to clipboard!'),
                      backgroundColor: theme.success,
                    ),
                  );
                }
              },
              icon: const Icon(PhosphorIcons.copy),
              label: const Text('Copy Code'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                // Auto-open join dialog with pre-filled code
                _showJoinRoomDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: theme.surface,
              ),
              child: const Text('Join Now'),
            ),
          ],
        );
      },
    );
  }

  /// Show join room dialog
  Future<void> _showJoinRoomDialog() async {
    final codeController = TextEditingController();

    final roomCode = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final theme = ThemeManager.of(dialogContext);
        
        return AlertDialog(
          title: Row(
            children: [
              Icon(PhosphorIcons.sign_in, color: theme.success),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Join Collaboration'),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter the 6-digit room code:',
                style: TextStyle(fontSize: 14, color: theme.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                labelText: 'Room Code',
                hintText: '000000',
                prefixIcon: const Icon(PhosphorIcons.key),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
              autofocus: true,
            ),
          ],
        ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final code = codeController.text.trim();
                if (code.length == 6) {
                  Navigator.pop(context, code);
                } else {
                  showErrorSnackbar(context, 'Please enter a 6-digit code');
                }
              },
              icon: const Icon(PhosphorIcons.sign_in),
              label: const Text('Join'),
            ),
          ],
        );
      },
    );

    if (roomCode != null && roomCode.isNotEmpty) {
      try {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            final theme = ThemeManager.of(context);
            
            return AlertDialog(
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      'Joining project...',
                      style: TextStyle(color: theme.textPrimary),
                    ),
                  ),
                ],
              ),
            );
          },
        );

        final project = await projectRepo.joinProjectByRoomCode(
          roomCode,
          currentUserId,
        );

        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog

        if (project != null) {
          _showSuccess('Successfully joined: ${project.name}');
          
          // Refresh the projects list
          setState(() {});

          // Navigate to project
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LayerPaintPage(
                projectId: project.id,
                isShared: project.isPublic,
              ),
            ),
          );
        } else {
          _showError('Failed to join: Project not found');
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog
        _showError('Failed to join: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  /// Show collaborators management dialog
  Future<void> _showCollaboratorsDialog(mvp.Project project) async {
    if (!project.isOwner(currentUserId)) {
      _showError('Only owner can manage collaborators');
      return;
    }

    // Fetch current user data for owner display
    final ownerDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();
    final ownerData = ownerDoc.data();
    final ownerName = ownerData?['displayName'] ?? 'You';
    final ownerPhoto = ownerData?['photoURL'];

    await showDialog(
      context: context,
      builder: (dialogContext) {
        final theme = ThemeManager.of(dialogContext);
        
        return AlertDialog(
          title: Row(
            children: [
              Icon(PhosphorIcons.users_three, color: theme.primary),
              const SizedBox(width: 12),
              const Text('Collaborators'),
            ],
          ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Owner info
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.primary,
                  backgroundImage: ownerPhoto != null ? NetworkImage(ownerPhoto) : null,
                  child: ownerPhoto == null 
                    ? Icon(PhosphorIcons.crown, color: theme.surface, size: 20)
                    : null,
                ),
                title: Text(ownerName),
                subtitle: const Text('Owner', style: TextStyle(fontSize: 10)),
                trailing: Chip(
                  label: const Text('Owner', style: TextStyle(fontSize: 10)),
                  backgroundColor: theme.primary,
                  labelStyle: TextStyle(color: theme.surface),
                ),
              ),
              const Divider(),
              // Collaborators list
              if (project.collaboratorIds.isEmpty)
                Builder(
                  builder: (context) {
                    final theme = ThemeManager.of(context);
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'No collaborators yet\nShare the room code to invite others',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.textSecondary),
                        ),
                      ),
                    );
                  },
                )
              else
                ...project.collaboratorIds.map((collaboratorId) {
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(collaboratorId)
                        .get(),
                    builder: (context, snapshot) {
                      // Default values
                      String displayName = 'Loading...';
                      String? photoURL;
                      
                      if (snapshot.connectionState == ConnectionState.done) {
                        if (snapshot.hasData && snapshot.data!.exists) {
                          final userData = snapshot.data!.data() as Map<String, dynamic>?;
                          displayName = userData?['displayName'] ?? 'User ${project.collaboratorIds.indexOf(collaboratorId) + 1}';
                          photoURL = userData?['photoURL'];
                        } else {
                          displayName = 'User ${project.collaboratorIds.indexOf(collaboratorId) + 1}';
                        }
                      }

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[300],
                          backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
                          child: photoURL == null 
                            ? Icon(PhosphorIcons.user, color: Colors.grey[700], size: 20)
                            : null,
                        ),
                        title: Text(displayName),
                        subtitle: Text(collaboratorId, style: const TextStyle(fontSize: 10)),
                        trailing: IconButton(
                          icon: const Icon(PhosphorIcons.x, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showConfirmationDialog(
                              context,
                              title: 'Remove Collaborator',
                              message: 'Are you sure you want to remove this collaborator?',
                              confirmText: 'Remove',
                              isDangerous: true,
                            );

                            if (confirm) {
                              try {
                                await projectRepo.removeCollaborator(
                                  project.id,
                                  collaboratorId,
                                  ownerId: currentUserId,
                                );
                                Navigator.pop(context); // Close dialog
                                setState(() {}); // Refresh
                                _showSuccess('Collaborator removed');
                              } catch (e) {
                                _showError('Failed to remove: $e');
                              }
                            }
                          },
                        ),
                      );
                    },
                  );
                }).toList(),
            ],
          ),
        ),
        actions: [
          if (project.roomCode != null)
            TextButton.icon(
              onPressed: () async {
                final confirm = await showConfirmationDialog(
                  context,
                  title: 'Revoke Room Code',
                  message: 'This will prevent new people from joining.\nExisting collaborators will remain.',
                  confirmText: 'Revoke',
                  isDangerous: true,
                );

                if (confirm) {
                  try {
                    await projectRepo.revokeRoomCode(
                      project.id,
                      currentUserId,
                      isShared: project.isPublic,
                    );
                    Navigator.pop(context);
                    setState(() {});
                    _showSuccess('Room code revoked');
                  } catch (e) {
                    _showError('Failed to revoke: $e');
                  }
                }
              },
              icon: const Icon(PhosphorIcons.prohibit, color: AppColors.error),
              label: const Text('Revoke Code'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showError(String message) {
    showErrorSnackbar(context, message);
  }

  void _showSuccess(String message) {
    showSuccessSnackbar(context, message);
  }

  @override
  Widget build(BuildContext context) {
    // Use ThemeManager from constant.dart
    final theme = ThemeManager.of(context);
    
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.primary,
        foregroundColor: theme.surface,
        elevation: 0,
        title: Text('My Projects', style: TextStyle(color: theme.surface, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.surface),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          // Join Room button in AppBar
          IconButton(
            icon: Icon(PhosphorIcons.sign_in, color: theme.surface),
            tooltip: 'Join Collaboration',
            onPressed: _showJoinRoomDialog,
          ),
        ],
      ),
      body: _buildPrivateProjectsTab(),
      floatingActionButton: ScaleFadeIn(
        child: FloatingActionButton.extended(
          onPressed: _showCreateProjectDialog,
          icon: const Icon(PhosphorIcons.plus),
          label: const Text('New Project'),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildPrivateProjectsTab() {
    return StreamBuilder<List<mvp.Project>>(
      stream: projectRepo.streamPrivateProjects(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CustomLoadingIndicator(
            message: 'Loading your projects...',
          );
        }

        if (snapshot.hasError) {
          return ErrorStateWidget(
            message: snapshot.error.toString(),
            onRetry: () => setState(() {}),
          );
        }

        final projects = snapshot.data ?? [];

        // Filter out projects that are already in marketplace
        // Note: Projects with room code WILL be shown here (My Projects page)
        final filteredProjects = projects
            .where((project) => !project.isInMarketplace)
            .toList();

        if (filteredProjects.isEmpty) {
          return EmptyStateWidget(
            icon: PhosphorIcons.folder_notch_open,
            title: 'No private projects yet',
            subtitle: 'Tap the + button below to create your first project',
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio:
                0.8, // Increased from 0.75 to give more vertical space
          ),
          itemCount: filteredProjects.length,
          itemBuilder: (context, index) {
            final project = filteredProjects[index];
            return AnimatedListItem(
              delay: Duration(milliseconds: 100 * index),
              child: _buildProjectCard(project, isShared: false),
            );
          },
        );
      },
    );
  }

  Widget _buildProjectCard(mvp.Project project, {required bool isShared}) {
    final isOwner = project.isOwner(currentUserId);
    final hasRoomCode = project.roomCode != null && project.roomCode!.isNotEmpty;

    // Use ThemeManager from constant.dart
    final theme = ThemeManager.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // 🔒 SECURITY: If project has room code, force user to join via code
          if (hasRoomCode) {
            _showRoomCodeRequiredDialog(project);
            return;
          }
          
          // Open project in collaboration mode if it has room code
          final bool shouldOpenAsShared = hasRoomCode || isShared;
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LayerPaintPage(
                projectId: project.id, 
                isShared: shouldOpenAsShared,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with aspect ratio
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.surfaceVariant,
                ),
                child: project.thumbnailBase64 != null
                    ? Image.memory(
                        base64Decode(project.thumbnailBase64!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholderIcon(),
                      )
                    : _buildPlaceholderIcon(),
              ),
            ),
            // Info section with better padding - use Expanded to prevent overflow
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0), // Reduced from 10
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Project name
                    Text(
                      project.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        height: 1.1,
                        color: theme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3), // Reduced from 4
                    // Canvas dimensions
                    Row(
                      children: [
                        Icon(
                          PhosphorIcons.frame_corners,
                          size: 12,
                          color: theme.textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${project.canvasWidth} × ${project.canvasHeight}',
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.textSecondary,
                          ),
                        ),
                        const Spacer(), // Push badges to right
                        // Collaboration indicators - wrapped untuk prevent overflow
                        if (project.roomCode != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 3,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: theme.success.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                color: theme.success,
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  PhosphorIcons.key,
                                  size: 8,
                                  color: theme.success,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  project.roomCode!,
                                  style: TextStyle(
                                    fontSize: 7,
                                    fontWeight: FontWeight.bold,
                                    color: theme.success,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (project.collaboratorIds.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 3,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: theme.info.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  PhosphorIcons.users,
                                  size: 8,
                                  color: theme.info,
                                ),
                                const SizedBox(width: 1),
                                Text(
                                  '${project.collaboratorIds.length}',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: theme.info,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Spacer(),
                    // Bottom row: ownership & menu
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5, // Reduced from 6
                            vertical: 2, // Reduced from 3
                          ),
                          decoration: BoxDecoration(
                            color: isOwner 
                                ? theme.info.withOpacity(0.2)
                                : theme.surfaceVariant,
                            borderRadius: BorderRadius.circular(
                              8,
                            ), // Reduced from 10
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isShared
                                    ? PhosphorIcons.users_three
                                    : PhosphorIcons.lock,
                                size: 10, // Reduced from 11
                                color: isOwner
                                    ? theme.info
                                    : theme.textSecondary,
                              ),
                              const SizedBox(width: 2), // Reduced from 3
                              Text(
                                isOwner ? 'Owner' : 'Collaborator',
                                style: TextStyle(
                                  fontSize: 9, // Reduced from 10
                                  fontWeight: FontWeight.w600,
                                  color: isOwner
                                      ? theme.info
                                      : theme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        PopupMenuButton<String>(
                          icon: Icon(
                            PhosphorIcons.dots_three_vertical,
                            size: 16, // Reduced from 18
                            color: theme.textSecondary,
                          ),
                          padding: EdgeInsets.zero,
                          itemBuilder: (context) {                            
                            return [
                              if (isOwner)
                                PopupMenuItem<String>(
                                  value: 'rename',
                                  child: Row(
                                    children: [
                                      Icon(PhosphorIcons.pencil, size: 20, color: theme.textPrimary),
                                      const SizedBox(width: 8),
                                      Text('Rename', style: TextStyle(color: theme.textPrimary)),
                                    ],
                                  ),
                                ),
                              // === COLLABORATION MENU ITEMS ===
                              if (isOwner && project.roomCode == null)
                                PopupMenuItem<String>(
                                  value: 'generate_code',
                                  child: Row(
                                    children: [
                                      Icon(PhosphorIcons.key, size: 20, color: theme.success),
                                      const SizedBox(width: 8),
                                      Text('Generate Room Code', style: TextStyle(color: theme.textPrimary)),
                                    ],
                                  ),
                                ),
                              if (isOwner && project.roomCode != null)
                                PopupMenuItem<String>(
                                  value: 'show_code',
                                  child: Row(
                                    children: [
                                      Icon(PhosphorIcons.qr_code, size: 20, color: theme.success),
                                      const SizedBox(width: 8),
                                      Text('Show Room Code', style: TextStyle(color: theme.textPrimary)),
                                    ],
                                  ),
                                ),
                              if (isOwner && project.collaboratorIds.isNotEmpty)
                                PopupMenuItem<String>(
                                  value: 'manage_collaborators',
                                  child: Row(
                                    children: [
                                      Icon(PhosphorIcons.users_three, size: 20, color: theme.info),
                                      const SizedBox(width: 8),
                                      Text('Manage Collaborators', style: TextStyle(color: theme.textPrimary)),
                                    ],
                                  ),
                                ),
                              // === END COLLABORATION MENU ===
                              if (isOwner && !project.isInMarketplace)
                                PopupMenuItem<String>(
                                  value: 'share_marketplace',
                                  child: Row(
                                    children: [
                                      Icon(PhosphorIcons.storefront, size: 20, color: theme.success),
                                      const SizedBox(width: 8),
                                      Text('Share to Marketplace', style: TextStyle(color: theme.textPrimary)),
                                    ],
                                  ),
                                ),
                              PopupMenuItem<String>(
                                value: 'share_artwork',
                                child: Row(
                                  children: [
                                    Icon(PhosphorIcons.share, size: 20, color: theme.warning),
                                    const SizedBox(width: 8),
                                    Text('Share Artwork', style: TextStyle(color: theme.textPrimary)),
                                  ],
                                ),
                              ),
                              
                              if (isOwner && isShared)
                                PopupMenuItem<String>(
                                  value: 'unshare',
                                  child: Row(
                                    children: [
                                      Icon(PhosphorIcons.lock, color: theme.textPrimary),
                                      const SizedBox(width: 8),
                                      Text('Make Private', style: TextStyle(color: theme.textPrimary)),
                                    ],
                                  ),
                                ),
                              PopupMenuItem<String>(
                                value: 'preview',
                                child: Row(
                                  children: [
                                    Icon(PhosphorIcons.eye, size: 20, color: theme.textPrimary),
                                    const SizedBox(width: 8),
                                    Text('Preview', style: TextStyle(color: theme.textPrimary)),
                                  ],
                                ),
                              ),
                              if (isOwner)
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        PhosphorIcons.trash,
                                        color: theme.error,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Delete',
                                        style: TextStyle(color: theme.error),
                                      ),
                                    ],
                                  ),
                                ),
                            ];
                          },
                          onSelected: (value) {
                            switch (value) {
                              case 'rename':
                                _renameProject(project, isShared);
                                break;
                              case 'generate_code':
                              case 'show_code':
                                _showRoomCodeDialog(project);
                                break;
                              case 'manage_collaborators':
                                _showCollaboratorsDialog(project);
                                break;
                              case 'share_marketplace':
                                _shareToMarketplace(project);
                                break;
                              case 'share_artwork':
                                _shareProjectArtwork(project);
                                break;
                              case 'share':
                                _shareProject(project);
                                break;
                              case 'unshare':
                                _unshareProject(project);
                                break;
                              case 'preview':
                                _showProjectPreview(project);
                                break;
                              case 'delete':
                                _deleteProject(project, isShared);
                                break;
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    // Use ThemeManager from constant.dart
    final theme = ThemeManager.of(context);
    
    return Center(
      child: Icon(PhosphorIcons.image, size: 48, color: theme.textSecondary),
    );
  }
}

/// Dialog for sharing project to marketplace
class _ShareToMarketplaceDialog extends StatefulWidget {
  final String projectName;

  const _ShareToMarketplaceDialog({
    required this.projectName,
  });

  @override
  State<_ShareToMarketplaceDialog> createState() => _ShareToMarketplaceDialogState();
}

class _ShareToMarketplaceDialogState extends State<_ShareToMarketplaceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.projectName; // Default to project name
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Theme-aware colors
    final theme = ThemeManager.of(context);
    
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIcons.storefront, color: theme.success, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Share to Marketplace',
              style: TextStyle(fontSize: 18, color: theme.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
          maxWidth: 500,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fill in the details for your marketplace listing:',
                style: TextStyle(fontSize: 14, color: theme.textSecondary),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  hintText: 'Enter listing title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  if (value.trim().length < 3) {
                    return 'Title must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Describe your artwork',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (IDR) *',
                  hintText: 'e.g., 50000',
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Price is required';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price < 0) {
                    return 'Invalid price';
                  }
                  if (price < 1000) {
                    return 'Minimum price is Rp 1,000';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.warning.withOpacity(0.2),
                  border: Border.all(color: theme.warning),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Wrap(
                  spacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Icon(PhosphorIcons.warning, color: theme.warning, size: 18),
                    Text(
                      'Project will be moved to marketplace.',
                      style: TextStyle(fontSize: 11, color: theme.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: theme.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final result = {
                'title': _titleController.text.trim(),
                'description': _descriptionController.text.trim().isEmpty 
                    ? null 
                    : _descriptionController.text.trim(),
                'price': double.parse(_priceController.text.trim()),
              };
              Navigator.pop(context, result);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.success,
            foregroundColor: Colors.white,
          ),
          child: const Text('Share'),
        ),
      ],
    );
  }
}
