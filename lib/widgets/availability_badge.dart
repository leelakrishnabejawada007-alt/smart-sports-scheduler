import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// ● 10 slots available (green) · ● 3 slots left (orange) · ● Fully booked (red)
class AvailabilityBadge extends StatelessWidget {
  const AvailabilityBadge({super.key, required this.free});
  final int free;

  @override
  Widget build(BuildContext context) {
    final (color, label) = free == 0
        ? (AppColors.danger, 'Fully booked')
        : free <= 4
            ? (AppColors.warning, '$free slots left')
            : (AppColors.success, '$free slots available');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text)),
        ],
      ),
    );
  }
}
