import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixcard/domain/repositories/listing_repository.dart';
import 'package:pixcard/presentation/providers/providers.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isAnalyzing = false;
  bool _hasError = false;
  String _errorMessage = '';
  double? _lastConfidence;
  FlashMode _flashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _showError('Aucune caméra disponible');
        return;
      }

      _controller = CameraController(
        _cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      await _controller!.setFlashMode(_flashMode);

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      _showError('Erreur caméra: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = message;
        _isInitialized = false;
      });
    }
  }

  void _hideError() {
    if (mounted) {
      setState(() {
        _hasError = false;
        _errorMessage = '';
      });
      _initializeCamera();
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final newMode = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    try {
      await _controller!.setFlashMode(newMode);
      setState(() => _flashMode = newMode);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur flash: $e')),
        );
      }
    }
  }

  Future<void> _analyzeCard() async {
    if (_controller == null || !_controller!.value.isInitialized || _isAnalyzing) {
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      final image = await _controller!.takePicture();
      final repository = ref.read(listingRepositoryProvider);
      final result = await repository.analyzeCard(image.path);

      if (!mounted) return;

      if (result.confidence < 0.6) {
        _showAnalysisError(
          'Carte non reconnue, réessayez avec un meilleur éclairage ou cadrage',
          confidence: result.confidence,
        );
        return;
      }

      // Navigate to scan result screen
      if (!mounted) return;
      context.push('/scan-result', extra: {
        'result': result,
        'imagePath': image.path,
      });
    } on CardAnalysisException catch (e) {
      _showAnalysisError(
        'Carte non reconnue, réessayez avec un meilleur éclairage ou cadrage',
        confidence: e.confidence,
      );
    } catch (e) {
      _showAnalysisError('Erreur lors de l\'analyse: $e');
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  void _showAnalysisError(String message, {double? confidence}) {
    setState(() {
      _hasError = true;
      _errorMessage = message;
      _lastConfidence = confidence;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorScreen();
    }

    if (!_isInitialized || _controller == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller!),
          _buildCornerGuides(),
          _buildTopBar(),
          _buildBottomBar(),
          if (_isAnalyzing) _buildAnalyzingOverlay(),
        ],
      ),
    );
  }

  Widget _buildCornerGuides() {
    return CustomPaint(
      painter: CornerGuidePainter(),
      child: const SizedBox.expand(),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => context.pop(),
            ),
            IconButton(
              icon: Icon(
                _flashMode == FlashMode.torch ? Icons.flash_on : Icons.flash_off,
                color: _flashMode == FlashMode.torch ? Colors.amber : Colors.white,
                size: 28,
              ),
              onPressed: _toggleFlash,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Cadrez la carte dans le guide',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isAnalyzing ? null : _analyzeCard,
                icon: _isAnalyzing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.search_rounded, size: 24),
                label: Text(
                  _isAnalyzing ? 'Analyse en cours...' : 'Analyser la carte',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.push('/create-listing'),
              child: Text(
                'Remplir manuellement',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Analyse de la carte...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 80,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Carte non reconnue',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              if (_lastConfidence != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Confiance: ${(_lastConfidence! * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _hideError,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Réessayer'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/create-listing'),
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Remplir manuellement'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CornerGuidePainter extends CustomPainter {
  static const double _cornerSize = 40;
  static const double _cornerThickness = 4;
  static const double _guideSize = 280;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = _cornerThickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    final rect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: _guideSize,
      height: _guideSize * 1.4,
    );

    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.top + _cornerSize)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.left + _cornerSize, rect.top),
      paint,
    );

    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - _cornerSize, rect.top)
        ..lineTo(rect.right, rect.top)
        ..lineTo(rect.right, rect.top + _cornerSize),
      paint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.bottom - _cornerSize)
        ..lineTo(rect.left, rect.bottom)
        ..lineTo(rect.left + _cornerSize, rect.bottom),
      paint,
    );

    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - _cornerSize, rect.bottom)
        ..lineTo(rect.right, rect.bottom)
        ..lineTo(rect.right, rect.bottom - _cornerSize),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
