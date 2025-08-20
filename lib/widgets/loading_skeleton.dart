// lib/widgets/loading_skeleton.dart - VERSIÓN COMPLETA CON listItem()
import 'package:flutter/material.dart';
import '../utils/colors.dart';

class LoadingSkeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const LoadingSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutSine,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.lightGray,
                AppColors.lightGray.withValues(alpha: 0.5),
                AppColors.lightGray,
              ],
              stops: [
                0.0,
                0.5,
                1.0,
              ],
              transform: GradientRotation(_animation.value * 3.14159),
            ),
          ),
        );
      },
    );
  }
}

/// Widgets predefinidos de skeleton loading
class SkeletonLoaders {
  /// ✅ NUEVO: Skeleton para tarjeta genérica
  static Widget card({double? height, double? width}) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? 80,
      margin: const EdgeInsets.only(bottom: 8),
      child: LoadingSkeleton(
        width: width ?? double.infinity,
        height: height ?? 80,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  /// ✅ NUEVO: Skeleton para item de lista genérico
  static Widget listItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGray.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          LoadingSkeleton(
            width: 40,
            height: 40,
            borderRadius: BorderRadius.circular(20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoadingSkeleton(
                  width: double.infinity,
                  height: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                LoadingSkeleton(
                  width: 100,
                  height: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          LoadingSkeleton(
            width: 60,
            height: 24,
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
    );
  }

  /// Skeleton para tarjeta de métrica
  static Widget metricCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            LoadingSkeleton(
              width: 60,
              height: 60,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LoadingSkeleton(
                    width: double.infinity,
                    height: 16,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  LoadingSkeleton(
                    width: 80,
                    height: 32,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 4),
                  LoadingSkeleton(
                    width: 120,
                    height: 12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Skeleton para tarjeta de evento
  static Widget eventCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            LoadingSkeleton(
              width: 8,
              height: 60,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LoadingSkeleton(
                    width: double.infinity,
                    height: 18,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  LoadingSkeleton(
                    width: 150,
                    height: 14,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  LoadingSkeleton(
                    width: 100,
                    height: 12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
            LoadingSkeleton(
              width: 60,
              height: 20,
              borderRadius: BorderRadius.circular(10),
            ),
          ],
        ),
      ),
    );
  }

  /// Skeleton para acciones rápidas
  static Widget quickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LoadingSkeleton(
          width: 160,
          height: 20,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: LoadingSkeleton(
                width: double.infinity,
                height: 100,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LoadingSkeleton(
                width: double.infinity,
                height: 100,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: LoadingSkeleton(
                width: double.infinity,
                height: 100,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LoadingSkeleton(
                width: double.infinity,
                height: 100,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Skeleton para lista de métricas
  static Widget metricsList({int count = 2}) {
    return Column(
      children: List.generate(count, (index) => metricCard()),
    );
  }

  /// Skeleton para lista de eventos
  static Widget eventsList({int count = 2}) {
    return Column(
      children: List.generate(count, (index) => eventCard()),
    );
  }

  /// Skeleton para header de bienvenida
  static Widget welcomeHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.lightGray.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          LoadingSkeleton(
            width: 80,
            height: 80,
            borderRadius: BorderRadius.circular(40),
          ),
          const SizedBox(height: 16),
          LoadingSkeleton(
            width: 200,
            height: 24,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          LoadingSkeleton(
            width: 150,
            height: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  /// Skeleton para pantalla completa de dashboard
  static Widget dashboardPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          welcomeHeader(),
          const SizedBox(height: 16),
          quickActions(),
          const SizedBox(height: 16),
          LoadingSkeleton(
            width: 140,
            height: 20,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          metricsList(count: 2),
          const SizedBox(height: 16),
          LoadingSkeleton(
            width: 160,
            height: 20,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          eventsList(count: 2),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
