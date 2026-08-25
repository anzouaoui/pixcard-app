import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { db, getStripe, stripeSecretKey } from './config';

export const createPaymentIntent = onCall(
  { secrets: [stripeSecretKey] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        'unauthenticated',
        'Vous devez être connecté pour effectuer un paiement.',
      );
    }

    const { listingId, buyerId } = request.data as {
      listingId?: string;
      buyerId?: string;
    };

    if (!listingId || !buyerId) {
      throw new HttpsError(
        'invalid-argument',
        'listingId et buyerId sont requis.',
      );
    }

    if (request.auth.uid !== buyerId) {
      throw new HttpsError(
        'permission-denied',
        'Vous ne pouvez payer qu\'en votre nom.',
      );
    }

    const listingRef = db.collection('listings').doc(listingId);
    const listingSnap = await listingRef.get();

    if (!listingSnap.exists) {
      throw new HttpsError(
        'not-found',
        'Annonce introuvable.',
      );
    }

    const listing = listingSnap.data()!;

    if (listing.status !== 'active') {
      throw new HttpsError(
        'failed-precondition',
        'Cette carte n\'est plus disponible à l\'achat.',
      );
    }

    if (listing.sellerId === buyerId) {
      throw new HttpsError(
        'failed-precondition',
        'Vous ne pouvez pas acheter votre propre carte.',
      );
    }

    const sellerSnap = await db
      .collection('users')
      .doc(listing.sellerId)
      .get();

    const stripeAccountId = sellerSnap.data()?.stripeAccountId as
      | string
      | undefined;

    if (!stripeAccountId) {
      throw new HttpsError(
        'failed-precondition',
        'Le vendeur n\'a pas encore configuré son compte de paiement.',
      );
    }

    const cardPrice = listing.price as number;
    const amountInCents = Math.round(cardPrice * 100);
    const sellerCommissionAmount = Math.round(cardPrice * 0.05 * 100);

    const stripe = getStripe();

    const paymentIntent = await stripe.paymentIntents.create({
      amount: amountInCents,
      currency: 'eur',
      application_fee_amount: sellerCommissionAmount,
      transfer_data: {
        destination: stripeAccountId,
      },
      metadata: {
        listingId,
        buyerId,
        sellerId: listing.sellerId,
      },
    });

    await db.runTransaction(async (transaction) => {
      const freshListing = await transaction.get(listingRef);

      if (!freshListing.exists || freshListing.data()!.status !== 'active') {
        await stripe.paymentIntents.cancel(paymentIntent.id);
        throw new HttpsError(
          'aborted',
          'Cette carte a déjà été achetée par un autre acheteur.',
        );
      }

      transaction.update(listingRef, {
        status: 'pending_payment',
        buyerId,
        stripePaymentIntentId: paymentIntent.id,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    return {
      clientSecret: paymentIntent.client_secret!,
      paymentIntentId: paymentIntent.id,
    };
  },
);
