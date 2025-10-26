import 'package:flutter/material.dart';
import '../../constant/constant.dart';

/// Animated card with hover effects (for web/desktop)
class AnimatedProjectCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double elevation;
  final Duration duration;

  const AnimatedProjectCard({
    Key? key,
    required this.child,
    this.onTap,
    this.elevation = 2,
    this.duration = const Duration(milliseconds: 200),
  }) : super(key: key);

  @override
  _AnimatedProjectCardState createState() => _AnimatedProjectCardState();
}

class _AnimatedProjectCardState extends State<AnimatedProjectCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: widget.elevation,
      end: widget.elevation + 4,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Card(
              elevation: _elevationAnimation.value,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: widget.onTap,
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Staggered list animation
class StaggeredListView extends StatelessWidget {
  final List<Widget> children;
  final Duration delay;
  final Axis scrollDirection;

  const StaggeredListView({
    Key? key,
    required this.children,
    this.delay = const Duration(milliseconds: 100),
    this.scrollDirection = Axis.vertical,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: scrollDirection,
      itemCount: children.length,
      itemBuilder: (context, index) {
        return AnimatedListItem(
          delay: delay * index,
          child: children[index],
        );
      },
    );
  }
}

/// Animated list item with fade and slide
class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const AnimatedListItem({
    Key? key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 500),
  }) : super(key: key);

  @override
  _AnimatedListItemState createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Pulse animation (for highlighting)
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final bool autoStart;

  const PulseAnimation({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 1000),
    this.autoStart = true,
  }) : super(key: key);

  @override
  _PulseAnimationState createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.autoStart) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );
  }
}

/// Shimmer loading effect
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const ShimmerLoading({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
  }) : super(key: key);

  @override
  _ShimmerLoadingState createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                AppColors.lightBorder,
                AppColors.lightSurfaceVariant,
                AppColors.lightBorder,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(-1.0 + _controller.value * 3, 0),
              end: Alignment(0.0 + _controller.value * 3, 0),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Slide and fade in animation
class SlideInAnimation extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset begin;

  const SlideInAnimation({
    Key? key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 500),
    this.begin = const Offset(0, 0.5),
  }) : super(key: key);

  @override
  _SlideInAnimationState createState() => _SlideInAnimationState();
}

class _SlideInAnimationState extends State<SlideInAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.begin,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Scale and fade in animation for FABs and dialogs
class ScaleFadeIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const ScaleFadeIn({
    Key? key,
    required this.child,
    this.delay = const Duration(milliseconds: 200),
    this.duration = const Duration(milliseconds: 400),
  }) : super(key: key);

  @override
  _ScaleFadeInState createState() => _ScaleFadeInState();
}

class _ScaleFadeInState extends State<ScaleFadeIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
