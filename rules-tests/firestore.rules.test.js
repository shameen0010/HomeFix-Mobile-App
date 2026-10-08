const fs = require('fs');
const path = require('path');
const assert = require('assert');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { doc, setDoc } = require('firebase/firestore');

describe('HomeFix Firestore rules', () => {
  let testEnv;

  before(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: 'homefix-mobile-app',
      firestore: {
        rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8'),
      },
    });
  });

  after(async () => {
    if (testEnv) await testEnv.cleanup();
  });
  afterEach(async () => testEnv.clearFirestore());

  it('allows a user to create only their own notification', async () => {
    const db = testEnv.authenticatedContext('customer-1').firestore();
    await assertSucceeds(setDoc(doc(db, 'notifications/own'), {
      userId: 'customer-1',
      title: 'Hello',
      body: 'Welcome',
      read: false,
    }));
    await assertFails(setDoc(doc(db, 'notifications/other'), {
      userId: 'customer-2',
      title: 'Forged',
      body: 'Not allowed',
      read: false,
    }));
  });

  it('requires the deterministic review id', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), 'users/customer-1'), { role: 'customer' });
      await setDoc(doc(context.firestore(), 'bookings/booking-1'), {
        customerId: 'customer-1',
        providerId: 'provider-1',
        status: 'completed',
      });
    });
    const db = testEnv.authenticatedContext('customer-1').firestore();
    const review = {
      bookingId: 'booking-1',
      customerId: 'customer-1',
      providerId: 'provider-1',
      rating: 5,
      comment: 'Great',
    };
    await assertSucceeds(setDoc(doc(db, 'reviews/booking-1_customer-1'), review));
    await assertFails(setDoc(doc(db, 'reviews/random-id'), review));
  });
});
