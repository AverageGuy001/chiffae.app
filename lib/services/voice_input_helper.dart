import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../constants.dart';

/// A reusable voice-to-text widget with pulsing emerald animation.
class VoiceInputButton extends StatefulWidget {
  /// Called when speech is successfully recognised.
  final ValueChanged<String> onResult;

  /// Called while listening (optional, for UI feedback).
  final VoidCallback? onListening;

  /// Called when listening stops.
  final VoidCallback? onStop;

  /// Icon size.
  final double iconSize;

  const VoiceInputButton({
    super.key,
    required this.onResult,
    this.onListening,
    this.onStop,
    this.iconSize = 24,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  late final stt.SpeechToText _speech;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  bool _isListening = false;
  bool _hasPermission = false;
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      _hasPermission = true;
      await _speech.initialize();
    }
  }

  Future<void> _startListening() async {
    if (!_hasPermission) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.mic_off_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Permission micro nécessaire.',
                    style: GoogleFonts.montserrat(fontSize: 13),
                  ),
                ],
              ),
              backgroundColor: AppColors.primary,
            ),
          );
        }
        return;
      }
      _hasPermission = true;
      final available = await _speech.initialize();
      if (!available) return;
    }

    if (_speech.isAvailable) {
      setState(() => _isListening = true);
      _pulseController.repeat(reverse: true);
      _lastWords = '';
      widget.onListening?.call();

      // Find best available locale: fr-FR, ar-SA, ar-MA
      String? selectedLocale;
      try {
        final systemLocales = await _speech.locales();
        final preferred = ['fr-FR', 'ar-SA', 'ar-MA'];
        for (final pref in preferred) {
          for (final loc in systemLocales) {
            if (loc.localeId == pref) {
              selectedLocale = pref;
              break;
            }
          }
          if (selectedLocale != null) break;
        }
      } catch (_) {
        // If locale detection fails, default to system locale
      }

      await _speech.listen(
        onResult: (result) {
          final text = result.recognizedWords.trim();
          _lastWords = text;
          if (result.finalResult && text.isNotEmpty) {
            widget.onResult(text);
          }
        },
        listenFor: const Duration(seconds: 8),
        pauseFor: const Duration(seconds: 2),
        localeId: selectedLocale,
        onSoundLevelChange: (level) {},
        listenOptions: stt.SpeechListenOptions(
          cancelOnError: true,
          partialResults: true,
        ),
      );
    }
  }

  Future<void> _stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _pulseController.stop();
      _pulseController.reset();
      setState(() => _isListening = false);
      widget.onStop?.call();

      if (_lastWords.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  "Désolé, je n'ai pas entendu. Réessayez ?",
                  style: GoogleFonts.montserrat(fontSize: 13),
                ),
              ],
            ),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _startListening(),
      onTapUp: (_) => _stopListening(),
      onTapCancel: () => _stopListening(),
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (context, child) {
          final size = _isListening ? 44.0 * _pulseAnim.value : 44.0;
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: _isListening
                  ? AppColors.primary.withValues(alpha: 0.85)
                  : AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              boxShadow: _isListening
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              _isListening ? Icons.mic_rounded : Icons.keyboard_voice_rounded,
              size: widget.iconSize,
              color: _isListening ? Colors.white : AppColors.primary,
            ),
          );
        },
      ),
    );
  }
}