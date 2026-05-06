import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants.dart';
import '../services/gemini_service.dart';

// ---------------------------------------------------------------------------
// HomeScreen – Chifaae chat UI
// ---------------------------------------------------------------------------

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _messages = <ChatMessage>[];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;
  // Key is loaded from .env at startup — always ready.
  final bool _apiKeySet = true;

  @override
  void initState() {
    super.initState();
    // Show welcome message immediately — no API key dialog needed.
    WidgetsBinding.instance.addPostFrameCallback((_) => _addWelcomeMessage());
  }


  void _addWelcomeMessage() {
    setState(() {
      _messages.add(ChatMessage(
        role: MessageRole.assistant,
        text:
            'Salam! 👋 Ana Chifaae, l\'assistant médical dyalek. '
            'Décrivez vos symptômes en Darija ou en français, et je vous '
            'orienterai vers le bon spécialiste.',
        timestamp: DateTime.now(),
      ));
    });
  }

  // ── Send message ─────────────────────────────────────────────────────────

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading || !_apiKeySet) return;

    _controller.clear();
    setState(() {
      _messages.add(ChatMessage(
        role: MessageRole.user,
        text: text,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });
    _scrollToBottom();

    final reply = await GeminiService.instance.send(text);
    setState(() {
      _messages.add(ChatMessage(
        role: MessageRole.assistant,
        text: reply.text,
        timestamp: DateTime.now(),
        usedFastMode: reply.usedFastMode,
      ));
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Timer(const Duration(milliseconds: 120), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          // Emerald green avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.medical_services_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chifaae',
                style: GoogleFonts.montserrat(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onBackground,
                ),
              ),
              Text(
                'En ligne · Assistant médical',
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: const [SizedBox(width: 8)],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.surface),
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return _buildEmptyState();
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == _messages.length) return _buildTypingIndicator();
        return _ChatBubble(message: _messages[i]);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Icon(Icons.medical_services_rounded,
                color: AppColors.primary, size: 36),
          ),
          const SizedBox(height: 20),
          Text(
            'Salam! Chifaae',
            style: GoogleFonts.montserrat(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.onBackground,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'رعاية صحية مغربية',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: AppColors.accent,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 24),
          _buildSuggestionChips(),
        ],
      ),
    );
  }

  Widget _buildSuggestionChips() {
    final suggestions = [
      '🦷 J\'ai mal aux dents',
      '❤️ J\'ai des palpitations',
      '👶 Mon bébé a de la fièvre',
      '😮‍💨 J\'ai du mal à respirer',
    ];
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: suggestions.map((s) => _SuggestionChip(
        label: s,
        onTap: () {
          _controller.text = s;
          _sendMessage();
        },
      )).toList(),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          _AssistantAvatar(),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: _TypingDots(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.surface)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.surface),
              ),
              child: TextField(
                controller: _controller,
                style: GoogleFonts.montserrat(
                  color: AppColors.onBackground,
                  fontSize: 14,
                ),
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Décrivez vos symptômes...',
                  hintStyle: GoogleFonts.montserrat(
                    color: AppColors.muted,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _SendButton(onTap: _sendMessage, loading: _isLoading),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Chat bubble with float-in animation
// ---------------------------------------------------------------------------

class _ChatBubble extends StatefulWidget {
  final ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  State<_ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<_ChatBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  bool get _isAssistant => widget.message.role == MessageRole.assistant;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: Offset(_isAssistant ? -0.08 : 0.08, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: _isAssistant
                ? MainAxisAlignment.start
                : MainAxisAlignment.end,
            children: _isAssistant
                ? [_AssistantAvatar(), const SizedBox(width: 10), _bubble()]
                : [_bubble()],
          ),
        ),
      ),
    );
  }

  Widget _bubble() {
    return Flexible(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          // Emerald green bubble for assistant, surface for user
          color: _isAssistant
              ? AppColors.primary.withValues(alpha: 0.13)
              : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(_isAssistant ? 4 : 18),
            bottomRight: Radius.circular(_isAssistant ? 18 : 4),
          ),
          border: Border.all(
            color: _isAssistant
                ? AppColors.primary.withValues(alpha: 0.35)
                : AppColors.surface,
            width: 1.2,
          ),
          boxShadow: _isAssistant
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.message.text,
              style: GoogleFonts.montserrat(
                fontSize: 13.5,
                height: 1.55,
                color: _isAssistant
                    ? AppColors.onBackground
                    : AppColors.onBackground,
              ),
            ),
            if (_isAssistant && widget.message.usedFastMode) ...[
              const SizedBox(height: 8),
              Text(
                'Mode rapide activé',
                style: GoogleFonts.montserrat(
                  fontSize: 10.5,
                  color: AppColors.primary.withValues(alpha: 0.85),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared small widgets
// ---------------------------------------------------------------------------

class _AssistantAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.medical_services_rounded,
          color: Colors.white, size: 16),
    );
  }
}

class _SendButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool loading;
  const _SendButton({required this.onTap, required this.loading});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: loading
                ? [AppColors.muted, AppColors.surface]
                : [
                    AppColors.primary.withValues(alpha: 0.9),
                    AppColors.primary,
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: loading
              ? []
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
        ),
        child: loading
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              )
            : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            color: AppColors.onBackground,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Animated typing dots
// ---------------------------------------------------------------------------

class _TypingDots extends StatefulWidget {
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = ((_ctrl.value * 3) - i).clamp(0.0, 1.0);
            final bounce = (phase < 0.5 ? phase : 1.0 - phase) * 2;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Transform.translate(
                offset: Offset(0, -4 * bounce),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.6 + 0.4 * bounce),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
