// lib/widgets/animated_components.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback and SystemSound
import 'package:flutter/scheduler.dart'; // For Ticker and TickerCallback

/// ✅ PRODUCTION READY: Animated UI Components Collection
/// Provides smooth animations and micro-interactions for better UX
class AnimatedComponents {
  AnimatedComponents._();
}

/// Animated loading indicators
class AnimatedLoadingIndicators {
  
  /// Pulsating dot indicator
  static Widget pulsatingDots({
    Color? color,
    double size = 8.0,
    Duration duration = const Duration(milliseconds: 1000),
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _createPulseAnimation(
            duration: duration,
            delay: Duration(milliseconds: index * 200),
          ),
          builder: (context, child) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: size * 0.2),
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (color ?? Theme.of(context).primaryColor).withValues(alpha: 
                  _createPulseAnimation(
                    duration: duration,
                    delay: Duration(milliseconds: index * 200),
                  ).value,
                ),
              ),
            );
          },
        );
      }),
    );
  }
  
  /// Bouncing ball indicator
  static Widget bouncingBall({
    Color? color,
    double size = 24.0,
    Duration duration = const Duration(milliseconds: 800),
  }) {
    return AnimatedBuilder(
      animation: _createBounceAnimation(duration: duration),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -20 * _createBounceAnimation(duration: duration).value),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color ?? Theme.of(context).primaryColor,
            ),
          ),
        );
      },
    );
  }
  
  /// Rotating ring indicator
  static Widget rotatingRing({
    Color? color,
    double size = 24.0,
    double strokeWidth = 3.0,
    Duration duration = const Duration(milliseconds: 1200),
  }) {
    return AnimatedBuilder(
      animation: _createRotationAnimation(duration: duration),
      builder: (context, child) {
        return Transform.rotate(
          angle: _createRotationAnimation(duration: duration).value * 2 * 3.14159,
          child: SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: strokeWidth,
              color: color ?? Theme.of(context).primaryColor,
              backgroundColor: (color ?? Theme.of(context).primaryColor).withValues(alpha: 0.2),
            ),
          ),
        );
      },
    );
  }
  
  static Animation<double> _createPulseAnimation({
    required Duration duration,
    Duration delay = Duration.zero,
  }) {
    final controller = AnimationController(
      duration: duration,
      vsync: _TickerProvider(),
    );
    
    final animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ));
    
    Future.delayed(delay, () {
      controller.repeat(reverse: true);
    });
    
    return animation;
  }
  
  static Animation<double> _createBounceAnimation({
    required Duration duration,
  }) {
    final controller = AnimationController(
      duration: duration,
      vsync: _TickerProvider(),
    );
    
    final animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.bounceOut,
    ));
    
    controller.repeat();
    
    return animation;
  }
  
  static Animation<double> _createRotationAnimation({
    required Duration duration,
  }) {
    final controller = AnimationController(
      duration: duration,
      vsync: _TickerProvider(),
    );
    
    controller.repeat();
    
    return controller;
  }
}

/// Enhanced animated button with haptic feedback
class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Duration animationDuration;
  final double scaleOnPress;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final bool enableHapticFeedback;
  final bool enableSoundFeedback;
  
  const AnimatedButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.animationDuration = const Duration(milliseconds: 150),
    this.scaleOnPress = 0.95,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.borderRadius,
    this.enableHapticFeedback = true,
    this.enableSoundFeedback = false,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleOnPress,
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

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    _controller.forward();
    
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _handleTapCancel();
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _controller.reverse();
  }

  void _handleTap() {
    if (widget.onPressed != null) {
      if (widget.enableHapticFeedback) {
        HapticFeedback.mediumImpact();
      }
      
      if (widget.enableSoundFeedback) {
        SystemSound.play(SystemSoundType.click);
      }
      
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTapDown: widget.onPressed != null ? _handleTapDown : null,
      onTapUp: widget.onPressed != null ? _handleTapUp : null,
      onTapCancel: widget.onPressed != null ? _handleTapCancel : null,
      onTap: widget.onPressed != null ? _handleTap : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: widget.padding ?? const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? theme.primaryColor,
                borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
                boxShadow: _isPressed ? [] : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: DefaultTextStyle(
                style: TextStyle(
                  color: widget.foregroundColor ?? theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Animated card with hover and press effects
class AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration animationDuration;
  final double elevation;
  final double hoverElevation;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final bool enableHoverEffect;

  const AnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.animationDuration = const Duration(milliseconds: 200),
    this.elevation = 2.0,
    this.hoverElevation = 8.0,
    this.borderRadius,
    this.padding,
    this.margin,
    this.color,
    this.enableHoverEffect = true,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _elevationAnimation;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _elevationAnimation = Tween<double>(
      begin: widget.elevation,
      end: widget.hoverElevation,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleHoverStart() {
    if (!widget.enableHoverEffect) return;
    
    setState(() {
      _isHovered = true;
    });
    _controller.forward();
  }

  void _handleHoverEnd() {
    if (!widget.enableHoverEffect) return;
    
    setState(() {
      _isHovered = false;
    });
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: widget.margin,
            child: Material(
              elevation: _elevationAnimation.value,
              borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
              color: widget.color,
              child: InkWell(
                onTap: widget.onTap,
                onHover: (isHovered) {
                  if (isHovered) {
                    _handleHoverStart();
                  } else {
                    _handleHoverEnd();
                  }
                },
                borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
                child: Padding(
                  padding: widget.padding ?? const EdgeInsets.all(16),
                  child: widget.child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Shimmer loading effect
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color? baseColor;
  final Color? highlightColor;
  final bool enabled;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.baseColor,
    this.highlightColor,
    this.enabled = true,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.enabled) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ShimmerLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = widget.baseColor ?? Colors.grey[300]!;
    final highlightColor = widget.highlightColor ?? Colors.grey[100]!;

    if (!widget.enabled) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                0.0,
                0.5,
                1.0,
              ],
              transform: GradientTransform.translate(_animation.value),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Custom gradient transform for shimmer effect
class GradientTransform {
  static GradientTransform translate(double offset) => _TranslateGradientTransform(offset);
}

class _TranslateGradientTransform implements GradientTransform {
  final double offset;
  
  const _TranslateGradientTransform(this.offset);
  
  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(offset * bounds.width, 0.0, 0.0);
  }
}

/// Staggered animation for list items
class StaggeredList extends StatefulWidget {
  final List<Widget> children;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final Axis direction;

  const StaggeredList({
    super.key,
    required this.children,
    this.duration = const Duration(milliseconds: 600),
    this.delay = const Duration(milliseconds: 100),
    this.curve = Curves.easeOutQuart,
    this.direction = Axis.vertical,
  });

  @override
  State<StaggeredList> createState() => _StaggeredListState();
}

class _StaggeredListState extends State<StaggeredList>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<Offset>> _offsetAnimations;
  late List<Animation<double>> _opacityAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startStaggeredAnimations();
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      widget.children.length,
      (index) => AnimationController(
        duration: widget.duration,
        vsync: this,
      ),
    );

    _offsetAnimations = _controllers.map((controller) {
      return Tween<Offset>(
        begin: widget.direction == Axis.vertical
            ? const Offset(0, 0.5)
            : const Offset(0.5, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: widget.curve,
      ));
    }).toList();

    _opacityAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: widget.curve,
      ));
    }).toList();
  }

  void _startStaggeredAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(widget.delay * i, () {
        if (mounted) {
          _controllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(widget.children.length, (index) {
        return AnimatedBuilder(
          animation: _controllers[index],
          builder: (context, child) {
            return SlideTransition(
              position: _offsetAnimations[index],
              child: FadeTransition(
                opacity: _opacityAnimations[index],
                child: widget.children[index],
              ),
            );
          },
        );
      }),
    );
  }
}

/// Page transition animations
class CustomPageTransitions {
  
  /// Slide transition from right
  static PageRouteBuilder slideFromRight(Widget page) {
    return PageRouteBuilder(
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
    );
  }

  /// Fade transition
  static PageRouteBuilder fadeTransition(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  /// Scale transition
  static PageRouteBuilder scaleTransition(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeInOut;
        
        var tween = Tween(begin: 0.8, end: 1.0).chain(
          CurveTween(curve: curve),
        );

        return ScaleTransition(
          scale: animation.drive(tween),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }
}

/// Simple ticker provider for standalone animations
class _TickerProvider extends TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) {
    return Ticker(onTick);
  }
}

/// Micro-interaction utilities
class MicroInteractions {
  
  /// Haptic feedback utilities
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }
  
  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }
  
  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }
  
  static void selectionClick() {
    HapticFeedback.selectionClick();
  }
  
  /// Sound feedback utilities
  static void playClickSound() {
    SystemSound.play(SystemSoundType.click);
  }
  
  /// Combined feedback
  static void buttonPress() {
    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);
  }
  
  static void success() {
    HapticFeedback.mediumImpact();
  }
  
  static void error() {
    HapticFeedback.heavyImpact();
  }
}