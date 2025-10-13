import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
// Ganti dengan ArtItem jika art_data.dart berisi model
import 'package:muraloka/all_code/model/art_data.dart';
import 'package:muraloka/all_code/model/project.dart';
import 'package:muraloka/all_code/state/home_cubit/home_cubit.dart';
import 'package:muraloka/all_code/state/home_cubit/home_state.dart';
import 'package:muraloka/constant/constant.dart';
import 'package:muraloka/constant/name_router.dart'; // Digunakan untuk navigasi

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager.of(context);
    final cubit = context.read<HomeCubit>();

    // Warna eksplisit untuk kontras Body:
    const Color appBarContentColor = Colors.white;
    const Color bodyContentColor = Colors.black;

    // Panggil fetchData hanya sekali saat build pertama (atau HomeInitial)
    if (cubit.state is HomeInitial) {
      cubit.fetchData();
    }

    return Scaffold(
      // --- PERUBAHAN UTAMA DI SINI: BODY BACKGROUND PUTIH ---
      backgroundColor: Colors.white,
      // --- PERUBAHAN UTAMA DI SINI: APPBAR WARNA SECONDARY1 ---
      appBar: AppBar(
        backgroundColor: theme.secondary1,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: appBarContentColor),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Muraloka',
          style: TextStyle(
            color: appBarContentColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: appBarContentColor),
            onPressed: () {
              // Aksi pencarian
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      // Drawer tetap menggunakan warna theme.primary1
      drawer: _buildDrawer(context, theme, appBarContentColor),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading || state is HomeInitial) {
            return Center(
              child: CircularProgressIndicator(color: theme.primary1),
            );
          }
          if (state is HomeFailure) {
            return Center(
              child: Text(
                'Error: ${state.message}',
                style: const TextStyle(color: bodyContentColor),
              ),
            );
          }

          if (state is HomeLoaded) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Resume your art
                  _buildSection(
                    context,
                    title: 'Resume your art',
                    items: state.resumeProjects,
                    theme: theme,
                    bodyTextColor: bodyContentColor, // Teks body hitam
                  ),
                  SizedBox(height: 8),
                  // 2. Popular Art
                  _buildSection(
                    context,
                    title: 'Popular Art',
                    items: state.popularProjects,
                    theme: theme,
                    bodyTextColor: bodyContentColor, // Teks body hitam
                  ),
                  // 3. Popular Author
                  // _buildSection(
                  //   context,
                  //   title: 'Popular Author',
                  //   items: state.popularAuthors,
                  //   theme: theme,
                  //   bodyTextColor: bodyContentColor, // Teks body hitam
                  //   isAuthor: true,
                  // ),
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

  // Widget _buildDrawer tetap menggunakan warna theme.primary1 dengan konten putih
  Widget _buildDrawer(
    BuildContext context,
    ThemeManager theme,
    Color drawerContentColor,
  ) {
    return Drawer(
      backgroundColor: theme.primary1, // Menggunakan primary1 untuk Drawer
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(color: theme.primary1),
            child: Text(
              'Muraloka',
              style: TextStyle(
                color: theme.tertiary1,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _drawerItem(
            icon: Icons.home,
            text: 'Beranda',
            onTap: () => context.goNamed(HOME_PAGE_ROUTE),
            textColor: Colors.white,
          ),
          _drawerItem(
            icon: Icons.format_paint,
            text: 'Canvas',
            onTap: () {
              Navigator.pop(context);
              context.go('/paint');
            },
            textColor: Colors.white,
          ),
          _drawerItem(
            icon: Icons.person,
            text: 'Profil',
            onTap: () => context.go('/profile'),
            textColor: Colors.white,
          ),
          _drawerItem(
            icon: Icons.settings,
            text: 'Pengaturan',
            onTap: () => context.goNamed(SETTING_PAGE_ROUTE),
            textColor: Colors.white,
          ),
          const Divider(color: Colors.white38),
          _drawerItem(
            icon: Icons.logout,
            text: 'Keluar',
            onTap: () {
              Navigator.pop(context);
            },
            textColor: Colors.white,
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

  // Widget _buildSection dan _buildCardItem menggunakan bodyTextColor (hitam)
  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Project> items,
    required ThemeManager theme,
    required Color bodyTextColor, // bodyTextColor = Colors.black
    bool isAuthor = false,
  }) {
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
                isAuthor: isAuthor,
              );
            },
          ),
        ),
      ],
    );
  }

  // Widget _buildCardItem menggunakan bodyTextColor (hitam)
  Widget _buildCardItem(
    BuildContext context, {
    required Project item,
    required ThemeManager theme,
    required Color bodyTextColor,
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
        color: Colors.white,
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
                      item.projectId,
                      fit: BoxFit.cover,
                      height: isAuthor ? 120 : 160,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: isAuthor ? 120 : 160,
                        color: Colors.grey,
                        child: Center(
                          child: Text(
                            isAuthor ? 'Author' : 'Art',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Ikon Hati/Like (Kanan Atas dengan Latar Belakang Hitam)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black, // Latar belakang hitam
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child:
                          // Icon(
                          //   item.isLiked ? Icons.favorite : Icons.favorite_border,
                          //   color: Colors.white, // Ikon selalu putih
                          //   size: 16,
                          // ),
                          Icon(
                            Icons.favorite_border,
                            color: Colors.white, // Ikon selalu putih
                            size: 16,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Bagian Teks
              Text(
                item.title,
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
                item.title,
                style: TextStyle(fontSize: 12, color: bodyTextColor),
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
