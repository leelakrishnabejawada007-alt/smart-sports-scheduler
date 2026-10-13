import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/booking.dart';
import '../models/facility.dart';
import '../providers/scheduler_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/sport_style.dart';
import '../utils/validators.dart';
import 'confirmation_dialog.dart';
import 'filter_pill.dart';
import 'slot_chip.dart';

/// Opens the booking panel (dialog on tablet/desktop, bottom sheet on phones).
/// Handles the confirmation animation and jumps to "My Bookings" on success.
Future<void> showBookingModal(
  BuildContext context,
  Facility facility, {
  DateTime? date,
  int? hour,
  Booking? rescheduleOf,
}) async {
  final navigator = Navigator.of(context);
  final provider = context.read<SchedulerProvider>();
  final modal = BookingModal(
    facility: facility,
    initialDate: date,
    initialHour: hour,
    rescheduleOf: rescheduleOf,
  );
  final wide = MediaQuery.sizeOf(context).width >= 700;

  final Booking? result;
  if (wide) {
    result = await showGeneralDialog<Booking>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, _, __) => SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: 540, maxHeight: MediaQuery.sizeOf(ctx).height - 48),
              child: Material(
                color: Colors.white,
                elevation: 8,
                borderRadius: BorderRadius.circular(24),
                clipBehavior: Clip.antiAlias,
                child: modal,
              ),
            ),
          ),
        ),
      ),
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
              scale: Tween(begin: 0.96, end: 1.0).animate(curved), child: child),
        );
      },
    );
  } else {
    result = await showModalBottomSheet<Booking>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => modal,
    );
  }

  if (result == null || !navigator.mounted) return;
  if (rescheduleOf != null) {
    await provider.cancelBooking(rescheduleOf.id); // replaces the old booking
  }
  if (!navigator.mounted) return;
  await showDialog<void>(
    context: navigator.context,
    barrierDismissible: false,
    builder: (_) => BookingConfirmationDialog(booking: result!),
  );
  provider.setTab(1);
  navigator.popUntil((r) => r.isFirst);
}

class BookingModal extends StatefulWidget {
  const BookingModal({
    super.key,
    required this.facility,
    this.initialDate,
    this.initialHour,
    this.rescheduleOf,
  });

  final Facility facility;
  final DateTime? initialDate;
  final int? initialHour;
  final Booking? rescheduleOf;

  @override
  State<BookingModal> createState() => _BookingModalState();
}

class _BookingModalState extends State<BookingModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _id;
  late DateTime _date;
  int? _hour;
  int _minutes = 60;
  int _players = 10;
  bool _submitting = false;
  String? _slotError;

  @override
  void initState() {
    super.initState();
    final p = context.read<SchedulerProvider>();
    final old = widget.rescheduleOf;
    _date = widget.initialDate != null ? dateOnly(widget.initialDate!) : p.today;
    _hour = widget.initialHour;
    _name = TextEditingController(text: old?.studentName ?? p.profileName);
    _id = TextEditingController(text: old?.studentId ?? p.profileId);
    if (old != null) {
      _minutes = old.durationMinutes;
      _players = old.players;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _id.dispose();
    super.dispose();
  }

  int? _effectiveHour(SchedulerProvider p) {
    final h = _hour;
    return (h != null && p.canBook(widget.facility, _date, h, _minutes)) ? h : null;
  }

  Future<void> _pickDate() async {
    final p = context.read<SchedulerProvider>();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: p.today,
      lastDate: addDays(p.today, 60),
    );
    if (picked != null) {
      setState(() {
        _date = dateOnly(picked);
        _hour = null;
        _slotError = null;
      });
    }
  }

  Future<void> _confirm() async {
    final p = context.read<SchedulerProvider>();
    final hour = _effectiveHour(p);
    setState(() => _slotError = hour == null ? 'Select a time slot' : null);
    final formOk = _formKey.currentState!.validate();
    if (!formOk || hour == null) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _submitting = true);
    try {
      final booking = await p.book(
        facility: widget.facility,
        date: _date,
        slotHour: hour,
        studentName: _name.text.trim(),
        studentId: _id.text.trim(),
        durationMinutes: _minutes,
        players: _players,
      );
      navigator.pop(booking);
    } on SlotUnavailableException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _hour = null;
        _slotError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      messenger.showSnackBar(
          const SnackBar(content: Text('Could not submit. Please try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SchedulerProvider>();
    final theme = Theme.of(context);
    final f = widget.facility;
    final hour = _effectiveHour(p);
    final total = (f.pricePerHour * _minutes / 60).round();
    final anySlot = f.slotHours.any((h) => p.canBook(f, _date, h, _minutes));
    final accent = SportStyle.color(f.sport);

    Widget label(String t) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(t,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
        );

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(SportStyle.icon(f.sport), color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          widget.rescheduleOf != null
                              ? 'Reschedule booking'
                              : 'Book a facility',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.muted)),
                      Text(f.name,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 20),
            label('Date'),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: Text(longDate(_date)),
              style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  minimumSize: const Size.fromHeight(48)),
            ),
            const SizedBox(height: 20),
            label('Available time slots'),
            if (!anySlot)
              const Text('No slots available on this date for this duration.',
                  style: TextStyle(color: AppColors.muted))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final h in f.slotHours)
                    SlotChip(
                      hour: h,
                      available: p.canBook(f, _date, h, _minutes),
                      selected: hour == h,
                      onSelected: () => setState(() {
                        _hour = h;
                        _slotError = null;
                      }),
                    ),
                ],
              ),
            if (_slotError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_slotError!,
                    style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
              ),
            const SizedBox(height: 20),
            label('Duration'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in const [30, 60, 120])
                  FilterPill(
                    label: durationLabel(m),
                    selected: _minutes == m,
                    onTap: () => setState(() => _minutes = m),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            label('Number of players'),
            Row(
              children: [
                _StepButton(
                    icon: Icons.remove,
                    onTap: _players > 1 ? () => setState(() => _players--) : null),
                SizedBox(
                  width: 56,
                  child: Text('$_players',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                _StepButton(
                    icon: Icons.add,
                    onTap: _players < 30 ? () => setState(() => _players++) : null),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                  labelText: 'Full name', prefixIcon: Icon(Icons.person_outline)),
              validator: Validators.name,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _id,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: const InputDecoration(
                  labelText: 'Student ID', prefixIcon: Icon(Icons.badge_outlined)),
              validator: Validators.studentId,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppColors.softBlue, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Price',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        Text(
                            '${rupees(f.pricePerHour)}/hour × ${durationLabel(_minutes)}',
                            style: const TextStyle(
                                fontSize: 12.5, color: AppColors.muted)),
                      ],
                    ),
                  ),
                  Text(rupees(total),
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.blue)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submitting ? null : _confirm,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : Text(widget.rescheduleOf != null
                      ? 'Confirm Reschedule'
                      : 'Confirm Booking'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        shape: CircleBorder(
            side: BorderSide(
                color: onTap == null ? AppColors.border : const Color(0xFFD3DAEA))),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon,
                size: 18, color: onTap == null ? AppColors.muted : AppColors.blue),
          ),
        ),
      );
}
