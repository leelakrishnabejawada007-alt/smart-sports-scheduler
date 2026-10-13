import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'surface.dart';

class FilterPill extends StatelessWidget {
  const FilterPill(
      {super.key, required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => HoverBuilder(
        builder: (context, hovered) => AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.blue
                : hovered
                    ? AppColors.tint
                    : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: selected ? AppColors.blue : AppColors.border),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 160),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selected) ...[
                        const Icon(Icons.check, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                      ],
                      Text(label,
                          style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : AppColors.text)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
