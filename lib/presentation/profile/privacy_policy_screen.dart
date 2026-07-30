import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = theme.textTheme.bodyMedium;
    final title = theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600);
    const spacing = SizedBox(height: 12);
    const sectionSpacing = SizedBox(height: 24);

    return Scaffold(
      appBar: AppBar(title: const Text('Politique de confidentialité')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              'Politique de confidentialité',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SelectableText(
              'Dernière mise à jour : juillet 2026',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            sectionSpacing,

            // ── 1 ──
            SelectableText('1. Responsable du traitement', style: title),
            spacing,
            SelectableText(
              'Le responsable du traitement des données à caractère personnel est la société '
              'PixCard. Pour toute question relative à vos données, vous pouvez nous contacter '
              'à l\'adresse email suivante : support@pixcard.app.',
              style: body,
            ),
            sectionSpacing,

            // ── 2 ──
            SelectableText('2. Données collectées', style: title),
            spacing,
            SelectableText(
              'Nous collectons les catégories de données suivantes :\n\n'
              '• Données d\'identité : pseudonyme, adresse email.\n'
              '• Données de profil : photo de profil, biographie.\n'
              '• Données de transaction : historique d\'achats et de ventes, évaluations.\n'
              '• Données de communication : messages échangés via la messagerie interne.\n'
              '• Données de navigation : pages consultées, durée de session, interactions '
              'avec l\'application.\n'
              '• Données techniques : identifiant d\'appareil, version de l\'OS, version '
              'de l\'application.',
              style: body,
            ),
            sectionSpacing,

            // ── 3 ──
            SelectableText('3. Modalités de collecte', style: title),
            spacing,
            SelectableText(
              'Les données sont collectées :\n\n'
              '• Directement auprès de vous lors de la création de votre compte, la '
              'publication d\'une annonce ou l\'utilisation de la messagerie.\n'
              '• Automatiquement lors de votre navigation via des outils d\'analyse '
              'et de suivi des performances.\n'
              '• Via des tiers de confiance (Google Firebase, Stripe) dans le cadre '
              'de l\'authentification et du traitement des paiements.',
              style: body,
            ),
            sectionSpacing,

            // ── 4 ──
            SelectableText('4. Finalités et bases légales du traitement', style: title),
            spacing,
            SelectableText(
              'Nous traitons vos données pour les finalités suivantes :\n\n'
              '• Gestion de votre compte et accès à la Plateforme (exécution du contrat).\n'
              '• Publication et gestion des annonces (exécution du contrat).\n'
              '• Traitement des transactions et paiements via Stripe (exécution du contrat).\n'
              '• Communication entre Utilisateurs via la messagerie (exécution du contrat).\n'
              '• Envoi de notifications push liées aux activités de votre compte '
              '(intérêt légitime).\n'
              '• Résolution des litiges entre Utilisateurs (exécution du contrat).\n'
              '• Sécurisation de la Plateforme et prévention de la fraude '
              '(intérêt légitime).\n'
              '• Amélioration de nos services et analyse d\'utilisation '
              '(consentement ou intérêt légitime).\n'
              '• Conformité aux obligations légales et réglementaires (obligation légale).',
              style: body,
            ),
            sectionSpacing,

            // ── 5 ──
            SelectableText('5. Destinataires des données', style: title),
            spacing,
            SelectableText(
              'Vos données sont accessibles aux destinataires suivants :\n\n'
              '• Les autres Utilisateurs de la Plateforme (pseudonyme, photo, évaluations, '
              'annonces).\n'
              '• Google Firebase (Firestore, Authentication, Storage, Functions) '
              '– hébergement et infrastructure.\n'
              '• Stripe – traitement des paiements (aucune donnée bancaire n\'est '
              'stockée par PixCard).\n'
              '• Sentry – suivi des erreurs techniques et performance.\n'
              '• Les autorités légalement habilitées, en cas d\'obligation légale.',
              style: body,
            ),
            sectionSpacing,

            // ── 6 ──
            SelectableText('6. Transferts hors UE', style: title),
            spacing,
            SelectableText(
              'Certains de nos sous-traitants (Google Cloud, Stripe, Sentry) sont '
              'susceptibles de transférer vos données vers des pays situés en dehors de '
              'l\'Espace Économique Européen. Ces transferts sont encadrés par des '
              'clauses contractuelles types approuvées par la Commission Européenne '
              'ou par des décisions d\'adéquation.',
              style: body,
            ),
            sectionSpacing,

            // ── 7 ──
            SelectableText('7. Durée de conservation', style: title),
            spacing,
            SelectableText(
              'Nous conservons vos données pendant la durée nécessaire aux finalités '
              'pour lesquelles elles sont collectées :\n\n'
              '• Données de compte : pendant toute la durée de votre inscription et '
              'jusqu\'à 12 mois après votre demande de suppression, sauf obligation '
              'légale de conservation plus longue.\n'
              '• Données de transaction : 5 ans à compter de la transaction '
              '(obligation comptable et fiscale).\n'
              '• Messages internes : 3 ans après le dernier échange.\n'
              '• Données de navigation : 13 mois maximum.',
              style: body,
            ),
            sectionSpacing,

            // ── 8 ──
            SelectableText('8. Vos droits', style: title),
            spacing,
            SelectableText(
              'Conformément au Règlement Général sur la Protection des Données (RGPD) '
              'et à la loi Informatique et Libertés, vous disposez des droits suivants :\n\n'
              '• Droit d\'accès : obtenir une copie de vos données personnelles.\n'
              '• Droit de rectification : faire corriger des données inexactes.\n'
              '• Droit à l\'effacement : demander la suppression de vos données '
              '(droit à l\'oubli).\n'
              '• Droit à la limitation du traitement : restreindre l\'utilisation '
              'de vos données.\n'
              '• Droit à la portabilité : recevoir vos données dans un format '
              'structuré et lisible.\n'
              '• Droit d\'opposition : vous opposer au traitement de vos données '
              'pour des motifs légitimes.\n'
              '• Droit de retirer votre consentement à tout moment, lorsque le '
              'traitement est fondé sur le consentement.\n\n'
              'Pour exercer vos droits, contactez-nous à support@pixcard.app. '
              'Nous répondrons dans un délai d\'un mois.',
              style: body,
            ),
            sectionSpacing,

            // ── 9 ──
            SelectableText('9. Sécurité', style: title),
            spacing,
            SelectableText(
              'Nous mettons en œuvre des mesures techniques et organisationnelles '
              'appropriées pour garantir la sécurité et la confidentialité de vos '
              'données personnelles, notamment :\n\n'
              '• Chiffrement des données en transit (TLS).\n'
              '• Authentification sécurisée via Firebase Authentication.\n'
              '• Accès restreint aux données basé sur les rôles.\n'
              '• Surveillance et journalisation des accès.\n'
              '• Sauvegardes régulières des données.\n\n'
              'Cependant, aucun système n\'est infaillible. En cas de violation de '
              'données, nous vous en informerons dans les 72 heures conformément au RGPD.',
              style: body,
            ),
            sectionSpacing,

            // ── 10 ──
            SelectableText('10. Cookies et traceurs', style: title),
            spacing,
            SelectableText(
              'L\'application PixCard utilise des cookies et traceurs strictement '
              'nécessaires à son fonctionnement (authentification, session). '
              'Aucun cookie publicitaire ou de suivi cross-site n\'est utilisé.\n\n'
              'Nous utilisons Firebase Analytics et Sentry pour mesurer les '
              'performances et détecter les erreurs techniques. Ces outils '
              'collectent des données anonymisées ou pseudonymisées.',
              style: body,
            ),
            sectionSpacing,

            // ── 11 ──
            SelectableText('11. Réclamation auprès de la CNIL', style: title),
            spacing,
            SelectableText(
              'Si vous estimez que vos droits ne sont pas respectés, vous pouvez '
              'introduire une réclamation auprès de la Commission Nationale de '
              'l\'Informatique et des Libertés (CNIL), autorité de contrôle française :\n\n'
              'CNIL – 3 Place de Fontenoy, 75007 Paris, France\n'
              'www.cnil.fr',
              style: body,
            ),
            sectionSpacing,

            // ── 12 ──
            SelectableText('12. Modification de la politique', style: title),
            spacing,
            SelectableText(
              'Nous pouvons modifier la présente politique de confidentialité à tout '
              'moment. En cas de modification substantielle, nous vous en informerons '
              'par email ou via l\'application. Nous vous invitons à consulter '
              'régulièrement cette page.',
              style: body,
            ),
            sectionSpacing,
            sectionSpacing,
          ],
        ),
      ),
    );
  }
}
