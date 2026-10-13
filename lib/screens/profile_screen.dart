import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/booking.dart';
import '../providers/scheduler_provider.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../utils/session.dart';
import '../utils/validators.dart';
import '../widgets/page_header.dart';
import '../widgets/surface.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _id;

  @override
  void initState() {
    super.initState();
    final p = context.read<SchedulerProvider>();
    _name = TextEditingController(text: p.profileName);
    _id = TextEditingController(text: p.profileId);
  }

  @override
  void dispose() {
    _name.dispose();
    _id.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<SchedulerProvider>().setProfile(_name.text, _id.text);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Profile saved')));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SchedulerProvider>();
    final all = p.myBookings;
    final upcoming = all.where((b) {
      final s = p.displayStatus(b);
      return s == BookingStatus.pending || s == BookingStatus.approved;
    }).length;

    Widget stat(String label, String value, IconData icon) => SizedBox(
          width: 170,
          child: SurfaceCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: AppColors.blue),
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

    return LayoutBuilder(builder: (context, c) {
      final pad = pagePadding(c.maxWidth);
      return ListView(
        padding: EdgeInsets.fromLTRB(pad, 24, pad, 32),
        children: [
          const PageHeader(
              title: 'Profile',
              subtitle: 'Your details are used to pre-fill bookings.'),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(spacing: 14, runSpacing: 14, children: [
                    stat('Total bookings', '${all.length}',
                        Icons.event_note_outlined),
                    stat('Upcoming', '$upcoming', Icons.upcoming_outlined),
                    stat('Favorites', '${p.favoriteFacilities.length}',
                        Icons.favorite_border),
                  ]),
                  const SizedBox(height: 20),
                  SurfaceCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('User details',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 16)),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _name,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                                labelText: 'Full name',
                                prefixIcon: Icon(Icons.person_outline)),
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
                                labelText: ' ID',
                                prefixIcon: Icon(Icons.badge_outlined)),
                            validator: Validators.studentId,
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(50)),
                            onPressed: _save,
                            child: const Text('Save changes'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      foregroundColor: AppColors.danger,
                      side: BorderSide(
                          color: AppColors.danger.withValues(alpha: 0.4)),
                    ),
                    onPressed: () => logOut(context),
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Log out'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }
}
