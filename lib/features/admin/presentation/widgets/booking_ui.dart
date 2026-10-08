import 'package:flutter/material.dart';

import '../../core/admin_feedback.dart';
import '../../core/admin_format.dart';
import '../../core/admin_theme.dart';
import '../../core/admin_widgets.dart';
import '../../data/models/booking_model.dart';
import '../../data/repositories/admin_repository.dart';

(String, Tone) bookingStatusChip(BookingModel b) {
  if (b.isEmergency && b.status == 'pending') return ('Emergency', Tone.orange);
  switch (b.status) {
    case 'in_progress':
      return ('In Progress', Tone.blue);
    case 'confirmed':
      return ('Confirmed', Tone.blue);
    case 'pending':
      return ('Pending', Tone.orange);
    case 'completed':
      return ('Completed', Tone.green);
    case 'cancelled':
      return ('Cancelled', Tone.red);
    default:
      return (b.status, Tone.grey);
  }
}

void showBookingDetails(
    BuildContext context, AdminRepository repo, BookingModel b) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetContext) {
      final (label, tone) = bookingStatusChip(b);
      return Theme(
        data: adminTheme,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(b.code, style: ts(15, w: FontWeight.w700)),
                  const SizedBox(width: 8),
                  StatusPill(label, tone: tone),
                ]),
                const SizedBox(height: 4),
                Text(b.title, style: ts(18, w: FontWeight.w700)),
                const SizedBox(height: 12),
                InfoField(label: 'Customer', value: b.customerName, icon: Icons.person_outline),
                const SizedBox(height: 8),
                InfoField(
                    label: 'Provider',
                    value: b.providerName ?? 'Unassigned',
                    icon: Icons.engineering_outlined),
                const SizedBox(height: 8),
                InfoField(label: 'Address', value: b.address, icon: Icons.place_outlined),
                const SizedBox(height: 8),
                InfoField(
                    label: 'Scheduled',
                    value: formatDate(b.scheduledAt, 'EEE, MMM d, yyyy - h:mm a'),
                    icon: Icons.schedule_rounded),
                const SizedBox(height: 8),
                InfoField(
                    label: 'Amount (cash on completion)',
                    value: formatMoney(b.amount),
                    icon: Icons.payments_outlined),
                if ((b.notes ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  InfoField(label: 'Customer notes', value: b.notes!, icon: Icons.notes_rounded),
                ],
                if (b.status == 'cancelled' && (b.cancelReason ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  InfoField(label: 'Cancellation reason', value: b.cancelReason!, icon: Icons.cancel_outlined),
                ],
                if (b.isActive) ...[
                  const SizedBox(height: 16),
                  AdminButton(
                    'Cancel booking',
                    kind: ButtonKind.danger,
                    icon: Icons.event_busy_rounded,
                    height: 46,
                    onPressed: () async {
                      final reason = await promptText(
                        sheetContext,
                        title: 'Cancel ${b.code}?',
                        hint: 'Reason for cancellation',
                        confirmLabel: 'Cancel booking',
                      );
                      if (reason == null || !sheetContext.mounted) return;
                      final ok = await runAdminAction(
                        sheetContext,
                        () => repo.cancelBooking(b.id, reason),
                        success: '${b.code} cancelled',
                      );
                      if (ok && sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}
