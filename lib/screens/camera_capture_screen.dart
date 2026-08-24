import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

enum _CaptureMode { scanner, repas, produit }

class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen>
    with WidgetsBindingObserver {
  static const List<double> _zoomSteps = [1.0, 2.0, 3.0];

  CameraController? _controller;
  Future<void>? _initializeFuture;
  FlashMode _flashMode = FlashMode.off;
  bool _isCapturing = false;
  bool _isPickingFromGallery = false;
  String? _errorMessage;
  double _maxZoom = 1.0;
  int _zoomStepIndex = 0;
  _CaptureMode _mode = _CaptureMode.repas;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _controller = null;
      _initializeFuture = null;
    } else if (state == AppLifecycleState.resumed && _controller == null) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) {
          return;
        }
        setState(() {
          _errorMessage = 'Aucune caméra disponible sur cet appareil.';
        });
        return;
      }

      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      final initializeFuture = controller.initialize();
      await initializeFuture;
      await controller.setFlashMode(_flashMode);
      final maxZoom = await controller.getMaxZoomLevel();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _initializeFuture = initializeFuture;
        _errorMessage = null;
        _maxZoom = maxZoom;
        _zoomStepIndex = 0;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Impossible d’ouvrir la caméra : $e';
      });
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    final nextMode = switch (_flashMode) {
      FlashMode.off => FlashMode.auto,
      FlashMode.auto => FlashMode.always,
      FlashMode.always => FlashMode.torch,
      FlashMode.torch => FlashMode.off,
    };

    await controller.setFlashMode(nextMode);
    if (!mounted) {
      return;
    }

    setState(() {
      _flashMode = nextMode;
    });
  }

  IconData _flashIcon() {
    switch (_flashMode) {
      case FlashMode.off:
        return Icons.flash_off_rounded;
      case FlashMode.auto:
        return Icons.flash_auto_rounded;
      case FlashMode.always:
      case FlashMode.torch:
        return Icons.flash_on_rounded;
    }
  }

  Future<void> _cycleZoom() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    final availableSteps = _zoomSteps.where((z) => z <= _maxZoom).toList();
    if (availableSteps.isEmpty) {
      return;
    }

    final nextIndex = (_zoomStepIndex + 1) % availableSteps.length;
    final nextZoom = availableSteps[nextIndex];
    await controller.setZoomLevel(nextZoom);
    if (!mounted) {
      return;
    }
    setState(() => _zoomStepIndex = nextIndex);
  }

  double get _currentZoom {
    final availableSteps = _zoomSteps.where((z) => z <= _maxZoom).toList();
    if (availableSteps.isEmpty) {
      return 1.0;
    }
    return availableSteps[_zoomStepIndex % availableSteps.length];
  }

  Future<void> _capturePhoto() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      await _initializeFuture;
      final image = await controller.takePicture();
      if (!mounted) {
        return;
      }
      context.pushReplacement('/meal_analysis', extra: image.path);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Échec de la capture : $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isPickingFromGallery) {
      return;
    }

    setState(() => _isPickingFromGallery = true);
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (!mounted || image == null) {
        return;
      }
      context.pushReplacement('/meal_analysis', extra: image.path);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible d’ouvrir la galerie : $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingFromGallery = false);
      }
    }
  }

  void _selectMode(_CaptureMode mode) {
    if (mode == _mode) {
      return;
    }
    if (mode != _CaptureMode.repas) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_modeLabel(mode)} : bientôt disponible.')),
      );
      return;
    }
    setState(() => _mode = mode);
  }

  String _modeLabel(_CaptureMode mode) {
    switch (mode) {
      case _CaptureMode.scanner:
        return 'Scanner';
      case _CaptureMode.repas:
        return 'Repas';
      case _CaptureMode.produit:
        return 'Produit';
    }
  }

  void _showHelp() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1B26),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comment ça marche ?',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Centre ton assiette dans le cercle, garde l’appareil stable puis appuie sur le '
              'déclencheur. Notre IA analyse automatiquement les aliments et leurs valeurs '
              'nutritionnelles.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.75), height: 1.45),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Compris', style: TextStyle(color: Color(0xFF6B66FF))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6B66FF);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _errorMessage != null
            ? _buildErrorState(primaryColor)
            : Stack(
                fit: StackFit.expand,
                children: [
                  if (_controller != null && _controller!.value.isInitialized)
                    CameraPreview(_controller!)
                  else
                    const ColoredBox(
                      color: Colors.black,
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _DishFocusPainter(
                        borderColor: Colors.white.withValues(alpha: 0.95),
                        shadeColor: Colors.black.withValues(alpha: 0.55),
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
                          icon: _flashIcon(),
                          onTap: _toggleFlash,
                        ),
                        Row(
                          children: [
                            _CircleIconButton(
                              icon: Icons.question_mark_rounded,
                              onTap: _showHelp,
                            ),
                            const SizedBox(width: 10),
                            _CircleIconButton(
                              icon: Icons.close_rounded,
                              onTap: _close,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const _FocusCaption(),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 24,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _BottomActionButton(
                              icon: Icons.photo_library_outlined,
                              label: 'GALERIE',
                              onTap: _pickFromGallery,
                              isLoading: _isPickingFromGallery,
                            ),
                            GestureDetector(
                              onTap: _isCapturing ? null : _capturePhoto,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 84,
                                height: 84,
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.72),
                                    width: 2,
                                  ),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _isCapturing
                                        ? primaryColor
                                        : Colors.white,
                                  ),
                                  child: _isCapturing
                                      ? const Padding(
                                          padding: EdgeInsets.all(22),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.camera_alt_rounded,
                                          color: Colors.black,
                                          size: 30,
                                        ),
                                ),
                              ),
                            ),
                            _BottomActionButton(
                              icon: Icons.crop_free_rounded,
                              label: '${_currentZoom.toStringAsFixed(0)}x',
                              onTap: _cycleZoom,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: _CaptureMode.values.map((mode) {
                            final selected = mode == _mode;
                            return GestureDetector(
                              onTap: () => _selectMode(mode),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _modeLabel(mode).toUpperCase(),
                                      style: TextStyle(
                                        color: selected ? primaryColor : Colors.white70,
                                        fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                                        fontSize: 12,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (selected)
                                      Container(
                                        width: 18,
                                        height: 2,
                                        color: primaryColor,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildErrorState(Color primaryColor) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black, Color(0xFF111111)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off_rounded, color: Colors.white, size: 64),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Impossible d’ouvrir la caméra.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _initializeCamera,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Réessayer'),
              ),
              TextButton(
                onPressed: _pickFromGallery,
                child: const Text(
                  'Choisir une photo depuis la galerie',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              TextButton(
                onPressed: _close,
                child: const Text(
                  'Retour',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FocusCaption extends StatelessWidget {
  const _FocusCaption();

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      left: 32,
      right: 32,
      top: 0,
      bottom: 0,
      child: Center(
        child: Padding(
          padding: EdgeInsets.only(bottom: 90),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ANALYSE NUTRITIONNELLE IA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Cadrez votre plat au centre',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                ),
              ),
            ],
          ),
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

class _BottomActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  const _BottomActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(13),
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _DishFocusPainter extends CustomPainter {
  final Color shadeColor;
  final Color borderColor;

  _DishFocusPainter({
    required this.shadeColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = shadeColor;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    const frameDiameterFactor = 0.72;
    final frameDiameter = size.width * frameDiameterFactor;
    final frameRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 20),
      width: frameDiameter,
      height: frameDiameter,
    );

    final cutoutPath = Path.combine(
      PathOperation.difference,
      Path()..addRect(rect),
      Path()..addOval(frameRect),
    );
    canvas.drawPath(cutoutPath, overlayPaint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawOval(frameRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _DishFocusPainter oldDelegate) {
    return oldDelegate.shadeColor != shadeColor ||
        oldDelegate.borderColor != borderColor;
  }
}
