import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

/// Booking confirmation with an animated, bouncing check mark.
class BookingConfirmationDialog extends StatelessWidget {
  const BookingConfirmationDialog({super.key, required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.elasticOut,
              builder: (_, value, child) =>
                  Transform.scale(scale: value, child: child),
              child: Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                    color: AppColors.successBg, shape: BoxShape.circle),
                child: Center(
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                        color: AppColors.success, shape: BoxShape.circle),
                    child: const Icon(Icons.check, color: Colors.white, size: 34),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Request submitted!',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text(
              '${booking.facilityName}\n${longDate(booking.date)}\n${rangeLabel(booking.slotHour, booking.durationMinutes)}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, height: 1.5),
            ),
            const SizedBox(height: 12),
            Text('${rupees(booking.amount)} · Pending approval',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.blue)),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('View my bookings'),
        ),
      ],
    );
  }
}
