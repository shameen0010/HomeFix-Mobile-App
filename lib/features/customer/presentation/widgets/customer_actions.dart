import 'package:flutter/material.dart';

import '../../../provider/data/models/provider_profile.dart';
import '../../core/customer_ui.dart';
import '../../data/models/booking_info.dart';
import '../../data/models/customer_chat.dart';
import '../../../provider/data/models/service_item.dart';
import '../screens/booking_checkout_screen.dart';
import '../screens/booking_tracking_screen.dart';
import '../screens/customer_chat_screen.dart';
import '../screens/emergency_service_screen.dart';
import '../screens/emergency_status_screen.dart';
import '../screens/provider_detail_screen.dart';
import '../screens/cash_confirmation_screen.dart';
import '../screens/review_checkout_screen.dart';
import '../../data/repositories/customer_repository.dart';

void openProvider(BuildContext context, String providerId, {bool emergency = false}) {
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => ProviderDetailScreen(providerId: providerId, emergency: emergency),
  ));
}

/// Direct enquiry thread (no booking yet): id = "{customerId}_{providerId}".
void openDirectChat(BuildContext context, ProviderProfile p) {
  final me = CustomerRepository.instance.uid;
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => CustomerChatScreen(
      thread: CustomerThread(
        id: '${me}_${p.id}',
        providerId: p.id,
        providerName: p.name,
        providerPhotoUrl: p.photoUrl,
        bookingNo: 'direct',
      ),
    ),
  ));
}

void openBookingChat(BuildContext context, BookingInfo b) {
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => CustomerChatScreen(
      thread: CustomerThread(
        id: b.id,
        providerId: b.providerId,
        providerName: b.providerName,
        bookingNo: b.bookingNo,
        bookingId: b.id,
      ),
    ),
  ));
}

/// Opens the right screen for a booking's current state.
void openBooking(BuildContext context, BookingInfo b) {
  Widget? page;
  if (b.status == 'completed' && !b.reviewed) {
    page = CashConfirmationScreen(bookingId: b.id);
  } else if (b.jobDone || b.status == 'completed') {
    page = CashConfirmationScreen(bookingId: b.id);
  }
  if (page != null) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page!));
  } else if (b.hasProvider) {
    openBookingChat(context, b);
  } else {
    showAdminSnack(context, 'Waiting for a provider to accept this booking.');
  }
}

void openReview(BuildContext context, String bookingId) {
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => ReviewCheckoutScreen(bookingId: bookingId),
  ));
}

/// Scheduled booking flow: checkout -> summary -> success.
void openCheckout(BuildContext context, ProviderProfile provider, ServiceItem service) {
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => BookingCheckoutScreen(provider: provider, service: service),
  ));
}

/// Emergency flow (type -> details -> providers -> confirm -> status).
void openEmergency(BuildContext context, {String? presetProviderId}) {
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => EmergencyServiceScreen(presetProviderId: presetProviderId),
  ));
}

/// Live status screen: emergency tracker for urgent bookings, details tracker otherwise.
void openTracking(BuildContext context, BookingInfo b) {
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => b.isEmergency ? EmergencyStatusScreen(bookingId: b.id) : BookingTrackingScreen(bookingId: b.id),
  ));
}
