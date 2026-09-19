import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../ui/app_state.dart';
import '../ui/app_theme.dart';
import '../ui/foot_shapes.dart';
import '../ui/strings.dart';

class GuideStep {
  final String key;
  final String labelKey;
  final FootSide side;
  final FootView view;

  const GuideStep({
    required this.key,
    required this.labelKey,
    required this.side,
    required this.view,
  });
}

/// Guided capture, one position at a time.
///
/// The foot outline dims everything around it, breathes while you frame, and
/// locks green the moment the shot lands. The ring at the top fills segment by
/// segment so the person always knows how many positions are left.
class CaptureGuidePage extends StatefulWidget {
  final List<GuideStep> steps;
  final Map<String, Uint8List> existing;

  const CaptureGuidePage({
    super.key,
    required this.steps,
    this.existing = const {},
  });

  @override
  State<CaptureGuidePage> createState() => _CaptureGuidePageState();
}

class _CaptureGuidePageState extends State<CaptureGuidePage>
    with SingleTickerProviderStateMixin {
  CameraController? _camera;
  late final AnimationController _pulse;

  final Map<String, Uint8List> _shots = {};
  final ImagePicker _picker = ImagePicker();

  int _index = 0;
  bool _busy = false;
  bool _locked = false;
  bool _holding = false;
  bool _torch = false;
  String? _cameraError;

  String get lang => appLanguage.value;

  GuideStep get step => widget.steps[_index];

  @override
  void initState() {
    super.initState();
    _shots.addAll(widget.existing);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _startCamera();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _camera?.dispose();
    super.dispose();
  }

  Future<void> _startCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _cameraError = 'no-camera');
        return;
      }

      final back = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _camera = controller;
        _cameraError = null;
      });
    } catch (_) {
      if (mounted) setState(() => _cameraError = 'denied');
    }
  }

  Future<void> _toggleTorch() async {
    final camera = _camera;
    if (camera == null) return;
    try {
      await camera.setFlashMode(_torch ? FlashMode.off : FlashMode.torch);
      setState(() => _torch = !_torch);
    } catch (_) {
      // Not supported on this device or on the web build: ignore quietly.
    }
  }

  Future<void> _capture() async {
    final camera = _camera;
    if (camera == null || _busy) return;

    setState(() {
      _busy = true;
      _holding = true;
    });

    // A short "hold still" beat, which genuinely reduces blur.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    try {
      final file = await camera.takePicture();
      final bytes = await file.readAsBytes();
      if (!mounted) return;

      HapticFeedback.mediumImpact();
      setState(() {
        _shots[step.key] = bytes;
        _locked = true;
        _holding = false;
      });

      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() {
        _locked = false;
        _busy = false;
      });
      _advance();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _holding = false;
      });
      kToast(context, S.t(lang, 'common.error'), error: true);
    }
  }

  Future<void> _fromGallery() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1400,
        imageQuality: 80,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _shots[step.key] = bytes);
      _advance();
    } catch (_) {
      if (mounted) kToast(context, S.t(lang, 'common.error'), error: true);
    }
  }

  void _advance() {
    final next = widget.steps.indexWhere(
      (item) => !_shots.containsKey(item.key),
    );
    if (next == -1) {
      _finish();
      return;
    }
    setState(() => _index = next);
  }

  void _finish() => Navigator.of(context).pop(_shots);

  @override
  Widget build(BuildContext context) {
    final captured = widget.steps.map((s) => _shots.containsKey(s.key)).toList();
    final doneCount = captured.where((value) => value).length;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1A1E),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _preview(),
          if (_camera != null && _camera!.value.isInitialized)
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) => CustomPaint(
                painter: FootGuidePainter(
                  side: step.side,
                  view: step.view,
                  pulse: _holding ? 1 : _pulse.value,
                  locked: _locked,
                ),
              ),
            ),
          SafeArea(
            child: Column(
              children: [
                _topBar(captured, doneCount),
                const Spacer(),
                _hint(),
                const SizedBox(height: 14),
                _bottomBar(doneCount),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _preview() {
    final camera = _camera;
    if (camera != null && camera.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: camera.value.previewSize?.height ?? 720,
          height: camera.value.previewSize?.width ?? 1280,
          child: CameraPreview(camera),
        ),
      );
    }

    return Container(
      color: const Color(0xFF0B1A1E),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_cameraError == null) ...[
              const CircularProgressIndicator(color: Colors.white54),
              const SizedBox(height: 18),
              Text(
                S.t(lang, 'capture.starting'),
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ] else ...[
              const Icon(Icons.no_photography_outlined, color: Colors.white38, size: 46),
              const SizedBox(height: 14),
              Text(
                S.t(lang, 'capture.noCamera'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _fromGallery,
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: Text(S.t(lang, 'check.gallery')),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _topBar(List<bool> captured, int doneCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 14, 0),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(_shots),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
              Expanded(
                child: Text(
                  '$doneCount / ${widget.steps.length}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: _camera == null ? null : _toggleTorch,
                icon: Icon(
                  _torch ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
                  color: _torch ? K.warn : Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 78,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.steps.length; i++)
                  _StepChip(
                    step: widget.steps[i],
                    label: S.t(lang, widget.steps[i].labelKey),
                    done: captured[i],
                    active: i == _index,
                    onTap: () => setState(() => _index = i),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hint() {
    final text = _holding
        ? S.t(lang, 'capture.hold')
        : '${S.t(lang, 'check.step')} ${_index + 1} · ${S.t(lang, step.labelKey)}';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: ValueKey(text),
        margin: const EdgeInsets.symmetric(horizontal: 26),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xCC0B1A1E),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              S.t(lang, 'capture.tip'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar(int doneCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: IconButton(
              onPressed: _fromGallery,
              icon: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 26),
              tooltip: S.t(lang, 'check.gallery'),
            ),
          ),
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: _camera == null || _busy ? null : _capture,
                child: SizedBox(
                  width: 92,
                  height: 92,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(92, 92),
                        painter: CaptureRingPainter(
                          total: widget.steps.length,
                          done: widget.steps.map((s) => _shots.containsKey(s.key)).toList(),
                          active: _index,
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: _busy ? 54 : 66,
                        height: _busy ? 54 : 66,
                        decoration: BoxDecoration(
                          color: _locked ? K.ok : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: _locked
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 30)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 58,
            child: doneCount == 0
                ? const SizedBox.shrink()
                : TextButton(
                    onPressed: _finish,
                    child: Text(
                      S.t(lang, 'capture.done'),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  final GuideStep step;
  final String label;
  final bool done;
  final bool active;
  final VoidCallback onTap;

  const _StepChip({
    required this.step,
    required this.label,
    required this.done,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = done ? K.ok : (active ? Colors.white : Colors.white54);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 42,
              height: 46,
              decoration: BoxDecoration(
                color: done ? K.ok.withAlpha(38) : Colors.white10,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: active ? Colors.white : Colors.transparent),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(42, 46),
                    painter: FootBadgePainter(side: step.side, color: color),
                  ),
                  if (done)
                    const Positioned(
                      right: 4,
                      bottom: 4,
                      child: Icon(Icons.check_circle_rounded, color: K.ok, size: 14),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                height: 1.15,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
