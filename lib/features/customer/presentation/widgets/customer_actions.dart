import 'package:flutter/material.dart';

import '../../../provider/data/models/provider_profile.dart';
import '../../core/customer_ui.dart';
import '../../data/models/booking_info.dart';
import '../../data/models/customer_chat.dart';
import '../screens/customer_chat_screen.dart';
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
