import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/hf_theme.dart';
import '../../core/widgets/hf_widgets.dart';
import '../../data/homefix_store.dart';
import '../../data/models.dart';

const customerNav = [
  HfNavItem(Icons.home_outlined, 'Home'),
  HfNavItem(Icons.search_rounded, 'Search'),
  HfNavItem(Icons.calendar_month_outlined, 'Bookings'),
  HfNavItem(Icons.chat_bubble_outline_rounded, 'Messages'),
  HfNavItem(Icons.person_outline_rounded, 'Profile'),
];

class BookingScheduleScreen extends ConsumerStatefulWidget {
  const BookingScheduleScreen({super.key});

  @override
  ConsumerState<BookingScheduleScreen> createState() => _BookingScheduleScreenState();
}

class _BookingScheduleScreenState extends ConsumerState<BookingScheduleScreen> {
  DateTime? _selectedDate;
  String? _selectedTime;

  final List<DateTime> _availableDates = [];
  final List<String> _timeSlots = [
    '9:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '1:00 PM',
    '2:00 PM',
    '3:00 PM',
    '4:00 PM',
    '5:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      _availableDates.add(DateTime(now.year, now.month, now.day + i));
    }
    _selectedDate = _availableDates.first;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homefixStoreProvider);
    final draft = ref.watch(draftProvider);
    final provider = state.providers.firstWhere(
      (p) => p.userId == draft.providerId,
      orElse: () => state.providers.first,
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        title: const Text('Booking Checkout'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                // Progress indicator
                Row(
                  children: [
                    _ProgressStep(number: 1, label: 'Schedule', active: true, completed: false),
                    _ProgressStep(number: 2, label: 'Confirm', active: false, completed: false),
                    _ProgressStep(number: 3, label: 'Success', active: false, completed: false),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Select Schedule section
                const Text('Select Schedule', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                const SizedBox(height: 12),
                
                // Date selector
                SizedBox(
                  height: 70,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _availableDates.length,
                    itemBuilder: (context, index) {
                      final date = _availableDates[index];
                      final isSelected = _selectedDate == date;
                      final isToday = date.day == DateTime.now().day;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedDate = date),
                        child: Container(
                          width: 56,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? HfColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? HfColors.primary : HfColors.border),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isToday ? 'Today' : _getWeekday(date.weekday),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : HfColors.muted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${date.day}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? Colors.white : HfColors.navy,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                
                // Time slots
                const Text('Available Time Slots', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _timeSlots.map((time) {
                    final isSelected = _selectedTime == time;
                    return HfPill(
                      label: time,
                      selected: isSelected,
                      onTap: () => setState(() => _selectedTime = time),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                
                // Service Location section
                const Text('Service Location', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                const SizedBox(height: 12),
                HfCard(
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: HfColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Home', style: TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(state.session?.location ?? 'Nugegoda, Sri Lanka', style: const TextStyle(color: HfColors.muted, fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: HfColors.muted),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Payment Method section
                const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                const SizedBox(height: 12),
                HfCard(
                  child: Row(
                    children: [
                      const Icon(Icons.payments, color: HfColors.success),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Cash on Service Completion', style: TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text('Pay the provider directly after service', style: TextStyle(color: HfColors.muted, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Booking Breakdown
                const Text('Booking Breakdown', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                const SizedBox(height: 12),
                HfCard(
                  child: Column(
                    children: [
                      _BreakdownRow('Service Cost', '\$${draft.amount?.toStringAsFixed(0) ?? '0'}/hour'),
                      _BreakdownRow('HomeFix Guarantee Fee', '\$50'),
                      const Divider(),
                      _BreakdownRow('Total Payable in Cash', '\$${((draft.amount ?? 0) + 50).toStringAsFixed(0)}', bold: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Fixed bottom button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
            ),
            child: HfPrimaryButton(
              label: 'Next',
              onPressed: () {
                if (_selectedTime == null) {
                  hfSnack(context, 'Please select a time slot');
                  return;
                }
                final newDraft = DraftBooking()
                  ..serviceId = draft.serviceId
                  ..providerId = draft.providerId
                  ..serviceTitle = draft.serviceTitle
                  ..amount = draft.amount
                  ..category = draft.category
                  ..scheduledDate = _selectedDate
                  ..timeSlot = _selectedTime;
                ref.read(draftProvider.notifier).set(newDraft);
                context.push('/booking-confirmation');
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getWeekday(int day) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[day - 1];
  }

  Widget _ProgressStep({required int number, required String label, required bool active, required bool completed}) {
    return Expanded(
      child: Column(
        children: [
          Row(
            children: [
              if (number > 1) Expanded(child: Container(height: 2, color: completed ? HfColors.success : HfColors.border)),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: completed ? HfColors.success : (active ? HfColors.primary : HfColors.field),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: completed
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : Text('$number', style: TextStyle(color: active ? Colors.white : HfColors.muted, fontWeight: FontWeight.w700)),
                ),
              ),
              if (number < 3) Expanded(child: Container(height: 2, color: HfColors.border)),
            ],
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.w700 : FontWeight.w400, color: active ? HfColors.primary : HfColors.muted)),
        ],
      ),
    );
  }

  Widget _BreakdownRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}

class BookingConfirmationScreen extends ConsumerWidget {
  const BookingConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homefixStoreProvider);
    final draft = ref.watch(draftProvider);
    final user = state.session;
    final provider = state.providers.firstWhere(
      (p) => p.userId == draft.providerId,
      orElse: () => state.providers.first,
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        title: const Text('Service Booking Flow'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                // Progress indicator
                Row(
                  children: [
                    _ProgressStep(number: 1, label: 'Schedule', active: false, completed: true),
                    _ProgressStep(number: 2, label: 'Confirm', active: true, completed: false),
                    _ProgressStep(number: 3, label: 'Success', active: false, completed: false),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Customer information card
                HfCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: HfColors.primarySoft,
                        child: const Icon(Icons.person, color: HfColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user?.name ?? 'Customer Name', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                            const SizedBox(height: 4),
                            const HfBadge(label: 'VERIFIED CUSTOMER', tone: BadgeTone.teal),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Assigned service provider card
                HfCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: HfColors.primarySoft,
                        child: const Icon(Icons.person, color: HfColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Assigned Service Provider', style: TextStyle(fontSize: 11, color: HfColors.muted)),
                            const SizedBox(height: 4),
                            const Text('David Smith', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(provider.specialty, style: const TextStyle(color: HfColors.muted, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Service information
                HfCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Service Information', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 12),
                      _InfoRow(Icons.calendar_today, 'Scheduled Arrival', '${_formatDate(draft.scheduledDate)} at ${draft.timeSlot ?? 'Not selected'}'),
                      _InfoRow(Icons.location_on, 'Service Location', draft.address ?? user?.location ?? 'Nugegoda, Sri Lanka'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Problem description
                HfCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Problem Description', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 12),
                      Text(draft.notes ?? 'No description provided', style: const TextStyle(color: HfColors.muted, fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Uploaded image area
                HfCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Uploaded Images', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 12),
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: HfColors.field,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: HfColors.border),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, color: HfColors.muted, size: 32),
                              SizedBox(height: 8),
                              Text('No images uploaded', style: TextStyle(color: HfColors.muted, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Direct Cash on Completion payment
                HfCard(
                  color: HfColors.primarySoft,
                  child: Row(
                    children: [
                      const Icon(Icons.payments, color: HfColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Direct Cash on Completion', style: TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text('Pay \$${((draft.amount ?? 0) + 50).toStringAsFixed(0)} to the provider after service completion', style: TextStyle(color: HfColors.muted, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Estimated Cost Breakdown
                HfCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Estimated Cost Breakdown', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 12),
                      _BreakdownRow('Diagnostic/First Hour', '\$${draft.amount?.toStringAsFixed(0) ?? '0'}'),
                      _BreakdownRow('HomeFix Guarantee Fee', '\$50'),
                      const Divider(),
                      _BreakdownRow('Total Estimated', '\$${((draft.amount ?? 0) + 50).toStringAsFixed(0)}', bold: true),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Cancellation info
                Text('Free cancellation up to 2 hours before scheduled time', style: TextStyle(color: HfColors.muted, fontSize: 11, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
              ],
            ),
          ),
          // Fixed bottom buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
            ),
            child: Column(
              children: [
                HfPrimaryButton(
                  label: 'Confirm Booking',
                  onPressed: () {
                    final bookingId = 'BK${DateTime.now().millisecondsSinceEpoch}';
                    ref.read(homefixStoreProvider.notifier).createBooking(
                          Booking(
                            id: bookingId,
                            customerId: state.session?.id ?? 'cust1',
                            providerId: draft.providerId ?? 'prov1',
                            serviceTitle: draft.serviceTitle ?? 'Service',
                            scheduledLabel: '${_formatDate(draft.scheduledDate)} at ${draft.timeSlot}',
                            status: BookingStatus.pending,
                            scheduledDate: draft.scheduledDate ?? DateTime.now(),
                            amount: (draft.amount ?? 0) + 50,
                            address: draft.address,
                            notes: draft.notes,
                            contactPhone: draft.contactPhone,
                          ),
                        );
                    context.push('/booking-success?bookingId=$bookingId');
                  },
                ),
                const SizedBox(height: 12),
                HfSoftButton(
                  label: 'Edit Booking Details',
                  onPressed: () {
                    context.pop();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select a date';
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _ProgressStep({required int number, required String label, required bool active, required bool completed}) {
    return Expanded(
      child: Column(
        children: [
          Row(
            children: [
              if (number > 1) Expanded(child: Container(height: 2, color: completed ? HfColors.success : HfColors.border)),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: completed ? HfColors.success : (active ? HfColors.primary : HfColors.field),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: completed
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : Text('$number', style: TextStyle(color: active ? Colors.white : HfColors.muted, fontWeight: FontWeight.w700)),
                ),
              ),
              if (number < 3) Expanded(child: Container(height: 2, color: HfColors.border)),
            ],
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.w700 : FontWeight.w400, color: active ? HfColors.primary : HfColors.muted)),
        ],
      ),
    );
  }

  Widget _InfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: HfColors.primary, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: HfColors.muted))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _BreakdownRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}

class BookingSuccessScreen extends ConsumerWidget {
  const BookingSuccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homefixStoreProvider);
    final bookingId = GoRouterState.of(context).uri.queryParameters['bookingId'] ?? 'N/A';
    final booking = state.bookings.last;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top navigation
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(onPressed: () => context.go('/c/home'), icon: const Icon(Icons.arrow_back)),
                  const Spacer(),
                  const HfBrandMark(compact: true),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Success icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: HfColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 60),
                    ),
                    const SizedBox(height: 32),
                    // Success message
                    Text('Booking Submitted!', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text('Booking ID: $bookingId', style: const TextStyle(color: HfColors.muted, fontSize: 14)),
                    const SizedBox(height: 8),
                    const Text('Your booking has been successfully submitted', style: TextStyle(color: HfColors.muted)),
                    const SizedBox(height: 24),
                    // Status indicator
                    HfCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pending, color: HfColors.orange, size: 20),
                          const SizedBox(width: 8),
                          const Text('Pending Provider Acceptance', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Buttons
                    HfPrimaryButton(
                      label: 'Track Booking Status',
                      onPressed: () {
                        context.go('/c/bookings');
                      },
                    ),
                    const SizedBox(height: 12),
                    HfSoftButton(
                      label: 'Go to My Bookings',
                      onPressed: () {
                        context.go('/c/bookings');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BookingCheckoutScreen extends ConsumerWidget {
  final String bookingId;
  const BookingCheckoutScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homefixStoreProvider);
    final booking = state.bookings.firstWhere(
      (b) => b.id == bookingId,
      orElse: () => state.bookings.first,
    );
    final provider = state.providers.firstWhere(
      (p) => p.userId == booking.providerId,
      orElse: () => state.providers.first,
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top navigation
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
                  const Spacer(),
                  const HfBrandMark(compact: true),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Progress indicator
                  Row(
                    children: [
                      _ProgressStep(number: 1, label: 'Pending', active: false, completed: true),
                      _ProgressStep(number: 2, label: 'Accepted', active: false, completed: true),
                      _ProgressStep(number: 3, label: 'Scheduled', active: false, completed: true),
                      _ProgressStep(number: 4, label: 'In Progress', active: booking.status == BookingStatus.inProgress, completed: booking.status == BookingStatus.completed),
                      _ProgressStep(number: 5, label: 'Completed', active: false, completed: booking.status == BookingStatus.completed),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Assigned professional section
                  const Text('Assigned Professional', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                  const SizedBox(height: 12),
                  HfCard(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: HfColors.primarySoft,
                          child: const Icon(Icons.person, color: HfColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('David Smith', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(provider.specialty, style: const TextStyle(color: HfColors.muted, fontSize: 12)),
                              const SizedBox(height: 4),
                              const HfBadge(label: 'VERIFIED PROVIDER', tone: BadgeTone.teal),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            context.push('/chat/${booking.id}');
                          },
                          icon: const Icon(Icons.message_outlined),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Service Details card
                  HfCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Service Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 12),
                        _DetailRow(Icons.home_repair_service, 'Service', booking.serviceTitle),
                        _DetailRow(Icons.calendar_today, 'Date & Time', booking.scheduledLabel),
                        _DetailRow(Icons.location_on, 'Location', booking.address ?? 'Nugegoda, Sri Lanka'),
                        _DetailRow(Icons.attach_money, 'Price', 'Rs. ${booking.amount.toStringAsFixed(0)}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Cash payment section
                  HfCard(
                    color: HfColors.primarySoft,
                    child: Row(
                      children: [
                        const Icon(Icons.payments, color: HfColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Paid in Cash', style: TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text('Payment completed after service', style: TextStyle(color: HfColors.muted, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Cancellation policy
                  HfCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Cancellation Policy', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 8),
                        Text('Free cancellation up to 2 hours before scheduled time. Late cancellations may incur a fee.', style: TextStyle(color: HfColors.muted, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (booking.status == BookingStatus.pending || booking.status == BookingStatus.accepted)
                    HfPrimaryButton(
                      label: 'Cancel Booking',
                      backgroundColor: HfColors.danger,
                      onPressed: () {
                        context.push('/cancel-booking/${booking.id}');
                      },
                    ),
                  const SizedBox(height: 24),
                  
                  // Support text
                  Text('Need help? Contact our 24/7 support team', style: TextStyle(color: HfColors.muted, fontSize: 12), textAlign: TextAlign.center),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ProgressStep({required int number, required String label, required bool active, required bool completed}) {
    return Expanded(
      child: Column(
        children: [
          Row(
            children: [
              if (number > 1) Expanded(child: Container(height: 2, color: completed ? HfColors.success : HfColors.border)),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: completed ? HfColors.success : (active ? HfColors.primary : HfColors.field),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: completed
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text('$number', style: TextStyle(color: active ? Colors.white : HfColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ),
              if (number < 5) Expanded(child: Container(height: 2, color: HfColors.border)),
            ],
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: active ? FontWeight.w700 : FontWeight.w400, color: active ? HfColors.primary : HfColors.muted)),
        ],
      ),
    );
  }

  Widget _DetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: HfColors.primary, size: 18),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 12, color: HfColors.muted)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}

class CancelBookingScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const CancelBookingScreen({super.key, required this.bookingId});

  @override
  ConsumerState<CancelBookingScreen> createState() => _CancelBookingScreenState();
}

class _CancelBookingScreenState extends ConsumerState<CancelBookingScreen> {
  String? _selectedReason;
  final _commentsController = TextEditingController();
  bool _releaseSlot = false;

  final List<String> _reasons = [
    'No longer needed',
    'Found another provider',
    'Schedule conflict',
    'Service too expensive',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homefixStoreProvider);
    final booking = state.bookings.firstWhere(
      (b) => b.id == widget.bookingId,
      orElse: () => state.bookings.first,
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        title: const Text('Cancel Booking'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Booking ID
          Text('Booking ID: ${booking.id}', style: const TextStyle(color: HfColors.muted, fontSize: 12)),
          const SizedBox(height: 16),
          
          // Service/provider card
          HfCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: HfColors.primarySoft,
                  child: const Icon(Icons.person, color: HfColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('David Smith', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(booking.serviceTitle, style: const TextStyle(color: HfColors.muted, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(booking.scheduledLabel, style: const TextStyle(color: HfColors.muted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Cash payment info
          HfCard(
            color: HfColors.primarySoft,
            child: Row(
              children: [
                const Icon(Icons.payments, color: HfColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Cash Payment', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('Rs. ${booking.amount.toStringAsFixed(0)} payable on completion', style: TextStyle(color: HfColors.muted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Cancellation guarantee
          HfCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cancellation Guarantee', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 8),
                Text('Free cancellation up to 2 hours before scheduled time. After that, a 10% fee may apply.', style: TextStyle(color: HfColors.muted, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Reason for cancellation
          const Text('Reason for cancellation', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          ..._reasons.map((reason) {
            return RadioListTile<String>(
              title: Text(reason),
              value: reason,
              groupValue: _selectedReason,
              onChanged: (value) => setState(() => _selectedReason = value),
              activeColor: HfColors.primary,
            );
          }),
          const SizedBox(height: 16),
          
          // Additional comments
          HfField(
            label: 'Additional Comments (Optional)',
            hint: 'Tell us more about why you want to cancel',
            icon: Icons.edit_outlined,
            controller: _commentsController,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          
          // Release schedule slot checkbox
          HfCard(
            child: CheckboxListTile(
              value: _releaseSlot,
              onChanged: (value) => setState(() => _releaseSlot = value ?? false),
              title: const Text('Release schedule slot for other customers'),
              subtitle: const Text('Your time slot will be available for other bookings', style: TextStyle(fontSize: 12)),
              activeColor: HfColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 16),
          
          // Warning
          HfCard(
            color: HfColors.danger.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: HfColors.danger),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('This action cannot be undone. Your booking will be permanently cancelled.', style: TextStyle(color: HfColors.danger, fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Buttons
          HfPrimaryButton(
            label: 'Keep My Booking',
            onPressed: () {
              context.pop();
            },
          ),
          const SizedBox(height: 12),
          HfSoftButton(
            label: 'Cancel My Booking',
            color: HfColors.danger.withValues(alpha: 0.1),
            foreground: HfColors.danger,
            onPressed: () {
              ref.read(homefixStoreProvider.notifier).cancelBooking(booking.id);
              hfSnack(context, 'Booking cancelled successfully');
              context.go('/c/bookings');
            },
          ),
        ],
      ),
    );
  }
}
