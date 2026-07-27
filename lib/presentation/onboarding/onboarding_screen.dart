import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixcard/presentation/providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _purpleStart = Color(0xFF7C3AED);
  static const _purpleEnd = Color(0xFF4C1D95);

  static const _pages = [
    _OnboardingPage(
      icon: Icons.document_scanner_outlined,
      title: 'Scannez vos cartes',
      subtitle:
          'Zéro saisie, zéro recherche. Pointez votre caméra sur une carte et obtenez sa cote de marché à la seconde.',
    ),
    _OnboardingPage(
      icon: Icons.verified_user_outlined,
      title: 'Achetez en confiance',
      subtitle:
          'Paiement sécurisé entre particuliers, frais transparents de 5%. Votre argent est protégé jusqu\'à la réception.',
    ),
    _OnboardingPage(
      icon: Icons.sell_outlined,
      title: 'Vendez facilement',
      subtitle:
          'Publiez vos cartes en quelques secondes. Prix fixe ou offre directe, la mise en vente n\'a jamais été aussi simple.',
    ),
  ];

  final _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _goToLogin() async {
    await completeOnboarding();
    ref.invalidate(onboardingCompletedProvider);
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_purpleStart, _purpleEnd],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _goToLogin,
                  child: const Text(
                    'Passer l\'intro',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (_, i) => _buildPage(_pages[i]),
                ),
              ),
              _buildDots(),
              const SizedBox(height: 24),
              _buildButton(),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, size: 72, color: Colors.white),
          ),
          const SizedBox(height: 48),
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            page.subtitle,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (i) {
        final active = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white38,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildButton() {
    final isLast = _currentPage == _pages.length - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: _purpleStart,
            elevation: 6,
            shadowColor: Colors.black38,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: isLast ? _goToLogin : _next,
          child: Text(
            isLast ? 'Commencer' : 'Suivant',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}
