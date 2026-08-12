import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';
import { db } from './config';

export const releaseExpiredListingLocks = onSchedule(
  {
    schedule: 'every 15 minutes',
    timeZone: 'UTC',
  },
  async () => {
    const cutoff = new Date(
      Date.now() - 20 * 60 * 1000,
    );

    const expiredSnap = await db
      .collection('listings')
      .where('status', '==', 'pending_payment')
      .where('updatedAt', '<=', cutoff)
      .get();

    if (expiredSnap.empty) {
      return;
    }

    const batch = db.batch();

    expiredSnap.docs.forEach((doc) => {
      batch.update(doc.ref, {
        status: 'active',
        buyerId: admin.firestore.FieldValue.delete(),
        stripePaymentIntentId: admin.firestore.FieldValue.delete(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    await batch.commit();
  },
);
