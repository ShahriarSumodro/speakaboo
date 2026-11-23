/// Animated character face widget.
///
/// Simple cartoon face with:
/// - Mouth animation synced to audio playback
/// - Idle blink animation
/// - Different expressions for states
library;

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Character face that animates based on state.
class CharacterFace extends StatefulWidget {
  final bool isTalking;
  final bool isListening;
  final bool isThinking;
  final double size;

  const CharacterFace({
    super.key,
    this.isTalking = false,
    this.isListening = false,
    this.isThinking = false,
    this.size = 200,
  });

  @override
  State<CharacterFace> createState() => _CharacterFaceState();
}

class _CharacterFaceState extends State<CharacterFace>
    with TickerProviderStateMixin {
  Timer? _blinkTimer;
  late AnimationController _blinkController;
  late AnimationController _talkController;
  late AnimationController _thinkController;
  late Animation<double> _blinkAnimation;
  late Animation<double> _talkAnimation;
  late Animation<double> _thinkAnimation;

  @override
  void initState() {
    super.initState();

    // Blink animation (periodic)
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.1).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
    _scheduleNextBlink();

    // Talk animation (mouth opening/closing)
    _talkController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _talkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _talkController, curve: Curves.easeInOut),
    );

    // Think animation (dots bouncing)
    _thinkController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _thinkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      _thinkController,
    );
  }

  void _scheduleNextBlink() {
    _blinkTimer?.cancel();
    if (!mounted) return;
    _blinkTimer = Timer(Duration(milliseconds: 2000 + Random().nextInt(3000)), () async {
      if (mounted && !widget.isTalking) {
        await _blinkController.forward();
        if (mounted) {
          await _blinkController.reverse();
        }
      }
      if (mounted) {
        _scheduleNextBlink();
      }
    });
  }

  @override
  void didUpdateWidget(CharacterFace oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isTalking && !oldWidget.isTalking) {
      _talkController.repeat(reverse: true);
    } else if (!widget.isTalking && oldWidget.isTalking) {
      _talkController.stop();
      _talkController.reset();
    }

    if (widget.isThinking && !oldWidget.isThinking) {
      _thinkController.repeat();
    } else if (!widget.isThinking && oldWidget.isThinking) {
      _thinkController.stop();
      _thinkController.reset();
    }
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _blinkController.dispose();
    _talkController.dispose();
    _thinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_blinkAnimation, _talkAnimation, _thinkAnimation]),
        builder: (context, child) {
          return CustomPaint(
            painter: _FacePainter(
              blinkValue: _blinkAnimation.value,
              talkValue: _talkAnimation.value,
              isListening: widget.isListening,
              isThinking: widget.isThinking,
              thinkValue: _thinkAnimation.value,
            ),
            size: Size(widget.size, widget.size),
          );
        },
      ),
    );
  }
}

class _FacePainter extends CustomPainter {
  final double blinkValue;
  final double talkValue;
  final bool isListening;
  final bool isThinking;
  final double thinkValue;

  _FacePainter({
    required this.blinkValue,
    required this.talkValue,
    required this.isListening,
    required this.isThinking,
    required this.thinkValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Face circle
    final facePaint = Paint()
      ..color = SpeakabooTheme.surface
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.9, facePaint);

    // Face border
    final borderPaint = Paint()
      ..color = SpeakabooTheme.accent.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius * 0.9, borderPaint);

    // Hat (farmer hat)
    final hatPaint = Paint()..color = SpeakabooTheme.accent;
    final hatPath = Path();
    hatPath.moveTo(center.dx - radius * 0.7, center.dy - radius * 0.4);
    hatPath.lineTo(center.dx + radius * 0.7, center.dy - radius * 0.4);
    hatPath.lineTo(center.dx + radius * 0.5, center.dy - radius * 0.9);
    hatPath.lineTo(center.dx - radius * 0.5, center.dy - radius * 0.9);
    hatPath.close();
    canvas.drawPath(hatPath, hatPaint);

    // Hat brim
    final brimPaint = Paint()
      ..color = SpeakabooTheme.accent
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy - radius * 0.4),
          width: radius * 1.6,
          height: radius * 0.15,
        ),
        const Radius.circular(4),
      ),
      brimPaint,
    );

    // Eyes
    final eyePaint = Paint()..color = SpeakabooTheme.textPrimary;
    final eyeY = center.dy - radius * 0.1;
    final eyeHeight = radius * 0.12 * blinkValue;

    // Left eye
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - radius * 0.25, eyeY),
        width: radius * 0.15,
        height: eyeHeight,
      ),
      eyePaint,
    );

    // Right eye
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + radius * 0.25, eyeY),
        width: radius * 0.15,
        height: eyeHeight,
      ),
      eyePaint,
    );

    // Eyebrows (slightly serious for farmer character)
    final browPaint = Paint()
      ..color = SpeakabooTheme.textPrimary
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(center.dx - radius * 0.35, eyeY - radius * 0.18),
      Offset(center.dx - radius * 0.15, eyeY - radius * 0.22),
      browPaint,
    );
    canvas.drawLine(
      Offset(center.dx + radius * 0.15, eyeY - radius * 0.22),
      Offset(center.dx + radius * 0.35, eyeY - radius * 0.18),
      browPaint,
    );

    // Mouth
    final mouthPaint = Paint()
      ..color = SpeakabooTheme.textPrimary
      ..style = PaintingStyle.fill;

    final mouthY = center.dy + radius * 0.25;
    final mouthOpen = talkValue * radius * 0.15;

    if (isListening) {
      // Small open circle when listening
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx, mouthY),
          width: radius * 0.15,
          height: radius * 0.12,
        ),
        mouthPaint,
      );
    } else if (isThinking) {
      // Three dots when thinking
      for (int i = 0; i < 3; i++) {
        final dotOffset = sin((thinkValue * 2 * pi) + (i * 0.8)) * 3;
        canvas.drawCircle(
          Offset(
            center.dx + (i - 1) * radius * 0.12,
            mouthY + dotOffset,
          ),
          3,
          mouthPaint,
        );
      }
    } else if (mouthOpen > 1) {
      // Talking mouth
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx, mouthY),
          width: radius * 0.25,
          height: mouthOpen,
        ),
        mouthPaint,
      );
    } else {
      // Slight smile
      final smilePaint = Paint()
        ..color = SpeakabooTheme.textPrimary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      
      final smilePath = Path();
      smilePath.moveTo(center.dx - radius * 0.15, mouthY - 2);
      smilePath.quadraticBezierTo(
        center.dx, mouthY + radius * 0.08,
        center.dx + radius * 0.15, mouthY - 2,
      );
      canvas.drawPath(smilePath, smilePaint);
    }

    // Cheeks (subtle warm blush)
    final cheekPaint = Paint()
      ..color = SpeakabooTheme.accent.withValues(alpha: 0.15);
    canvas.drawCircle(
      Offset(center.dx - radius * 0.4, mouthY - radius * 0.05),
      radius * 0.1,
      cheekPaint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.4, mouthY - radius * 0.05),
      radius * 0.1,
      cheekPaint,
    );
  }

  @override
  bool shouldRepaint(_FacePainter oldDelegate) {
    return blinkValue != oldDelegate.blinkValue ||
        talkValue != oldDelegate.talkValue ||
        isListening != oldDelegate.isListening ||
        isThinking != oldDelegate.isThinking ||
        thinkValue != oldDelegate.thinkValue;
  }
}
