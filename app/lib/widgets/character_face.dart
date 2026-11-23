/// Animated character face widget with dynamic emotional reactions.
library;

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Character face that animates based on state: listening, thinking, talking, celebrating.
class CharacterFace extends StatefulWidget {
  final bool isTalking;
  final bool isListening;
  final bool isThinking;
  final bool isCelebrating;
  final String characterId;
  final double size;

  const CharacterFace({
    super.key,
    this.isTalking = false,
    this.isListening = false,
    this.isThinking = false,
    this.isCelebrating = false,
    this.characterId = 'rule_farmer',
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
  late AnimationController _celebrateController;
  late Animation<double> _blinkAnimation;
  late Animation<double> _talkAnimation;
  late Animation<double> _thinkAnimation;
  late Animation<double> _celebrateAnimation;

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

    // Celebrate animation (gentle bounce / pulse)
    _celebrateController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _celebrateAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _celebrateController, curve: Curves.easeInOut),
    );
  }

  void _scheduleNextBlink() {
    _blinkTimer?.cancel();
    if (!mounted) return;
    _blinkTimer = Timer(Duration(milliseconds: 2000 + Random().nextInt(3000)), () async {
      if (mounted && !widget.isTalking && !widget.isCelebrating) {
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

    if (widget.isCelebrating && !oldWidget.isCelebrating) {
      _celebrateController.repeat(reverse: true);
    } else if (!widget.isCelebrating && oldWidget.isCelebrating) {
      _celebrateController.stop();
      _celebrateController.reset();
    }
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _blinkController.dispose();
    _talkController.dispose();
    _thinkController.dispose();
    _celebrateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _blinkAnimation,
          _talkAnimation,
          _thinkAnimation,
          _celebrateAnimation,
        ]),
        builder: (context, child) {
          final scale = widget.isCelebrating ? _celebrateAnimation.value : 1.0;
          return Transform.scale(
            scale: scale,
            child: CustomPaint(
              painter: _FacePainter(
                blinkValue: _blinkAnimation.value,
                talkValue: _talkAnimation.value,
                isListening: widget.isListening,
                isThinking: widget.isThinking,
                isCelebrating: widget.isCelebrating,
                thinkValue: _thinkAnimation.value,
                characterId: widget.characterId,
              ),
              size: Size(widget.size, widget.size),
            ),
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
  final bool isCelebrating;
  final double thinkValue;
  final String characterId;

  _FacePainter({
    required this.blinkValue,
    required this.talkValue,
    required this.isListening,
    required this.isThinking,
    required this.isCelebrating,
    required this.thinkValue,
    required this.characterId,
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
      ..color = (isCelebrating ? SpeakabooTheme.accent : SpeakabooTheme.accent.withValues(alpha: 0.3))
      ..style = PaintingStyle.stroke
      ..strokeWidth = isCelebrating ? 4 : 3;
    canvas.drawCircle(center, radius * 0.9, borderPaint);

    // Accessory by character
    _drawAccessory(canvas, center, radius);

    // Eyes
    final eyePaint = Paint()..color = SpeakabooTheme.textPrimary;
    final eyeY = center.dy - radius * 0.1;

    if (isCelebrating) {
      // Joyful squinting curve eyes: ^ ^
      final eyeArcPaint = Paint()
        ..color = SpeakabooTheme.textPrimary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      final leftEyePath = Path();
      leftEyePath.moveTo(center.dx - radius * 0.35, eyeY);
      leftEyePath.quadraticBezierTo(center.dx - radius * 0.25, eyeY - radius * 0.12, center.dx - radius * 0.15, eyeY);
      canvas.drawPath(leftEyePath, eyeArcPaint);

      final rightEyePath = Path();
      rightEyePath.moveTo(center.dx + radius * 0.15, eyeY);
      rightEyePath.quadraticBezierTo(center.dx + radius * 0.25, eyeY - radius * 0.12, center.dx + radius * 0.35, eyeY);
      canvas.drawPath(rightEyePath, eyeArcPaint);
    } else {
      // Normal blinking oval eyes
      final eyeHeight = radius * 0.12 * blinkValue;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx - radius * 0.25, eyeY),
          width: radius * 0.15,
          height: eyeHeight,
        ),
        eyePaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx + radius * 0.25, eyeY),
          width: radius * 0.15,
          height: eyeHeight,
        ),
        eyePaint,
      );
    }

    // Eyebrows
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

    if (isCelebrating) {
      // Wide joyful open grin
      final grinPaint = Paint()..color = SpeakabooTheme.accent;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(center.dx, mouthY), width: radius * 0.35, height: radius * 0.2),
          const Radius.circular(8),
        ),
        grinPaint,
      );
    } else if (isListening) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx, mouthY),
          width: radius * 0.15,
          height: radius * 0.12,
        ),
        mouthPaint,
      );
    } else if (isThinking) {
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
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx, mouthY),
          width: radius * 0.25,
          height: mouthOpen,
        ),
        mouthPaint,
      );
    } else {
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

    // Cheeks
    final cheekPaint = Paint()
      ..color = SpeakabooTheme.accent.withValues(alpha: isCelebrating ? 0.35 : 0.15);
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

  void _drawAccessory(Canvas canvas, Offset center, double radius) {
    if (characterId == 'dhaka_detective') {
      // Detective fedora / flat cap
      final hatPaint = Paint()..color = const Color(0xFF4A3E38);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(center.dx, center.dy - radius * 0.5),
            width: radius * 1.5,
            height: radius * 0.22,
          ),
          const Radius.circular(8),
        ),
        hatPaint,
      );
    } else if (characterId == 'professor_anika') {
      // Scholar reading glasses
      final glassPaint = Paint()
        ..color = const Color(0xFF2C5E7A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      final eyeY = center.dy - radius * 0.1;
      canvas.drawCircle(Offset(center.dx - radius * 0.25, eyeY), radius * 0.14, glassPaint);
      canvas.drawCircle(Offset(center.dx + radius * 0.25, eyeY), radius * 0.14, glassPaint);
      canvas.drawLine(
        Offset(center.dx - radius * 0.11, eyeY),
        Offset(center.dx + radius * 0.11, eyeY),
        glassPaint,
      );
    } else {
      // Farmer Reggie straw hat
      final hatPaint = Paint()..color = SpeakabooTheme.accent;
      final hatPath = Path();
      hatPath.moveTo(center.dx - radius * 0.7, center.dy - radius * 0.4);
      hatPath.lineTo(center.dx + radius * 0.7, center.dy - radius * 0.4);
      hatPath.lineTo(center.dx + radius * 0.5, center.dy - radius * 0.9);
      hatPath.lineTo(center.dx - radius * 0.5, center.dy - radius * 0.9);
      hatPath.close();
      canvas.drawPath(hatPath, hatPaint);

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
    }
  }

  @override
  bool shouldRepaint(_FacePainter oldDelegate) {
    return blinkValue != oldDelegate.blinkValue ||
        talkValue != oldDelegate.talkValue ||
        isListening != oldDelegate.isListening ||
        isThinking != oldDelegate.isThinking ||
        isCelebrating != oldDelegate.isCelebrating ||
        characterId != oldDelegate.characterId ||
        thinkValue != oldDelegate.thinkValue;
  }
}
