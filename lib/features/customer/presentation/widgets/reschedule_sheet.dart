import 'package:flutter/material.dart';

import '../../../provider/data/models/provider_profile.dart';
import '../../core/customer_ui.dart';
import '../../data/models/booking_info.dart';
import '../../data/repositories/customer_repository.dart';
import 'booking_widgets.dart';

/// Bottom sheet that moves a pending/confirmed booking to a new arrival window.
Future<void> showRescheduleSheet(BuildContext context, BookingInfo b) {
  if (!b.hasProvider) {
    showAdminSnack(context, 'Wait until a provider is assigned before rescheduling.', error: true);
    return Future<void>.value();
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _RescheduleSheet(booking: b),
  );
}

class _RescheduleSheet extends StatefulWidget {
  const _RescheduleSheet({required this.booking});
  final BookingInfo booking;

  @override
  State<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<_RescheduleSheet> {
  final _repo = CustomerRepository.instance;
  late final Stream<ProviderProfile?> _provider = _repo.watchProvider(widget.booking.providerId);
  DateTime? _slot;

  Future<void> _save() async {
    final at = _slot;
    if (at == null) {
      showAdminSnack(context, 'Choose a new arrival window.', error: true);
      return;
    }
    final ok = await runAdminAction(
      context,
      () => _repo.rescheduleBooking(widget.booking.id, at),
      success: 'Rescheduled. Waiting for the provider to accept the new time.',
    );
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: StreamBuilder<ProviderProfile?>(
        stream: _provider,
        builder: (context, snap) {
          if (snap.hasError) return const SizedBox(height: 160, child: ErrorView(message: 'Could not load availability.'));
          if (!snap.hasData) return const SizedBox(height: 160, child: LoadingView());
          final p = snap.data;
          if (p == null) return const SizedBox(height: 160, child: ErrorView(message: 'This provider is no longer available.'));
          return SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Reschedule ${b.code}', style: ts(18, w: FontWeight.w700)),
              Text('Currently ${formatDate(b.scheduledAt, 'EEE, MMM d \u2022 h:mm a')}. The provider must accept the new time.',
                  style: ts(11.5, color: AdminColors.grey)),
              const SizedBox(height: 14),
              SlotPicker(provider: p, onChanged: (t) => setState(() => _slot = t)),
              const SizedBox(height: 16),
              AdminButton('Confirm new time', kind: ButtonKind.filled, height: 48, onPressed: _save),
            ]),
          );
        },
      ),
    );
  }
}
