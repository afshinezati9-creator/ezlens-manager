import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class AppSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const AppSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = AppSpacing.radiusSm,
  });

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.28, end: 0.62).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
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
            color: AppColors.border.withValues(alpha: _animation.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

/// Stat / metric card placeholder (dashboard style).
class AppSkeletonCard extends StatelessWidget {
  const AppSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppSkeleton(width: 36, height: 36, borderRadius: 10),
          SizedBox(height: 14),
          AppSkeleton(width: 72, height: 22, borderRadius: 6),
          SizedBox(height: 10),
          AppSkeleton(width: 56, height: 12, borderRadius: 4),
        ],
      ),
    );
  }
}

/// One list-row placeholder (avatar + two lines).
class AppSkeletonListTile extends StatelessWidget {
  const AppSkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          AppSkeleton(width: 44, height: 44, borderRadius: 10),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeleton(width: double.infinity, height: 14, borderRadius: 4),
                SizedBox(height: 8),
                AppSkeleton(width: 120, height: 11, borderRadius: 4),
              ],
            ),
          ),
          SizedBox(width: 10),
          AppSkeleton(width: 48, height: 12, borderRadius: 4),
        ],
      ),
    );
  }
}

/// Vertical list of skeleton rows — use while pages load.
class AppSkeletonList extends StatelessWidget {
  final int itemCount;
  final EdgeInsetsGeometry padding;

  const AppSkeletonList({
    super.key,
    this.itemCount = 6,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      itemCount: itemCount,
      itemBuilder: (_, __) => const AppSkeletonListTile(),
    );
  }
}

/// Grid of skeleton cards (e.g. 4 status cards).
class AppSkeletonGrid extends StatelessWidget {
  final int count;
  final int crossAxisCount;

  const AppSkeletonGrid({
    super.key,
    this.count = 4,
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: crossAxisCount >= 4 ? 1.55 : 1.35,
      ),
      itemBuilder: (_, __) => const AppSkeletonCard(),
    );
  }
}
