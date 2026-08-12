import { onRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import Stripe from 'stripe';
import { db, getStripe, stripeSecretKey, stripeWebhookSecret } from './config';

export const stripeWebhook = onRequest(
  { secrets: [stripeSecretKey, stripeWebhookSecret] },
  async (req, res) => {
    const sig = req.headers['stripe-signature'] as string;

    const stripe = getStripe();

    let event: Stripe.Event;

    try {
      event = stripe.webhooks.constructEvent(
        req.rawBody,
        sig,
        stripeWebhookSecret.value(),
      );
    } catch (err) {
      res.status(400).send(`Webhook Error: ${(err as Error).message}`);
      return;
    }

    switch (event.type) {
      case 'payment_intent.succeeded': {
        const paymentIntent = event.data.object as Stripe.PaymentIntent;
        await handlePaymentIntentSucceeded(paymentIntent);
        break;
      }

      case 'account.updated': {
        const account = event.data.object as Stripe.Account;
        await handleAccountUpdated(account);
        break;
      }

      default:
        break;
    }

    res.json({ received: true });
  },
);

async function handlePaymentIntentSucceeded(
  paymentIntent: Stripe.PaymentIntent,
) {
  const { listingId, buyerId, sellerId } = paymentIntent.metadata;

  if (!listingId || !buyerId || !sellerId) return;

  const listingRef = db.collection('listings').doc(listingId);
  const listingSnap = await listingRef.get();

  if (!listingSnap.exists) return;

  const listing = listingSnap.data()!;

  const cardPrice = (listing.price as number) || 0;
  const paymentFee = cardPrice * 0.029 + 0.30;
  const sellerCommissionRate = 0.05;
  const sellerCommissionAmount = cardPrice * sellerCommissionRate;
  const sellerNetAmount = cardPrice - sellerCommissionAmount;
  const totalPaid = cardPrice + paymentFee;

  const orderRef = db.collection('orders').doc();

  await db.runTransaction(async (transaction) => {
    transaction.set(orderRef, {
      listingId,
      buyerId,
      sellerId,
      cardPrice,
      paymentFee,
      totalPaid,
      sellerCommissionRate,
      sellerCommissionAmount,
      sellerNetAmount,
      status: 'paid',
      stripePaymentIntentId: paymentIntent.id,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    transaction.update(listingRef, {
      status: 'sold',
      buyerId,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    transaction.update(
      db.collection('users').doc(sellerId),
      {
        salesCount: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
    );
  });
}

async function handleAccountUpdated(account: Stripe.Account) {
  const accountId = account.id;

  const usersSnap = await db
    .collection('users')
    .where('stripeAccountId', '==', accountId)
    .limit(1)
    .get();

  if (usersSnap.empty) return;

  const userId = usersSnap.docs[0].id;

  let status: string;
  if (!account.charges_enabled || !account.payouts_enabled) {
    status = 'restricted';
  } else if (account.requirements?.disabled_reason) {
    status = 'restricted';
  } else {
    status =
      account.requirements?.currently_due &&
      account.requirements.currently_due.length > 0
        ? 'pending'
        : 'verified';
  }

  await db.collection('users').doc(userId).update({
    stripeAccountStatus: status,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}
