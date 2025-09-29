import 'package:firebase_auth/firebase_auth.dart'
    hide PhoneAuthProvider, EmailAuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:muraloka/all_code/state/detail_cubit.dart/detail_cubit.dart';
import 'package:muraloka/all_code/state/home_cubit/home_cubit.dart';
import 'package:muraloka/constant/name_router.dart';
import 'package:muraloka/di.dart' as di;
import 'package:muraloka/firebase_options.dart';
// import 'package:muraloka/presentation/cubit/popular_paint_cubit/popular_paint_cubit.dart';
import 'package:muraloka/all_code/page/home_page.dart';
import 'package:muraloka/all_code/page/setting_page.dart';

void main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  di.init;
  FirebaseUIAuth.configureProviders([EmailAuthProvider(), PhoneAuthProvider()]);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: FirebaseAuth.instance.currentUser == null
          ? '/sign-in'
          : '/profile',
      routes: <RouteBase>[
        GoRoute(
          path: '/sign-in',
          builder: (context, state) => SignInScreen(
            showAuthActionSwitch: true,
            showPasswordVisibilityToggle: true,
            actions: [
              AuthStateChangeAction<SignedIn>(
                (context, state) => context.go('/home'),
              ),
              AuthStateChangeAction<UserCreated>(
                (context, state) => context.go('/sign-in'),
              ),
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
          path: '/profile',
          builder: (context, state) => ProfileScreen(
            showDeleteConfirmationDialog: true,
            showMFATile: true,
            actions: [SignedOutAction((context) => context.go('/sign-in'))],
          ),
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
    return MultiBlocProvider(
      providers: [
        // BlocProvider(create: (context) => di.locator<PopularPaintCubit>()),
        BlocProvider<HomeCubit>(create: (context) => HomeCubit()),
        BlocProvider<DetailCubit>(create: (context) => DetailCubit()),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.merriweatherTextTheme(),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.dark,
          ),
          textTheme: GoogleFonts.merriweatherTextTheme(
            ThemeData(brightness: Brightness.dark).textTheme,
          ),
        ),
      ),
    );
  }
}
