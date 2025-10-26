import 'package:flutter/material.dart';

/// Fade page transition
class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  FadePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}

/// Slide page transition from bottom
class SlideUpPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  SlideUpPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        );
}

/// Scale and fade transition
class ScaleFadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  ScaleFadePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return ScaleTransition(
              scale: Tween<double>(
                begin: 0.8,
                end: 1.0,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                ),
              ),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
        );
}

/// Slide from right transition (default Material behavior)
class SlideRightPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  SlideRightPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}

/// Shared axis transition (Material 3 style)
class SharedAxisPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  SharedAxisPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.3, 0.0);
            const end = Offset.zero;
            
            return SlideTransition(
              position: Tween<Offset>(
                begin: begin,
                end: end,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        );
}

/// Custom route helper
class CustomPageRoute {
  static Route<T> fadeIn<T>(Widget page) => FadePageRoute<T>(page: page);
  
  static Route<T> slideUp<T>(Widget page) => SlideUpPageRoute<T>(page: page);
  
  static Route<T> scaleFade<T>(Widget page) => ScaleFadePageRoute<T>(page: page);
  
  static Route<T> slideRight<T>(Widget page) => SlideRightPageRoute<T>(page: page);
  
  static Route<T> sharedAxis<T>(Widget page) => SharedAxisPageRoute<T>(page: page);
}
