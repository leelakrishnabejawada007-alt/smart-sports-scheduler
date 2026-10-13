import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/scheduler_provider.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'booking_modal.dart';
import 'surface.dart';

/// Two small insight cards: a dark gradient "recommended" banner and a
/// light "best time today" card.
class SmartInsights extends StatelessWidget {
  const SmartInsights({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SchedulerProvider>();
    if (!p.smartEnabled) return const SizedBox.shrink();
    final rec = p.recommendation();
    final best = p.bestHourToday();
    if (rec == null && best == null) return const SizedBox.shrink();

    final cards = <Widget>[
      if (rec != null) _recommended(context, p, rec),
      if (best != null) _bestTime(best),
    ];
    return LayoutBuilder(
      builder: (context, c) => c.maxWidth >= 720 && cards.length == 2
          ? Row(children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 16),
              Expanded(child: cards[1]),
            ])
          : Column(children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                cards[i],
              ],
            ]),
    );
  }

  Widget _recommended(BuildContext context, SchedulerProvider p, SmartPick rec) {
    final day = rec.date == p.today ? 'Today' : 'Tomorrow';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.slate, Color(0xFF16457A), AppColors.blue],
        ),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RECOMMENDED FOR YOU',
                    style: AppText.label(10.5, color: AppColors.blueLight, spacing: 1.6)),
                const SizedBox(height: 3),
                Text(rec.facility.name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.display(15, color: Colors.white)),
                const SizedBox(height: 2),
                Text(
                    '$day · ${timeLabel(rec.hour)} · ${rec.demand.replaceAll('demand', 'crowd')} · ${rupees(rec.facility.pricePerHour)}/hour',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.slate,
                minimumSize: const Size(0, 38),
                padding: const EdgeInsets.symmetric(horizontal: 18)),
            onPressed: () => showBookingModal(context, rec.facility,
                date: rec.date, hour: rec.hour),
            child: const Text('BOOK'),
          ),
        ],
      ),
    );
  }

  Widget _bestTime(BestHour best) => SurfaceCard(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.star_rounded, color: AppColors.warning, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BEST TIME TODAY',
                      style: AppText.label(10.5, color: AppColors.warning, spacing: 1.6)),
                  const SizedBox(height: 3),
                  Text(slotLabel(best.hour), style: AppText.display(15)),
                  const SizedBox(height: 2),
                  Text(
                      '${best.demand} · ${best.facilityCount} ${best.facilityCount == 1 ? 'facility' : 'facilities'} available',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                ],
              ),
            ),
          ],
        ),
      );
}
