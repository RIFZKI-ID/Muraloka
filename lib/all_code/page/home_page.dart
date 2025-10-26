import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:muraloka/all_code/model/project.dart';
import 'package:muraloka/all_code/state/home_cubit/home_cubit.dart';
import 'package:muraloka/all_code/state/home_cubit/home_state.dart';
import 'package:muraloka/all_code/providers/theme_provider.dart';
import 'package:muraloka/constant/constant.dart';
import 'package:muraloka/constant/name_router.dart'; // Digunakan untuk navigasi

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Use ThemeManager from constant.dart
    final theme = ThemeManager.of(context);
    final cubit = context.read<HomeCubit>();

    // Panggil fetchData hanya sekali saat build pertama (atau HomeInitial)
    if (cubit.state is HomeInitial) {
      cubit.fetchData();
    }

    return Scaffold(
      // Dark mode aware background
      backgroundColor: theme.background,
      // AppBar dengan primary color (biru)
      appBar: AppBar(
        backgroundColor: theme.primary,
        foregroundColor: theme.surface,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: theme.surface),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          'Muraloka',
          style: TextStyle(
            color: theme.surface,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Dark Mode Toggle
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) => IconButton(
              icon: Icon(
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: theme.surface,
              ),
              tooltip: themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
              onPressed: () => themeProvider.toggleTheme(),
            ),
          ),
          IconButton(
            icon: Icon(Icons.search, color: theme.surface),
            onPressed: () {
              // Aksi pencarian
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      // Drawer tetap menggunakan warna primary
      drawer: _buildDrawer(context, theme),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading || state is HomeInitial) {
            return Center(
              child: CircularProgressIndicator(color: theme.primary),
            );
          }
          if (state is HomeFailure) {
            return Center(
              child: Text(
                'Error: ${state.message}',
                style: TextStyle(color: theme.textPrimary),
              ),
            );
          }

          if (state is HomeLoaded) {
            // Check if all data is empty
            final hasResumeProjects = state.resumeProjects.isNotEmpty;
            final hasPopularProjects = state.popularProjects.isNotEmpty;
            final hasAnyData = hasResumeProjects || hasPopularProjects;

            if (!hasAnyData) {
              // Show empty state
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.art_track,
                      size: 80,
                      color: theme.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome to Muraloka!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start creating your first artwork',
                      style: TextStyle(fontSize: 16, color: theme.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/projects'),
                      icon: const Icon(Icons.add),
                      label: Text(
                        'Create New Project',
                        style: TextStyle(color: theme.surface),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: theme.surface,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Resume your art - only show if has data
                  if (hasResumeProjects)
                    _buildSection(
                      context,
                      title: 'Resume your art',
                      items: state.resumeProjects,
                      theme: theme,
                      bodyTextColor: theme.textPrimary,
                      cardBackgroundColor: theme.surface,
                      subtitleColor: theme.textSecondary,
                    ),
                  if (hasResumeProjects) SizedBox(height: 8),

                  // 2. Popular Art - only show if has data
                  if (hasPopularProjects)
                    _buildSection(
                      context,
                      title: 'Popular Art',
                      items: state.popularProjects,
                      theme: theme,
                      bodyTextColor: theme.textPrimary,
                      cardBackgroundColor: theme.surface,
                      subtitleColor: theme.textSecondary,
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  // Widget _buildDrawer dengan primary color
  Widget _buildDrawer(
    BuildContext context,
    ThemeManager theme,
  ) {
    return Drawer(
       backgroundColor: theme.primary, // Menggunakan primary untuk Drawer
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(color: theme.primary),
            child: Text(
              'Muraloka',
              style: TextStyle(
                color: theme.surface,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _drawerItem(
            icon: Icons.home,
            text: 'Beranda',
            onTap: () => context.goNamed(HOME_PAGE_ROUTE),
            textColor: theme.surface,
          ),
          _drawerItem(
            icon: Icons.folder_open,
            text: 'My Projects',
            onTap: () {
              Navigator.pop(context);
              context.go('/projects');
            },
            textColor: theme.surface,
          ),
          _drawerItem(
            icon: Icons.collections,
            text: 'My Artworks',
            onTap: () {
              Navigator.pop(context);
              context.go('/my-artworks');
            },
            textColor: theme.surface,
          ),
          _drawerItem(
            icon: Icons.storefront,
            text: 'Marketplace',
            onTap: () {
              Navigator.pop(context);
              context.go('/marketplace');
            },
            textColor: theme.surface,
          ),
          _drawerItem(
            icon: Icons.person,
            text: 'Profile',
            onTap: () => context.go('/profile'),
            textColor: theme.surface,
          ),
          _drawerItem(
            icon: Icons.settings,
            text: 'Pengaturan',
            onTap: () => context.goNamed(SETTING_PAGE_ROUTE),
            textColor: theme.surface,
          ),
        ],
      ),
    );
  }

  ListTile _drawerItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    required Color textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(text, style: TextStyle(color: textColor)),
      onTap: onTap,
    );
  }

  // Widget _buildSection dan _buildCardItem menggunakan bodyTextColor dinamis
  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Project> items,
    required ThemeManager theme,
    required Color bodyTextColor,
    required Color cardBackgroundColor,
    required Color subtitleColor,
    bool isAuthor = false,
  }) {
    // Don't render if no items
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 8.0, top: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: bodyTextColor,
                ),
              ),
              IconButton(
                icon: Icon(Icons.arrow_forward, color: bodyTextColor),
                onPressed: () {
                  // Aksi Lihat Semua
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: isAuthor ? 220 : 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _buildCardItem(
                context,
                item: items[index],
                theme: theme,
                bodyTextColor: bodyTextColor,
                cardBackgroundColor: cardBackgroundColor,
                subtitleColor: subtitleColor,
                isAuthor: isAuthor,
              );
            },
          ),
        ),
      ],
    );
  }

  // Widget _buildCardItem dengan dark mode support
  Widget _buildCardItem(
    BuildContext context, {
    required Project item,
    required ThemeManager theme,
    required Color bodyTextColor,
    required Color cardBackgroundColor,
    required Color subtitleColor,
    bool isAuthor = false,
  }) {
    return SizedBox(
      width: isAuthor ? 140 : 180,
      child: Card(
        // Menetapkan shape dan radius 16.0
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 2.0,
        color: cardBackgroundColor, // Dynamic background color
        margin: const EdgeInsets.only(right: 12.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0), // Padding di dalam Card
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bagian Gambar
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      // item.imageUrl,
                      item.id,
                      fit: BoxFit.cover,
                      height: isAuthor ? 120 : 160,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: isAuthor ? 120 : 160,
                        color: subtitleColor,
                        child: Center(
                          child: Text(
                            isAuthor ? 'Author' : 'Art',
                            style: TextStyle(color: cardBackgroundColor),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Ikon Hati/Like (Kanan Atas dengan Latar Belakang Semi-Transparan)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.semiBlack, // Latar belakang semi-transparan
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child:
                          // Icon(
                          //   item.isLiked ? Icons.favorite : Icons.favorite_border,
                          //   color: cardBackgroundColor, // Ikon mengikuti theme
                          //   size: 16,
                          // ),
                          Icon(
                            Icons.favorite_border,
                            color: cardBackgroundColor, // Ikon mengikuti theme
                            size: 16,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Bagian Teks
              Text(
                item.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: bodyTextColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                // item.subtitle,
                item.name,
                style: TextStyle(
                  fontSize: 12,
                  color: subtitleColor,
                ), // Dynamic subtitle color
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
