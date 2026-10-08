import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/customer_ui.dart';
import '../../data/models/booking_info.dart';
import '../../data/models/customer_profile.dart';
import '../../data/repositories/customer_repository.dart';
import '../widgets/customer_header.dart';
import 'addresses_screen.dart';
import 'edit_customer_profile_screen.dart';
import 'emergency_info_screen.dart';
import 'help_support_screen.dart';
import 'payment_methods_screen.dart';
import 'privacy_security_screen.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final _repo = CustomerRepository.instance;
  late final Stream<CustomerProfile?> _me = _repo.watchMe();
  late final Stream<List<BookingInfo>> _bookings = _repo.watchMyBookings();
  late final Stream<List<SavedAddress>> _addresses = _repo.watchAddresses();

  void _push(Widget w) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => w));

  Future<void> _changePhoto() async {
    try {
      final f = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 800);
      if (f == null || !mounted) return;
      final Uint8List bytes = await f.readAsBytes();
      if (!mounted) return;
      await runAdminAction(context, () => _repo.uploadAvatar(bytes), success: 'Profile photo updated');
    } catch (_) {
      if (mounted) showAdminSnack(context, 'Could not access your photos.', error: true);
    }
  }

  Future<void> _logout() async {
    final ok = await confirmAction(context,
        title: 'Log out?', message: 'You will need to sign in again to book services.',
        confirmLabel: 'Log out', destructive: true);
    if (!ok || !mounted) return;
    final done = await runAdminAction(context, _repo.signOut, success: 'Logged out');
    if (done && mounted) context.go('/login');
  }

  Widget _stat(IconData icon, String value, String label, {bool dot = false}) => Expanded(
        child: AdminCard(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(children: [
            Stack(clipBehavior: Clip.none, children: [
              CircleAvatar(radius: 16, backgroundColor: AdminColors.field,
                  child: Icon(icon, size: 17, color: AdminColors.primary)),
              if (dot)
                const Positioned(right: -2, top: -2,
                    child: CircleAvatar(radius: 4, backgroundColor: AdminColors.orange)),
            ]),
            const SizedBox(height: 6),
            Text(value, style: ts(18, w: FontWeight.w700)),
            Text(label, style: ts(10.5, color: AdminColors.grey)),
          ]),
        ),
      );

  Widget _row(IconData icon, String title, String sub, VoidCallback onTap, {Widget? trailing}) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(children: [
            CircleAvatar(radius: 18, backgroundColor: AdminColors.chipBg,
                child: Icon(icon, size: 18, color: AdminColors.primary)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: ts(13.5, w: FontWeight.w700)),
                Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: ts(11, color: AdminColors.grey)),
              ]),
            ),
            trailing ?? const Icon(Icons.chevron_right_rounded, color: AdminColors.grey),
          ]),
        ),
      );

  Widget _group(String title, List<Widget> rows) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 0, 6),
          child: Text(title, style: ts(10.5, w: FontWeight.w700, color: AdminColors.grey)),
        ),
        AdminCard(padding: const EdgeInsets.symmetric(vertical: 4), child: Column(children: rows)),
      ]);

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(children: [
        const CustomerHeader(title: 'Profile'),
        Expanded(
          child: StreamBuilder<CustomerProfile?>(
            stream: _me,
            builder: (context, snap) {
              if (snap.hasError) return ErrorView(message: 'Could not load your profile.\n${snap.error}');
              if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
              final me = snap.data;
              if (me == null) return const ErrorView(message: 'Profile not found.');
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  AdminCard(
                    child: Column(children: [
                      Stack(children: [
                        AdminAvatar(name: me.name, photoUrl: me.photoUrl, radius: 44),
                        Positioned(
                          right: 0, bottom: 0,
                          child: GestureDetector(
                            onTap: _changePhoto,
                            child: const CircleAvatar(radius: 14, backgroundColor: AdminColors.primary,
                                child: Icon(Icons.photo_camera_outlined, size: 15, color: Colors.white)),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      Text(me.name, style: ts(21, w: FontWeight.w700)),
                      const SizedBox(height: 4),
                      const StatusPill('VERIFIED MEMBER', icon: Icons.shield_outlined, size: 10),
                      const SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.mail_outline_rounded, size: 14, color: AdminColors.primary),
                        const SizedBox(width: 4),
                        Flexible(child: Text(me.email, style: ts(12, color: AdminColors.grey))),
                      ]),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.phone_outlined, size: 14, color: AdminColors.primary),
                        const SizedBox(width: 4),
                        Text(me.phone, style: ts(12, color: AdminColors.grey)),
                      ]),
                      const SizedBox(height: 12),
                      AdminButton('Edit Profile',
                          kind: ButtonKind.filled, icon: Icons.edit_outlined, height: 46,
                          onPressed: () => _push(EditCustomerProfileScreen(profile: me))),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<List<BookingInfo>>(
                    stream: _bookings,
                    builder: (context, bs) {
                      final list = bs.data ?? const <BookingInfo>[];
                      final done = list.where((b) => b.status == 'completed').length;
                      final live = list.where((b) => b.status == 'confirmed' || b.status == 'in_progress').toList();
                      return StreamBuilder<List<SavedAddress>>(
                        stream: _addresses,
                        builder: (context, adr) {
                          return Column(children: [
                            Row(children: [
                              _stat(Icons.check_circle_outline_rounded, '$done', 'Completed'),
                              const SizedBox(width: 8),
                              _stat(Icons.assignment_outlined, '${live.length}', 'In Progress', dot: live.isNotEmpty),
                              const SizedBox(width: 8),
                              _stat(Icons.place_outlined, '${adr.data?.length ?? 0}', 'Locations'),
                            ]),
                            if (live.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: () => CustomerNav.goTab(2),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: AdminColors.chipBg, borderRadius: BorderRadius.circular(14)),
                                  child: Row(children: [
                                    const Icon(Icons.build_rounded, color: AdminColors.primary),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Row(children: [
                                          Flexible(child: Text(live.first.title, style: ts(12.5, w: FontWeight.w700))),
                                          const SizedBox(width: 6),
                                          if (live.first.scheduledAt != null &&
                                              DateUtils.isSameDay(live.first.scheduledAt, DateTime.now()))
                                            const StatusPill('TODAY', tone: Tone.orange, size: 9),
                                        ]),
                                        Text('${live.first.providerName}  |  ${startsIn(live.first.scheduledAt)}',
                                            style: ts(10.5, color: AdminColors.grey)),
                                      ]),
                                    ),
                                    const Icon(Icons.chevron_right_rounded, color: AdminColors.primary),
                                  ]),
                                ),
                              ),
                            ],
                          ]);
                        },
                      );
                    },
                  ),
                  _group('ACCOUNT & PREFERENCES', [
                    StreamBuilder<List<SavedAddress>>(
                      stream: _addresses,
                      builder: (context, snap) {
                        final l = snap.data ?? const <SavedAddress>[];
                        return _row(Icons.location_on_outlined, 'My Addresses',
                            l.isEmpty ? 'Add your home or office' : l.map((a) => a.label).join(', '),
                            () => _push(const AddressesScreen()),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              StatusPill('${l.length} saved', tone: Tone.blue, size: 9.5),
                              const Icon(Icons.chevron_right_rounded, color: AdminColors.grey),
                            ]));
                      },
                    ),
                    const Divider(height: 1),
                    _row(Icons.credit_card_outlined, 'Payment Methods', 'Cash on completion (default)',
                        () => _push(const PaymentMethodsScreen())),
                    const Divider(height: 1),
                    _row(Icons.contact_emergency_outlined, 'Emergency Contacts & Notes',
                        'Gate codes, pet safety, secondary phone', () => _push(EmergencyInfoScreen(profile: me))),
                    const Divider(height: 1),
                    _row(Icons.notifications_active_outlined, 'Service Status Alerts',
                        'SMS and live technician push updates', () {},
                        trailing: Switch(
                          value: me.alertsEnabled,
                          onChanged: (v) => runAdminAction(context, () => _repo.setAlerts(v),
                              success: v ? 'Alerts turned on' : 'Alerts turned off', showLoader: false),
                        )),
                  ]),
                  _group('SUPPORT & TRUST', [
                    _row(Icons.support_agent_rounded, 'Help & Support / FAQs', '24/7 HomeFix customer care helpline',
                        () => _push(const HelpSupportScreen())),
                    const Divider(height: 1),
                    _row(Icons.shield_outlined, 'Privacy & Security', 'Data permissions and password',
                        () => _push(const PrivacySecurityScreen())),
                  ]),
                  const SizedBox(height: 16),
                  AdminButton('Log Out', kind: ButtonKind.danger, icon: Icons.logout_rounded, height: 50, onPressed: _logout),
                  const SizedBox(height: 10),
                  Center(child: Text('HomeFix v${ProviderConfig.appVersion.split(' ').first}  |  Safe Home Guarantee',
                      style: ts(10.5, color: AdminColors.grey))),
                ],
              );
            },
          ),
        ),
      ]),
    );
  }
}
