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
      appBar: AppBar(
        title: Text('AI Assistant (Ollama)', style: GoogleFonts.outfit()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),
          _buildQuickActions(ref),
          _buildInputArea(ref),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: msg.isUser ? Colors.cyanAccent.withOpacity(0.2) : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(msg.isUser ? 20 : 0),
            bottomRight: Radius.circular(msg.isUser ? 0 : 20),
          ),
          border: Border.all(
            color: msg.isUser ? Colors.cyanAccent.withOpacity(0.5) : Colors.white.withOpacity(0.2),
          ),
        ),
        child: Text(
          msg.text,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(WidgetRef ref) {
    final actions = [
      "Current Glucose?",
      "What should I eat?",
      "Emergency Help",
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: actions.map((action) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(action, style: GoogleFonts.outfit(color: Colors.white)),
              backgroundColor: Colors.white.withOpacity(0.1),
              onPressed: () {
                ref.read(ollamaChatProvider.notifier).sendMessage(action);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputArea(WidgetRef ref) {
    return GlassContainer(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      blur: 10,
      border: null,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: GoogleFonts.outfit(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: GoogleFonts.outfit(color: Colors.white54),
                  border: InputBorder.none,
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
              icon: const Icon(Icons.send, color: Colors.cyanAccent),
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
    );
  }
}
