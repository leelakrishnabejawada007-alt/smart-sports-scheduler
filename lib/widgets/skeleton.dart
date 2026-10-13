import 'package:flutter/material.dart';

import 'surface.dart';

class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.width, this.height = 14, this.radius = 8});
  final double? width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween(begin: 0.5, end: 1.0)
            .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: const Color(0xFFE6EAF3),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      );
}

class FacilityCardSkeleton extends StatelessWidget {
  const FacilityCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => SurfaceCard(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Skeleton(height: 108, radius: 0, width: double.infinity),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Skeleton(width: 180, height: 18),
                    SizedBox(height: 10),
                    Skeleton(width: 140, height: 12),
                    SizedBox(height: 14),
                    Row(children: [
                      Skeleton(width: 64, height: 22),
                      SizedBox(width: 6),
                      Skeleton(width: 72, height: 22),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
