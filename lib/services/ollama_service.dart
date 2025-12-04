import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import 'mock_glucose_service.dart';

const String _ollamaBaseUrl = 'http://10.0.2.2:11434/api/chat';
const String _modelName = 'mistral';

class OllamaService {
  Future<String> sendMessage(String message, double currentGlucose) async {
    final contextSystemPrompt = '''
You are a helpful AI medical assistant for a patient with Type 1 Diabetes.
Current Glucose Level: ${currentGlucose.toStringAsFixed(0)} mg/dL.
Answer the user's question with this context in mind. Keep answers concise and supportive.
''';

    try {
      final response = await http.post(
        Uri.parse(_ollamaBaseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': _modelName,
          'messages': [
            {'role': 'system', 'content': contextSystemPrompt},
            {'role': 'user', 'content': message}
          ],
          'stream': false, // Set to true for streaming (requires stream handling)
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message']['content'] as String;
      } else {
        return "Error: Ollama returned status ${response.statusCode}. Make sure Ollama is running.";
      }
    } catch (e) {
      return "Error: Could not connect to Ollama. Is it running? ($e)";
    }
  }
}

final ollamaServiceProvider = Provider((ref) => OllamaService());

class OllamaChatState extends StateNotifier<List<ChatMessage>> {
  final OllamaService _ollamaService;
  final Ref _ref;

  OllamaChatState(this._ollamaService, this._ref) : super([
    ChatMessage(
      text: "Hello! I'm your Local AI Assistant (Ollama). How can I help?",
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ]);

  Future<void> sendMessage(String text) async {
    state = [
      ...state,
      ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
    ];

    try {
      final glucoseAsync = _ref.read(glucoseProvider);
      double currentGlucose = 110.0;
      
      glucoseAsync.whenData((readings) {
        if (readings.isNotEmpty) {
          currentGlucose = readings.where((r) => !r.isPrediction).last.value;
        }
      });

      final responseText = await _ollamaService.sendMessage(text, currentGlucose);

      state = [
        ...state,
        ChatMessage(text: responseText, isUser: false, timestamp: DateTime.now()),
      ];
    } catch (e) {
      state = [
        ...state,
        ChatMessage(
          text: "Error: ${e.toString()}",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ];
    }
  }
}

final ollamaChatProvider = StateNotifierProvider<OllamaChatState, List<ChatMessage>>((ref) {
  final service = ref.watch(ollamaServiceProvider);
  return OllamaChatState(service, ref);
});
