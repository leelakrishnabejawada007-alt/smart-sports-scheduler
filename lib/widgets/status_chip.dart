import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../theme/app_theme.dart';

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = switch (status) {
      BookingStatus.pending => (AppColors.warning, AppColors.warningBg),
      BookingStatus.approved => (AppColors.success, AppColors.successBg),
      BookingStatus.completed => (AppColors.blue, AppColors.softBlue),
      BookingStatus.cancelled => (AppColors.muted, const Color(0xFFF1F3F8)),
      BookingStatus.rejected => (AppColors.danger, AppColors.dangerBg),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(status.label,
              style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
}
