import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/facility.dart';
import '../providers/scheduler_provider.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/sport_style.dart';
import '../widgets/availability_badge.dart';
import '../widgets/booking_modal.dart';
import '../widgets/slot_chip.dart';
import '../widgets/surface.dart';

class FacilityDetailScreen extends StatefulWidget {
  const FacilityDetailScreen({super.key, required this.facility});
  final Facility facility;

  @override
  State<FacilityDetailScreen> createState() => _FacilityDetailScreenState();
}

class _FacilityDetailScreenState extends State<FacilityDetailScreen> {
  late DateTime _date;
  int? _hour;

  @override
  void initState() {
    super.initState();
    _date = context.read<SchedulerProvider>().today;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SchedulerProvider>();
    final f = widget.facility;
    // Drop the selection if the slot became unavailable meanwhile.
    final hour = (_hour != null && p.isAvailable(f, _date, _hour!)) ? _hour : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(f.name),
        actions: [
          IconButton(
            tooltip: 'Favorite',
            onPressed: () => p.toggleFavorite(f.id),
            icon: Icon(
              p.isFavorite(f.id) ? Icons.favorite : Icons.favorite_border,
              color: p.isFavorite(f.id) ? AppColors.danger : AppColors.muted,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 800;
        final info = _buildInfo(context, p);
        final scheduler = _buildScheduler(context, p, hour);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 4, child: info),
                        const SizedBox(width: 20),
                        Expanded(flex: 5, child: scheduler),
                      ],
                    )
                  : Column(children: [info, const SizedBox(height: 16), scheduler]),
            ),
          ),
        );
      }),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(hour == null
                      ? 'Select a time slot'
                      : 'Book ${slotLabel(hour)}'),
                  onPressed: hour == null
                      ? null
                      : () => showBookingModal(context, f, date: _date, hour: hour),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context, SchedulerProvider p) {
    final theme = Theme.of(context);
    final f = widget.facility;
    final accent = SportStyle.color(f.sport);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 140,
            width: double.infinity,
            color: accent.withValues(alpha: 0.10),
            child: Center(
              child: Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.soft),
                child: Icon(SportStyle.icon(f.sport), size: 42, color: accent),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(f.name,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800)),
                    ),
                    Text('${rupees(f.pricePerHour)}/hr',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.blue,
                            fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.place_outlined, size: 18, color: AppColors.muted),
                  const SizedBox(width: 4),
                  Expanded(
                      child: Text('${f.sport} · ${f.location}',
                          style: const TextStyle(color: AppColors.muted))),
                ]),
                const SizedBox(height: 14),
                Text(f.description, style: const TextStyle(height: 1.5)),
                const SizedBox(height: 18),
                Text('Amenities',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final a in f.amenities)
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                            color: AppColors.tint,
                            borderRadius: BorderRadius.circular(10)),
                        child: Text(a, style: const TextStyle(fontSize: 13)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduler(BuildContext context, SchedulerProvider p, int? hour) {
    final theme = Theme.of(context);
    final f = widget.facility;
    final dates = [for (var i = 0; i < 7; i++) addDays(p.today, i)];

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choose a date',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: dates.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => _DateTile(
                date: dates[i],
                selected: dateOnly(dates[i]) == dateOnly(_date),
                onTap: () => setState(() {
                  _date = dates[i];
                  _hour = null;
                }),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: Text('Time slots',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              AvailabilityBadge(free: p.availableCount(f, _date)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final h in f.slotHours)
                SlotChip(
                  hour: h,
                  available: p.isAvailable(f, _date, h),
                  mine: p.isMine(f.id, _date, h),
                  selected: hour == h,
                  onSelected: () => setState(() => _hour = h),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Text('Crossed-out slots are already booked or have passed.',
              style: TextStyle(fontSize: 12, color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile(
      {required this.date, required this.selected, required this.onTap});
  final DateTime date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.text;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 58,
      decoration: BoxDecoration(
        color: selected ? AppColors.blue : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: selected ? AppColors.blue : AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(shortDay(date), style: TextStyle(color: fg, fontSize: 12)),
              const SizedBox(height: 2),
              Text('${date.day}',
                  style: TextStyle(
                      color: fg, fontSize: 20, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}
