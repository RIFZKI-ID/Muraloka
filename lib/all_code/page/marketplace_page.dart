import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:muraloka/constant/constant.dart';
import 'dart:convert';
import 'dart:typed_data';

import '../model/store_listing.dart';
import '../data_api/store_listing_repository.dart';
import '../data_api/project_repository.dart';
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

  /// Show listing details
  void _showListingDetails(StoreListing listing) {
    // Use ThemeManager
    final theme = ThemeManager.of(context);

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
                color: theme.surfaceVariant,
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
                      color: AppColors.semiBlack,
                      borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                      PhosphorIcons.arrows_out,
                      color: theme.surface,
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                  'Rp ${listing.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 20,
                    color: theme.success,
                    fontWeight: FontWeight.bold,
                  ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                  children: [
                    const Icon(
                    PhosphorIcons.star_fill,
                    color: AppColors.amber,
                    size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                    '${listing.averageRating.toStringAsFixed(1)} (${listing.totalReviews} reviews)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textSecondary,
                      fontSize: 12,
                    ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                    PhosphorIcons.shopping_cart,
                    size: 20,
                    color: theme.textPrimary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                    '${listing.totalSold} sold',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textSecondary,
                      fontSize: 12,
                    ),
                    ),
                  ],
                  ),
                  const SizedBox(height: 12),
                  // Creator info
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.textTertiary.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          PhosphorIcons.user_circle,
                          size: 18,
                          color: theme.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Created by: ',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTertiary,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            listing.ownerName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (listing.description != null &&
                    listing.description!.isNotEmpty) ...[
                  Text(
                    'Description:',
                    style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    listing.description!,
                    style: TextStyle(color: theme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ],
                  if (listing.tags.isNotEmpty) ...[
                  Text(
                    'Tags:',
                    style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: listing.tags.map((tag) {
                    return Chip(
                      label: Text(
                      tag,
                      style: TextStyle(color: theme.textPrimary),
                      ),
                      backgroundColor: theme.surfaceVariant,
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
                    child: SizedBox(
                      height: 48,
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
                      style: OutlinedButton.styleFrom(
                        textStyle: const TextStyle(fontSize: 16),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      ),
                    ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteListing(listing);
                      },
                      icon: const Icon(PhosphorIcons.trash),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.error,
                        textStyle: const TextStyle(fontSize: 16),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      ),
                    ),
                    ),
                  ],
                  )
                : SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                    Navigator.pop(context);
                    _purchaseListing(listing);
                    },
                    icon: const Icon(PhosphorIcons.shopping_cart),
                    label: const Text('Buy Now'),
                    style: ElevatedButton.styleFrom(
                    backgroundColor: theme.success,
                    textStyle: const TextStyle(fontSize: 16),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
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
            // image: Image.memory(
            //   base64Decode(listing.thumbnailBase64!),
            // ),
          ),
        ),
      );

      if (result == true) {
        // Payment completed (user clicked "Selesai")
        _showSuccess(
          'Pembayaran berhasil! Silakan cek "My Projects" untuk mengakses project.',
        );

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
    // Use ThemeManager from constant.dart
    final theme = ThemeManager.of(context);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.primary,
        foregroundColor: theme.surface,
        elevation: 0,
        title: Text(
          'Marketplace',
          style: TextStyle(color: theme.surface, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.surface),
          onPressed: () => context.go('/home'),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.surface,
          unselectedLabelColor: theme.surface.withOpacity(0.7),
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
          indicatorColor: theme.surface,
          indicatorWeight: 3.0,
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
    );
  }

  Widget _buildBrowseTab() {
    // Use ThemeManager
    final theme = ThemeManager.of(context);

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search artworks...',
              hintStyle: TextStyle(color: theme.textSecondary),
              prefixIcon: Icon(
                PhosphorIcons.magnifying_glass,
                color: theme.textSecondary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: theme.surfaceVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: theme.surfaceVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: theme.primary),
              ),
              filled: true,
              fillColor: theme.surfaceVariant,
            ),
            style: TextStyle(color: theme.textPrimary),
            cursorColor: theme.primary,
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
            final bool isDark = Theme.of(context).brightness == Brightness.dark;
            final Color textPrimaryColor = isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary;
            final Color textTertiaryColor = isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextTertiary;
            final Color warningColor = isDark
                ? AppColors.darkWarning
                : AppColors.lightWarning;

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
                          Icon(
                            PhosphorIcons.warning_circle,
                            size: 64,
                            color: warningColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load listings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: textTertiaryColor),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _refreshData,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '💡 Pull down to refresh\n• Check internet connection\n• Deploy Firestore indexes',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: textTertiaryColor,
                            ),
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
                      l.title.toLowerCase().contains(
                        searchQuery.toLowerCase(),
                      ) ||
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
              listings.sort(
                (a, b) => b.averageRating.compareTo(a.averageRating),
              );
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
            final bool isDark = Theme.of(context).brightness == Brightness.dark;
            final Color textPrimaryColor = isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary;
            final Color textTertiaryColor = isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextTertiary;
            final Color warningColor = isDark
                ? AppColors.darkWarning
                : AppColors.lightWarning;

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
                          Icon(
                            PhosphorIcons.warning_circle,
                            size: 64,
                            color: warningColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load your listings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: textTertiaryColor),
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
                    subtitle:
                        'Share your artwork with the world and start earning!',
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
    return Builder(
      builder: (context) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        final Color textTertiaryColor = isDark
            ? AppColors.darkTextSecondary
            : AppColors.lightTextTertiary;
        final Color successColor = isDark
            ? AppColors.darkSuccess
            : AppColors.success;
        final Color surfaceColor = isDark
            ? AppColors.darkSurface
            : AppColors.lightSurface;

        return Card(
          clipBehavior: Clip.antiAlias,
          elevation: 6,
          shadowColor: isDark ? AppColors.darkShadow : AppColors.lightShadow,
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceVariant
                              : AppColors.lightSurfaceVariant,
                        ),
                        child: listing.thumbnailBase64 != null
                            ? Image.memory(
                                base64Decode(listing.thumbnailBase64!),
                                fit: BoxFit.cover,
                              )
                            : const Icon(PhosphorIcons.image, size: 64),
                      ),
                      if (showStatus && !listing.isActive)
                        Container(
                          color: AppColors.semiBlack,
                          child: Center(
                            child: Text(
                              'INACTIVE',
                              style: TextStyle(
                                color: surfaceColor,
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          fit: FlexFit.tight,
                          child: Text(
                            listing.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rp ${listing.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: successColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              PhosphorIcons.star_fill,
                              size: 12,
                              color: AppColors.amber,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                              '${listing.averageRating.toStringAsFixed(1)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: ThemeManager.of(context).textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '${listing.totalSold} sold',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: textTertiaryColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Creator name
                        Row(
                          children: [
                            Icon(
                              PhosphorIcons.user,
                              size: 11,
                              color: textTertiaryColor,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                listing.ownerName,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: textTertiaryColor,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
      },
    );
  }
}

/// Full screen image viewer with zoom and pan
class _FullScreenImageViewer extends StatefulWidget {
  final Uint8List imageBytes;
  final String title;

  const _FullScreenImageViewer({required this.imageBytes, required this.title});

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  final TransformationController _transformationController =
      TransformationController();

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
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppColors.darkSurface,
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
          child: Image.memory(widget.imageBytes, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
