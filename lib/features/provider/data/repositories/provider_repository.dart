import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../admin/data/models/model_utils.dart';
import '../../core/provider_ui.dart';
import '../models/chat_models.dart';
import '../models/job_model.dart';
import '../models/notification_model.dart';
import '../models/provider_profile.dart';
import '../models/review_model.dart';
import '../models/service_item.dart';

/// Single Firestore gateway for the service-provider module.
/// Streams for reads; guarded writes throw [AdminException] (SnackBar-safe).
class ProviderRepository {
  ProviderRepository._();
  static final ProviderRepository instance = ProviderRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser?.uid ?? '_signed_out_';
  String _requireUid() {
    final u = _auth.currentUser?.uid;
    if (u == null) throw AdminException('Please sign in again.');
    return u;
  }

  CollectionReference<Map<String, dynamic>> get _providers => _db.collection('providers');
  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _bookings => _db.collection('bookings');
  CollectionReference<Map<String, dynamic>> get _chats => _db.collection('chats');
  CollectionReference<Map<String, dynamic>> get _reviews => _db.collection('reviews');
  CollectionReference<Map<String, dynamic>> get _notifications => _db.collection('notifications');
  CollectionReference<Map<String, dynamic>> get _services => _providers.doc(uid).collection('services');

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
    } catch (_) {
      throw AdminException('Unexpected error. Please try again.');
    }
  }

  // ---------------------------------------------------------------- profile
  Stream<ProviderProfile?> watchProfile() => _providers
      .doc(uid)
      .snapshots()
      .map((d) => d.exists ? ProviderProfile.fromDoc(d) : null);

  Future<ProviderProfile?> getProfile() => _guard(() async {
        final d = await _providers.doc(_requireUid()).get();
        return d.exists ? ProviderProfile.fromDoc(d) : null;
      });

  /// Registration step "Trade Credentials": creates (or updates) providers/{uid}
  /// as `pending` so it appears in the admin verification queue.
  Future<void> saveTradeCredentials(List<String> trades) => _guard(() async {
        final id = _requireUid();
        final user = _auth.currentUser!;
        final uRef = _users.doc(id);
        final pRef = _providers.doc(id);
        final u = await uRef.get();
        final p = await pRef.get();
        final ud = u.data() ?? <String, dynamic>{};
        final batch = _db.batch();
        final base = <String, dynamic>{
          'trades': trades,
          'trade': trades.first,
          'services': trades,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (p.exists) {
          batch.update(pRef, base);
        } else {
          batch.set(pRef, {
            ...base,
            'name': ud['name'] ?? user.displayName ?? 'New provider',
            'email': ud['email'] ?? user.email ?? '',
            'phone': ud['phone'] ?? user.phoneNumber ?? '',
            'status': 'pending',
            'isOnline': false,
            'rating': 0,
            'reviewCount': 0,
            'completedCount': 0,
            'experienceYears': 0,
            'documents': <Object>[],
            'appId': shortId(id),
            'submittedAt': FieldValue.serverTimestamp(),
          });
        }
        batch.set(
          uRef,
          {'role': 'provider', 'providerStatus': p.data()?['status'] ?? 'pending'},
          SetOptions(merge: true),
        );
        await batch.commit();
      });

  Future<void> setOnline(bool online) =>
      _guard(() => _providers.doc(_requireUid()).update({'isOnline': online}));

  Future<void> setCatalogActive(bool v) =>
      _guard(() => _providers.doc(_requireUid()).update({'catalogActive': v}));

  Future<void> updateCoverage(String area, int radius) => _guard(() =>
      _providers.doc(_requireUid()).update({'coverageArea': area.trim(), 'radiusMiles': radius}));

  /// Profile + linked users doc updated atomically.
  Future<void> updateProfile({
    required String name,
    required String headline,
    required String phone,
    required int experienceYears,
    required String coverageArea,
    required int radiusMiles,
    required String bio,
    required double standardRate,
    required double emergencyRate,
  }) =>
      _guard(() async {
        final id = _requireUid();
        final batch = _db.batch();
        batch.update(_providers.doc(id), {
          'name': name.trim(),
          'headline': headline.trim(),
          'phone': phone.trim(),
          'experienceYears': experienceYears,
          'coverageArea': coverageArea.trim(),
          'radiusMiles': radiusMiles,
          'bio': bio.trim(),
          'pricing': [
            PricingItem(
                    title: 'Standard Diagnostic & 1st Hour',
                    subtitle: 'Includes equipment check & triage',
                    price: standardRate)
                .toMap(),
            PricingItem(
                    title: 'Emergency Response',
                    subtitle: 'Urgent call-outs',
                    price: emergencyRate,
                    badge: '24/7')
                .toMap(),
          ],
          'updatedAt': FieldValue.serverTimestamp(),
        });
        batch.set(_users.doc(id), {'name': name.trim(), 'phone': phone.trim()}, SetOptions(merge: true));
        await batch.commit();
      });

  Future<void> saveAvailability({
    required Map<String, DaySchedule> schedule,
    required bool acceptsSameDay,
    DateTime? vacationFrom,
    DateTime? vacationTo,
  }) =>
      _guard(() => _providers.doc(_requireUid()).update({
            'schedule': {for (final e in schedule.entries) e.key: e.value.toMap()},
            'acceptsSameDay': acceptsSameDay,
            'vacationFrom': vacationFrom == null ? FieldValue.delete() : Timestamp.fromDate(vacationFrom),
            'vacationTo': vacationTo == null ? FieldValue.delete() : Timestamp.fromDate(vacationTo),
            'availabilityUpdatedAt': FieldValue.serverTimestamp(),
          }));

  Future<void> updateDispatchPrefs({bool? emergency, int? travelBufferMins}) =>
      _guard(() => _providers.doc(_requireUid()).update({
            if (emergency != null) 'emergencyEnabled': emergency,
            if (travelBufferMins != null) 'travelBufferMins': travelBufferMins,
          }));

  Future<void> sendPasswordReset() => _guard(() async {
        final email = _auth.currentUser?.email;
        if (email == null || email.isEmpty) throw AdminException('No email on this account.');
        await _auth.sendPasswordResetEmail(email: email);
      });

  Future<void> signOut() => _guard(() => _auth.signOut());

  // --------------------------------------------------------------- services
  Stream<List<ServiceItem>> watchServices() => _services
      .snapshots()
      .map((s) => s.docs.map(ServiceItem.fromDoc).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())));

  Future<void> saveService({
    String? id,
    required String name,
    required String category,
    required double price,
    required String priceType,
    required int durationMin,
    required int durationMax,
    required bool isActive,
  }) =>
      _guard(() async {
        _requireUid();
        final data = <String, dynamic>{
          'name': name.trim(),
          'category': category,
          'price': price,
          'priceType': priceType,
          'durationMin': durationMin,
          'durationMax': durationMax,
          'isActive': isActive,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (id == null) {
          await _services.add({...data, 'createdAt': FieldValue.serverTimestamp()});
        } else {
          await _services.doc(id).update(data);
        }
      });

  Future<void> setServiceActive(String id, bool v) =>
      _guard(() => _services.doc(id).update({'isActive': v}));

  Future<void> deleteService(String id) => _guard(() => _services.doc(id).delete());

  // ------------------------------------------------------------------- jobs
  Stream<List<JobModel>> watchJobs() => _bookings
      .where('providerId', isEqualTo: uid)
      .limit(300)
      .snapshots()
      .map((s) => s.docs.map(JobModel.fromDoc).toList());

  Future<JobModel?> getJob(String id) => _guard(() async {
        final d = await _bookings.doc(id).get();
        return d.exists ? JobModel.fromDoc(d) : null;
      });

  /// Requests this provider declined (providerId is cleared on decline, so we
  /// query the declinedBy array instead).
  Stream<List<JobModel>> watchDeclinedJobs() => _bookings
      .where('declinedBy', arrayContains: uid)
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map(JobModel.fromDoc).toList()
        ..sort((a, b) => (b.scheduledAt ?? DateTime(2000)).compareTo(a.scheduledAt ?? DateTime(2000))));

  Stream<JobModel?> watchJob(String id) =>
      _bookings.doc(id).snapshots().map((d) => d.exists ? JobModel.fromDoc(d) : null);

  Future<void> acceptJob(String id) => _guard(() async {
        final ref = _bookings.doc(id);
        final me = _requireUid();
        await _db.runTransaction((tx) async {
          final s = await tx.get(ref);
          if (!s.exists) throw AdminException('Booking not found.');
          final d = s.data()!;
          if (d['providerId'] != me) throw AdminException('This request is no longer assigned to you.');
          if (d['status'] != 'pending') throw AdminException('This request is already ${d['status']}.');
          final exp = asDate(d['expiresAt']);
          if (exp != null && exp.isBefore(DateTime.now())) throw AdminException('This request has expired.');
          tx.update(ref, {'status': 'confirmed', 'acceptedAt': FieldValue.serverTimestamp()});
        });
      });

  /// Returns the booking to the dispatch pool so admin can reassign it.
  Future<void> declineJob(String id) => _guard(() async {
        final ref = _bookings.doc(id);
        final me = _requireUid();
        await _db.runTransaction((tx) async {
          final s = await tx.get(ref);
          if (!s.exists) throw AdminException('Booking not found.');
          final d = s.data()!;
          if (d['providerId'] != me || d['status'] != 'pending') {
            throw AdminException('This request can no longer be declined.');
          }
          // Release the customer's slot lock (booking_slots) so the time can be booked again.
          final at = asDate(d['scheduledAt']);
          String two(int n) => n.toString().padLeft(2, '0');
          final slotRef = (at == null || d['isEmergency'] == true)
              ? null
              : _db.collection('booking_slots').doc('${me}_${at.year}${two(at.month)}${two(at.day)}');
          final slotKey = at == null ? '' : '${two(at.hour)}${two(at.minute)}';
          final slotSnap = slotRef == null ? null : await tx.get(slotRef);
          final slots = slotSnap?.data()?['slots'];
          if (slotRef != null && slotSnap != null && slotSnap.exists && slots is Map) {
            final lock = slots[slotKey];
            if (lock is Map && lock['bookingId'] == id) {
              tx.update(slotRef, {'slots.$slotKey': FieldValue.delete()});
            }
          }
          tx.update(ref, {
            'providerId': FieldValue.delete(),
            'providerName': FieldValue.delete(),
            'declinedBy': FieldValue.arrayUnion([me]),
            'declinedAt': FieldValue.serverTimestamp(),
          });
        });
      });

  Future<void> startJob(String id) => _guard(() async {
        final ref = _bookings.doc(id);
        await _db.runTransaction((tx) async {
          final s = await tx.get(ref);
          if (!s.exists) throw AdminException('Booking not found.');
          final d = s.data()!;
          if (d['status'] == 'in_progress') return;
          if (d['status'] != 'confirmed') throw AdminException('Only confirmed jobs can be started.');
          final hasList = (d['checklist'] as List? ?? const []).isNotEmpty;
          tx.update(ref, {
            'status': 'in_progress',
            'stage': 'en_route',
            'startedAt': FieldValue.serverTimestamp(),
            if (!hasList)
              'checklist': [
                for (final t in const [
                  'Confirm job scope with customer',
                  'Complete the repair work',
                  'Test and check for issues',
                  'Clean the work area',
                ])
                  {'title': t, 'done': false, 'mandatory': true},
              ],
          });
        });
      });

  Future<void> setStage(String id, String stage) => _guard(
      () => _bookings.doc(id).update({'stage': stage, 'stageUpdatedAt': FieldValue.serverTimestamp()}));

  Future<void> toggleChecklist(String id, int index, bool done) => _guard(() async {
        final ref = _bookings.doc(id);
        await _db.runTransaction((tx) async {
          final s = await tx.get(ref);
          final list = List<Map<String, dynamic>>.from(
              (s.data()?['checklist'] as List? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)));
          if (index < 0 || index >= list.length) throw AdminException('Checklist item not found.');
          list[index]['done'] = done;
          tx.update(ref, {'checklist': list});
        });
      });

  Future<void> addNote(String id, String note) => _guard(
      () => _bookings.doc(id).update({'inspectionNotes': FieldValue.arrayUnion([note.trim()])}));

  Future<void> addPhoto(String id, Uint8List bytes, String label) => _guard(() async {
        final ref = FirebaseStorage.instance
            .ref('bookings/$id/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
        final url = await ref.getDownloadURL();
        await _bookings.doc(id).update({
          'photos': FieldValue.arrayUnion([
            {'url': url, 'label': label}
          ]),
        });
      });

  Future<void> completeJob(String id) => _guard(() async {
        final ref = _bookings.doc(id);
        await _db.runTransaction((tx) async {
          final s = await tx.get(ref);
          if (!s.exists) throw AdminException('Booking not found.');
          final list = (s.data()?['checklist'] as List? ?? const []).whereType<Map>();
          final pending = list.any((m) => (m['mandatory'] ?? true) == true && m['done'] != true);
          if (pending) throw AdminException('Finish all mandatory checklist items first.');
          tx.update(ref, {'stage': 'done', 'finishedAt': FieldValue.serverTimestamp()});
        });
      });

  /// Closes the job and bumps the provider's completed counter atomically.
  Future<void> confirmReceipt(String id) => _guard(() async {
        final ref = _bookings.doc(id);
        final pRef = _providers.doc(_requireUid());
        await _db.runTransaction((tx) async {
          final s = await tx.get(ref);
          if (!s.exists) throw AdminException('Booking not found.');
          final d = s.data()!;
          if (d['providerId'] != uid) throw AdminException('This job is not assigned to you.');
          if (d['stage'] != 'done') throw AdminException('Complete the job before closing it.');
          if (d['receiptConfirmed'] == true) throw AdminException('Receipt was already confirmed.');
          tx.update(ref, {
            'status': 'completed',
            'receiptConfirmed': true,
            'cashCollectedAt': FieldValue.serverTimestamp(),
            'completedAt': FieldValue.serverTimestamp(),
          });
          tx.update(pRef, {'completedCount': FieldValue.increment(1)});
        });
      });

  Future<void> sendReceipt(JobModel j) => _guard(() async {
        if (j.customerId.isEmpty) throw AdminException('Customer account not found.');
        await _notifications.add({
          'userId': j.customerId,
          'type': 'payment',
          'title': 'Payment receipt ${j.code}',
          'body': 'Cash payment of ${formatMoney(j.amount)} for ${j.title} was received.',
          'jobId': j.id,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

  // ------------------------------------------------------------------- chat
  Stream<List<ChatThread>> watchThreads() => _chats
      .where('providerId', isEqualTo: uid)
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map(ChatThread.fromDoc).toList()
        ..sort((a, b) => (b.lastAt ?? DateTime(2000)).compareTo(a.lastAt ?? DateTime(2000))));

  Stream<List<ChatMessage>> watchMessages(String chatId) => _chats
      .doc(chatId)
      .collection('messages')
      .orderBy('createdAt')
      .limit(300)
      .snapshots()
      .map((s) => s.docs.map(ChatMessage.fromDoc).toList());

  Future<void> sendMessage(ChatThread t, String text) => _guard(() async {
        final me = _requireUid();
        final ref = _chats.doc(t.id);
        final batch = _db.batch();
        batch.set(
          ref,
          {
            ...t.toMap(),
            'providerId': me,
            'lastMessage': text,
            'lastAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        batch.set(ref.collection('messages').doc(), {
          'senderId': me,
          'text': text,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await batch.commit();
      });

  // ---------------------------------------------------------------- reviews
  Stream<List<ReviewModel>> watchReviews() => _reviews
      .where('providerId', isEqualTo: uid)
      .limit(200)
      .snapshots()
      .map((s) => s.docs.map(ReviewModel.fromDoc).toList()
        ..sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000))));

  Future<void> replyToReview(String id, String text) => _guard(() => _reviews.doc(id).update({
        'reply': {'text': text.trim(), 'at': FieldValue.serverTimestamp()},
      }));

  Future<void> deleteReply(String id) =>
      _guard(() => _reviews.doc(id).update({'reply': FieldValue.delete()}));

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
