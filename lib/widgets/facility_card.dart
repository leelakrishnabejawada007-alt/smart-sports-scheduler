import 'package:flutter/material.dart';

import '../models/facility.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/sport_style.dart';
import 'availability_badge.dart';
import 'surface.dart';

class FacilityCard extends StatelessWidget {
  const FacilityCard({
    super.key,
    required this.facility,
    required this.freeToday,
    required this.isFavorite,
    required this.onTap,
    required this.onBook,
    required this.onFavorite,
  });

  final Facility facility;
  final int freeToday;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onBook;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final accent = SportStyle.color(facility.sport);
    final extra = facility.amenities.length - 3;

    return HoverLift(
      radius: 26,
      onTap: onTap,
      builder: (hovered) => Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 92,
                child: Stack(
                  children: [
                    Positioned.fill(
                        child: ColoredBox(color: accent.withValues(alpha: 0.10))),
                    Center(
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: AppShadows.soft),
                        child: Icon(SportStyle.icon(facility.sport),
                            size: 28, color: accent),
                      ),
                    ),
                    Positioned(
                        left: 10, top: 10, child: AvailabilityBadge(free: freeToday)),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Material(
                        color: Colors.white,
                        shape: const CircleBorder(
                            side: BorderSide(color: AppColors.border)),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onFavorite,
                          child: Padding(
                            padding: const EdgeInsets.all(7),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                key: ValueKey(isFavorite),
                                size: 18,
                                color: isFavorite ? AppColors.danger : AppColors.muted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 12, 6, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(facility.name.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.display(15)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined,
                            size: 16, color: AppColors.muted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text('${facility.sport} · ${facility.location}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12.5, color: AppColors.muted)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ClipRect(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final a in facility.amenities.take(3)) _Tag(a),
                            if (extra > 0) _Tag('+$extra'),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(rupees(facility.pricePerHour),
                                style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.blue)),
                            const Text('per hour',
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.muted)),
                          ],
                        ),
                        const Spacer(),
                        OutlinedButton(
                          onPressed: onTap,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 40),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            textStyle: AppText.label(11, spacing: 1),
                          ),
                          child: const Text('DETAILS'),
                        ),
                        const SizedBox(width: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: hovered
                                ? [
                                    BoxShadow(
                                        color: AppColors.slate.withValues(alpha: 0.3),
                                        blurRadius: 14,
                                        offset: const Offset(0, 6))
                                  ]
                                : const [],
                          ),
                          child: FilledButton(
                            onPressed: onBook,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.slate,
                              minimumSize: const Size(0, 40),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              textStyle: AppText.label(11, spacing: 1.2),
                            ),
                            child: const Text('BOOK NOW'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
            color: AppColors.tint, borderRadius: BorderRadius.circular(8)),
        child: Text(text,
            style: const TextStyle(
                fontSize: 11.5, fontWeight: FontWeight.w500, color: AppColors.text)),
      );
}
