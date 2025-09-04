// lib/widgets/loading_states.dart
import 'package:flutter/material.dart';
import 'animated_components.dart';

/// ✅ PRODUCTION READY: Enhanced Loading States and Skeleton Screens
/// Provides comprehensive loading indicators for better user experience
class LoadingStates {
  LoadingStates._();
}

/// Enhanced loading indicator with customizable appearance
class EnhancedLoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;
  final Color? color;
  final LoadingIndicatorType type;
  final bool showMessage;
  final EdgeInsetsGeometry padding;

  const EnhancedLoadingIndicator({
    super.key,
    this.message,
    this.size = 24.0,
    this.color,
    this.type = LoadingIndicatorType.circular,
    this.showMessage = true,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indicatorColor = color ?? theme.primaryColor;
    
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIndicator(indicatorColor),
          if (showMessage && message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIndicator(Color color) {
    switch (type) {
      case LoadingIndicatorType.circular:
        return SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            color: color,
            strokeWidth: size * 0.1,
          ),
        );
      case LoadingIndicatorType.dots:
        return AnimatedLoadingIndicators.pulsatingDots(
          color: color,
          size: size * 0.3,
        );
      case LoadingIndicatorType.bouncing:
        return AnimatedLoadingIndicators.bouncingBall(
          color: color,
          size: size,
        );
      case LoadingIndicatorType.ring:
        return AnimatedLoadingIndicators.rotatingRing(
          color: color,
          size: size,
          strokeWidth: size * 0.1,
        );
    }
  }
}

/// Loading indicator types
enum LoadingIndicatorType {
  circular,
  dots,
  bouncing,
  ring,
}

/// Skeleton screen for event cards
class EventCardSkeleton extends StatelessWidget {
  final bool enabled;
  
  const EventCardSkeleton({
    super.key,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      enabled: enabled,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title skeleton
              Container(
                width: double.infinity,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              
              // Subtitle skeleton
              Container(
                width: MediaQuery.of(context).size.width * 0.6,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              
              // Location and time row skeleton
              Row(
                children: [
                  // Location icon placeholder
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Location text
                  Container(
                    width: 120,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Spacer(),
                  
                  // Time text
                  Container(
                    width: 80,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Status badge skeleton
              Container(
                width: 80,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton screen for attendance list
class AttendanceListSkeleton extends StatelessWidget {
  final int itemCount;
  final bool enabled;
  
  const AttendanceListSkeleton({
    super.key,
    this.itemCount = 5,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        return ShimmerLoading(
          enabled: enabled,
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
              ),
              title: Container(
                width: double.infinity,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              trailing: Container(
                width: 60,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton screen for user profile
class ProfileSkeleton extends StatelessWidget {
  final bool enabled;
  
  const ProfileSkeleton({
    super.key,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      enabled: enabled,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile picture skeleton
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 16),
            
            // Name skeleton
            Container(
              width: 200,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            
            // Email skeleton
            Container(
              width: 150,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 24),
            
            // Stats section skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (index) {
                return Column(
                  children: [
                    Container(
                      width: 40,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 60,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// Generic list skeleton
class GenericListSkeleton extends StatelessWidget {
  final int itemCount;
  final bool enabled;
  final double itemHeight;
  final EdgeInsetsGeometry? padding;
  
  const GenericListSkeleton({
    super.key,
    this.itemCount = 5,
    this.enabled = true,
    this.itemHeight = 80,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding ?? const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return ShimmerLoading(
          enabled: enabled,
          child: Container(
            height: itemHeight,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }
}

/// Loading overlay for entire screen
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final Color? backgroundColor;
  final LoadingIndicatorType indicatorType;
  
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.backgroundColor,
    this.indicatorType = LoadingIndicatorType.circular,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: backgroundColor ?? Colors.black.withOpacity(0.3),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: EnhancedLoadingIndicator(
                  message: message ?? 'Loading...',
                  type: indicatorType,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Pull-to-refresh indicator
class CustomRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? color;
  final Color? backgroundColor;
  final double displacement;
  
  const CustomRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color,
    this.backgroundColor,
    this.displacement = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? Theme.of(context).primaryColor,
      backgroundColor: backgroundColor ?? Theme.of(context).cardColor,
      displacement: displacement,
      strokeWidth: 3.0,
      child: child,
    );
  }
}

/// Lazy loading indicator for infinite scroll
class LazyLoadingIndicator extends StatelessWidget {
  final bool isLoading;
  final String? message;
  final EdgeInsetsGeometry padding;
  
  const LazyLoadingIndicator({
    super.key,
    required this.isLoading,
    this.message,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return const SizedBox.shrink();
    
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          if (message != null) ...[
            const SizedBox(width: 12),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

/// Progress indicator with percentage
class ProgressIndicatorWithPercentage extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String? label;
  final Color? color;
  final Color? backgroundColor;
  final double height;
  final BorderRadius? borderRadius;
  final bool showPercentage;
  
  const ProgressIndicatorWithPercentage({
    super.key,
    required this.progress,
    this.label,
    this.color,
    this.backgroundColor,
    this.height = 8.0,
    this.borderRadius,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressColor = color ?? theme.primaryColor;
    final bgColor = backgroundColor ?? progressColor.withOpacity(0.2);
    final percentage = (progress * 100).round();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label!,
                style: theme.textTheme.bodySmall,
              ),
              if (showPercentage)
                Text(
                  '$percentage%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: progressColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Container(
          height: height,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: progressColor,
                borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Loading state manager for different screen states
class LoadingStateManager extends StatelessWidget {
  final LoadingState state;
  final Widget child;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final Widget? emptyWidget;
  final String? loadingMessage;
  final String? errorMessage;
  final String? emptyMessage;
  final VoidCallback? onRetry;
  
  const LoadingStateManager({
    super.key,
    required this.state,
    required this.child,
    this.loadingWidget,
    this.errorWidget,
    this.emptyWidget,
    this.loadingMessage,
    this.errorMessage,
    this.emptyMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case LoadingState.loading:
        return loadingWidget ?? EnhancedLoadingIndicator(
          message: loadingMessage ?? 'Loading...',
        );
      case LoadingState.error:
        return errorWidget ?? _buildErrorState(context);
      case LoadingState.empty:
        return emptyWidget ?? _buildEmptyState(context);
      case LoadingState.success:
        return child;
    }
  }
  
  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage ?? 'Something went wrong',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage ?? 'No data available',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading states enum
enum LoadingState {
  loading,
  success,
  error,
  empty,
}