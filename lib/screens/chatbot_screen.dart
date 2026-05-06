import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants.dart';
import '../services/gemini_service.dart';
import '../services/voice_input_helper.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _controller = TextEditingController();
  final _messages = <_UiMessage>[];
  bool _loading = false;
  bool _showRetry = false;
  String _lastPrompt = '';

  Future<void> _send([String? forcedText]) async {
    final text = (forcedText ?? _controller.text).trim();
    if (text.isEmpty || _loading) return;
    _controller.clear();
    setState(() {
      _messages.add(_UiMessage(text: text, isUser: true));
      _loading = true;
      _showRetry = false;
      _lastPrompt = text;
    });
    final reply = await GeminiService.instance.send(text);
    setState(() {
      _messages.add(_UiMessage(text: reply.text, isUser: false));
      _loading = false;
      _showRetry = reply.hadApiError;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Chatbot', style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _messages.length,
            itemBuilder: (_, i) {
              final m = _messages[i];
              return Align(
                alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: m.isUser ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white),
                  ),
                  child: Text(
                    m.text,
                    style: GoogleFonts.montserrat(
                      color: m.isUser ? Colors.white : AppColors.onBackground,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_showRetry)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextButton(
              onPressed: () => _send(_lastPrompt),
              child: const Text('3awd jarrab', style: TextStyle(color: AppColors.primary)),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onSubmitted: (_) => _send(),
                  decoration: const InputDecoration(
                    hintText: 'Posez votre question medicale...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              VoiceInputButton(
                onResult: (text) {
                  _controller.text = text;
                  _send();
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: _loading ? null : _send,
                icon: const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UiMessage {
  final String text;
  final bool isUser;

  const _UiMessage({required this.text, required this.isUser});
}
