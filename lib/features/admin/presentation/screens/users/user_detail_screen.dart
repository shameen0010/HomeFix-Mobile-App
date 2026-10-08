import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/admin_feedback.dart';
import '../../../core/admin_format.dart';
import '../../../core/admin_theme.dart';
import '../../../core/admin_widgets.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../widgets/booking_ui.dart';
import '../../widgets/customer_actions.dart';

class UserDetailScreen extends StatefulWidget {
  const UserDetailScreen({super.key, required this.userId, required this.repository});
  final String userId;
  final AdminRepository repository;

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  late final Stream<AppUser?> _user = widget.repository.watchUser(widget.userId);
  late final Stream<List<BookingModel>> _bookings =
      widget.repository.watchCustomerBookings(widget.userId);

  Future<void> _email(AppUser u) async {
    try {
      final ok = await launchUrl(Uri(scheme: 'mailto', path: u.email));
      if (!ok && mounted) {
        showAdminSnack(context, 'No email app available on this device.', error: true);
      }
    } catch (_) {
      if (mounted) showAdminSnack(context, 'Could not open the email app.', error: true);
    }
  }

  Future<void> _resetPassword(AppUser u) async {
    if (u.email.isEmpty) {
      showAdminSnack(context, 'This customer has no email on file.', error: true);
      return;
    }
    final ok = await confirmAction(context,
        title: 'Send reset link?',
        message: 'A password reset email will be sent to ${u.email}.',
        confirmLabel: 'Send');
    if (!ok || !mounted) return;
    await runAdminAction(context, () => widget.repository.sendPasswordReset(u.email),
        success: 'Reset link sent to ${u.email}');
  }

  Future<void> _copy(String text, String what) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) showAdminSnack(context, '$what copied');
  }

  Widget _copyButton(String text, String what) => IconButton(
        visualDensity: VisualDensity.compact,
        onPressed: () => _copy(text, what),
        icon: const Icon(Icons.copy_rounded, size: 18, color: AdminColors.grey),
      );

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(
        children: [
          AdminHeader(
              screenTitle: 'Customer Details',
              onBack: () => Navigator.of(context).pop()),
          Expanded(
            child: StreamBuilder<AppUser?>(
              stream: _user,
              builder: (context, snap) {
                if (snap.hasError) {
                  return ErrorView(message: 'Could not load customer.\n${snap.error}');
                }
                if (snap.connectionState == ConnectionState.waiting) {
                  return const LoadingView();
                }
                final u = snap.data;
                if (u == null) {
                  return const ErrorView(message: 'This customer no longer exists.');
                }
                return _body(u);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(AppUser u) {
    final rate = (u.completionRate * 100).round();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        AdminCard(
          child: Column(children: [
            Row(children: [
              AdminAvatar(
                name: u.name,
                photoUrl: u.photoUrl,
                radius: 34,
                badgeColor: u.isActive ? AdminColors.primary : AdminColors.red,
                badgeIcon: u.isActive ? Icons.check : Icons.close,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u.name, style: ts(18, w: FontWeight.w700)),
                    Text(u.code, style: ts(11.5, color: AdminColors.grey)),
                    Text('Customer since ${formatDate(u.createdAt, 'MMM yyyy')}',
                        style: ts(12, color: AdminColors.grey)),
                    const SizedBox(height: 6),
                    StatusPill(u.isActive ? 'Active Homeowner' : 'Suspended',
                        tone: u.isActive ? Tone.blue : Tone.red,
                        icon: Icons.circle,
                        size: 10.5),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                  child: AdminButton('Email',
                      icon: Icons.mail_outline_rounded,
                      height: 46,
                      onPressed: () => _email(u))),
              const SizedBox(width: 10),
              Expanded(
                  child: AdminButton('Reset Pass',
                      icon: Icons.lock_reset_rounded,
                      height: 46,
                      onPressed: () => _resetPassword(u))),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AdminCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text('Total Bookings',
                              style: ts(11, color: AdminColors.grey))),
                      const Icon(Icons.calendar_month_outlined,
                          size: 16, color: AdminColors.primary),
                    ]),
                    const SizedBox(height: 6),
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('${u.totalBookings}', style: ts(24, w: FontWeight.w700)),
                      const SizedBox(width: 6),
                      Text('$rate% rate',
                          style: ts(11, w: FontWeight.w600, color: const Color(0xFF047857))),
                    ]),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: u.totalBookings == 0 ? 0 : u.completionRate,
                        minHeight: 6,
                        backgroundColor:
                            u.totalBookings == 0 ? AdminColors.border : AdminColors.red,
                        valueColor: const AlwaysStoppedAnimation(AdminColors.primary),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('${u.completedBookings} Completed',
                          style: ts(10, color: AdminColors.primary)),
                      Text('${u.cancelledBookings} Cancelled',
                          style: ts(10, color: AdminColors.red)),
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AdminCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text('Total Spend',
                              style: ts(11, color: AdminColors.grey))),
                      const Icon(Icons.payments_outlined,
                          size: 16, color: AdminColors.orange),
                    ]),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(formatMoney(u.totalSpend),
                          style: ts(24, w: FontWeight.w700)),
                    ),
                    const SizedBox(height: 10),
                    const StatusPill('Cash on completion',
                        tone: Tone.grey, icon: Icons.check_circle_outline, size: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AdminCard(
          child: Column(children: [
            SectionTitle('Account Information',
                icon: Icons.badge_outlined,
                trailing: (u.emailVerified && u.phoneVerified)
                    ? const StatusPill('Verified Profile', tone: Tone.blue, size: 10)
                    : null),
            const SizedBox(height: 12),
            InfoField(label: 'Full Name', value: u.name, icon: Icons.person_outline),
            const SizedBox(height: 8),
            InfoField(
              label: u.emailVerified ? 'Verified Email' : 'Email',
              value: u.email.isEmpty ? '-' : u.email,
              verified: u.emailVerified,
              trailing: u.email.isEmpty ? null : _copyButton(u.email, 'Email'),
            ),
            const SizedBox(height: 8),
            InfoField(
              label: u.phoneVerified ? 'Verified Phone' : 'Phone',
              value: u.phone,
              verified: u.phoneVerified,
              trailing: u.phone == '-' ? null : _copyButton(u.phone, 'Phone'),
            ),
            const SizedBox(height: 8),
            InfoField(
                label: 'Default Home Address',
                value: u.address,
                trailing: const Icon(Icons.place_outlined,
                    size: 20, color: AdminColors.primary)),
          ]),
        ),
        const SizedBox(height: 12),
        AdminCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Recent Bookings', icon: Icons.history_rounded),
              const SizedBox(height: 10),
              StreamBuilder<List<BookingModel>>(
                stream: _bookings,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Text('Could not load bookings.',
                        style: ts(12.5, color: AdminColors.red));
                  }
                  if (!snap.hasData) {
                    return const Padding(
                        padding: EdgeInsets.all(12), child: LoadingView());
                  }
                  final items = snap.data!.take(5).toList();
                  if (items.isEmpty) {
                    return Text('No bookings yet.',
                        style: ts(12.5, color: AdminColors.grey));
                  }
                  return Column(children: [
                    for (final b in items) _bookingRow(b),
                  ]);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AdminCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Administrative Controls',
                  icon: Icons.admin_panel_settings_outlined),
              const SizedBox(height: 12),
              AdminButton('Edit Customer Info',
                  kind: ButtonKind.filled,
                  icon: Icons.edit_outlined,
                  height: 48,
                  onPressed: () => editCustomer(context, widget.repository, u)),
              const SizedBox(height: 8),
              AdminButton(
                  u.isActive ? 'Deactivate Customer Account' : 'Reactivate Customer Account',
                  kind: u.isActive ? ButtonKind.danger : ButtonKind.tonal,
                  icon: u.isActive ? Icons.person_off_outlined : Icons.power_settings_new_rounded,
                  height: 48,
                  onPressed: () => toggleCustomerStatus(context, widget.repository, u)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AdminColors.redBg, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shield_outlined, size: 18, color: AdminColors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Security note: Deactivation pauses active bookings and restricts homeowner app access instantly. Data retention policies comply with HomeFix Terms 4.1.',
                        style: ts(11.5, color: const Color(0xFF7F1D1D)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bookingRow(BookingModel b) {
    final (label, tone) = bookingStatusChip(b);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: AdminColors.field, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
              color: AdminColors.chipBg, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.build_rounded, size: 18, color: AdminColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${b.code}  |  ${formatDate(b.scheduledAt, 'MMM d')}',
                  style: ts(10.5, color: AdminColors.grey)),
              Text(b.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ts(13, w: FontWeight.w600)),
            ],
          ),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(formatMoney(b.amount), style: ts(13, w: FontWeight.w700)),
          Text(label, style: ts(10.5, w: FontWeight.w600, color: toneColor(tone))),
        ]),
      ]),
    );
  }
}
