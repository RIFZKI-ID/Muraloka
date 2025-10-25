import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:muraloka/all_code/data_api/canvas_artwork_repository.dart';
import 'package:muraloka/all_code/data_api/project_repository.dart';
import 'package:muraloka/all_code/data_api/store_listing_repository.dart';
import 'package:muraloka/all_code/model/canvas_artwork.dart';
import 'package:muraloka/all_code/model/project.dart' as mvp;
import 'package:muraloka/all_code/model/store_listing.dart';
import 'package:muraloka/constant/constant.dart';

class MyArtworksPage extends StatefulWidget {
  const MyArtworksPage({Key? key}) : super(key: key);

  @override
  State<MyArtworksPage> createState() => _MyArtworksPageState();
}

class _MyArtworksPageState extends State<MyArtworksPage> with SingleTickerProviderStateMixin {
  late final ProjectRepository _projectRepo;
  late final StoreListingRepository _listingRepo;
  late final String currentUserId;
  late TabController _tabController;
  
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser!.uid;
    _projectRepo = ProjectRepository(appId: 'muraloka_v1');
    _listingRepo = StoreListingRepository(appId: 'muraloka_v1');
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() {
      _refreshKey++;
    });
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.secondary1,
        title: const Text('My Artworks'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh artworks',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.all_inclusive), text: 'All'),
            Tab(icon: Icon(Icons.folder), text: 'Projects'),
            Tab(icon: Icon(Icons.store), text: 'Marketplace'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3.0,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllTab(),
          _buildProjectsTab(),
          _buildMarketplaceTab(),
        ],
      ),
    );
  }

  // TAB 1: All Artworks (combined projects + marketplace)
  Widget _buildAllTab() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: StreamBuilder<List<mvp.Project>>(
        key: ValueKey('all_$_refreshKey'),
        stream: _getCombinedProjectsStream(),
        builder: (context, projectSnapshot) {
          return StreamBuilder<List<StoreListing>>(
            stream: _listingRepo.streamActiveListings(),
            builder: (context, listingSnapshot) {
              if (projectSnapshot.connectionState == ConnectionState.waiting ||
                  listingSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading artworks...'),
                    ],
                  ),
                );
              }

              if (projectSnapshot.hasError || listingSnapshot.hasError) {
                return _buildErrorView(
                  projectSnapshot.error ?? listingSnapshot.error,
                );
              }

              final projects = projectSnapshot.data ?? [];
              final listings = (listingSnapshot.data ?? [])
                  .where((l) => l.ownerId == currentUserId)
                  .toList();

              if (projects.isEmpty && listings.isEmpty) {
                return _buildEmptyView();
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: projects.length + listings.length,
                itemBuilder: (context, index) {
                  if (index < projects.length) {
                    return ProjectCard(
                      project: projects[index],
                      onTap: () => _openProject(projects[index]),
                      onDelete: () => _deleteProject(projects[index]),
                    );
                  } else {
                    final listing = listings[index - projects.length];
                    return MarketplaceCard(
                      listing: listing,
                      onTap: () => _viewListing(listing),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  // TAB 2: Projects Only
  Widget _buildProjectsTab() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: StreamBuilder<List<mvp.Project>>(
        key: ValueKey('projects_$_refreshKey'),
        stream: _getCombinedProjectsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorView(snapshot.error);
          }

          final projects = snapshot.data ?? [];

          if (projects.isEmpty) {
            return _buildEmptyView(message: 'No projects yet');
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              return ProjectCard(
                project: projects[index],
                onTap: () => _openProject(projects[index]),
                onDelete: () => _deleteProject(projects[index]),
              );
            },
          );
        },
      ),
    );
  }

  // TAB 3: Marketplace Listings Only
  Widget _buildMarketplaceTab() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: StreamBuilder<List<StoreListing>>(
        key: ValueKey('marketplace_$_refreshKey'),
        stream: _listingRepo.streamActiveListings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorView(snapshot.error);
          }

          final listings = (snapshot.data ?? [])
              .where((l) => l.ownerId == currentUserId)
              .toList();

          if (listings.isEmpty) {
            return _buildEmptyView(
              message: 'No marketplace listings yet',
              icon: Icons.store,
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: listings.length,
            itemBuilder: (context, index) {
              return MarketplaceCard(
                listing: listings[index],
                onTap: () => _viewListing(listings[index]),
              );
            },
          );
        },
      ),
    );
  }

  // Helper: Combined stream of private + shared projects for current user
  Stream<List<mvp.Project>> _getCombinedProjectsStream() {
    final privateStream = _projectRepo.streamPrivateProjects(currentUserId);
    final collaborativeStream = _projectRepo.streamCollaborativeProjects(currentUserId);

    return privateStream.asyncExpand((privateProjects) async* {
      await for (final sharedProjects in collaborativeStream) {
        // Combine and deduplicate by ID
        final combined = <String, mvp.Project>{};
        for (final project in privateProjects) {
          combined[project.id] = project;
        }
        for (final project in sharedProjects) {
          combined[project.id] = project;
        }
        
        // Sort by updatedAt descending
        final sorted = combined.values.toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        
        yield sorted;
      }
    });
  }

  Widget _buildEmptyView({String? message, IconData? icon}) {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height - 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon ?? Icons.art_track, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 24),
                Text(
                  message ?? 'No artworks yet',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first canvas masterpiece!',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Start Creating'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(Object? error) {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height - 200,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load artworks',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$error',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _refreshData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openProject(mvp.Project project) {
    context.push(
      '/paint',
      extra: {
        'projectId': project.id,
        'isShared': project.isPublic,
      },
    );
  }

  Future<void> _deleteProject(mvp.Project project) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text('Are you sure you want to delete "${project.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        if (project.isPublic) {
          await _projectRepo.deleteSharedProject(project.id);
        } else {
          await _projectRepo.deletePrivateProject(currentUserId, project.id);
        }
        
        // Refresh data to reload streams
        await _refreshData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Project deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _viewListing(StoreListing listing) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(listing.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (listing.thumbnailBase64 != null)
                Image.memory(
                  base64Decode(listing.thumbnailBase64!),
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              const SizedBox(height: 16),
              Text('Price: Rp ${listing.price.toStringAsFixed(0)}'),
              const SizedBox(height: 8),
              Text(listing.description ?? 'No description'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// ============== PROJECT CARD ==============
class ProjectCard extends StatelessWidget {
  final mvp.Project project;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ProjectCard({
    Key? key,
    required this.project,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Uint8List? thumbnailBytes;
    if (project.thumbnailBase64 != null && project.thumbnailBase64!.isNotEmpty) {
      try {
        thumbnailBytes = base64Decode(project.thumbnailBase64!);
      } catch (e) {
        print('Error decoding thumbnail: $e');
      }
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: thumbnailBytes != null
                  ? Image.memory(
                      thumbnailBytes,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image, size: 48),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 48),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        project.isPublic ? Icons.public : Icons.lock,
                        size: 12,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          project.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${project.canvasWidth}x${project.canvasHeight}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  Text(
                    _formatDate(project.updatedAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete, size: 18),
                  onPressed: onDelete,
                  color: Colors.red,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// ============== MARKETPLACE CARD ==============
class MarketplaceCard extends StatelessWidget {
  final StoreListing listing;
  final VoidCallback onTap;

  const MarketplaceCard({
    Key? key,
    required this.listing,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Uint8List? thumbnailBytes;
    if (listing.thumbnailBase64 != null && listing.thumbnailBase64!.isNotEmpty) {
      try {
        thumbnailBytes = base64Decode(listing.thumbnailBase64!);
      } catch (e) {
        print('Error decoding thumbnail: $e');
      }
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  thumbnailBytes != null
                      ? Image.memory(
                          thumbnailBytes,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image, size: 48),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.store, size: 48),
                        ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Rp ${listing.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.store, size: 12, color: Colors.orange),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          listing.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    listing.tags.isEmpty ? 'Artwork' : listing.tags.first,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ArtworkCard extends StatelessWidget {
  final CanvasArtwork artwork;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const ArtworkCard({
    Key? key,
    required this.artwork,
    required this.onDelete,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Uint8List? imageBytes;
    try {
      imageBytes = base64Decode(artwork.imageDataBase64);
    } catch (e) {
      print('Error decoding image: $e');
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: imageBytes != null
                  ? Image.memory(
                      imageBytes,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image, size: 48),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 48),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artwork.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(artwork.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: onDelete,
                  color: Colors.red,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class ArtworkDetailDialog extends StatefulWidget {
  final CanvasArtwork artwork;

  const ArtworkDetailDialog({Key? key, required this.artwork})
      : super(key: key);

  @override
  State<ArtworkDetailDialog> createState() => _ArtworkDetailDialogState();
}

class _ArtworkDetailDialogState extends State<ArtworkDetailDialog> {
  late TextEditingController _titleController;
  final CanvasArtworkRepository _repository = CanvasArtworkRepository();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.artwork.title);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Uint8List? imageBytes;
    try {
      imageBytes = base64Decode(widget.artwork.imageDataBase64);
    } catch (e) {
      print('Error decoding image: $e');
    }

    return AlertDialog(
      title: _isEditing
          ? TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Enter title',
                border: OutlineInputBorder(),
              ),
            )
          : Row(
              children: [
                Expanded(child: Text(widget.artwork.title)),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => setState(() => _isEditing = true),
                ),
              ],
            ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageBytes != null)
              InteractiveViewer(
                maxScale: 5.0,
                child: Image.memory(imageBytes),
              )
            else
              Container(
                height: 200,
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.broken_image, size: 48),
                ),
              ),
            const SizedBox(height: 16),
            _buildInfoRow('Created', _formatDateTime(widget.artwork.createdAt)),
            _buildInfoRow('Updated', _formatDateTime(widget.artwork.updatedAt)),
            if (widget.artwork.metadata != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Size', _formatBytes(widget.artwork.metadata!['size'] ?? 0)),
              _buildInfoRow('Format', widget.artwork.metadata!['format'] ?? 'N/A'),
            ],
          ],
        ),
      ),
      actions: [
        if (_isEditing) ...[
          TextButton(
            onPressed: () => setState(() => _isEditing = false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _saveTitle,
            child: const Text('Save'),
          ),
        ] else ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _saveTitle() async {
    final newTitle = _titleController.text.trim();
    if (newTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Title cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await _repository.updateTitle(widget.artwork.id, newTitle);
    if (mounted) {
      if (success) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Title updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update title'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
