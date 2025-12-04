import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import '../services/ollama_service.dart';
import '../models/chat_message.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(ollamaChatProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: GlassContainer(
          blur: 10,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'AI Assistant',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return _buildModernMessageBubble(msg);
                  },
                ),
              ),
              _buildModernQuickActions(ref),
              _buildModernInputArea(ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: isUser 
              ? Colors.cyanAccent.withOpacity(0.15) 
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(24),
            topRight: const Radius.circular(24),
            bottomLeft: Radius.circular(isUser ? 24 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 24),
          ),
          border: Border.all(
            color: isUser 
                ? Colors.cyanAccent.withOpacity(0.3) 
                : Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                msg.text,
                textAlign: TextAlign.left,
                style: GoogleFonts.outfit(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}",
                style: GoogleFonts.outfit(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernQuickActions(WidgetRef ref) {
    final actions = [
      "Current Glucose?",
      "What should I eat?",
      "Emergency Help",
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: actions.map((action) {
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () {
                ref.read(ollamaChatProvider.notifier).sendMessage(action);
              },
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Text(
                  action,
                  style: GoogleFonts.outfit(
                    color: Colors.cyanAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildModernInputArea(WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.9),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: GoogleFonts.outfit(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: GoogleFonts.outfit(color: Colors.white38),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          ref.read(ollamaChatProvider.notifier).sendMessage(value);
                          _controller.clear();
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.cyanAccent),
                    onPressed: () {
                      if (_controller.text.isNotEmpty) {
                        ref.read(ollamaChatProvider.notifier).sendMessage(_controller.text);
                        _controller.clear();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
