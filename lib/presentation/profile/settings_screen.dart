import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixcard/presentation/profile/cgu_screen.dart';
import 'package:pixcard/presentation/profile/privacy_policy_screen.dart';
import 'package:pixcard/presentation/providers/auth_provider.dart';
import 'package:pixcard/presentation/providers/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notifOffers = true;
  bool _notifMessages = true;
  bool _notifOrderUpdates = true;
  bool _isLoadingPrefs = true;
  bool _isSendingReset = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationPrefs();
  }

  Future<void> _loadNotificationPrefs() async {
    final user = ref.read(authStateProvider).user;
    if (user == null) return;

    try {
      final doc = await ref
          .read(firebaseFirestoreProvider)
          .collection('users')
          .doc(user.id)
          .get();
      final data = doc.data();
      if (data != null && data.containsKey('notificationPrefs')) {
        final prefs = data['notificationPrefs'] as Map<String, dynamic>;
        if (!mounted) return;
        setState(() {
          _notifOffers = prefs['offers'] as bool? ?? true;
          _notifMessages = prefs['messages'] as bool? ?? true;
          _notifOrderUpdates = prefs['orderUpdates'] as bool? ?? true;
          _isLoadingPrefs = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _isLoadingPrefs = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingPrefs = false);
    }
  }

  Future<void> _updateNotificationPrefs() async {
    final user = ref.read(authStateProvider).user;
    if (user == null) return;

    await ref.read(firebaseFirestoreProvider).collection('users').doc(user.id).update({
      'notificationPrefs': {
        'offers': _notifOffers,
        'messages': _notifMessages,
        'orderUpdates': _notifOrderUpdates,
      },
    });
  }

  Future<void> _sendPasswordReset() async {
    final user = ref.read(authStateProvider).user;
    if (user == null) return;

    setState(() => _isSendingReset = true);
    try {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(user.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email de réinitialisation envoyé')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    } finally {
      if (mounted) setState(() => _isSendingReset = false);
    }
  }

  Future<void> _confirmLogout() async {
    final ctx = context;
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authStateProvider.notifier).signOut();
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final firstConfirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer mon compte'),
        content: const Text(
          'Cette action est irréversible. Toutes vos données seront définitivement supprimées. '
          'Voulez-vous continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (firstConfirmed != true) return;
    if (!mounted) return;

    final secondConfirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text(
          'Cette action est définitive. Êtes-vous absolument sûr ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Oui, tout supprimer'),
          ),
        ],
      ),
    );
    if (secondConfirmed != true) return;
    if (!mounted) return;

    try {
      await ref.read(firebaseFunctionsProvider).httpsCallable('deleteUserAccount').call();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La suppression de compte sera disponible prochainement')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authStateProvider).user;
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        children: [
          // ── Notifications ──
          _buildSectionHeader(theme, 'Notifications'),
          if (_isLoadingPrefs)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else ...[
            SwitchListTile(
              title: const Text('Nouvelles offres reçues'),
              value: _notifOffers,
              onChanged: (v) {
                setState(() => _notifOffers = v);
                _updateNotificationPrefs();
              },
            ),
            SwitchListTile(
              title: const Text('Nouveaux messages'),
              value: _notifMessages,
              onChanged: (v) {
                setState(() => _notifMessages = v);
                _updateNotificationPrefs();
              },
            ),
            SwitchListTile(
              title: const Text('Mises à jour de commande'),
              value: _notifOrderUpdates,
              onChanged: (v) {
                setState(() => _notifOrderUpdates = v);
                _updateNotificationPrefs();
              },
            ),
          ],
          const Divider(height: 1),

          // ── Compte ──
          _buildSectionHeader(theme, 'Compte'),
          ListTile(
            title: const Text('Email'),
            subtitle: Text(user.email),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Changer le mot de passe'),
            trailing: _isSendingReset
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: _isSendingReset ? null : _sendPasswordReset,
          ),
          const Divider(height: 1),

          // ── Informations légales ──
          _buildSectionHeader(theme, 'Informations légales'),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Conditions générales d\'utilisation'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CguScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: const Text('Politique de confidentialité'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              );
            },
          ),
          const Divider(height: 1),

          // ── Actions ──
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _confirmLogout,
                child: const Text('Se déconnecter'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _confirmDeleteAccount,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text('Supprimer mon compte'),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
