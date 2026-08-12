import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { db, getStripe, stripeSecretKey } from './config';

export const createConnectedAccount = onCall(
  { secrets: [stripeSecretKey] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        'unauthenticated',
        'Vous devez être connecté pour créer un compte vendeur.',
      );
    }

    const userId = request.data.userId as string | undefined;

    if (!userId) {
      throw new HttpsError(
        'invalid-argument',
        'userId est requis.',
      );
    }

    if (request.auth.uid !== userId) {
      throw new HttpsError(
        'permission-denied',
        'Vous ne pouvez créer un compte que pour vous-même.',
      );
    }

    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw new HttpsError(
        'not-found',
        'Utilisateur introuvable.',
      );
    }

    const userEmail = userDoc.data()?.email;

    const stripe = getStripe();

    const account = await stripe.accounts.create({
      type: 'express',
      email: userEmail,
      business_type: 'individual',
      capabilities: {
        transfers: { requested: true },
      },
    });

    await db.collection('users').doc(userId).update({
      stripeAccountId: account.id,
      stripeAccountStatus: 'pending',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const accountLink = await stripe.accountLinks.create({
      account: account.id,
      refresh_url: 'https://pixcard.app/retour-stripe',
      return_url: 'https://pixcard.app/parametres',
      type: 'account_onboarding',
    });

    return { url: accountLink.url };
  },
);
