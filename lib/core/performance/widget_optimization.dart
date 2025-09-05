// lib/core/performance/widget_optimization.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:geo_asist_front/core/utils/app_logger.dart';

/// Optimized list view with RepaintBoundary for expensive list items
/// Implements performance best practices for large datasets
class OptimizedListView<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final double? itemExtent;
  final bool addRepaintBoundaries;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final bool reverse;
  final ScrollController? controller;
  final VoidCallback? onEndReached;
  final double endReachedThreshold;

  const OptimizedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.itemExtent,
    this.addRepaintBoundaries = true,
    this.physics,
    this.padding,
    this.reverse = false,
    this.controller,
    this.onEndReached,
    this.endReachedThreshold = 200.0,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (onEndReached != null &&
            scrollInfo.metrics.pixels >= 
            scrollInfo.metrics.maxScrollExtent - endReachedThreshold) {
          onEndReached!();
        }
        return false;
      },
      child: ListView.builder(
        controller: controller,
        itemCount: items.length,
        itemExtent: itemExtent,
        physics: physics,
        padding: padding,
        reverse: reverse,
        itemBuilder: (context, index) {
          final item = items[index];
          final child = itemBuilder(context, item, index);
          
          if (addRepaintBoundaries) {
            return RepaintBoundary(
              key: ValueKey(index),
              child: child,
            );
          }
          
          return child;
        },
      ),
    );
  }
}

/// Optimized grid view with performance enhancements
class OptimizedGridView<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final SliverGridDelegate gridDelegate;
  final bool addRepaintBoundaries;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;

  const OptimizedGridView({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.gridDelegate,
    this.addRepaintBoundaries = true,
    this.physics,
    this.padding,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: controller,
      itemCount: items.length,
      gridDelegate: gridDelegate,
      physics: physics,
      padding: padding,
      itemBuilder: (context, index) {
        final item = items[index];
        final child = itemBuilder(context, item, index);
        
        if (addRepaintBoundaries) {
          return RepaintBoundary(
            key: ValueKey(index),
            child: child,
          );
        }
        
        return child;
      },
    );
  }
}

/// Optimized image widget with caching and memory management
class OptimizedImage extends StatelessWidget {
  final String? imageUrl;
  final String? assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool enableMemoryCache;
  final Duration fadeInDuration;
  final Color? color;
  final BlendMode? colorBlendMode;

  const OptimizedImage({
    super.key,
    this.imageUrl,
    this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.enableMemoryCache = true,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.color,
    this.colorBlendMode,
  }) : assert(imageUrl != null || assetPath != null, 'Either imageUrl or assetPath must be provided');

  @override
  Widget build(BuildContext context) {
    // Asset image
    if (assetPath != null) {
      return Image.asset(
        assetPath!,
        width: width,
        height: height,
        fit: fit,
        color: color,
        colorBlendMode: colorBlendMode,
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? _buildDefaultErrorWidget();
        },
      );
    }

    // Network image
    return Image.network(
      imageUrl!,
      width: width,
      height: height,
      fit: fit,
      color: color,
      colorBlendMode: colorBlendMode,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return AnimatedOpacity(
            opacity: 1.0,
            duration: fadeInDuration,
            child: child,
          );
        }
        
        return placeholder ?? _buildDefaultPlaceholder(loadingProgress);
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? _buildDefaultErrorWidget();
      },
    );
  }

  Widget _buildDefaultPlaceholder(ImageChunkEvent? progress) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Center(
        child: CircularProgressIndicator(
          value: progress?.expectedTotalBytes != null
              ? progress!.cumulativeBytesLoaded / progress.expectedTotalBytes!
              : null,
          strokeWidth: 2.0,
        ),
      ),
    );
  }

  Widget _buildDefaultErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Icon(
        Icons.error_outline,
        color: Colors.grey,
      ),
    );
  }
}

/// High-performance widget for handling animations
class OptimizedAnimatedWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final AnimationController? controller;
  final Curve curve;

  const OptimizedAnimatedWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.controller,
    this.curve = Curves.easeInOut,
  });

  @override
  State<OptimizedAnimatedWidget> createState() => _OptimizedAnimatedWidgetState();
}

class _OptimizedAnimatedWidgetState extends State<OptimizedAnimatedWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? 
        AnimationController(duration: widget.duration, vsync: this);
    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);
    _controller.forward();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Opacity(
            opacity: _animation.value,
            child: child,
          ),
        );
      },
    );
  }
}

/// Mixin for widgets that need performance monitoring
mixin PerformanceMonitor<T extends StatefulWidget> on State<T> {
  Stopwatch? _renderStopwatch;
  static const Duration _performanceWarningThreshold = Duration(milliseconds: 16);

  @override
  Widget build(BuildContext context) {
    _renderStopwatch = Stopwatch()..start();
    
    final widget = buildOptimized(context);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _renderStopwatch?.stop();
      final renderTime = _renderStopwatch?.elapsed;
      
      if (renderTime != null && renderTime > _performanceWarningThreshold) {
        logger.d('⚠️ Slow render detected in ${T.toString()}: ${renderTime.inMilliseconds}ms');
      }
    });
    
    return widget;
  }

  Widget buildOptimized(BuildContext context);
}

/// Custom scroll view with optimizations
class OptimizedCustomScrollView extends StatelessWidget {
  final List<Widget> slivers;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final Key? center;
  final double anchor;

  const OptimizedCustomScrollView({
    super.key,
    required this.slivers,
    this.controller,
    this.physics,
    this.shrinkWrap = false,
    this.center,
    this.anchor = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: controller,
      physics: physics,
      shrinkWrap: shrinkWrap,
      center: center,
      anchor: anchor,
      slivers: slivers.map((sliver) => RepaintBoundary(child: sliver)).toList(),
    );
  }
}

/// Debounced text field for search optimization
class DebouncedTextField extends StatefulWidget {
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final Duration debounceDuration;
  final TextEditingController? controller;
  final InputDecoration? decoration;
  final TextStyle? style;

  const DebouncedTextField({
    super.key,
    this.hintText,
    this.onChanged,
    this.debounceDuration = const Duration(milliseconds: 500),
    this.controller,
    this.decoration,
    this.style,
  });

  @override
  State<DebouncedTextField> createState() => _DebouncedTextFieldState();
}

class _DebouncedTextFieldState extends State<DebouncedTextField> {
  late TextEditingController _controller;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  void _onTextChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, () {
      widget.onChanged?.call(_controller.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: widget.decoration ?? 
        InputDecoration(hintText: widget.hintText),
      style: widget.style,
    );
  }
}

/// Performance utilities
class PerformanceUtils {
  /// Batch widget updates to reduce rebuilds
  static void batchUpdates(List<VoidCallback> updates) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final update in updates) {
        update();
      }
    });
  }

  /// Create a throttled callback
  static VoidCallback throttle(
    VoidCallback callback,
    Duration duration,
  ) {
    bool isThrottled = false;
    
    return () {
      if (isThrottled) return;
      
      isThrottled = true;
      callback();
      
      timer = Timer(duration, () {
        isThrottled = false;
      });
    };
  }

  /// Measure widget build time
  static T measureBuildTime<T>(String widgetName, T Function() builder) {
    final stopwatch = Stopwatch()..start();
    final result = builder();
    stopwatch.stop();
    
    if (stopwatch.elapsedMilliseconds > 16) {
      logger.d('⚠️ Slow build in $widgetName: ${stopwatch.elapsedMilliseconds}ms');
    }
    
    return result;
  }
}