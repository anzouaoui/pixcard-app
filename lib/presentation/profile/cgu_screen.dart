import 'package:flutter/material.dart';

class CguScreen extends StatelessWidget {
  const CguScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = theme.textTheme.bodyMedium;
    final title = theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600);
    const spacing = SizedBox(height: 12);
    const sectionSpacing = SizedBox(height: 24);

    return Scaffold(
      appBar: AppBar(title: const Text('Conditions générales d\'utilisation')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              'Conditions générales d\'utilisation',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SelectableText(
              'Dernière mise à jour : juillet 2026',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            sectionSpacing,

            // ── Article 1 ──
            SelectableText('Article 1 – Objet', style: title),
            spacing,
            SelectableText(
              'Les présentes Conditions Générales d\'Utilisation (ci-après « CGU ») régissent l\'accès et '
              'l\'utilisation de l\'application mobile PixCard (ci-après la « Plateforme »), éditée par la '
              'société PixCard. La Plateforme est une place de marché en ligne dédiée à l\'achat et à la '
              'vente de cartes à collectionner, principalement Pokémon TCG, entre particuliers.\n\n'
              'En créant un compte ou en utilisant la Plateforme, vous reconnaissez avoir pris '
              'connaissance des présentes CGU et les accepter sans réserve.',
              style: body,
            ),
            sectionSpacing,

            // ── Article 2 ──
            SelectableText('Article 2 – Définitions', style: title),
            spacing,
            SelectableText(
              '• « Plateforme » : l\'application mobile PixCard et l\'ensemble de ses services.\n'
              '• « Utilisateur » : toute personne physique majeure ou mineure émancipée disposant '
              'd\'un compte sur la Plateforme.\n'
              '• « Vendeur » : Utilisateur qui met en vente une ou plusieurs cartes.\n'
              '• « Acheteur » : Utilisateur qui acquiert une ou plusieurs cartes via la Plateforme.\n'
              '• « Annonce » : offre de vente publiée par un Vendeur.\n'
              '• « Transaction » : processus d\'achat entre un Vendeur et un Acheteur.\n'
              '• « Contenu » : ensemble des informations, photos, descriptions publiées sur la Plateforme.',
              style: body,
            ),
            sectionSpacing,

            // ── Article 3 ──
            SelectableText('Article 3 – Accès à la Plateforme et inscription', style: title),
            spacing,
            SelectableText(
              '3.1. L\'utilisation de la Plateforme est réservée aux personnes physiques âgées d\'au '
              'moins 18 ans ou aux mineurs émancipés. En créant un compte, vous déclarez remplir '
              'ces conditions.\n\n'
              '3.2. L\'inscription nécessite la fourniture d\'une adresse email valide et la création '
              'd\'un pseudonyme. Vous vous engagez à fournir des informations exactes et à les '
              'tenir à jour.\n\n'
              '3.3. Vous êtes seul responsable de la confidentialité de vos identifiants de connexion. '
              'Toute utilisation de votre compte est présumée émaner de votre personne.',
              style: body,
            ),
            sectionSpacing,

            // ── Article 4 ──
            SelectableText('Article 4 – Compte Utilisateur', style: title),
            spacing,
            SelectableText(
              '4.1. Chaque Utilisateur ne peut posséder qu\'un seul compte. La création de comptes '
              'multiples est interdite et peut entraîner la suspension de l\'ensemble des comptes.\n\n'
              '4.2. Vous pouvez supprimer votre compte à tout moment depuis la section « Paramètres » '
              'de l\'application. La suppression entraîne la désactivation de vos annonces en cours.\n\n'
              '4.3. PixCard se réserve le droit de suspendre ou supprimer tout compte en cas de '
              'violation des présentes CGU, de comportement frauduleux ou de signalements répétés.',
              style: body,
            ),
            sectionSpacing,

            // ── Article 5 ──
            SelectableText('Article 5 – Fonctionnalités de la Plateforme', style: title),
            spacing,
            SelectableText(
              '5.1. Mise en vente : tout Vendeur peut publier des annonces avec photos, description, '
              'état et prix. Le Vendeur garantit que la carte proposée est authentique et conforme '
              'à sa description.\n\n'
              '5.2. Recherche et achat : les Acheteurs peuvent parcourir les annonces, filtrer par '
              'critères et contacter les Vendeurs via la messagerie intégrée.\n\n'
              '5.3. Négociation : un Acheteur peut faire une offre de prix inférieur au prix '
              'affiché. Le Vendeur est libre de l\'accepter ou de la refuser.\n\n'
              '5.4. Messagerie : la Plateforme met à disposition un système de messagerie '
              'interne. Tout échange doit rester courtois et respectueux. L\'utilisation de la '
              'messagerie pour contourner la Plateforme est interdite.',
              style: body,
            ),
            sectionSpacing,

            // ── Article 6 ──
            SelectableText('Article 6 – Transactions et paiements', style: title),
            spacing,
            SelectableText(
              '6.1. Les transactions sont sécurisées via notre partenaire de paiement Stripe. '
              'Aucune information bancaire n\'est stockée par PixCard.\n\n'
              '6.2. Le prix affiché par le Vendeur est ferme et définitif, sauf négociation '
              'préalable via la fonctionnalité d\'offre.\n\n'
              '6.3. Le Vendeur s\'engage à expédier la carte dans un délai maximal de 5 jours '
              'ouvrés après confirmation de la transaction, sauf mention contraire dans l\'annonce.\n\n'
              '6.4. L\'Acheteur dispose d\'un délai de 14 jours à compter de la réception pour '
              'contester la conformité de la carte reçue via le système de litige de la Plateforme.',
              style: body,
            ),
            sectionSpacing,

            // ── Article 7 ──
            SelectableText('Article 7 – Frais et commissions', style: title),
            spacing,
            SelectableText(
              '7.1. L\'inscription et la consultation de la Plateforme sont gratuites.\n\n'
              '7.2. Une commission est prélevée sur chaque transaction réalisée via la Plateforme. '
              'Le montant de cette commission est exprimé en pourcentage du prix de vente et '
              'affiché de manière transparente avant la publication de l\'annonce.\n\n'
              '7.3. PixCard se réserve le droit de modifier ses barèmes de commission à tout '
              'moment, sous réserve d\'en informer les Utilisateurs 30 jours à l\'avance.',
              style: body,
            ),
            sectionSpacing,

            // ── Article 8 ──
            SelectableText('Article 8 – Système d\'évaluation', style: title),
            spacing,
            SelectableText(
              '8.1. Après chaque transaction, Vendeur et Acheteur peuvent s\'évaluer mutuellement '
              'sur la base d\'une note et d\'un commentaire.\n\n'
              '8.2. Les évaluations sont publiques et associées au profil de chaque Utilisateur. '
              'Elles ne peuvent être supprimées ou modifiées une fois publiées.\n\n'
              '8.3. Tout abus du système d\'évaluation (évaluations frauduleuses, chantage à la '
              'note) est strictement interdit et peut entraîner la suspension du compte.',
              style: body,
            ),
            sectionSpacing,

            // ── Article 9 ──
            SelectableText('Article 9 – Propriété intellectuelle', style: title),
            spacing,
            SelectableText(
              '9.1. PixCard détient tous les droits de propriété intellectuelle relatifs à la '
              'Plateforme, son code, son design, son logo et son nom.\n\n'
              '9.2. Les Utilisateurs concèdent à PixCard une licence non exclusive, gratuite et '
              'limitée à la durée de leur inscription, pour l\'utilisation des photos et descriptions '
              'publiées dans le cadre du fonctionnement de la Plateforme.\n\n'
              '9.3. Les marques Pokémon, Magic: The Gathering, Yu-Gi-Oh! et autres marques de '
              'cartes à collectionner sont la propriété de leurs détenteurs respectifs. PixCard '
              'n\'est pas affiliée à ces sociétés.',
              style: body,
            ),
            sectionSpacing,

            // ── Article 10 ──
            SelectableText('Article 10 – Données personnelles', style: title),
            spacing,
            SelectableText(
              'Les données personnelles collectées sont traitées conformément à notre Politique '
              'de confidentialité, accessible depuis la section « Paramètres » de l\'application. '
              'Conformément au Règlement Général sur la Protection des Données (RGPD), vous '
              'disposez d\'un droit d\'accès, de rectification et de suppression de vos données.',
              style: body,
            ),
            sectionSpacing,

            // ── Article 11 ──
            SelectableText('Article 11 – Responsabilités et garanties', style: title),
            spacing,
            SelectableText(
              '11.1. PixCard agit en tant qu\'intermédiaire technique entre Vendeurs et Acheteurs. '
              'La Plateforme n\'est pas partie aux contrats de vente conclus entre Utilisateurs.\n\n'
              '11.2. PixCard ne garantit ni l\'authenticité, ni la qualité, ni la conformité des '
              'cartes mises en vente. Cette responsabilité incombe au Vendeur.\n\n'
              '11.3. PixCard met en œuvre les moyens techniques raisonnables pour assurer le '
              'bon fonctionnement de la Plateforme, sans garantie de disponibilité continue.\n\n'
              '11.4. La responsabilité de PixCard ne saurait être engagée en cas de dommage '
              'indirect, perte de chance ou préjudice commercial résultant de l\'utilisation '
              'de la Plateforme.\n\n'
              '11.5. Les Utilisateurs garantissent PixCard contre toute réclamation de tiers '
              'résultant d\'une violation des présentes CGU.',
              style: body,
            ),
            sectionSpacing,

            // ── Article 12 ──
            SelectableText('Article 12 – Suspension et résiliation', style: title),
            spacing,
            SelectableText(
              '12.1. PixCard peut suspendre immédiatement l\'accès d\'un Utilisateur en cas de '
              'violation grave des présentes CGU, de comportement frauduleux ou de non-paiement '
              'des frais dus.\n\n'
              '12.2. L\'Utilisateur peut résilier son compte à tout moment depuis les paramètres. '
              'La résiliation est effective immédiatement.\n\n'
              '12.3. En cas de résiliation, les annonces en cours sont automatiquement désactivées. '
              'Les transactions déjà engagées doivent être honorées.',
              style: body,
            ),
            sectionSpacing,

            // ── Article 13 ──
            SelectableText('Article 13 – Litiges et médiation', style: title),
            spacing,
            SelectableText(
              '13.1. En cas de litige entre Utilisateurs, PixCard propose un système interne de '
              'résolution des litiges accessible depuis la messagerie.\n\n'
              '13.2. À défaut d\'accord amiable, les parties peuvent recourir à une médiation '
              'conventionnelle auprès d\'un médiateur de la consommation.\n\n'
              '13.3. Tout litige relatif à l\'interprétation ou l\'exécution des présentes CGU '
              'est soumis au droit français et, à défaut de solution amiable, aux tribunaux '
              'compétents du ressort de la Cour d\'appel de Paris.',
              style: body,
            ),
            sectionSpacing,

            // ── Article 14 ──
            SelectableText('Article 14 – Dispositions générales', style: title),
            spacing,
            SelectableText(
              '14.1. Les présentes CGU constituent l\'intégralité de l\'accord entre PixCard et '
              'l\'Utilisateur concernant l\'utilisation de la Plateforme.\n\n'
              '14.2. Si une disposition des CGU est jugée nulle ou inapplicable, les autres '
              'dispositions restent en vigueur.\n\n'
              '14.3. PixCard se réserve le droit de modifier les présentes CGU à tout moment. '
              'Les Utilisateurs seront informés des modifications significatives par email ou '
              'via l\'application. L\'utilisation continue de la Plateforme après une modification '
              'vaut acceptation des nouvelles CGU.\n\n'
              '14.4. Le défaut de PixCard d\'exercer un droit prévu aux présentes ne constitue '
              'pas une renonciation à ce droit.',
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
