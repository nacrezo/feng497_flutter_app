import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv
import '../models/chat_message.dart';
import 'mock_glucose_service.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      print('Warning: GEMINI_API_KEY not found in .env');
    }
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
    );
  }

  Future<String> sendMessage(String message, double currentGlucose) async {
    final contextSystemPrompt = '''
You are a helpful AI medical assistant for a patient with Type 1 Diabetes.
Current Glucose Level: ${currentGlucose.toStringAsFixed(0)} mg/dL.
Answer the user's question with this context in mind. Keep answers concise and supportive.
''';

    final chat = _model.startChat(history: [
      Content.text(contextSystemPrompt),
    ]);

    try {
      final response = await chat.sendMessage(Content.text(message));
      return response.text ?? "I couldn't generate a response.";
    } catch (e) {
      if (e.toString().contains('API_KEY_INVALID')) {
        return "Error: Invalid API Key. Please update lib/services/gemini_service.dart";
      }
      return "Error connecting to Gemini: $e";
    }
  }
}

final geminiServiceProvider = Provider<GeminiService>((ref) => GeminiService());

// State Management for Chat

class GeminiChatState extends StateNotifier<List<ChatMessage>> {
  final GeminiService _geminiService;
  final Ref _ref;

  GeminiChatState(this._geminiService, this._ref) : super([
    ChatMessage(
      text: "Hello! I'm Gemini (Flash). How can I help you today?",
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

      final responseText = await _geminiService.sendMessage(text, currentGlucose);

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

final geminiChatProvider = StateNotifierProvider<GeminiChatState, List<ChatMessage>>((ref) {
  final service = ref.watch(geminiServiceProvider);
  return GeminiChatState(service, ref);
});
