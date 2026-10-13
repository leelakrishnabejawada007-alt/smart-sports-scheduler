import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class HoverBuilder extends StatefulWidget {
  const HoverBuilder({super.key, required this.builder});
  final Widget Function(BuildContext context, bool hovered) builder;

  @override
  State<HoverBuilder> createState() => _HoverBuilderState();
}

class _HoverBuilderState extends State<HoverBuilder> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: widget.builder(context, _hovered),
      );
}

/// White rounded container with a thin border and a very light shadow.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(20),
      this.radius = 24});
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.soft,
        ),
        child: child,
      );
}

/// Card that lifts slightly and deepens its shadow on hover.
class HoverLift extends StatelessWidget {
  const HoverLift({super.key, required this.builder, this.onTap, this.radius = 24});
  final Widget Function(bool hovered) builder;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) => HoverBuilder(
        builder: (context, hovered) => AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, hovered ? -4 : 0, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
                color: hovered ? const Color(0xFFD3DAEA) : AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: hovered ? 28 : 12,
                offset: Offset(0, hovered ? 10 : 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Material(
              color: Colors.transparent,
              child: InkWell(onTap: onTap, child: builder(hovered)),
            ),
          ),
        ),
      );
}
