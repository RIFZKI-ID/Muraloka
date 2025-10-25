import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../model/store_listing.dart';
import '../model/project.dart' as mvp;
import '../model/layer.dart' as mvp;
import '../data_api/store_listing_repository.dart';
import '../data_api/project_repository.dart';
import '../data_api/layer_repository.dart';
import '../widgets/ui_helpers.dart';
import '../widgets/animated_widgets.dart';
import '../../presentation/pages/qris_webview_page.dart';

/// Marketplace page untuk menjual dan membeli karya seni
class MarketplacePage extends StatefulWidget {
  const MarketplacePage({Key? key}) : super(key: key);

  @override
  _MarketplacePageState createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late StoreListingRepository listingRepo;
  late ProjectRepository projectRepo;

  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final String appId = 'muraloka_v1';

  // Search & Filter
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  String selectedFilter = 'all'; // all, popular, top-rated, newest

  // Refresh key untuk force rebuild stream
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    listingRepo = StoreListingRepository(appId: appId);
    projectRepo = ProjectRepository(appId: appId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() {
      _refreshKey++;
    });
    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// Show publish to store dialog (owner only)
  Future<void> _showPublishDialog() async {
    // Get user's shared projects that are not yet published
    final projects = await projectRepo.streamSharedProjects().first;
    final userProjects = projects
        .where((p) => p.isOwner(currentUserId))
        .toList();

    if (userProjects.isEmpty) {
      _showError('You need to create and share a project first');
      return;
    }

    mvp.Project? selectedProject;
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController(text: '0');
    final tagsController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Publish to Store'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Project:'),
                DropdownButton<mvp.Project>(
                  isExpanded: true,
                  value: selectedProject,
                  hint: const Text('Choose a project'),
                  items: userProjects.map((project) {
                    return DropdownMenuItem(
                      value: project,
                      child: Text(project.name),
                    );
                  }).toList(),
                  onChanged: (project) {
                    setDialogState(() {
                      selectedProject = project;
                      titleController.text = project?.name ?? '';
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Listing Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price (IDR)',
                    border: OutlineInputBorder(),
                    prefixText: 'Rp ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tagsController,
                  decoration: const InputDecoration(
                    labelText: 'Tags (comma-separated)',
                    border: OutlineInputBorder(),
                    hintText: 'landscape, digital, abstract',
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
              onPressed: selectedProject == null
                  ? null
                  : () {
                      Navigator.pop(context, {
                        'project': selectedProject,
                        'title': titleController.text,
                        'description': descController.text,
                        'price': double.tryParse(priceController.text) ?? 0.0,
                        'tags': tagsController.text
                            .split(',')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList(),
                      });
                    },
              child: const Text('Publish'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      _publishToStore(result);
    }
  }

  /// Publish project to store
  Future<void> _publishToStore(Map<String, dynamic> data) async {
    try {
      final mvp.Project project = data['project'];

      print('Publishing project: ${project.name} (ID: ${project.id})');
      print('Initial thumbnail: ${project.thumbnailBase64?.substring(0, 50) ?? "null"}...');

      // Generate thumbnail if project doesn't have one
      String? thumbnailBase64 = project.thumbnailBase64;
      if (thumbnailBase64 == null || thumbnailBase64.isEmpty) {
        print('Generating thumbnail for project...');
        thumbnailBase64 = await _generateProjectThumbnail(project);
        print('Generated thumbnail: ${thumbnailBase64?.substring(0, 50) ?? "null"}...');
      }

      if (thumbnailBase64 == null || thumbnailBase64.isEmpty) {
        _showError('Cannot publish: No thumbnail available. Please draw something first.');
        return;
      }

      final listing = StoreListing(
        id: '',
        title: data['title'],
        projectId: project.id,
        ownerId: currentUserId,
        price: data['price'],
        description: data['description'],
        thumbnailBase64: thumbnailBase64,
        tags: data['tags'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await listingRepo.createListing(listing);
      print('Listing created successfully with thumbnail length: ${thumbnailBase64.length}');
      _showSuccess('Published to store successfully!');
      setState(() {}); // Refresh listings
    } catch (e) {
      print('Error publishing to store: $e');
      _showError('Failed to publish: $e');
    }
  }

  /// Generate thumbnail from project layers
  Future<String?> _generateProjectThumbnail(mvp.Project project) async {
    try {
      print('Generating thumbnail for project: ${project.id}');
      
      // Get all layers for the project
      final layerRepo = LayerRepository(appId: appId);
      final layers = await layerRepo.streamSharedLayers(project.id).first;

      print('Found ${layers.length} layers');
      
      if (layers.isEmpty) {
        print('No layers to render');
        return null; // No layers to render
      }

      // Create a picture recorder to draw all layers
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = Size(
        project.canvasWidth.toDouble(),
        project.canvasHeight.toDouble(),
      );

      print('Canvas size: ${size.width}x${size.height}');

      // Draw white background
      final paint = Paint()..color = Colors.white;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

      // Draw all visible layers (sorted by zIndex)
      final sortedLayers = List<mvp.Layer>.from(layers)
        ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

      int strokeCount = 0;
      for (final layer in sortedLayers) {
        if (!layer.isVisible) continue;

        print('Drawing layer ${layer.name} with ${layer.strokes.length} strokes');

        // Draw each stroke in the layer
        for (final strokeData in layer.strokes) {
          // Strokes are stored as Map<String, dynamic>
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
          final strokeWidth =
              (strokeData['strokeWidth'] as num?)?.toDouble() ?? 2.0;

          final strokePaint = Paint()
            ..color = Color(color).withOpacity(layer.opacity)
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..style = PaintingStyle.stroke;

          canvas.drawPath(path, strokePaint);
          strokeCount++;
        }
      }

      print('Drew $strokeCount strokes total');

      // Convert to image (create thumbnail at 400x300 for smaller file size)
      final picture = recorder.endRecording();
      final thumbnailWidth = 400;
      final thumbnailHeight = (400 * size.height / size.width).toInt();
      
      print('Creating thumbnail: ${thumbnailWidth}x$thumbnailHeight');
      
      final image = await picture.toImage(thumbnailWidth, thumbnailHeight);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        print('Failed to convert image to bytes');
        return null;
      }

      // Convert to base64
      final bytes = byteData.buffer.asUint8List();
      final base64String = base64Encode(bytes);
      
      print('Thumbnail generated: ${base64String.length} bytes');
      return base64String;
    } catch (e) {
      print('Failed to generate thumbnail: $e');
      return null;
    }
  }

  /// Show listing details
  void _showListingDetails(StoreListing listing) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thumbnail with fullscreen preview on tap
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () {
                    // Show fullscreen image preview
                    if (listing.thumbnailBase64 != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => _FullScreenImageViewer(
                            imageBytes: base64Decode(listing.thumbnailBase64!),
                            title: listing.title,
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    color: Colors.grey[200],
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        listing.thumbnailBase64 != null
                            ? Image.memory(
                                base64Decode(listing.thumbnailBase64!),
                                fit: BoxFit.cover,
                              )
                            : const Icon(PhosphorIcons.image, size: 64),
                        // Fullscreen icon overlay
                        if (listing.thumbnailBase64 != null)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                PhosphorIcons.arrows_out,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              // Details
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Rp ${listing.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(
                            PhosphorIcons.star_fill,
                            color: Colors.amber,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${listing.averageRating.toStringAsFixed(1)} (${listing.totalReviews} reviews)',
                          ),
                          const SizedBox(width: 16),
                          const Icon(PhosphorIcons.shopping_cart, size: 20),
                          const SizedBox(width: 4),
                          Text('${listing.totalSold} sold'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (listing.description != null &&
                          listing.description!.isNotEmpty) ...[
                        const Text(
                          'Description:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(listing.description!),
                        const SizedBox(height: 16),
                      ],
                      if (listing.tags.isNotEmpty) ...[
                        const Text(
                          'Tags:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: listing.tags.map((tag) {
                            return Chip(
                              label: Text(tag),
                              backgroundColor: Colors.blue[100],
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Actions
              Padding(
                padding: const EdgeInsets.all(16),
                child: listing.isOwner(currentUserId)
                    ? Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _toggleListingStatus(listing);
                              },
                              icon: Icon(
                                listing.isActive
                                    ? PhosphorIcons.eye_slash
                                    : PhosphorIcons.eye,
                              ),
                              label: Text(
                                listing.isActive ? 'Deactivate' : 'Activate',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _deleteListing(listing);
                              },
                              icon: const Icon(PhosphorIcons.trash),
                              label: const Text('Delete'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      )
                    : ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _purchaseListing(listing);
                        },
                        icon: const Icon(PhosphorIcons.shopping_cart),
                        label: const Text('Buy Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Purchase listing (QRIS Payment Integration - Simplified)
  Future<void> _purchaseListing(StoreListing listing) async {
    try {
      // Navigate to QRIS WebView (Simple Display)
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => QRISWebViewPage(
            listingTitle: listing.title,
            price: listing.price,
          ),
        ),
      );

      if (result == true) {
        // Payment completed (user clicked "Selesai")
        _showSuccess('Pembayaran berhasil! Silakan cek "My Projects" untuk mengakses project.');
        
        // TODO: Backend integration
        // - Verify payment status dari payment gateway
        // - Transfer ownership project ke buyer
        // - Kirim notifikasi ke seller dan buyer
        // - Update listing status (sold out jika one-time purchase)
        
        // Refresh data
        await _refreshData();
      }
    } catch (e) {
      _showError('Gagal membuka pembayaran: $e');
    }
  }

  /// Toggle listing active status
  Future<void> _toggleListingStatus(StoreListing listing) async {
    try {
      await listingRepo.toggleListingStatus(listing.id, !listing.isActive);
      _showSuccess('Listing ${listing.isActive ? 'deactivated' : 'activated'}');
      setState(() {});
    } catch (e) {
      _showError('Failed to update: $e');
    }
  }

  /// Delete listing
  Future<void> _deleteListing(StoreListing listing) async {
    final confirm = await showConfirmationDialog(
      context,
      title: 'Delete Listing',
      message:
          'Are you sure you want to delete "${listing.title}" from the marketplace? This action cannot be undone.',
      confirmText: 'Delete',
      isDangerous: true,
    );

    if (confirm) {
      try {
        await listingRepo.deleteListing(listing.id);
        _showSuccess('Listing deleted');
        setState(() {});
      } catch (e) {
        _showError('Failed to delete: $e');
      }
    }
  }

  void _showError(String message) {
    showErrorSnackbar(context, message);
  }

  void _showSuccess(String message) {
    showSuccessSnackbar(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white, // Warna text saat dipilih (putih)
          unselectedLabelColor: Colors.white70, // Warna text saat tidak dipilih (putih transparan)
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold, // Bold saat dipilih
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal, // Normal saat tidak dipilih
          ),
          indicatorColor: Colors.white, // Garis indikator putih
          indicatorWeight: 3.0, // Garis indikator lebih tebal
          tabs: const [
            Tab(text: 'Browse'),
            Tab(text: 'My Listings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildBrowseTab(), _buildMyListingsTab()],
      ),
      floatingActionButton: ScaleFadeIn(
        child: FloatingActionButton.extended(
          onPressed: _showPublishDialog,
          icon: const Icon(PhosphorIcons.plus),
          label: const Text('Publish'),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildBrowseTab() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search artworks...',
              prefixIcon: const Icon(PhosphorIcons.magnifying_glass),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) {
              setState(() => searchQuery = value);
            },
          ),
        ),
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildFilterChip('All', 'all'),
              _buildFilterChip('Popular', 'popular'),
              _buildFilterChip('Top Rated', 'top-rated'),
              _buildFilterChip('Newest', 'newest'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Listings grid
        Expanded(child: _buildListingsGrid()),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => selectedFilter = value);
        },
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.3),
      ),
    );
  }

  Widget _buildListingsGrid() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: StreamBuilder<List<StoreListing>>(
        key: ValueKey('browse_$_refreshKey'),
        stream: listingRepo.streamActiveListings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CustomLoadingIndicator(
              message: 'Loading marketplace listings...',
            );
          }

          if (snapshot.hasError) {
            return ListView(
              children: [
                SizedBox(
                  height: 400,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(PhosphorIcons.warning_circle,
                              size: 64, color: Colors.orange),
                          const SizedBox(height: 16),
                          const Text(
                            'Failed to load listings',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _refreshData,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '💡 Pull down to refresh\n• Check internet connection\n• Deploy Firestore indexes',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          var listings = snapshot.data ?? [];

          // Apply search filter
          if (searchQuery.isNotEmpty) {
            listings = listings
                .where(
                  (l) =>
                      l.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
                      l.tags.any(
                        (t) =>
                            t.toLowerCase().contains(searchQuery.toLowerCase()),
                      ),
                )
                .toList();
          }

          // Apply sort filter
          switch (selectedFilter) {
            case 'popular':
              listings.sort((a, b) => b.totalSold.compareTo(a.totalSold));
              break;
            case 'top-rated':
              listings.sort((a, b) => b.averageRating.compareTo(a.averageRating));
              break;
            case 'newest':
              listings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              break;
          }

          if (listings.isEmpty) {
            return ListView(
              children: [
                SizedBox(
                  height: 400,
                  child: EmptyStateWidget(
                    icon: PhosphorIcons.storefront,
                    title: searchQuery.isNotEmpty
                        ? 'No listings found'
                        : 'No listings available yet',
                    subtitle: searchQuery.isNotEmpty
                        ? 'Try a different search term'
                        : 'Be the first to publish your artwork!',
                  ),
                ),
              ],
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.7,
            ),
            itemCount: listings.length,
            itemBuilder: (context, index) {
              return AnimatedListItem(
                delay: Duration(milliseconds: 80 * index),
                child: _buildListingCard(listings[index]),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMyListingsTab() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: StreamBuilder<List<StoreListing>>(
        key: ValueKey('mylisting_$_refreshKey'),
        stream: listingRepo.streamListingsByOwner(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CustomLoadingIndicator(
              message: 'Loading your listings...',
            );
          }

          if (snapshot.hasError) {
            return ListView(
              children: [
                SizedBox(
                  height: 400,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(PhosphorIcons.warning_circle,
                              size: 64, color: Colors.orange),
                          const SizedBox(height: 16),
                          const Text(
                            'Failed to load your listings',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _refreshData,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          final listings = snapshot.data ?? [];

          if (listings.isEmpty) {
            return ListView(
              children: [
                SizedBox(
                  height: 400,
                  child: EmptyStateWidget(
                    icon: PhosphorIcons.storefront,
                    title: 'You haven\'t published any listings yet',
                    subtitle: 'Share your artwork with the world and start earning!',
                    action: ElevatedButton.icon(
                      onPressed: _showPublishDialog,
                      icon: const Icon(PhosphorIcons.plus),
                      label: const Text('Publish Your First Listing'),
                    ),
                  ),
                ),
              ],
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.7,
            ),
            itemCount: listings.length,
            itemBuilder: (context, index) {
              return AnimatedListItem(
                delay: Duration(milliseconds: 80 * index),
                child: _buildListingCard(listings[index], showStatus: true),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildListingCard(StoreListing listing, {bool showStatus = false}) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showListingDetails(listing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: Colors.grey[200],
                    child: listing.thumbnailBase64 != null
                        ? Image.memory(
                            base64Decode(listing.thumbnailBase64!),
                            fit: BoxFit.cover,
                          )
                        : const Icon(PhosphorIcons.image, size: 48),
                  ),
                  if (showStatus && !listing.isActive)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Text(
                          'INACTIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      'Rp ${listing.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          PhosphorIcons.star_fill,
                          size: 12,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${listing.averageRating.toStringAsFixed(1)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${listing.totalSold} sold',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
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
}

/// Full screen image viewer with zoom and pan
class _FullScreenImageViewer extends StatefulWidget {
  final Uint8List imageBytes;
  final String title;

  const _FullScreenImageViewer({
    required this.imageBytes,
    required this.title,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  final TransformationController _transformationController = TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(PhosphorIcons.magnifying_glass_minus),
            onPressed: _resetZoom,
            tooltip: 'Reset Zoom',
          ),
        ],
      ),
      body: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: Image.memory(
            widget.imageBytes,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
