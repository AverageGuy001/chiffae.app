import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Service that sends audio to Groq Whisper API and returns transcribed text.
class VoiceService {
  VoiceService._();
  static final VoiceService instance = VoiceService._();

  static const _kGroqWhisperUrl =
      'https://api.groq.com/openai/v1/audio/transcriptions';

  String? _apiKey;

  /// Must be called after .env is loaded.
  void init() {
    _apiKey = dotenv.env['GROQ_API_KEY'] ?? dotenv.env['GEMINI_API_KEY'];
  }

  /// Transcribe an audio file via Groq Whisper.
  /// Returns the transcribed text, or null on failure.
  Future<String?> transcribeSpeech(String filePath) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      debugPrint('[VoiceService] No API key available.');
      return null;
    }

    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        debugPrint('[VoiceService] File not found: $filePath');
        return null;
      }

      final request = http.MultipartRequest('POST', Uri.parse(_kGroqWhisperUrl))
        ..headers['Authorization'] = 'Bearer $_apiKey'
        ..files.add(await http.MultipartFile.fromPath('file', filePath))
        ..fields['model'] = 'whisper-large-v3-turbo'
        ..fields['language'] = 'fr'
        ..fields['prompt'] =
            'Le patient parle en Arabe Marocain (Darija) ou en Français. '
            'Traduis les termes médicaux informels en français professionnel.'
        ..fields['response_format'] = 'json';

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
        return decoded['text'] as String?;
      } else {
        debugPrint(
            '[VoiceService] Groq Whisper error ${response.statusCode}: $responseBody');
        return null;
      }
    } catch (e) {
      debugPrint('[VoiceService] Exception: $e');
      return null;
    }
  }
}