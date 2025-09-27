import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:muraloka/constant/name_router.dart';
import 'package:muraloka/di.dart' as di;
import 'package:muraloka/presentation/cubit/popular_paint_cubit/popular_paint_cubit.dart';
import 'package:muraloka/presentation/page/home_page.dart';
import 'package:muraloka/presentation/page/setting_page.dart';

void main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);
  di.init;
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/',
      routes: <RouteBase>[
        GoRoute(
          name: HOME_PAGE_ROUTE,
          path: '/',
          builder: (context, state) => HomePage(),
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
        BlocProvider(create: (context) => di.locator<PopularPaintCubit>()),
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
