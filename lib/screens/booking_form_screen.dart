import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/facility.dart';
import '../providers/scheduler_provider.dart';
import '../services/api_service.dart';
import '../utils/format.dart';
import '../utils/validators.dart';
import '../widgets/confirmation_dialog.dart';

class BookingFormScreen extends StatefulWidget {
  const BookingFormScreen({
    super.key,
    required this.facility,
    required this.date,
    required this.slotHour,
  });

  final Facility facility;
  final DateTime date;
  final int slotHour;

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _id = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _id.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<SchedulerProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _submitting = true);

    try {
      final booking = await provider.book(
        facility: widget.facility,
        date: widget.date,
        slotHour: widget.slotHour,
        studentName: _name.text.trim(),
        studentId: _id.text.trim(),
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => BookingConfirmationDialog(booking: booking),
      );
      provider.setTab(1); // jump to "My bookings"
      navigator.popUntil((r) => r.isFirst);
    } on SlotUnavailableException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      navigator.pop(); // back to the slot picker, now refreshed
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      messenger.showSnackBar(
          const SnackBar(content: Text('Could not submit. Please try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = widget.facility;
    return Scaffold(
      appBar: AppBar(title: const Text('Booking request')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(f.name,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        Row(children: [
                          const Icon(Icons.calendar_today, size: 18),
                          const SizedBox(width: 8),
                          Text(longDate(widget.date)),
                        ]),
                        const SizedBox(height: 6),
                        Row(children: [
                          const Icon(Icons.schedule, size: 18),
                          const SizedBox(width: 8),
                          Text(slotLabel(widget.slotHour)),
                        ]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: Validators.name,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _id,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'ID',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: Validators.studentId,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5))
                      : const Text('Submit booking request'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
