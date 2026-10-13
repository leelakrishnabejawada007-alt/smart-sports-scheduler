import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/facility.dart';
import '../providers/scheduler_provider.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/responsive.dart';
import '../utils/sport_style.dart';
import '../widgets/availability_badge.dart';
import '../widgets/booking_modal.dart';
import '../widgets/page_header.dart';
import '../widgets/slot_chip.dart';
import '../widgets/surface.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _selected;
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final today = context.read<SchedulerProvider>().today;
    _selected = today;
    _month = DateTime(today.year, today.month);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SchedulerProvider>();
    return LayoutBuilder(builder: (context, c) {
      final pad = pagePadding(c.maxWidth);
      final wide = c.maxWidth >= 980;
      final calendar = _monthCard(p);
      final panel = _availability(p);
      return ListView(
        padding: EdgeInsets.fromLTRB(pad, 24, pad, 32),
        children: [
          const PageHeader(
              title: 'Calendar',
              subtitle: 'Pick a date, check availability and create a booking.'),
          const SizedBox(height: 24),
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 380, child: calendar),
                const SizedBox(width: 24),
                Expanded(child: panel),
              ],
            )
          else ...[calendar, const SizedBox(height: 24), panel],
        ],
      );
    });
  }

  Widget _monthCard(SchedulerProvider p) {
    final first = DateTime(_month.year, _month.month);
    final offset = first.weekday - 1;
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final rows = ((offset + days) / 7).ceil();
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SurfaceCard(
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                  onPressed: () => setState(
                      () => _month = DateTime(_month.year, _month.month - 1)),
                  icon: const Icon(Icons.chevron_left)),
              Expanded(
                child: Text(monthYear(_month),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
              IconButton(
                  onPressed: () => setState(
                      () => _month = DateTime(_month.year, _month.month + 1)),
                  icon: const Icon(Icons.chevron_right)),
            ],
          ),
          const SizedBox(height: 8),
          Row(children: [
            for (final d in weekdays)
              Expanded(
                child: Center(
                  child: Text(d,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted)),
                ),
              ),
          ]),
          const SizedBox(height: 6),
          for (var r = 0; r < rows; r++)
            Row(children: [
              for (var col = 0; col < 7; col++)
                Expanded(child: _dayCell(p, r * 7 + col - offset + 1, days)),
            ]),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      color: AppColors.blue, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              const Text('You have a booking',
                  style: TextStyle(fontSize: 12, color: AppColors.muted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dayCell(SchedulerProvider p, int day, int days) {
    if (day < 1 || day > days) return const SizedBox(height: 46);
    final d = DateTime(_month.year, _month.month, day);
    final selected = dateOnly(d) == dateOnly(_selected);
    final isToday = dateOnly(d) == p.today;
    final past = d.isBefore(p.today);
    final fg = selected
        ? Colors.white
        : past
            ? const Color(0xFF9AA3B8)
            : AppColors.text;
    return SizedBox(
      height: 46,
      child: Center(
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => setState(() => _selected = d),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? AppColors.blue : Colors.transparent,
              border: isToday && !selected
                  ? Border.all(color: AppColors.blue)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$day',
                    style: TextStyle(
                        color: fg,
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 14)),
                if (p.hasBookingOn(d))
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? Colors.white : AppColors.blue),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _availability(SchedulerProvider p) {
    Widget legend(Color bg, Color border, String t) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: border)),
            ),
            const SizedBox(width: 6),
            Text(t, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(longDate(_selected),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 10),
        Wrap(spacing: 16, runSpacing: 6, children: [
          legend(Colors.white, const Color(0xFFD3DAEA), 'Available'),
          legend(const Color(0xFFF1F3F8), const Color(0xFFF1F3F8), 'Booked / past'),
          legend(AppColors.softBlue, AppColors.softBlue, 'Your booking'),
        ]),
        const SizedBox(height: 16),
        for (final f in p.facilities)
          Padding(padding: const EdgeInsets.only(bottom: 14), child: _facilityRow(p, f)),
      ],
    );
  }

  Widget _facilityRow(SchedulerProvider p, Facility f) {
    final accent = SportStyle.color(f.sport);
    return SurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(SportStyle.icon(f.sport), color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('${f.sport} · ${f.location}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AvailabilityBadge(free: p.availableCount(f, _selected)),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final h in f.slotHours)
                SlotChip(
                  hour: h,
                  available: p.isAvailable(f, _selected, h),
                  mine: p.isMine(f.id, _selected, h),
                  selected: false,
                  onSelected: () =>
                      showBookingModal(context, f, date: _selected, hour: h),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
              onPressed: () => showBookingModal(context, f, date: _selected),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create booking'),
            ),
          ),
        ],
      ),
    );
  }
}
