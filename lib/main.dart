import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:muraloka/constant/constant.dart';
import 'package:provider/provider.dart';
import 'package:muraloka/all_code/page/paint_page.dart';
import 'package:muraloka/all_code/page/layer_paint_page.dart';
import 'package:muraloka/all_code/page/my_artworks_page.dart';
import 'package:muraloka/all_code/page/projects_gallery_page.dart';
import 'package:muraloka/all_code/page/marketplace_page.dart';
import 'package:muraloka/all_code/providers/theme_provider.dart';
import 'package:muraloka/all_code/theme/app_theme.dart';
import 'package:muraloka/all_code/state/detail_cubit.dart/detail_cubit.dart';
import 'package:muraloka/all_code/state/home_cubit/home_cubit.dart';
import 'package:muraloka/constant/name_router.dart';
import 'package:muraloka/di.dart' as di;
import 'package:muraloka/firebase_options.dart';
// import 'package:muraloka/presentation/cubit/popular_paint_cubit/popular_paint_cubit.dart';
import 'package:muraloka/all_code/page/home_page.dart';
import 'package:muraloka/all_code/page/setting_page.dart';
import 'package:muraloka/all_code/services/user_profile_service.dart';
import 'package:muraloka/presentation/pages/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  di.init;
  FirebaseUIAuth.configureProviders([EmailAuthProvider(), PhoneAuthProvider()]);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // User profile service untuk sync auth -> Firestore
    final userProfileService = UserProfileService();

    final router = GoRouter(
      initialLocation: '/',
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/sign-in',
          builder: (context, state) => SignInScreen(
            showAuthActionSwitch: true,
            showPasswordVisibilityToggle: true,
            actions: [
              AuthStateChangeAction<SignedIn>((context, state) async {
                // Sync user profile ke Firestore setelah login
                await userProfileService.syncCurrentUserProfile();
                context.go('/home');
              }),
              AuthStateChangeAction<UserCreated>((context, state) async {
                // Sync user profile ke Firestore setelah registrasi
                await userProfileService.syncCurrentUserProfile();
                context.go('/sign-in');
              }),
              AuthStateChangeAction<AuthFailed>(
                (context, state) => context.go('/sign-in'),
              ),
            ],
          ),
        ),
        GoRoute(
          name: HOME_PAGE_ROUTE,
          path: '/home',
          builder: (context, state) => HomePage(),
        ),
        GoRoute(
          path: '/paint',
          builder: (context, state) {
            // Get parameters from extra
            final extra = state.extra as Map<String, dynamic>?;
            final projectId = extra?['projectId'] as String?;
            final isShared = extra?['isShared'] as bool? ?? false;
            
            // If no projectId, go to demo page
            if (projectId == null) {
              return PaintPage();
            }
            
            // Otherwise, open LayerPaintPage with project
            return LayerPaintPage(
              projectId: projectId,
              isShared: isShared,
            );
          },
        ),
        GoRoute(
          path: '/my-artworks',
          builder: (context, state) => MyArtworksPage(),
        ),
        GoRoute(
          path: '/projects',
          builder: (context, state) => ProjectsGalleryPage(),
        ),
        GoRoute(
          path: '/marketplace',
          builder: (context, state) => MarketplacePage(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) {
            final theme = ThemeManager.of(context);
            
            return Theme(
              data: Theme.of(context).copyWith(
                // Ensure text colors follow the theme
                textTheme: Theme.of(context).textTheme.apply(
                  bodyColor: theme.textPrimary,
                  displayColor: theme.textPrimary,
                ),
                // Ensure ListTile text follows theme
                listTileTheme: ListTileThemeData(
                  textColor: theme.textPrimary,
                  iconColor: theme.textSecondary,
                ),
              ),
              child: ProfileScreen(
                appBar: AppBar(
                  backgroundColor: theme.primary,
                  foregroundColor: theme.surface,
                  elevation: 0,
                  title: Text(
                    'Profile Pengguna',
                    style: TextStyle(
                      color: theme.surface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: theme.surface),
                    onPressed: () {
                      context.go('/home');
                    },
                  ),
                  automaticallyImplyLeading: false,
                ),
                showDeleteConfirmationDialog: true,
                showMFATile: true,
                actions: [SignedOutAction((context) => context.go('/sign-in'))],
              ),
            );
          },
        ),
        //#example if use parameter#
        // GoRoute(
        //   name: DETAIL_PAGE_ROUTE,
        //   path: '/detail/:id',
        //   builder: (context, state) {
        //     final id = state.pathParameters['id']!;
        //     return DetailPage(id: id);
        //   },
        // ),
        GoRoute(
          name: SETTING_PAGE_ROUTE,
          path: '/setting',
          builder: (context, state) => SettingPage(),
        ),
      ],
    );
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        BlocProvider<HomeCubit>(create: (context) => HomeCubit()),
        BlocProvider<DetailCubit>(create: (context) => DetailCubit()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            routerConfig: router,
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: AppTheme.lightTheme.copyWith(
              textTheme: GoogleFonts.merriweatherTextTheme(
                ThemeData(brightness: Brightness.light).textTheme,
              ),
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
                  TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
                },
              ),
            ),
            darkTheme: AppTheme.darkTheme.copyWith(
              textTheme: GoogleFonts.merriweatherTextTheme(
                ThemeData(brightness: Brightness.dark).textTheme,
              ),
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
                  TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
