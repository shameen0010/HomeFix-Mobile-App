import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../../admin/data/models/model_utils.dart';
import '../../../admin/data/models/service_category.dart';
import '../../../provider/data/models/notification_model.dart';
import '../../../provider/data/models/provider_profile.dart';
import '../../../provider/data/models/review_model.dart';
import '../../../provider/data/models/service_item.dart';
import '../../core/customer_ui.dart';
import '../../presentation/widgets/availability.dart';
import '../models/booking_draft.dart';
import '../models/booking_info.dart';
import '../models/customer_chat.dart';
import '../models/customer_profile.dart';

/// Single Firestore gateway for the customer module.
class CustomerRepository {
  CustomerRepository._();
  static final CustomerRepository instance = CustomerRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser?.uid ?? '_signed_out_';
  String _requireUid() {
    final u = _auth.currentUser?.uid;
    if (u == null) throw AdminException('Please sign in again.');
    return u;
  }

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _providers => _db.collection('providers');
  CollectionReference<Map<String, dynamic>> get _bookings => _db.collection('bookings');
  CollectionReference<Map<String, dynamic>> get _chats => _db.collection('chats');
  CollectionReference<Map<String, dynamic>> get _reviews => _db.collection('reviews');
  CollectionReference<Map<String, dynamic>> get _notifications => _db.collection('notifications');
  CollectionReference<Map<String, dynamic>> get _addresses => _users.doc(uid).collection('addresses');
  CollectionReference<Map<String, dynamic>> get _favorites => _users.doc(uid).collection('favorites');

  Future<T> _guard<T>(Future<T> Function() task) async {
    try {
      return await task();
    } on AdminException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AdminException(e.message ?? 'Authentication error (${e.code}).');
    } on FirebaseException catch (e) {
      switch (e.code) {
        case 'permission-denied':
          throw AdminException('You do not have permission to perform this action.');
        case 'unavailable':
          throw AdminException('Network unavailable. Check your connection and retry.');
        case 'not-found':
          throw AdminException('Record not found.');
        default:
          throw AdminException(e.message ?? 'Database error (${e.code}).');
      }
    } catch (e, st) {
      debugPrint('CustomerRepository error: $e\n$st');
      final s = e.toString();
      if (s.contains('AdminException:')) {
        throw AdminException(s.split('AdminException:').last.trim());
      }
      throw AdminException(
        s.isNotEmpty ? s.replaceFirst('Exception: ', '') : 'Unexpected error. Please try again.',
      );
    }
  }

  // ---------------------------------------------------------------- account
  Stream<CustomerProfile?> watchMe() =>
      _users.doc(uid).snapshots().map((d) => d.exists ? CustomerProfile.fromDoc(d) : null);

  Future<CustomerProfile?> getMe() => _guard(() async {
        final d = await _users.doc(_requireUid()).get();
        return d.exists ? CustomerProfile.fromDoc(d) : null;
      });

  Future<void> updateProfile({required String name, required String phone}) => _guard(() async {
        final id = _requireUid();
        await _users.doc(id).update({'name': name.trim(), 'phone': phone.trim(), 'updatedAt': FieldValue.serverTimestamp()});
      });

  Future<void> updateLocation(String location) =>
      _guard(() => _users.doc(_requireUid()).update({'location': location.trim()}));

  Future<void> setAlerts(bool v) => _guard(() => _users.doc(_requireUid()).update({'alertsEnabled': v}));

  Future<void> saveEmergencyInfo({
    required String gateCode,
    required String petSafety,
    required String secondaryPhone,
    required String notes,
  }) =>
      _guard(() => _users.doc(_requireUid()).update({
            'emergencyInfo': {
              'gateCode': gateCode.trim(),
              'petSafety': petSafety.trim(),
              'secondaryPhone': secondaryPhone.trim(),
              'notes': notes.trim(),
            },
          }));

  Future<void> uploadAvatar(Uint8List bytes) => _guard(() async {
        final id = _requireUid();
        final ref = FirebaseStorage.instance.ref('users/$id/avatar.jpg');
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
        await _users.doc(id).update({'photoUrl': await ref.getDownloadURL()});
      });

  Future<void> sendPasswordReset() => _guard(() async {
        final email = _auth.currentUser?.email;
        if (email == null || email.isEmpty) throw AdminException('No email on this account.');
        await _auth.sendPasswordResetEmail(email: email);
      });

  Future<void> signOut() => _guard(() => _auth.signOut());

  // -------------------------------------------------------------- addresses
  Stream<List<SavedAddress>> watchAddresses() => _addresses.snapshots().map((s) {
        final l = s.docs.map(SavedAddress.fromDoc).toList();
        l.sort((a, b) => a.isDefault == b.isDefault ? a.label.compareTo(b.label) : (a.isDefault ? -1 : 1));
        return l;
      });

  Future<List<SavedAddress>> getAddresses() => _guard(() async {
        final s = await _addresses.get();
        return s.docs.map(SavedAddress.fromDoc).toList();
      });

  Future<void> saveAddress({String? id, required String label, required String address, required bool isDefault}) =>
      _guard(() async {
        _requireUid();
        final batch = _db.batch();
        if (isDefault) {
          final existing = await _addresses.where('isDefault', isEqualTo: true).get();
          for (final d in existing.docs) {
            if (d.id != id) batch.update(d.reference, {'isDefault': false});
          }
        }
        final ref = id == null ? _addresses.doc() : _addresses.doc(id);
        batch.set(ref, {'label': label, 'address': address.trim(), 'isDefault': isDefault}, SetOptions(merge: true));
        await batch.commit();
      });

  Future<void> deleteAddress(String id) => _guard(() => _addresses.doc(id).delete());

  // -------------------------------------------------------------- discovery
  Stream<List<ServiceCategory>> watchCategories() => _db
      .collection('categories')
      .orderBy('order')
      .snapshots()
      .map((s) => s.docs.map(ServiceCategory.fromDoc).where((c) => c.isActive).toList());

  Stream<List<FeaturedService>> watchFeatured() => _db
      .collection('featured_services')
      .limit(10)
      .snapshots()
      .map((s) => s.docs.map(FeaturedService.fromDoc).toList());

  Stream<List<ProviderProfile>> watchProviders() => _providers
      .where('status', isEqualTo: 'approved')
      .limit(200)
      .snapshots()
      .map((s) => s.docs.map(ProviderProfile.fromDoc).toList());

  Stream<ProviderProfile?> watchProvider(String id) =>
      _providers.doc(id).snapshots().map((d) => d.exists ? ProviderProfile.fromDoc(d) : null);

  Future<ProviderProfile?> getProvider(String id) => _guard(() async {
        final d = await _providers.doc(id).get();
        return d.exists ? ProviderProfile.fromDoc(d) : null;
      });

  Stream<List<ServiceItem>> watchServices(String providerId) => _providers
      .doc(providerId)
      .collection('services')
      .snapshots()
      .map((s) => s.docs.map(ServiceItem.fromDoc).where((x) => x.isActive).toList()
        ..sort((a, b) => a.name.compareTo(b.name)));

  Stream<List<ReviewModel>> watchReviews(String providerId) => _reviews
      .where('providerId', isEqualTo: providerId)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map(ReviewModel.fromDoc).toList()
        ..sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000))));

  Stream<Set<String>> watchFavorites() => _favorites.snapshots().map((s) => s.docs.map((d) => d.id).toSet());

  Future<void> toggleFavorite(String providerId, bool makeFavorite) => _guard(() async {
        _requireUid();
        final ref = _favorites.doc(providerId);
        if (makeFavorite) {
          await ref.set({'createdAt': FieldValue.serverTimestamp()});
        } else {
          await ref.delete();
        }
      });

  // --------------------------------------------------------------- bookings

  /// Gate code / pet / notes saved in the customer's profile, shown to the provider.
  String? _accessText(Map<String, dynamic> u) {
    final e = u['emergencyInfo'];
    if (e is! Map) return null;
    final parts = <String>[
      if (asString(e['gateCode']).isNotEmpty) 'Gate code: ${e['gateCode']}',
      if (asString(e['petSafety']).isNotEmpty) 'Pets: ${e['petSafety']}',
      if (asString(e['notes']).isNotEmpty) '${e['notes']}',
    ];
    return parts.isEmpty ? null : parts.join('. ');
  }
  Stream<List<BookingInfo>> watchMyBookings() => _bookings
      .where('customerId', isEqualTo: uid)
      .limit(200)
      .snapshots()
      .map((s) => s.docs.map(BookingInfo.fromDoc).toList()
        ..sort((a, b) => (b.scheduledAt ?? DateTime(2000)).compareTo(a.scheduledAt ?? DateTime(2000))));

  Stream<BookingInfo?> watchBooking(String id) =>
      _bookings.doc(id).snapshots().map((d) => d.exists ? BookingInfo.fromDoc(d) : null);

  CollectionReference<Map<String, dynamic>> get _slots => _db.collection('booking_slots');

  /// Active services of a provider (one-shot read, used by the emergency flow).
  Future<List<ServiceItem>> getServices(String providerId) => _guard(() async {
        final s = await _providers.doc(providerId).collection('services').get();
        return s.docs.map(ServiceItem.fromDoc).where((x) => x.isActive).toList()
          ..sort((a, b) => a.price.compareTo(b.price));
      });

  /// Slots already taken on [day] for a provider (drives the arrival-window chips).
  Stream<DayLoad> watchDayLoad(String providerId, DateTime day) => _slots
      .doc(slotDayIdOf(providerId, day))
      .snapshots()
      .map((d) {
        final raw = d.data()?['slots'];
        return DayLoad(taken: raw is Map ? raw.keys.map((k) => k.toString()).toSet() : <String>{});
      });

  String? _slotProblem(ProviderProfile p, DateTime at) {
    final err = validateSlot(p, at);
    if (err != null) return err;
    final now = DateTime.now();
    final sameDay = at.year == now.year && at.month == now.month && at.day == now.day;
    if (sameDay && !p.acceptsSameDay) return '${p.name} does not accept same-day bookings.';
    return null;
  }

  Map<String, dynamic> _slotsOf(DocumentSnapshot<Map<String, dynamic>> s) {
    final raw = s.data()?['slots'];
    return raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
  }

  /// Creates the booking, its slot lock and the provider notification in ONE transaction.
  /// Standard bookings are validated against the provider's schedule, vacation, same-day
  /// rule, maxJobs per day and an exclusive slot lock (no double booking).
  Future<String> createBooking({
    required ProviderProfile provider,
    required ServiceItem service,
    required DateTime scheduledAt,
    required String address,
    String? notes,
    bool emergency = false,
    List<Uint8List> photos = const [],
  }) =>
      _guard(() async {
        final me = _requireUid();
        if (address.trim().length < 5) throw AdminException('Enter the full service address.');
        final ref = _bookings.doc();
        final uploaded = <Reference>[];
        final photoDocs = <Map<String, dynamic>>[];
        try {
          for (var i = 0; i < photos.length && i < 4; i++) {
            final r = FirebaseStorage.instance.ref('bookings/${ref.id}/request_$i.jpg');
            await r.putData(photos[i], SettableMetadata(contentType: 'image/jpeg'));
            uploaded.add(r);
            photoDocs.add({'url': await r.getDownloadURL(), 'label': 'Customer photo ${i + 1}'});
          }
          late PriceQuote finalQuote;
          await _db.runTransaction((tx) async {
            final pSnap = await tx.get(_providers.doc(provider.id));
            final pd = pSnap.data();
            if (!pSnap.exists || pd?['status'] != 'approved') {
              throw AdminException('This provider is not accepting bookings right now.');
            }
            if (pd?['catalogActive'] == false) throw AdminException('This provider has paused new bookings.');
            final fresh = ProviderProfile.fromDoc(pSnap);
            final uSnap = await tx.get(_users.doc(me));
            final u = uSnap.data() ?? <String, dynamic>{};

            DocumentReference<Map<String, dynamic>>? dayRef;
            final key = slotKeyOf(scheduledAt);
            if (emergency) {
              if (!fresh.emergencyEnabled || !fresh.isOnline) {
                throw AdminException('${fresh.name} is not taking emergency calls right now.');
              }
            } else {
              final err = _slotProblem(fresh, scheduledAt);
              if (err != null) throw AdminException(err);
              dayRef = _slots.doc(slotDayIdOf(provider.id, scheduledAt));
              final slots = _slotsOf(await tx.get(dayRef));
              if (slots.containsKey(key)) {
                throw AdminException('That arrival window was just taken. Please pick another time.');
              }
              final max = fresh.schedule[ProviderConfig.days[scheduledAt.weekday - 1]]?.maxJobs ?? 4;
              if (slots.length >= max) throw AdminException('${fresh.name} is fully booked on that day.');
            }

            final quote = emergency ? PriceQuote.emergency(service, fresh) : PriceQuote.scheduled(service);
            finalQuote = quote;
            final no = (DateTime.now().millisecondsSinceEpoch % 90000 + 10000).toString();
            tx.set(ref, {
              'bookingNo': no,
              'title': service.name,
              'category': service.category,
              'customerId': me,
              'customerName': u['name'] ?? _auth.currentUser?.displayName ?? 'Customer',
              'customerPhone': u['phone'] ?? '',
              'customerPhotoUrl': u['photoUrl'],
              'providerId': provider.id,
              'providerName': fresh.name,
              'address': address.trim(),
              'notes': notes?.trim(),
              'status': 'pending',
              'isEmergency': emergency,
              'amount': quote.total,
              'serviceAmount': quote.service,
              'guaranteeFee': quote.fee,
              'description': service.category,
              'estimatedMin': service.durationMin,
              'estimatedMax': service.durationMax,
              'customerSince': u['createdAt'],
              'accessInstructions': _accessText(u),
              'requestPhotos': photoDocs,
              'scheduledAt': Timestamp.fromDate(scheduledAt),
              'createdAt': FieldValue.serverTimestamp(),
              if (emergency) 'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 15))),
            });
            if (dayRef != null) {
              tx.set(
                  dayRef,
                  {
                    'providerId': provider.id,
                    'day': dayStrOf(scheduledAt),
                    'slots': {key: {'bookingId': ref.id, 'customerId': me}},
                  },
                  SetOptions(merge: true));
            }
          });
          try {
            await _notifications.add({
              'userId': provider.id,
              'type': emergency ? 'urgent' : 'booking',
              'title': emergency ? 'New Urgent Request nearby!' : 'New booking request',
              'body': '${service.name} at ${address.trim()}. Estimated cash payout ${formatMoney(finalQuote.total)}.',
              'jobId': ref.id,
              'read': false,
              'createdAt': FieldValue.serverTimestamp(),
            });
          } catch (e) {
            debugPrint('Failed to send provider notification: $e');
          }
        } catch (_) {
          for (final r in uploaded) {
            try {
              await r.delete();
            } catch (_) {}
          }
          rethrow;
        }
        return ref.id;
      });

  /// Moves a pending/confirmed booking to a new arrival window. Releases the old slot,
  /// locks the new one and sends the booking back to 'pending' so the provider re-accepts.
  Future<void> rescheduleBooking(String id, DateTime newAt) => _guard(() async {
        final me = _requireUid();
        final ref = _bookings.doc(id);
        String notifPid = '';
        Map<String, dynamic> notifData = const {};
        await _db.runTransaction((tx) async {
          final s = await tx.get(ref);
          if (!s.exists) throw AdminException('Booking not found.');
          final d = s.data()!;
          if (d['customerId'] != me) throw AdminException('This booking belongs to another account.');
          if (d['status'] != 'pending' && d['status'] != 'confirmed') {
            throw AdminException('This booking can no longer be rescheduled (${d['status']}).');
          }
          if (d['isEmergency'] == true) throw AdminException('Emergency requests cannot be rescheduled.');
          final pid = asString(d['providerId']);
          if (pid.isEmpty) throw AdminException('Wait until a provider is assigned before rescheduling.');
          notifPid = pid;
          notifData = d;
          final oldAt = asDate(d['scheduledAt']);
          final pSnap = await tx.get(_providers.doc(pid));
          if (!pSnap.exists) throw AdminException('This provider is no longer available.');
          final fresh = ProviderProfile.fromDoc(pSnap);
          final err = _slotProblem(fresh, newAt);
          if (err != null) throw AdminException(err);

          final newRef = _slots.doc(slotDayIdOf(pid, newAt));
          final oldRef = oldAt == null ? null : _slots.doc(slotDayIdOf(pid, oldAt));
          final sameDoc = oldRef != null && oldRef.path == newRef.path;
          final newSnap = await tx.get(newRef);
          final oldSnap = (oldRef == null || sameDoc) ? null : await tx.get(oldRef);
          final newKey = slotKeyOf(newAt);
          final oldKey = oldAt == null ? '' : slotKeyOf(oldAt);

          final slots = _slotsOf(newSnap);
          if (sameDoc) {
            final mine = slots[oldKey];
            if (mine is Map && mine['bookingId'] == id) slots.remove(oldKey);
          }
          if (slots.containsKey(newKey)) {
            throw AdminException('That arrival window is already taken. Please pick another time.');
          }
          final max = fresh.schedule[ProviderConfig.days[newAt.weekday - 1]]?.maxJobs ?? 4;
          if (slots.length >= max) throw AdminException('${fresh.name} is fully booked on that day.');
          slots[newKey] = {'bookingId': id, 'customerId': me};

          if (oldSnap != null && oldSnap.exists) {
            final old = _slotsOf(oldSnap)[oldKey];
            if (old is Map && old['bookingId'] == id) {
              tx.update(oldRef!, {'slots.$oldKey': FieldValue.delete()});
            }
          }
          tx.set(newRef, {'providerId': pid, 'day': dayStrOf(newAt), 'slots': slots});
          tx.update(ref, {
            'scheduledAt': Timestamp.fromDate(newAt),
            'status': 'pending',
            'acceptedAt': FieldValue.delete(),
            if (oldAt != null) 'previousScheduledAt': Timestamp.fromDate(oldAt),
            'rescheduledAt': FieldValue.serverTimestamp(),
          });
        });
        if (notifPid.isNotEmpty) {
          try {
            await _notifications.add({
              'userId': notifPid,
              'type': 'booking',
              'title': 'Booking rescheduled',
              'body': '${notifData['customerName'] ?? 'A customer'} moved ${notifData['title'] ?? 'a booking'} to '
                  '${formatDate(newAt, 'EEE, MMM d, h:mm a')}. Please accept again.',
              'jobId': id,
              'read': false,
              'createdAt': FieldValue.serverTimestamp(),
            });
          } catch (e) {
            debugPrint('Failed to send reschedule notification: $e');
          }
        }
      });

  /// Cancels (pending/confirmed only), releases the provider's slot and notifies them.
  Future<void> cancelBooking(String id, String reason, {String? comments}) => _guard(() async {
        final ref = _bookings.doc(id);
        final me = _requireUid();
        String notifPid = '';
        Map<String, dynamic> notifData = const {};
        await _db.runTransaction((tx) async {
          final s = await tx.get(ref);
          if (!s.exists) throw AdminException('Booking not found.');
          final d = s.data()!;
          if (d['customerId'] != me) throw AdminException('This booking belongs to another account.');
          if (d['status'] != 'pending' && d['status'] != 'confirmed') {
            throw AdminException('This booking can no longer be cancelled (${d['status']}).');
          }
          final pid = asString(d['providerId']);
          notifPid = pid;
          notifData = d;
          final at = asDate(d['scheduledAt']);
          final dayRef = (pid.isNotEmpty && at != null && d['isEmergency'] != true)
              ? _slots.doc(slotDayIdOf(pid, at))
              : null;
          final daySnap = dayRef == null ? null : await tx.get(dayRef);

          tx.update(ref, {
            'status': 'cancelled',
            'cancelReason': reason,
            if (comments != null && comments.trim().isNotEmpty) 'cancelComments': comments.trim(),
            'cancelledBy': 'customer',
            'cancelledAt': FieldValue.serverTimestamp(),
          });
          if (dayRef != null && daySnap != null && daySnap.exists && at != null) {
            final key = slotKeyOf(at);
            final mine = _slotsOf(daySnap)[key];
            if (mine is Map && mine['bookingId'] == id) tx.update(dayRef, {'slots.$key': FieldValue.delete()});
          }
        });
        if (notifPid.isNotEmpty) {
          try {
            await _notifications.add({
              'userId': notifPid,
              'type': 'booking',
              'title': 'Booking cancelled',
              'body': '${notifData['customerName'] ?? 'The customer'} cancelled ${notifData['title'] ?? 'a booking'}. Reason: $reason',
              'jobId': id,
              'read': false,
              'createdAt': FieldValue.serverTimestamp(),
            });
          } catch (e) {
            debugPrint('Failed to send cancel notification: $e');
          }
        }
      });

  /// Customer side of the dual cash handshake.
  Future<void> attestCash(String id) => _guard(() async {
        final ref = _bookings.doc(id);
        final me = _requireUid();
        await _db.runTransaction((tx) async {
          final s = await tx.get(ref);
          if (!s.exists) throw AdminException('Booking not found.');
          final d = s.data()!;
          if (d['customerId'] != me) throw AdminException('This booking belongs to another account.');
          if (d['stage'] != 'done' && d['status'] != 'completed') {
            throw AdminException('The provider has not finished the job yet.');
          }
          if (d['customerAttested'] == true) throw AdminException('You already confirmed this payment.');
          tx.update(ref, {'customerAttested': true, 'customerAttestedAt': FieldValue.serverTimestamp()});
        });
      });

  /// Review + provider rating aggregate + notification, all in one transaction.
  Future<void> submitReview({
    required String bookingId,
    required double rating,
    required String comment,
    required List<String> tags,
  }) =>
      _guard(() async {
        final me = _requireUid();
        final bRef = _bookings.doc(bookingId);
        final rRef = _reviews.doc(bookingId);
        String notifPid = '';
        String notifCustomer = '';
        await _db.runTransaction((tx) async {
          final b = await tx.get(bRef);
          if (!b.exists) throw AdminException('Booking not found.');
          final bd = b.data()!;
          if (bd['customerId'] != me) throw AdminException('This booking belongs to another account.');
          if (bd['status'] != 'completed') throw AdminException('You can review once the job is closed.');
          if (bd['reviewed'] == true) throw AdminException('You already reviewed this job.');
          final pid = asString(bd['providerId']);
          if (pid.isEmpty) throw AdminException('No provider is linked to this booking.');
          notifPid = pid;
          notifCustomer = asString(bd['customerName'], 'A customer');
          final pRef = _providers.doc(pid);
          final p = await tx.get(pRef);
          final pd = p.data() ?? <String, dynamic>{};
          final count = asInt(pd['reviewCount']);
          final avg = asDouble(pd['rating']);
          final newCount = count + 1;
          final newAvg = ((avg * count) + rating) / newCount;
          tx.set(rRef, {
            'providerId': pid,
            'customerId': me,
            'customerName': bd['customerName'],
            'customerPhotoUrl': bd['customerPhotoUrl'],
            'bookingId': bookingId,
            'service': bd['title'],
            'rating': rating,
            'comment': comment.trim(),
            'tags': tags,
            'verified': true,
            'createdAt': FieldValue.serverTimestamp(),
          });
          tx.update(bRef, {'reviewed': true});
          if (p.exists) {
            tx.update(pRef, {
              'rating': double.parse(newAvg.toStringAsFixed(2)),
              'reviewCount': newCount,
              if (tags.isNotEmpty) 'tags': FieldValue.arrayUnion(tags),
            });
          }
        });
        if (notifPid.isNotEmpty) {
          try {
            await _notifications.add({
              'userId': notifPid,
              'type': 'review',
              'title': '${rating.toStringAsFixed(0)}-Star Review Received!',
              'body': comment.trim().isEmpty ? '$notifCustomer rated you ${rating.toStringAsFixed(0)} stars.' : comment.trim(),
              'jobId': bookingId,
              'read': false,
              'createdAt': FieldValue.serverTimestamp(),
            });
          } catch (e) {
            debugPrint('Failed to send review notification: $e');
          }
        }
      });

  // ------------------------------------------------------------------- chat
  Stream<List<CustomerThread>> watchThreads() => _chats
      .where('customerId', isEqualTo: uid)
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map(CustomerThread.fromDoc).toList()
        ..sort((a, b) => (b.lastAt ?? DateTime(2000)).compareTo(a.lastAt ?? DateTime(2000))));

  Stream<List<CustomerMessage>> watchMessages(String chatId) => _chats
      .doc(chatId)
      .collection('messages')
      .orderBy('createdAt')
      .limit(300)
      .snapshots()
      .map((s) => s.docs.map(CustomerMessage.fromDoc).toList());

  Future<void> sendMessage(CustomerThread t, {String text = '', Uint8List? image}) => _guard(() async {
        final me = _requireUid();
        if (text.trim().isEmpty && image == null) throw AdminException('Type a message first.');
        final u = (await _users.doc(me).get()).data() ?? <String, dynamic>{};
        String? imageUrl;
        if (image != null) {
          final ref = FirebaseStorage.instance
              .ref('chats/${t.id}/${DateTime.now().millisecondsSinceEpoch}.jpg');
          await ref.putData(image, SettableMetadata(contentType: 'image/jpeg'));
          imageUrl = await ref.getDownloadURL();
        }
        final ref = _chats.doc(t.id);
        final batch = _db.batch();
        batch.set(
          ref,
          {
            'customerId': me,
            'customerName': u['name'] ?? 'Customer',
            'customerPhotoUrl': u['photoUrl'],
            'providerId': t.providerId,
            'providerName': t.providerName,
            'providerPhotoUrl': t.providerPhotoUrl,
            'bookingNo': t.bookingNo,
            if (t.bookingId != null) 'bookingId': t.bookingId,
            'lastMessage': text.trim().isEmpty ? 'Photo' : text.trim(),
            'lastAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        batch.set(ref.collection('messages').doc(), {
          'senderId': me,
          'text': text.trim(),
          if (imageUrl != null) 'imageUrl': imageUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await batch.commit();
      });

  // ---------------------------------------------------------- notifications
  Stream<List<NotificationModel>> watchNotifications() => _notifications
      .where('userId', isEqualTo: uid)
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map(NotificationModel.fromDoc).toList()
        ..sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000))));

  Stream<int> watchUnreadCount() => _notifications
      .where('userId', isEqualTo: uid)
      .where('read', isEqualTo: false)
      .snapshots()
      .map((s) => s.size);

  Future<void> markAllRead(List<String> ids) => _guard(() async {
        final batch = _db.batch();
        for (final id in ids) {
          batch.update(_notifications.doc(id), {'read': true});
        }
        await batch.commit();
      });

  Future<void> dismissNotification(String id) => _guard(() => _notifications.doc(id).delete());
}
