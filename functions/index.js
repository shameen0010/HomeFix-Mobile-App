const { onDocumentCreated, onDocumentWritten } = require('firebase-functions/v2/firestore');
const { setGlobalOptions } = require('firebase-functions/v2');
const admin = require('firebase-admin');

admin.initializeApp();
setGlobalOptions({ region: 'us-central1', maxInstances: 10 });

const db = admin.firestore();

function notificationId(bookingId, userId, type, updatedAt) {
  const suffix = updatedAt ? updatedAt.toMillis() : Date.now();
  return `${bookingId}_${userId}_${type}_${suffix}`;
}

async function createNotification({ userId, bookingId, type, title, body }) {
  if (!userId || !bookingId) return;
  await db.collection('notifications').doc(notificationId(bookingId, userId, type)).set({
    userId,
    bookingId,
    type,
    title,
    body,
    read: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

exports.notifyBookingCreated = onDocumentCreated('bookings/{bookingId}', async (event) => {
  const booking = event.data.data();
  await createNotification({
    userId: booking.providerId,
    bookingId: event.params.bookingId,
    type: 'booking_request',
    title: 'New booking request',
    body: `${booking.customerName || 'A customer'} requested ${booking.serviceTitle || booking.service || 'a service'}.`,
  });
});

exports.notifyBookingStatusChanged = onDocumentWritten('bookings/{bookingId}', async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (!before || !after || before.status === after.status) return;
  const recipient = after.status === 'pending' ? after.providerId : after.customerId;
  await createNotification({
    userId: recipient,
    bookingId: event.params.bookingId,
    type: 'booking_status',
    title: 'Booking status updated',
    body: `Your booking is now ${String(after.status).replaceAll('_', ' ')}.`,
  });
});

exports.aggregateProviderRating = onDocumentWritten('reviews/{reviewId}', async (event) => {
  const providerId = event.data.after.exists
    ? event.data.after.data().providerId
    : event.data.before.data().providerId;
  if (!providerId) return;
  const reviews = await db.collection('reviews').where('providerId', '==', providerId).get();
  const total = reviews.docs.reduce((sum, doc) => sum + Number(doc.data().rating || 0), 0);
  await db.collection('providers').doc(providerId).set({
    rating: reviews.empty ? 0 : total / reviews.size,
    reviewCount: reviews.size,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
});
