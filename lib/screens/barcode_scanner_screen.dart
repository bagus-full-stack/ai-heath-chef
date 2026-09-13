import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/meal_analysis_args.dart';

const Color _kPrimaryColor = Color(0xFF6B66FF);

/// Scan de code-barres produit (EAN/UPC). Une fois un code détecté, on route
/// vers l'écran d'analyse qui cherche les infos nutritionnelles via
/// Open Food Facts ([MealNotifier.loadFromBarcode]) et permet d'ajuster puis
/// de valider, comme pour une photo de repas.
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;
  bool _detected = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled || capture.barcodes.isEmpty) {
      return;
    }
    final code = capture.barcodes.first.rawValue;
    if (code == null || code.isEmpty) {
      return;
    }

    _handled = true;
    unawaited(_controller.stop());
    setState(() => _detected = true);

    // Petit temps de pause pour laisser le retour visuel de succès se voir
    // avant de naviguer, plutôt que de couper directement vers l'écran suivant.
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) {
      return;
    }
    context.pushReplacement('/meal_analysis', extra: MealAnalysisArgs(barcode: code));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(controller: _controller, onDetect: _onDetect),
            Positioned.fill(
              child: CustomPaint(painter: _BarcodeFocusPainter(success: _detected)),
            ),
            IgnorePointer(
              child: Center(
                child: Transform.translate(
                  offset: const Offset(0, -20),
                  child: AnimatedOpacity(
                    opacity: _detected ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CircleIconButton(
                    icon: Icons.close_rounded,
                    onTap: () => context.pop(),
                  ),
                  ValueListenableBuilder(
                    valueListenable: _controller,
                    builder: (context, state, child) {
                      return _CircleIconButton(
                        icon: state.torchState == TorchState.on
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded,
                        onTap: () => _controller.toggleTorch(),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Positioned(
              left: 32,
              right: 32,
              bottom: 120,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SCANNER UN PRODUIT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Cadre le code-barres du produit',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _BarcodeFocusPainter extends CustomPainter {
  final bool success;

  _BarcodeFocusPainter({required this.success});

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final frameWidth = size.width * 0.8;
    final frameHeight = frameWidth * 0.6;
    final frameRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 20),
      width: frameWidth,
      height: frameHeight,
    );
    final frameRRect = RRect.fromRectAndRadius(frameRect, const Radius.circular(20));

    final cutoutPath = Path.combine(
      PathOperation.difference,
      Path()..addRect(rect),
      Path()..addRRect(frameRRect),
    );
    canvas.drawPath(cutoutPath, overlayPaint);

    final borderPaint = Paint()
      ..color = success ? Colors.greenAccent : _kPrimaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = success ? 3.5 : 2.5;
    canvas.drawRRect(frameRRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _BarcodeFocusPainter oldDelegate) => oldDelegate.success != success;
}
