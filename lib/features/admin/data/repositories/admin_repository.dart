import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/admin_exception.dart';
import '../../core/admin_theme.dart';
import '../models/app_user.dart';
import '../models/booking_model.dart';
import '../models/dispute_model.dart';
import '../models/model_utils.dart';
import '../models/provider_model.dart';
import '../models/service_category.dart';

class AdminCounts {
  const AdminCounts({
    required this.customers,
    required this.newCustomers,
    required this.providers,
    required this.approvedProviders,
    required this.pendingProviders,
    required this.openDisputes,
  });
  final int customers, newCustomers, providers, approvedProviders,
      pendingProviders, openDisputes;
}

/// Single entry point to Firestore for the admin module.
/// Reads are exposed as streams (realtime); writes are guarded and throw
/// [AdminException] with a message that is safe to show in a SnackBar.
class AdminRepository {
  AdminRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _providers => _db.collection('providers');
  CollectionReference<Map<String, dynamic>> get _categories => _db.collection('categories');
  CollectionReference<Map<String, dynamic>> get _bookings => _db.collection('bookings');
  CollectionReference<Map<String, dynamic>> get _disputes => _db.collection('disputes');

  String get currentAdminId => _auth.currentUser?.uid ?? 'unknown';
  String get currentAdminTag => shortId(currentAdminId);

  // ---------------------------------------------------------------- guard
  Future<T> _guard<T>(Future<T> Function() task) async {
    try {
      return await task();
    } on AdminException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AdminException(e.message ?? 'Authentication error (${e.code}).');
    } on FirebaseException catch (e) {
      throw AdminException(_firestoreMessage(e));
    } catch (_) {
      throw AdminException('Unexpected error. Please try again.');
    }
  }

  String _firestoreMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'You do not have permission to perform this action.';
      case 'unavailable':
        return 'Network unavailable. Check your connection and retry.';
      case 'not-found':
        return 'Record not found.';
      case 'aborted':
        return 'Another change happened at the same time. Please retry.';
      default:
        return e.message ?? 'Database error (${e.code}).';
    }
  }

  // ------------------------------------------------------------- customers
  Stream<List<AppUser>> watchCustomers() => _users
      .where('role', isEqualTo: 'customer')
      .limit(AdminConfig.queryLimit)
      .snapshots()
      .map((s) {
        final list = s.docs.map(AppUser.fromDoc).toList();
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return list;
      });

  Stream<AppUser?> watchUser(String id) => _users
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? AppUser.fromDoc(d) : null);

  Future<void> setCustomerActive(String uid,
          {required bool active, String? reason}) =>
      _guard(() => _users.doc(uid).update({
            'status': active ? 'active' : 'suspended',
            'suspendReason':
                active ? FieldValue.delete() : (reason ?? 'No reason provided'),
            'statusUpdatedAt': FieldValue.serverTimestamp(),
            'statusUpdatedBy': currentAdminId,
          }));

  Future<void> updateCustomer(String uid,
          {required String name,
          required String phone,
          required String address}) =>
      _guard(() => _users.doc(uid).update({
            'name': name.trim(),
            'phone': phone.trim(),
            'address': address.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          }));

  Future<void> sendPasswordReset(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email));

  // ------------------------------------------------------------- providers
  Stream<List<ProviderModel>> watchProviders() => _providers
      .limit(AdminConfig.queryLimit)
      .snapshots()
      .map((s) {
        final list = s.docs.map(ProviderModel.fromDoc).toList();
        list.sort((a, b) {
          if (a.isPending != b.isPending) return a.isPending ? -1 : 1;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        return list;
      });

  Stream<ProviderModel?> watchProvider(String id) => _providers
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? ProviderModel.fromDoc(d) : null);

  Stream<List<AuditEntry>> watchProviderAudit(String id) => _providers
      .doc(id)
      .collection('audit')
      .orderBy('at', descending: true)
      .limit(30)
      .snapshots()
      .map((s) => s.docs.map(AuditEntry.fromDoc).toList());

  /// Atomic status change: provider doc, linked user doc and audit entry are
  /// written in ONE transaction, and only if the current status allows it.
  Future<void> _changeProviderStatus(
    String id, {
    required String to,
    required List<String> from,
    String? reason,
  }) =>
      _guard(() async {
        final pRef = _providers.doc(id);
        final uRef = _users.doc(id);
        final adminId = currentAdminId;
        await _db.runTransaction((tx) async {
          final p = await tx.get(pRef);
          if (!p.exists) throw AdminException('Provider record not found.');
          final current = asString(p.data()?['status'], 'pending');
          if (!from.contains(current)) {
            throw AdminException(
                'Action not allowed: provider is already "$current".');
          }
          final u = await tx.get(uRef);
          tx.update(pRef, {
            'status': to,
            'statusReason': reason ?? FieldValue.delete(),
            'reviewedAt': FieldValue.serverTimestamp(),
            'reviewedBy': adminId,
            if (to == 'approved' || to == 'rejected')
              'infoRequest': FieldValue.delete(),
          });
          if (u.exists) tx.update(uRef, {'providerStatus': to});
          tx.set(pRef.collection('audit').doc(), {
            'action': to,
            'from': current,
            'reason': reason,
            'by': adminId,
            'at': FieldValue.serverTimestamp(),
          });
        });
      });

  Future<void> approveProvider(String id) =>
      _changeProviderStatus(id, to: 'approved', from: const ['pending']);

  Future<void> rejectProvider(String id, String reason) =>
      _changeProviderStatus(id,
          to: 'rejected', from: const ['pending'], reason: reason);

  Future<void> suspendProvider(String id, String reason) =>
      _changeProviderStatus(id,
          to: 'suspended', from: const ['approved'], reason: reason);

  Future<void> reinstateProvider(String id) =>
      _changeProviderStatus(id, to: 'approved', from: const ['suspended']);

  Future<void> reEvaluateProvider(String id) =>
      _changeProviderStatus(id, to: 'pending', from: const ['rejected']);

  Future<void> requestProviderInfo(String id, String message) =>
      _guard(() async {
        final pRef = _providers.doc(id);
        final batch = _db.batch();
        batch.update(pRef, {
          'infoRequest': {
            'message': message,
            'by': currentAdminId,
            'at': FieldValue.serverTimestamp(),
          },
        });
        batch.set(pRef.collection('audit').doc(), {
          'action': 'info_requested',
          'reason': message,
          'by': currentAdminId,
          'at': FieldValue.serverTimestamp(),
        });
        await batch.commit();
      });

  // ------------------------------------------------------------ categories
  Stream<List<ServiceCategory>> watchCategories() => _categories
      .orderBy('order')
      .snapshots()
      .map((s) => s.docs.map(ServiceCategory.fromDoc).toList());

  Future<void> saveCategory({
    String? id,
    required String name,
    required String icon,
    required int servicesCount,
    int nextOrder = 0,
  }) =>
      _guard(() async {
        final data = <String, dynamic>{
          'name': name.trim(),
          'icon': icon,
          'servicesCount': servicesCount,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (id == null) {
          await _categories.add({
            ...data,
            'isActive': true,
            'prosCount': 0,
            'order': nextOrder,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          await _categories.doc(id).update(data);
        }
      });

  Future<void> setCategoryActive(String id, bool active) =>
      _guard(() => _categories.doc(id).update({'isActive': active}));

  Future<void> deleteCategory(String id) =>
      _guard(() => _categories.doc(id).delete());

  Future<void> reorderCategories(List<String> orderedIds) => _guard(() async {
        final batch = _db.batch();
        for (var i = 0; i < orderedIds.length; i++) {
          batch.update(_categories.doc(orderedIds[i]), {'order': i});
        }
        await batch.commit();
      });

  // -------------------------------------------------------------- bookings
  Stream<List<BookingModel>> watchBookings({int limit = 200}) => _bookings
      .orderBy('scheduledAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(BookingModel.fromDoc).toList());

  Stream<List<BookingModel>> watchCustomerBookings(String uid) => _bookings
      .where('customerId', isEqualTo: uid)
      .limit(50)
      .snapshots()
      .map((s) {
        final list = s.docs.map(BookingModel.fromDoc).toList();
        list.sort((a, b) => (b.scheduledAt ?? DateTime(2000))
            .compareTo(a.scheduledAt ?? DateTime(2000)));
        return list;
      });

  Future<void> cancelBooking(String id, String reason) => _guard(() async {
        final ref = _bookings.doc(id);
        await _db.runTransaction((tx) async {
          final snap = await tx.get(ref);
          if (!snap.exists) throw AdminException('Booking not found.');
          final status = asString(snap.data()?['status'], 'pending');
          if (status == 'completed' || status == 'cancelled') {
            throw AdminException('This booking is already $status.');
          }
          tx.update(ref, {
            'status': 'cancelled',
            'cancelReason': reason,
            'cancelledBy': 'admin',
            'cancelledAt': FieldValue.serverTimestamp(),
          });
        });
      });

  // -------------------------------------------------------------- disputes
  Stream<List<DisputeModel>> watchDisputes() => _disputes
      .orderBy('createdAt', descending: true)
      .limit(200)
      .snapshots()
      .map((s) => s.docs.map(DisputeModel.fromDoc).toList());

  Future<void> updateDispute(String id,
          {required String status, String? resolution}) =>
      _guard(() => _disputes.doc(id).update({
            'status': status,
            if (resolution != null) 'resolution': resolution,
            'handledBy': currentAdminId,
            'handledAt': FieldValue.serverTimestamp(),
          }));

  // ---------------------------------------------------------------- counts
  Future<AdminCounts> fetchCounts() => _guard(() async {
        final now = DateTime.now();
        final monthStart = Timestamp.fromDate(DateTime(now.year, now.month));

        Future<int> count(Query<Map<String, dynamic>> q) async {
          final snap = await q.count().get();
          return snap.count ?? 0;
        }

        final results = await Future.wait<int>([
          count(_users.where('role', isEqualTo: 'customer')),
          count(_providers),
          count(_providers.where('status', isEqualTo: 'approved')),
          count(_providers.where('status', isEqualTo: 'pending')),
          count(_disputes.where('status', isEqualTo: 'pending')),
          // single-field range query (no composite index), role filtered here
          _users
              .where('createdAt', isGreaterThanOrEqualTo: monthStart)
              .limit(1000)
              .get()
              .then((s) =>
                  s.docs.where((d) => d.data()['role'] == 'customer').length),
        ]);
        return AdminCounts(
          customers: results[0],
          providers: results[1],
          approvedProviders: results[2],
          pendingProviders: results[3],
          openDisputes: results[4],
          newCustomers: results[5],
        );
      });
}
