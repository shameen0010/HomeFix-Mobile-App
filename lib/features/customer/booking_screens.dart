import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/theme/hf_theme.dart';
import '../../core/widgets/hf_widgets.dart';
import '../../data/firestore_booking_service.dart';
import '../../data/homefix_store.dart';
import '../../data/models.dart';

const customerNav = [
  HfNavItem(Icons.home_outlined, 'Home'),
  HfNavItem(Icons.search_rounded, 'Search'),
  HfNavItem(Icons.calendar_month_outlined, 'Bookings'),
  HfNavItem(Icons.chat_bubble_outline_rounded, 'Messages'),
  HfNavItem(Icons.person_outline_rounded, 'Profile'),
];

// ==================== EMERGENCY BOOKING SCREENS ====================

class EmergencyServiceSelectionScreen extends ConsumerStatefulWidget {
  const EmergencyServiceSelectionScreen({super.key});

  @override
  ConsumerState<EmergencyServiceSelectionScreen> createState() => _EmergencyServiceSelectionScreenState();
}

class _EmergencyServiceSelectionScreenState extends ConsumerState<EmergencyServiceSelectionScreen> {
  String? _selectedService;

  final List<Map<String, dynamic>> _services = [
    {
      'title': 'Emergency Plumbing',
      'description': 'Burst pipes, severe leaks, water shutoff failure, overflowing drains',
      'tags': <String>['Avg. response 15 min', 'Certified Techs'],
      'icon': Icons.plumbing,
    },
    {
      'title': 'Emergency Electrical',
      'description': 'Power outage, sparking outlet, breaker failure, burning wire odor',
      'tags': <String>['Critical safety hazard', 'Licensed Electrician'],
      'icon': Icons.electrical_services,
    },
    {
      'title': 'Appliance Repair',
      'description': 'Refrigerator cooling failure, gas oven leak, urgent breakdown',
      'tags': <String>['Same-day visits', 'All Major Brands'],
      'icon': Icons.kitchen,
    },
    {
      'title': 'Other Home Emergency',
      'description': 'Door lockout, urgent structural issue, storm leak, broken window',
      'tags': <String>[],
      'icon': Icons.home_repair_service,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const HfBrandMark(compact: true),
                  const SizedBox(width: 8),
                  const HfBadge(label: 'URGENT', tone: BadgeTone.orange),
                  const Spacer(),
                  CircleAvatar(
                    backgroundColor: HfColors.primary,
                    radius: 20,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                ],
              ),
            ),
            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('STEP 1 OF 4 • Service Type', style: const TextStyle(fontSize: 11, color: HfColors.muted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const LinearProgressIndicator(value: 0.25, backgroundColor: HfColors.border, color: HfColors.primary),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Title
                  const HfBadge(label: 'FAST-TRACK REQUEST', tone: BadgeTone.orange),
                  const SizedBox(height: 8),
                  Text('Emergency Booking', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text('What help do you need right now?', style: TextStyle(color: HfColors.muted)),
                  const SizedBox(height: 24),
                  
                  // Service cards
                  ..._services.map((service) {
                    final isSelected = _selectedService == service['title'];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedService = service['title']),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? HfColors.primary : HfColors.border,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isSelected ? HfColors.primarySoft : HfColors.field,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(service['icon'], color: isSelected ? HfColors.primary : HfColors.muted),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(service['title'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text(service['description'], style: const TextStyle(color: HfColors.muted, fontSize: 12)),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      for (var tag in service['tags'] as List)
                                        HfPill(label: tag as String, selected: false),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: HfColors.primary, size: 24),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  
                  // Trust indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _TrustIcon(Icons.verified_user, 'Vetted Pros'),
                      _TrustIcon(Icons.attach_money, 'Fixed Pricing'),
                      _TrustIcon(Icons.shield, 'Covered'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Continue button
                  HfPrimaryButton(
                    label: 'Continue →',
                    onPressed: () {
                      if (_selectedService != null) {
                        context.push(Uri(
                          path: '/emergency-details',
                          queryParameters: {'service': _selectedService!},
                        ).toString());
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text('No prepayment required to place urgent request', style: TextStyle(color: HfColors.muted, fontSize: 12), textAlign: TextAlign.center),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _TrustIcon(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: HfColors.primary, size: 24),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: HfColors.muted)),
      ],
    );
  }
}

class EmergencyDetailsScreen extends ConsumerStatefulWidget {
  const EmergencyDetailsScreen({super.key});

  @override
  ConsumerState<EmergencyDetailsScreen> createState() => _EmergencyDetailsScreenState();
}

class _EmergencyDetailsScreenState extends ConsumerState<EmergencyDetailsScreen> {
  final _addressController = TextEditingController();
  final _areaController = TextEditingController();
  final _zipController = TextEditingController();
  final _unitController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _addressController.dispose();
    _areaController.dispose();
    _zipController.dispose();
    _unitController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
                  const Spacer(),
                  CircleAvatar(
                    backgroundColor: HfColors.primary,
                    radius: 20,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                ],
              ),
            ),
            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Emergency Details • 24/7 Priority Response', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('STEP 2 OF 4', style: const TextStyle(fontSize: 11, color: HfColors.muted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Location & Issue', style: const TextStyle(fontSize: 12, color: HfColors.muted)),
                  const SizedBox(height: 8),
                  const LinearProgressIndicator(value: 0.5, backgroundColor: HfColors.border, color: HfColors.primary),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Active banner
                  HfCard(
                    color: HfColors.primarySoft,
                    child: Row(
                      children: [
                        const HfBadge(label: 'Active Emergency: Emergency Plumbing', tone: BadgeTone.orange),
                        const Spacer(),
                        TextButton(onPressed: () {}, child: const Text('Change')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Warning alert
                  HfCard(
                    color: HfColors.peach.withValues(alpha: 0.3),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber, color: HfColors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Rapid Dispatch Alert', style: TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text('A local technician will review your address and respond immediately upon submission.', style: TextStyle(color: HfColors.muted, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Address fields
                  HfField(
                    label: 'Service Address*',
                    hint: 'Enter your service address e.g. 742 Evergreen',
                    icon: Icons.location_on,
                    controller: _addressController,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: HfField(
                          label: 'Area / City*',
                          hint: 'Brooklyn',
                          icon: Icons.location_city,
                          controller: _areaController,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: HfField(
                          label: 'Neighborhood or Zip',
                          hint: '11201',
                          icon: Icons.map,
                          controller: _zipController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  HfField(
                    label: 'Apartment / Unit / Floor (Optional)',
                    hint: 'Apt 4B',
                    icon: Icons.apartment,
                    controller: _unitController,
                  ),
                  const SizedBox(height: 16),
                  
                  // Problem description
                  HfField(
                    label: 'Describe the Problem*',
                    hint: 'Be specific about the issue...',
                    icon: Icons.description,
                    controller: _descriptionController,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  
                  // Add photo
                  HfCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Add Photo (Optional)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 12),
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: HfColors.field,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: HfColors.border, style: BorderStyle.solid),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt_outlined, color: HfColors.muted, size: 32),
                                SizedBox(height: 8),
                                Text('Tap to take or upload a photo', style: TextStyle(color: HfColors.muted, fontSize: 12)),
                                Text('(JPEG or PNG up to 10MB)', style: TextStyle(color: HfColors.muted, fontSize: 10)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Privacy notice
                  HfCard(
                    child: Row(
                      children: [
                        const Icon(Icons.security, color: HfColors.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('Your address is securely transmitted only to assigned emergency technicians.', style: TextStyle(color: HfColors.muted, fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Find providers button
                  HfPrimaryButton(
                    label: 'Find Available Providers →',
                    onPressed: () {
                      if (_addressController.text.trim().isEmpty ||
                          _areaController.text.trim().isEmpty ||
                          _descriptionController.text.trim().isEmpty) {
                        hfSnack(context, 'Enter the address, area, and problem description.');
                        return;
                      }
                      context.push(Uri(
                        path: '/emergency-providers',
                        queryParameters: {
                          'service': GoRouterState.of(context).uri.queryParameters['service'] ?? 'Home Emergency',
                          'address': '${_addressController.text.trim()}, ${_areaController.text.trim()} ${_zipController.text.trim()}'.trim(),
                          'unit': _unitController.text.trim(),
                          'description': _descriptionController.text.trim(),
                        },
                      ).toString());
                    },
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmergencyProvidersScreen extends ConsumerWidget {
  const EmergencyProvidersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uri = GoRouterState.of(context).uri;
    final requestedService = uri.queryParameters['service'] ?? 'Home Emergency';
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
                  const Spacer(),
                  CircleAvatar(
                    backgroundColor: HfColors.primary,
                    radius: 20,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                ],
              ),
            ),
            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select Dispatch Tier • 24/7 Priority Response', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('STEP 3 OF 4', style: const TextStyle(fontSize: 11, color: HfColors.muted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const LinearProgressIndicator(value: 0.75, backgroundColor: HfColors.border, color: HfColors.primary),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Available Providers', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                  const SizedBox(height: 4),
                  const Text('Choose a provider who is available for your emergency', style: TextStyle(color: HfColors.muted)),
                  const SizedBox(height: 8),
                  HfBadge(label: '$requestedService • Approved pros available', tone: BadgeTone.orange),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance.collection('providers').where('status', isEqualTo: 'approved').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) return const Text('Unable to load available providers.');
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final normalizedService = requestedService.toLowerCase().replaceFirst('emergency ', '');
                      final providers = snapshot.data!.docs.where((document) {
                        final data = document.data();
                        final serviceType = (data['serviceType'] ?? '').toString().toLowerCase();
                        final categories = (data['categories'] as List?)?.map((value) => value.toString().toLowerCase()) ?? const <String>[];
                        return normalizedService.contains('other') ||
                            serviceType.isEmpty ||
                            serviceType.contains(normalizedService) ||
                            categories.any((category) => normalizedService.contains(category));
                      }).toList();
                      if (providers.isEmpty) return const HfCard(child: Text('No approved provider is available for this emergency yet.'));
                      return Column(
                        children: [
                          for (var index = 0; index < providers.length; index++) ...[
                            _ProviderCard(context, providers[index].id, providers[index].data(), index == 0, uri.queryParameters),
                            if (index < providers.length - 1) const SizedBox(height: 12),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Footer guarantee
                  HfCard(
                    child: Row(
                      children: [
                        const Icon(Icons.shield, color: HfColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('HomeFix Emergency Guarantee', style: TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text('Licensed, insured & background-checked professionals', style: TextStyle(color: HfColors.muted, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ProviderCard(
    BuildContext context,
    String providerId,
    Map<String, dynamic> data,
    bool recommended,
    Map<String, String> bookingParameters,
  ) {
    final name = (data['name'] ?? data['displayName'] ?? 'Approved provider').toString();
    final subtitle = (data['serviceType'] ?? 'Home services provider').toString();
    final rating = ((data['rating'] as num?)?.toDouble() ?? 0).toStringAsFixed(1);
    final reviews = ((data['reviewCount'] as num?)?.toInt() ?? 0).toString();
    final exp = data['experience']?.toString() ?? 'Verified provider';
    final diagnostic = data['hourlyRate'] ?? data['diagnosticFee'] ?? 55;
    final area = (data['serviceArea'] ?? '').toString();
    return HfCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: HfColors.muted, fontSize: 12)),
                  ],
                ),
              ),
              if (recommended) const HfBadge(label: 'Recommended', tone: BadgeTone.orange),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.star, color: HfColors.gold, size: 16),
              const SizedBox(width: 4),
              Text('$rating ($reviews) | $exp', style: const TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              const HfPill(label: 'Available Now', selected: false),
              if (area.isNotEmpty) HfPill(label: area, selected: false),
            ],
          ),
          const SizedBox(height: 8),
          HfPill(label: 'Diagnostic: Rs. $diagnostic', selected: false),
          const SizedBox(height: 12),
          HfPrimaryButton(
            label: 'Request Service →',
            onPressed: () {
              context.push(Uri(
                path: '/emergency-confirm',
                queryParameters: {
                  'service': bookingParameters['service'] ?? 'Home Emergency',
                  'address': bookingParameters['address'] ?? '',
                  'unit': bookingParameters['unit'] ?? '',
                  'description': bookingParameters['description'] ?? '',
                  'providerId': providerId,
                  'providerName': name,
                },
              ).toString());
            },
          ),
        ],
      ),
    );
  }
}

class EmergencyConfirmScreen extends ConsumerWidget {
  const EmergencyConfirmScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
                  const Spacer(),
                  CircleAvatar(
                    backgroundColor: HfColors.primary,
                    radius: 20,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                ],
              ),
            ),
            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Review & Confirm • 24/7 Priority Response', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('STEP 4 OF 4', style: const TextStyle(fontSize: 11, color: HfColors.muted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const LinearProgressIndicator(value: 1.0, backgroundColor: HfColors.border, color: HfColors.primary),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Confirm Emergency Booking', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 24)),
                  const SizedBox(height: 16),
                  
                  // Notice card
                  HfCard(
                    color: HfColors.primarySoft,
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: HfColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('Instant Dispatch Notice - The provider will be notified about your emergency request immediately upon confirmation.', style: TextStyle(color: HfColors.muted, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Service card
                  HfCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.plumbing, color: HfColors.primary),
                            const SizedBox(width: 8),
                            const Expanded(child: Text('EMERGENCY SERVICE: Emergency Plumbing', style: TextStyle(fontWeight: FontWeight.w700))),
                            const HfBadge(label: 'Urgent Leak', tone: BadgeTone.orange),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: HfColors.primarySoft,
                              child: const Icon(Icons.person, color: HfColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Marcus Vance', style: TextStyle(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  const Text('Master Plumber • 11 yrs exp', style: TextStyle(color: HfColors.muted, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: HfColors.gold, size: 16),
                                      const SizedBox(width: 4),
                                      const Text('4.9', style: TextStyle(fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text('Technician Status', style: TextStyle(fontSize: 12, color: HfColors.muted)),
                            const Spacer(),
                            const HfBadge(label: 'Available Now (Priority Queue)', tone: BadgeTone.orange),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Service destination
                  HfCard(
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: HfColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Service Destination', style: TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              const Text('742 Evergreen Terrace, Apt 4B, Brooklyn, NY 11201', style: TextStyle(fontSize: 14)),
                              const SizedBox(height: 4),
                              const HfBadge(label: 'Manual Entry', tone: BadgeTone.teal),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Problem description
                  HfCard(
                    child: Row(
                      children: [
                        const Icon(Icons.description, color: HfColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Problem Description', style: TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              const Text('Kitchen sink supply line burst under cabinet. Water spraying continuously. Main valve closed temporarily.', style: TextStyle(fontSize: 12, color: HfColors.muted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Estimated diagnostic fee
                  HfCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Estimated Diagnostic Fee', style: TextStyle(fontWeight: FontWeight.w700)),
                              Text('Cash / Direct settlement on-site', style: TextStyle(color: HfColors.muted, fontSize: 12)),
                            ],
                          ),
                        ),
                        const Text('\$55.00', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Payment terms
                  HfCard(
                    color: HfColors.primarySoft,
                    child: Row(
                      children: [
                        const Icon(Icons.lock, color: HfColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('No Upfront Online Payment - Pay your technician directly via cash or approved settlement after work is completed.', style: TextStyle(color: HfColors.muted, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Buttons
                  HfPrimaryButton(
                    label: 'Confirm Emergency Booking *',
                    onPressed: () async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) {
                        hfSnack(context, 'Please log in before requesting emergency service.');
                        return;
                      }
                      final uri = GoRouterState.of(context).uri;
                      try {
                        final reference = FirebaseFirestore.instance.collection('bookings').doc();
                        await reference.set({
                          'customerId': user.uid,
                          'customerName': user.displayName ?? '',
                          'providerId': uri.queryParameters['providerId'],
                          'providerName': uri.queryParameters['providerName'] ?? 'Emergency dispatch',
                          'service': uri.queryParameters['service'] ?? 'Home Emergency',
                          'serviceTitle': uri.queryParameters['service'] ?? 'Home Emergency',
                          'serviceType': uri.queryParameters['service'] ?? 'Home Emergency',
                          'address': '${uri.queryParameters['address'] ?? ''} ${uri.queryParameters['unit'] ?? ''}'.trim(),
                          'notes': uri.queryParameters['description'] ?? '',
                          'priority': 'emergency',
                          'isEmergency': true,
                          'paymentMethod': 'Cash on Completion',
                          'totalPrice': 55.0,
                          'amount': 55.0,
                          'status': 'pending',
                          'createdAt': FieldValue.serverTimestamp(),
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                        if (context.mounted) {
                          context.go('/emergency-status?bookingId=${reference.id}');
                        }
                      } on FirebaseException catch (error) {
                        if (context.mounted) hfSnack(context, 'Could not create emergency booking: ${error.message}');
                      } catch (error) {
                        if (context.mounted) hfSnack(context, 'Could not create emergency booking: $error');
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Cancel Request'),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmergencyStatusScreen extends ConsumerWidget {
  const EmergencyStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
                  const Spacer(),
                  CircleAvatar(
                    backgroundColor: HfColors.primary,
                    radius: 20,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                ],
              ),
            ),
            // Status banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: HfColors.peach.withValues(alpha: 0.3),
              ),
              child: Column(
                children: [
                  const Text('EMERGENCY REQUEST ACTIVE • BOOKING #EMG-7012', style: TextStyle(fontWeight: FontWeight.w700, color: HfColors.orange)),
                  const SizedBox(height: 8),
                  const Text('Emergency Booking Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
                  const SizedBox(height: 4),
                  const HfBadge(label: 'Priority Dispatched', tone: BadgeTone.orange),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Progress tracker
                  HfCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('PROGRESS TRACKER', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Spacer(),
                            const HfBadge(label: 'Step 3 of 5', tone: BadgeTone.orange),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _TimelineStep(
                          number: 1,
                          title: 'Request Sent',
                          description: 'System received your urgent request',
                          time: '2:05 PM',
                          completed: true,
                        ),
                        _TimelineStep(
                          number: 2,
                          title: 'Provider Accepted',
                          description: 'Technician assigned & prepped tools',
                          time: '2:07 PM',
                          completed: true,
                        ),
                        _TimelineStep(
                          number: 3,
                          title: 'On the Way',
                          description: 'Provider heading to your address with priority service van',
                          tag: 'Active Now',
                          completed: false,
                          active: true,
                        ),
                        _TimelineStep(
                          number: 4,
                          title: 'Service Started',
                          description: 'Inspection and pipe stabilization',
                          completed: false,
                        ),
                        _TimelineStep(
                          number: 5,
                          title: 'Completed',
                          description: 'Sign-off, safety test, and diagnostic receipt',
                          completed: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Provider contact card
                  HfCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
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
                                  const Text('Marcus Vance', style: TextStyle(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  const Text('Master Plumber & Pipe Specialist', style: TextStyle(color: HfColors.muted, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  const Text('Dispatched from Brooklyn Hub', style: TextStyle(color: HfColors.muted, fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.star, color: HfColors.gold, size: 16),
                            const SizedBox(width: 4),
                            const Text('4.9 (125)', style: TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        HfSoftButton(
                          label: 'Chat with Provider',
                          icon: Icons.message,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Booking details
                  HfCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('Booking Details', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Spacer(),
                            const HfBadge(label: 'Urgent Tier', tone: BadgeTone.orange),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _DetailRow(Icons.plumbing, 'Service', 'Emergency Plumbing Repair'),
                        _DetailRow(Icons.location_on, 'Service Address', '742 Evergreen Terrace, Apt 4B, Brooklyn, NY 11201'),
                        _DetailRow(Icons.calendar_today, 'Booking Date & Time', 'Today, Oct 16 • 2:05 PM'),
                        _DetailRow(Icons.access_time, 'Estimated Arrival', '15–25 minutes', highlight: true),
                        _DetailRow(Icons.attach_money, 'Payment Terms', 'Cash settlement on completion (\$55.00 base diagnostic)'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Footer notice
                  HfCard(
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: HfColors.primary, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('Please ensure your building gate or front door is accessible for technician arrival.', style: TextStyle(color: HfColors.muted, fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Return button
                  HfSoftButton(
                    label: 'Return to Dashboard',
                    color: HfColors.danger.withValues(alpha: 0.1),
                    foreground: HfColors.danger,
                    onPressed: () {
                      context.go('/c/home');
                    },
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _TimelineStep({
    required int number,
    required String title,
    required String description,
    String? time,
    String? tag,
    required bool completed,
    bool active = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: completed ? HfColors.success : (active ? HfColors.orange : HfColors.border),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: completed
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : Text('$number', style: TextStyle(color: active ? Colors.white : HfColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: TextStyle(fontWeight: active ? FontWeight.w700 : FontWeight.w600, color: active ? HfColors.orange : null)),
                    if (time != null) ...[
                      const SizedBox(width: 8),
                      Text(time, style: const TextStyle(color: HfColors.muted, fontSize: 11)),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(color: HfColors.muted, fontSize: 12)),
                if (tag != null) ...[
                  const SizedBox(height: 4),
                  HfBadge(label: tag, tone: BadgeTone.orange),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _DetailRow(IconData icon, String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: HfColors.primary, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: HfColors.muted))),
          Text(value, style: TextStyle(fontWeight: highlight ? FontWeight.w800 : FontWeight.w600, fontSize: 14, color: highlight ? HfColors.orange : null)),
        ],
      ),
    );
  }
}

// ==================== NORMAL BOOKING SCREENS ====================

class FirestoreEmergencyStatusScreen extends StatelessWidget {
  const FirestoreEmergencyStatusScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('bookings').doc(bookingId).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Center(child: Text('Unable to load emergency booking.'));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final data = snapshot.data!.data();
            if (data == null) return const Center(child: Text('Emergency booking not found.'));
            final status = (data['status'] ?? 'pending').toString().toLowerCase();
            final provider = (data['providerName'] ?? 'Waiting for provider assignment').toString();
            final steps = <Map<String, dynamic>>[
              {'title': 'Request Sent', 'description': 'System received your urgent request', 'statuses': ['pending', 'accepted', 'en_route', 'arrived', 'in_progress', 'completed']},
              {'title': 'Provider Accepted', 'description': 'Technician assigned and preparing', 'statuses': ['accepted', 'en_route', 'arrived', 'in_progress', 'completed']},
              {'title': 'On the Way', 'description': 'Provider is heading to your address', 'statuses': ['en_route', 'arrived', 'in_progress', 'completed']},
              {'title': 'Service Started', 'description': 'Inspection and work in progress', 'statuses': ['in_progress', 'completed']},
              {'title': 'Completed', 'description': 'Service and receipt completed', 'statuses': ['completed']},
            ];
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Row(children: [
                  IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
                  const Spacer(),
                  const HfBadge(label: 'URGENT', tone: BadgeTone.orange),
                ]),
                const SizedBox(height: 12),
                HfCard(color: HfColors.peach.withValues(alpha: .3), child: Column(children: [
                  Text('EMERGENCY REQUEST ACTIVE • ${bookingId.substring(0, bookingId.length > 8 ? 8 : bookingId.length)}', style: const TextStyle(fontWeight: FontWeight.w700, color: HfColors.orange)),
                  const SizedBox(height: 8),
                  const Text('Emergency Booking Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
                  const SizedBox(height: 6),
                  Text(_bookingStatusLabel(status), style: const TextStyle(fontWeight: FontWeight.w700, color: HfColors.primary)),
                ])),
                const SizedBox(height: 16),
                HfCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('PROGRESS TRACKER', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  ...steps.map((step) {
                    final completed = (step['statuses'] as List<String>).contains(status);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: completed ? HfColors.primary : HfColors.field,
                        child: Icon(completed ? Icons.check : Icons.more_horiz, color: completed ? Colors.white : HfColors.muted),
                      ),
                      title: Text(step['title'] as String, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(step['description'] as String),
                    );
                  }),
                ])),
                const SizedBox(height: 16),
                HfCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(provider, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 8),
                  _LiveBookingRow(icon: Icons.location_on, label: 'Address', value: (data['address'] ?? 'Not provided').toString()),
                  _LiveBookingRow(icon: Icons.plumbing, label: 'Service', value: (data['serviceTitle'] ?? 'Emergency service').toString()),
                  _LiveBookingRow(icon: Icons.payments, label: 'Payment', value: 'Cash on completion'),
                ])),
                const SizedBox(height: 16),
                HfSoftButton(label: 'Message Provider', icon: Icons.message, onPressed: provider == 'Emergency dispatch' ? () {} : () => context.push('/chat/$bookingId')),
              ],
            );
          },
        ),
      ),
    );
  }
}

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
                  onPressed: () async {
                    try {
                      final providerId = draft.providerId;
                      if (providerId == null || providerId.isEmpty) {
                        hfSnack(context, 'Please select a provider before booking.');
                        return;
                      }
                      final currentUser = FirebaseAuth.instance.currentUser;
                      if (currentUser == null) {
                        hfSnack(context, 'Please log in before booking.');
                        return;
                      }
                      final customerId = currentUser.uid;
                      final userDoc = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUser.uid)
                          .get();
                      final providerDoc = await FirebaseFirestore.instance
                          .collection('providers')
                          .doc(providerId)
                          .get();
                      final customerName = (userDoc.data()?['name'] ??
                              currentUser.email ??
                              'Customer')
                          .toString();
                      final providerName =
                          (providerDoc.data()?['name'] ?? 'Provider').toString();
                      final scheduledDate = _combineDateAndTime(
                        draft.scheduledDate ?? DateTime.now(),
                        draft.timeSlot,
                      );
                      final amount = (draft.amount ?? 0) + 50;
                      final firestoreId =
                          await FirestoreBookingService().createBooking(
                        customerId: customerId,
                        customerName: customerName,
                        providerId: providerId,
                        providerName: providerName,
                        serviceTitle: draft.serviceTitle ?? 'Service',
                        scheduledAt: scheduledDate,
                        amount: amount,
                        address: draft.address,
                        notes: draft.notes,
                        contactPhone: draft.contactPhone,
                      );
                      if (!context.mounted) return;
                      ref.read(homefixStoreProvider.notifier).createBooking(
                            Booking(
                              id: firestoreId,
                              customerId: customerId,
                              providerId: providerId,
                              serviceTitle: draft.serviceTitle ?? 'Service',
                              scheduledLabel:
                                  '${_formatDate(draft.scheduledDate)} at ${draft.timeSlot}',
                              status: BookingStatus.pending,
                              scheduledDate: scheduledDate,
                              amount: amount,
                              address: draft.address,
                              notes: draft.notes,
                              contactPhone: draft.contactPhone,
                            ),
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Booking submitted successfully.')),
                      );
                      context.push('/booking-success?bookingId=$firestoreId');
                    } on FirebaseException catch (error) {
                      if (!context.mounted) return;
                      hfSnack(context, 'Could not submit booking: ${error.message}');
                    } catch (error) {
                      if (!context.mounted) return;
                      hfSnack(context, 'Could not submit booking: $error');
                    }
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

class FirestoreBookingSuccessScreen extends StatelessWidget {
  const FirestoreBookingSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookingId = GoRouterState.of(context).uri.queryParameters['bookingId'];
    if (bookingId == null || bookingId.isEmpty) {
      return const Scaffold(body: Center(child: Text('Booking reference is missing.')));
    }
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('bookings').doc(bookingId).snapshots(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data();
            final status = (data?['status'] ?? 'pending').toString();
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const CircleAvatar(radius: 50, backgroundColor: HfColors.success, child: Icon(Icons.check, color: Colors.white, size: 56)),
                  const SizedBox(height: 24),
                  Text('Booking Submitted!', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text('Booking ID: $bookingId', style: const TextStyle(color: HfColors.muted)),
                  const SizedBox(height: 24),
                  HfCard(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.pending, color: HfColors.orange),
                    const SizedBox(width: 8),
                    Text(_bookingStatusLabel(status), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ])),
                  const SizedBox(height: 24),
                  HfPrimaryButton(label: 'Track Booking Status', onPressed: () => context.go('/booking-checkout/$bookingId')),
                  const SizedBox(height: 12),
                  HfSoftButton(label: 'Go to My Bookings', onPressed: () => context.go('/c/bookings')),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class FirestoreBookingCheckoutScreen extends StatelessWidget {
  const FirestoreBookingCheckoutScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('bookings').doc(bookingId).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Center(child: Text('Unable to load booking.'));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final data = snapshot.data!.data();
            if (data == null) return const Center(child: Text('Booking not found.'));
            final status = (data['status'] ?? 'pending').toString().toLowerCase();
            final provider = (data['providerName'] ?? 'Provider pending').toString();
            final service = (data['serviceTitle'] ?? data['serviceType'] ?? 'Home service').toString();
            final amount = data['totalPrice'] ?? data['amount'] ?? 0;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Row(children: [
                  IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
                  const Spacer(),
                  const HfBrandMark(compact: true),
                ]),
                const SizedBox(height: 16),
                Text('Track Your Booking', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                HfCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(provider, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                  Text(service, style: const TextStyle(color: HfColors.muted)),
                  const SizedBox(height: 12),
                  _LiveBookingRow(icon: Icons.calendar_today, label: 'Scheduled', value: _timestampLabel(data['scheduledDate'] ?? data['scheduledAt'])),
                  _LiveBookingRow(icon: Icons.location_on, label: 'Location', value: (data['address'] ?? 'Address not provided').toString()),
                  _LiveBookingRow(icon: Icons.payments, label: 'Cash total', value: 'Rs. $amount'),
                ])),
                const SizedBox(height: 16),
                HfCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Booking progress', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 12),
                  Text(_bookingStatusLabel(status), style: const TextStyle(color: HfColors.primary, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: _statusProgress(status), color: HfColors.primary),
                ])),
                const SizedBox(height: 16),
                HfSoftButton(label: 'Message Provider', icon: Icons.message_outlined, onPressed: () => context.push('/chat/$bookingId')),
                if (status == 'completed')
                  HfPrimaryButton(
                    label: (data['paymentStatus'] ?? '').toString() == 'cash_paid'
                        ? 'Rate Provider'
                        : 'Confirm Cash Payment',
                    onPressed: () => context.push(
                      (data['paymentStatus'] ?? '').toString() == 'cash_paid'
                          ? '/rate-review?bookingId=$bookingId'
                          : '/payment-confirmation?bookingId=$bookingId',
                    ),
                  ),
                if (status == 'pending' || status == 'accepted' || status == 'confirmed')
                  HfPrimaryButton(label: 'Cancel Booking', backgroundColor: HfColors.danger, onPressed: () => context.push('/cancel-booking/$bookingId')),
              ],
            );
          },
        ),
      ),
    );
  }
}

class FirestoreCancelBookingScreen extends StatefulWidget {
  const FirestoreCancelBookingScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  State<FirestoreCancelBookingScreen> createState() => _FirestoreCancelBookingScreenState();
}

class _FirestoreCancelBookingScreenState extends State<FirestoreCancelBookingScreen> {
  final _reasonController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _cancel() async {
    if (_reasonController.text.trim().isEmpty) {
      hfSnack(context, 'Please enter a cancellation reason.');
      return;
    }
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).update({
        'status': 'cancelled',
        'cancellationReason': _reasonController.text.trim(),
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      hfSnack(context, 'Booking cancelled.');
      context.go('/c/bookings');
    } on FirebaseException catch (error) {
      if (mounted) hfSnack(context, 'Could not cancel booking: ${error.message}');
    } catch (error) {
      if (mounted) hfSnack(context, 'Could not cancel booking: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cancel Booking')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Why are you cancelling?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 12),
        TextField(controller: _reasonController, maxLines: 4, decoration: const InputDecoration(hintText: 'Enter a reason')),
        const SizedBox(height: 16),
        HfPrimaryButton(
          label: _saving ? 'Cancelling...' : 'Confirm Cancellation',
          backgroundColor: HfColors.danger,
          onPressed: _saving ? () {} : _cancel,
        ),
      ]),
    );
  }
}

class _LiveBookingRow extends StatelessWidget {
  const _LiveBookingRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Icon(icon, size: 18, color: HfColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(color: HfColors.muted, fontSize: 12))),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
      );
}

String _bookingStatusLabel(String status) {
  switch (status) {
    case 'accepted':
    case 'confirmed':
      return 'Confirmed';
    case 'en_route':
      return 'En Route';
    case 'in_progress':
    case 'started':
      return 'Service in Progress';
    case 'completed':
      return 'Completed';
    case 'cancelled':
      return 'Cancelled';
    default:
      return 'Pending Provider Acceptance';
  }
}

double _statusProgress(String status) {
  switch (status) {
    case 'accepted':
    case 'confirmed':
      return .4;
    case 'en_route':
      return .6;
    case 'in_progress':
    case 'started':
      return .8;
    case 'completed':
      return 1;
    default:
      return .2;
  }
}

String _timestampLabel(dynamic value) {
  DateTime? date;
  if (value is Timestamp) date = value.toDate();
  if (value is String) date = DateTime.tryParse(value);
  if (date == null) return 'Not scheduled';
  return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

DateTime _combineDateAndTime(DateTime date, String? timeSlot) {
  if (timeSlot == null) return date;
  final match = RegExp(r'^(\d+):(\d+) (AM|PM)$').firstMatch(timeSlot);
  if (match == null) return date;
  var hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  if (match.group(3) == 'PM' && hour != 12) hour += 12;
  if (match.group(3) == 'AM' && hour == 12) hour = 0;
  return DateTime(date.year, date.month, date.day, hour, minute);
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
