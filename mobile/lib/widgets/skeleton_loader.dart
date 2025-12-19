import 'package:flutter/material.dart';

/// A reusable skeleton loading widget that shows animated loading placeholders
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final bool isCircle;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = 8,
    this.isCircle = false,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
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
          width: widget.isCircle ? widget.height : widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(
              widget.isCircle ? widget.height / 2 : widget.borderRadius,
            ),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Pre-built skeleton layouts for common UI patterns
class SkeletonListItem extends StatelessWidget {
  final bool hasAvatar;
  final bool hasDescription;
  final int lines;

  const SkeletonListItem({
    super.key,
    this.hasAvatar = true,
    this.hasDescription = true,
    this.lines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasAvatar)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: SkeletonLoader(
                height: 48,
                width: 48,
                isCircle: true,
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLoader(height: 18, width: 200),
                const SizedBox(height: 8),
                if (hasDescription) ...[
                  for (int i = 0; i < lines; i++) ...[
                    SkeletonLoader(
                      height: 14,
                      width: i.isEven ? double.infinity : 180,
                    ),
                    const SizedBox(height: 6),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  final double height;
  final double width;
  final bool hasHeader;
  final bool hasFooter;

  const SkeletonCard({
    super.key,
    this.height = 180,
    this.width = double.infinity,
    this.hasHeader = true,
    this.hasFooter = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasHeader) ...[
            Row(
              children: [
                const SkeletonLoader(height: 24, width: 24, isCircle: true),
                const SizedBox(width: 12),
                const Expanded(
                  child: SkeletonLoader(height: 16, width: 120),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          SkeletonLoader(height: height - (hasHeader ? 56 : 0) - (hasFooter ? 40 : 0)),
          if (hasFooter) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SkeletonLoader(height: 14, width: 80),
                const SkeletonLoader(height: 14, width: 60),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class SkeletonGridItem extends StatelessWidget {
  final double height;
  final double width;
  final bool hasIcon;
  final bool hasTitle;
  final bool hasSubtitle;

  const SkeletonGridItem({
    super.key,
    this.height = 120,
    this.width = 120,
    this.hasIcon = true,
    this.hasTitle = true,
    this.hasSubtitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (hasIcon) ...[
            const SkeletonLoader(height: 40, width: 40, isCircle: true),
            const SizedBox(height: 12),
          ],
          if (hasTitle) ...[
            const SkeletonLoader(height: 16, width: 80),
            const SizedBox(height: 8),
          ],
          if (hasSubtitle) ...[
            const SkeletonLoader(height: 12, width: 60),
          ],
        ],
      ),
    );
  }
}
