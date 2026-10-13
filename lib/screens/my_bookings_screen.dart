import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/booking.dart';
import '../providers/scheduler_provider.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/responsive.dart';
import '../widgets/booking_modal.dart';
import '../widgets/message_view.dart';
import '../widgets/page_header.dart';
import '../widgets/status_chip.dart';
import '../widgets/surface.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Poll for status changes while something is still pending.
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      final p = context.read<SchedulerProvider>();
      if (p.myBookings.any((b) => b.status == BookingStatus.pending)) {
        p.refreshBookings();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _cancel(Booking b) async {
    final p = context.read<SchedulerProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this booking?'),
        content: Text(
            '${b.facilityName} · ${shortDate(b.date)} · ${timeLabel(b.slotHour)}\nThe slot will be released for others.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await p.cancelBooking(b.id);
      messenger.showSnackBar(const SnackBar(content: Text('Booking cancelled')));
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Could not cancel. Please try again.')));
    }
  }

  void _reschedule(Booking b) {
    final f = context.read<SchedulerProvider>().facilityById(b.facilityId);
    if (f != null) showBookingModal(context, f, rescheduleOf: b);
  }

  void _view(Booking b, BookingStatus status, String sport) {
    Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                  width: 110,
                  child: Text(k, style: const TextStyle(color: AppColors.muted))),
              Expanded(
                  child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600))),
            ],
          ),
        );
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(b.facilityName),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(alignment: Alignment.centerLeft, child: StatusChip(status)),
              const SizedBox(height: 10),
              row('Booking ID', b.id),
              row('Sport', sport),
              row('Date', longDate(b.date)),
              row('Time', rangeLabel(b.slotHour, b.durationMinutes)),
              row('Duration', durationLabel(b.durationMinutes)),
              row('Players', '${b.players}'),
              row('Amount', rupees(b.amount)),
              row('Booked by', '${b.studentName} (${b.studentId})'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SchedulerProvider>();
    final bookings = p.myBookings;

    return LayoutBuilder(builder: (context, c) {
      final pad = pagePadding(c.maxWidth);
      final table = c.maxWidth >= 1000;

      return RefreshIndicator(
        onRefresh: p.refreshBookings,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(pad, 24, pad, 32),
          children: [
            const PageHeader(
                title: 'My Bookings',
                subtitle: 'Track and manage your reservations.'),
            const SizedBox(height: 24),
            if (bookings.isEmpty)
              SurfaceCard(
                child: MessageView(
                  icon: Icons.event_busy,
                  title: 'No bookings yet',
                  subtitle: 'Pick a facility and request a time slot.',
                  actionLabel: 'Browse facilities',
                  onAction: () => p.setTab(0),
                ),
              )
            else if (table)
              _buildTable(p, bookings)
            else
              for (final b in bookings)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _buildCard(p, b),
                ),
          ],
        ),
      );
    });
  }

  String _sport(SchedulerProvider p, Booking b) =>
      p.facilityById(b.facilityId)?.sport ?? '-';

  Widget _actions(SchedulerProvider p, Booking b, BookingStatus s,
      {bool iconsOnly = false}) {
    final canModify = s == BookingStatus.pending || s == BookingStatus.approved;
    if (iconsOnly) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
              tooltip: 'View',
              visualDensity: VisualDensity.compact,
              onPressed: () => _view(b, s, _sport(p, b)),
              icon: const Icon(Icons.visibility_outlined, size: 20)),
          IconButton(
              tooltip: 'Reschedule',
              visualDensity: VisualDensity.compact,
              onPressed: canModify ? () => _reschedule(b) : null,
              icon: const Icon(Icons.event_repeat, size: 20)),
          IconButton(
              tooltip: 'Cancel',
              visualDensity: VisualDensity.compact,
              color: AppColors.danger,
              onPressed: canModify ? () => _cancel(b) : null,
              icon: const Icon(Icons.cancel_outlined, size: 20)),
        ],
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 38)),
          onPressed: () => _view(b, s, _sport(p, b)),
          icon: const Icon(Icons.visibility_outlined, size: 18),
          label: const Text('View'),
        ),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 38)),
          onPressed: canModify ? () => _reschedule(b) : null,
          icon: const Icon(Icons.event_repeat, size: 18),
          label: const Text('Reschedule'),
        ),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 38),
              foregroundColor: AppColors.danger,
              side: BorderSide(
                  color: canModify
                      ? AppColors.danger.withValues(alpha: 0.4)
                      : AppColors.border)),
          onPressed: canModify ? () => _cancel(b) : null,
          icon: const Icon(Icons.close, size: 18),
          label: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildCard(SchedulerProvider p, Booking b) {
    final s = p.displayStatus(b);
    return SurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(b.facilityName,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: StatusChip(s, key: ValueKey(s)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(_sport(p, b), style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 20,
            runSpacing: 10,
            children: [
              _info(Icons.calendar_today_outlined, shortDate(b.date)),
              _info(Icons.schedule, rangeLabel(b.slotHour, b.durationMinutes)),
              _info(Icons.timelapse, durationLabel(b.durationMinutes)),
              _info(Icons.payments_outlined, rupees(b.amount)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 14),
          _actions(p, b, s),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.muted),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 13.5)),
        ],
      );

  Widget _buildTable(SchedulerProvider p, List<Booking> bookings) {
    Widget head(String t, int flex) => Expanded(
        flex: flex,
        child: Text(t.toUpperCase(),
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: AppColors.muted)));
    Widget cell(String t, int flex, {bool bold = false}) => Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Text(t,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 13.5, fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
        ));

    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(children: [
              head('Facility', 3),
              head('Sport', 2),
              head('Date', 2),
              head('Time', 3),
              head('Duration', 2),
              head('Status', 3),
              head('Amount', 2),
              const SizedBox(width: 120, child: Text('')),
            ]),
          ),
          for (final b in bookings) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Builder(builder: (context) {
                final s = p.displayStatus(b);
                return Row(children: [
                  cell(b.facilityName, 3, bold: true),
                  cell(_sport(p, b), 2),
                  cell(shortDate(b.date), 2),
                  cell(rangeLabel(b.slotHour, b.durationMinutes), 3),
                  cell(durationLabel(b.durationMinutes), 2),
                  Expanded(
                    flex: 3,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        child: StatusChip(s, key: ValueKey(s)),
                      ),
                    ),
                  ),
                  cell(rupees(b.amount), 2, bold: true),
                  SizedBox(
                      width: 120,
                      child: _actions(p, b, s, iconsOnly: true)),
                ]);
              }),
            ),
          ],
        ],
      ),
    );
  }
}
