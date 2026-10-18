import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/booking.dart';
import '../models/facility.dart';
import '../providers/scheduler_provider.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/responsive.dart';
import '../utils/sport_style.dart';
import '../widgets/filter_pill.dart';
import '../widgets/message_view.dart';
import '../widgets/page_header.dart';
import '../widgets/status_chip.dart';
import '../widgets/surface.dart';

/// Admin dashboard: approve/reject bookings, manage facilities, list users.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key, this.standalone = false});

  /// True on the dedicated /admin page (hides the student header buttons).
  final bool standalone;

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _section = 0; // 0 bookings, 1 facilities, 2 users
  BookingStatus? _filter;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SchedulerProvider>().loadAdmin();
    });
    // New registrations and booking requests show up without reloading the page.
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) context.read<SchedulerProvider>().loadAdmin();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _clean(Object e) => e.toString().replaceFirst('Exception: ', '');

  Future<void> _setStatus(Booking b, BookingStatus s) async {
    final p = context.read<SchedulerProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await p.setBookingStatus(b.id, s);
      messenger.showSnackBar(
          SnackBar(content: Text('Booking ${s.label.toLowerCase()}')));
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('Could not update: ${_clean(e)}')));
    }
  }

  Future<void> _editFacility([Facility? existing]) async {
    final p = context.read<SchedulerProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<Facility>(
        context: context, builder: (_) => _FacilityDialog(existing: existing));
    if (result == null) return;
    try {
      await p.saveFacility(result, isNew: existing == null);
      messenger.showSnackBar(SnackBar(
          content:
              Text(existing == null ? 'Facility added' : 'Facility updated')));
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('Could not save: ${_clean(e)}')));
    }
  }

  Future<void> _deleteFacility(Facility f) async {
    final p = context.read<SchedulerProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${f.name}?'),
        content:
            const Text('The facility and all of its bookings will be removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await p.deleteFacility(f.id);
      messenger.showSnackBar(const SnackBar(content: Text('Facility deleted')));
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('Could not delete: ${_clean(e)}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SchedulerProvider>();

    return LayoutBuilder(builder: (context, c) {
      final pad = pagePadding(c.maxWidth);
      return RefreshIndicator(
        onRefresh: p.loadAdmin,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(pad, 24, pad, 32),
          children: [
            PageHeader(
                title: 'Admin Dashboard',
                actions: !widget.standalone,
                subtitle:
                    'Review requests, manage facilities and see who is using them.'),
            const SizedBox(height: 24),
            if (p.adminError != null)
              SurfaceCard(
                child: MessageView(
                  icon: Icons.cloud_off,
                  title: 'Could not load admin data',
                  subtitle: p.adminError,
                  actionLabel: 'Retry',
                  onAction: p.loadAdmin,
                ),
              )
            else ...[
              _stats(p),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(spacing: 10, runSpacing: 10, children: [
                      for (final e
                          in const ['Bookings', 'Facilities', 'Users'].asMap().entries)
                        FilterPill(
                            label: e.value,
                            selected: _section == e.key,
                            onTap: () {
                              setState(() => _section = e.key);
                              p.loadAdmin();
                            }),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  _refreshButton(p),
                ],
              ),
              const SizedBox(height: 20),
              if (p.adminLoading && p.adminBookings.isEmpty && p.users.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_section == 0)
                ..._bookings(p)
              else if (_section == 1)
                ..._facilities(p)
              else
                ..._users(p),
            ],
          ],
        ),
      );
    });
  }

  // ---------------------------------------------------------------- stats
  String _two(int n) => n.toString().padLeft(2, '0');

  Widget _refreshButton(SchedulerProvider p) {
    final t = p.adminUpdatedAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 42)),
          onPressed: p.adminLoading ? null : p.loadAdmin,
          icon: p.adminLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.refresh, size: 18),
          label: const Text('Refresh'),
        ),
        if (t != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('Updated ${_two(t.hour)}:${_two(t.minute)}:${_two(t.second)}',
                style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ),
      ],
    );
  }

  Widget _stats(SchedulerProvider p) {
    final pending =
        p.adminBookings.where((b) => b.status == BookingStatus.pending).length;
    final confirmed = p.adminBookings
        .where((b) => b.status == BookingStatus.approved)
        .toList();
    final revenue = confirmed.fold<int>(0, (a, b) => a + b.amount);
    final students = p.users.where((u) => !u.isAdmin).length;

    Widget tile(String label, String value, IconData icon, {Color? color}) =>
        SizedBox(
          width: 180,
          child: SurfaceCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color ?? AppColors.blue),
                const SizedBox(height: 10),
                Text(value,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w800)),
                Text(label,
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.muted)),
              ],
            ),
          ),
        );

    return Wrap(spacing: 14, runSpacing: 14, children: [
      tile('Pending requests', '$pending', Icons.hourglass_top,
          color: AppColors.warning),
      tile('Confirmed bookings', '${confirmed.length}',
          Icons.check_circle_outline,
          color: AppColors.success),
      tile('Confirmed revenue', rupees(revenue), Icons.payments_outlined),
      tile('Facilities', '${p.facilities.length}', Icons.stadium_outlined),
      tile('Students', '$students', Icons.groups_outlined),
    ]);
  }

  // ------------------------------------------------------------- bookings
  List<Widget> _bookings(SchedulerProvider p) {
    final filters = <BookingStatus?>[
      null,
      BookingStatus.pending,
      BookingStatus.approved,
      BookingStatus.rejected,
      BookingStatus.cancelled,
      BookingStatus.completed,
    ];
    final shown = p.adminBookings
        .where((b) => _filter == null || p.displayStatus(b) == _filter)
        .toList();

    return [
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final f in filters)
          FilterPill(
              label: f?.label ?? 'All',
              selected: _filter == f,
              onTap: () => setState(() => _filter = f)),
      ]),
      const SizedBox(height: 16),
      if (shown.isEmpty)
        const SurfaceCard(
            child: MessageView(
                icon: Icons.inbox_outlined,
                title: 'No bookings here',
                subtitle: 'Nothing matches this filter yet.'))
      else
        for (final b in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _bookingCard(p, b),
          ),
    ];
  }

  Widget _bookingCard(SchedulerProvider p, Booking b) {
    final s = p.displayStatus(b);
    final canAct = s == BookingStatus.pending;
    final canCancel = s == BookingStatus.approved;
    return SurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(b.facilityName.toUpperCase(),
                    style: AppText.display(15)),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: StatusChip(s, key: ValueKey(s)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 20, runSpacing: 8, children: [
            _info(Icons.calendar_today_outlined, shortDate(b.date)),
            _info(Icons.schedule, rangeLabel(b.slotHour, b.durationMinutes)),
            _info(Icons.person_outline, '${b.studentName} (ID ${b.studentId})'),
            _info(Icons.groups_outlined, '${b.players} players'),
            _info(Icons.payments_outlined, rupees(b.amount)),
          ]),
          if (canAct || canCancel) ...[
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (canAct) ...[
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      minimumSize: const Size(0, 40)),
                  onPressed: () => _setStatus(b, BookingStatus.approved),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Approve'),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      minimumSize: const Size(0, 40)),
                  onPressed: () => _setStatus(b, BookingStatus.rejected),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Reject'),
                ),
              ],
              if (canCancel)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      minimumSize: const Size(0, 40)),
                  onPressed: () => _setStatus(b, BookingStatus.cancelled),
                  icon: const Icon(Icons.event_busy, size: 18),
                  label: const Text('Cancel booking'),
                ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _info(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.muted),
          const SizedBox(width: 6),
          Flexible(child: Text(text, style: const TextStyle(fontSize: 13.5))),
        ],
      );

  // ----------------------------------------------------------- facilities
  List<Widget> _facilities(SchedulerProvider p) => [
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: () => _editFacility(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add facility'),
          ),
        ),
        const SizedBox(height: 16),
        for (final f in p.facilities)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _facilityCard(f),
          ),
      ];

  Widget _facilityCard(Facility f) {
    final accent = SportStyle.color(f.sport);
    final first =
        f.slotHours.isEmpty ? 0 : f.slotHours.reduce((a, b) => a < b ? a : b);
    final last =
        f.slotHours.isEmpty ? 0 : f.slotHours.reduce((a, b) => a > b ? a : b);
    return SurfaceCard(
      padding: const EdgeInsets.all(18),
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
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(SportStyle.icon(f.sport), color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.name.toUpperCase(), style: AppText.display(15)),
                    Text('${f.sport} · ${f.location}',
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.muted)),
                  ],
                ),
              ),
              Text('${rupees(f.pricePerHour)}/hr',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.blue,
                      fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
              'Open ${timeLabel(first)} – ${timeLabel(last + 1)} · ${f.amenities.join(', ')}',
              style: const TextStyle(fontSize: 13, color: AppColors.muted)),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
              onPressed: () => _editFacility(f),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit'),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  minimumSize: const Size(0, 40)),
              onPressed: () => _deleteFacility(f),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Delete'),
            ),
          ]),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- users
  List<Widget> _users(SchedulerProvider p) {
    if (p.users.isEmpty) {
      return [
        const SurfaceCard(
            child:
                MessageView(icon: Icons.groups_outlined, title: 'No users yet'))
      ];
    }
    return [
      for (final u in p.users.reversed) // newest registrations first
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SurfaceCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.softBlue,
                  child: Text(
                      u.name.isEmpty ? '?' : u.name.trim()[0].toUpperCase(),
                      style: const TextStyle(
                          color: AppColors.blue, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.name,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('${u.email} · ID ${u.studentId}',
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.muted)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: u.isAdmin ? AppColors.softBlue : AppColors.tint,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(u.isAdmin ? 'Admin' : 'Student',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: u.isAdmin ? AppColors.blue : AppColors.muted)),
                ),
              ],
            ),
          ),
        ),
    ];
  }
}

/// Add / edit facility form.
class _FacilityDialog extends StatefulWidget {
  const _FacilityDialog({this.existing});
  final Facility? existing;

  @override
  State<_FacilityDialog> createState() => _FacilityDialogState();
}

class _FacilityDialogState extends State<_FacilityDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _sport;
  late final TextEditingController _location;
  late final TextEditingController _description;
  late final TextEditingController _amenities;
  late final TextEditingController _price;
  late int _first;
  late int _last;

  @override
  void initState() {
    super.initState();
    final f = widget.existing;
    _name = TextEditingController(text: f?.name ?? '');
    _sport = TextEditingController(text: f?.sport ?? '');
    _location = TextEditingController(text: f?.location ?? '');
    _description = TextEditingController(text: f?.description ?? '');
    _amenities = TextEditingController(text: f?.amenities.join(', ') ?? '');
    _price = TextEditingController(text: '${f?.pricePerHour ?? 200}');
    _first = (f == null || f.slotHours.isEmpty)
        ? 8
        : f.slotHours.reduce((a, b) => a < b ? a : b);
    _last = (f == null || f.slotHours.isEmpty)
        ? 20
        : f.slotHours.reduce((a, b) => a > b ? a : b);
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _sport,
      _location,
      _description,
      _amenities,
      _price
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v) => (v ?? '').trim().isEmpty ? 'Required' : null;

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      Facility(
        id: widget.existing?.id ?? '',
        name: _name.text.trim(),
        sport: _sport.text.trim(),
        location: _location.text.trim(),
        description: _description.text.trim(),
        amenities: _amenities.text
            .split(',')
            .map((a) => a.trim())
            .where((a) => a.isNotEmpty)
            .toList(),
        slotHours: [for (var h = _first; h <= _last; h++) h],
        pricePerHour: int.parse(_price.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget hourPicker(String label, int value, ValueChanged<int> onChanged) =>
        Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: value,
            decoration: InputDecoration(labelText: label),
            items: [
              for (var h = 0; h < 24; h++)
                DropdownMenuItem(value: h, child: Text(timeLabel(h))),
            ],
            onChanged: (v) => setState(() => onChanged(v ?? value)),
            validator: (_) =>
                _last < _first ? 'Must be after first slot' : null,
          ),
        );

    return AlertDialog(
      title: Text(widget.existing == null ? 'Add facility' : 'Edit facility'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: _required),
                const SizedBox(height: 12),
                TextFormField(
                    controller: _sport,
                    decoration: const InputDecoration(
                        labelText: 'Sport',
                        helperText:
                            'e.g. Basketball, Tennis, Football, Badminton'),
                    validator: _required),
                const SizedBox(height: 12),
                TextFormField(
                    controller: _location,
                    decoration: const InputDecoration(labelText: 'Location'),
                    validator: _required),
                const SizedBox(height: 12),
                TextFormField(
                    controller: _description,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: _required),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amenities,
                  decoration: const InputDecoration(
                      labelText: 'Amenities',
                      helperText: 'Separate with commas'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _price,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                      labelText: 'Price per hour (₹)', prefixText: '₹ '),
                  validator: (v) => (v ?? '').isEmpty ? 'Enter a price' : null,
                ),
                const SizedBox(height: 12),
                Row(children: [
                  hourPicker('First slot', _first, (v) => _first = v),
                  const SizedBox(width: 12),
                  hourPicker('Last slot starts', _last, (v) => _last = v),
                ]),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
