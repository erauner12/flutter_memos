import 'dart:async'; // Import for Stream

import 'package:flutter/foundation.dart'; // Import for debugPrint
import 'package:flutter_memos/providers/settings_provider.dart'; // Import for geminiApiKeyProvider
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  final String _apiKey;
  GenerativeModel? _model;
  bool _isInitialized = false;
  String? _initializationError;

  // Expose the model for potential MCP client usage (or direct chat use)
  GenerativeModel? get model => _model;

  GeminiService(this._apiKey) {
    _initialize();
  }

  void _initialize() {
    if (_apiKey.isEmpty) {
      _initializationError = "API Key is empty.";
      debugPrint("Warning: GeminiService initialized with an empty API Key.");
      return;
    }
    try {
      // Use a model that supports generateContentStream, like gemini-pro or a flash model
      _model = GenerativeModel(
        // Consider making the model name configurable if needed
        model: 'gemini-1.5-flash-latest',
        apiKey: _apiKey,
        // Optional: Configure safety settings, generation config etc.
        // safetySettings: [ ... ],
        // generationConfig: GenerationConfig(...)
      );
      _isInitialized = true;
      _initializationError = null;
      debugPrint("GeminiService initialized successfully for streaming.");
    } catch (e) {
      debugPrint("Error initializing GenerativeModel: $e");
      _model = null;
      _isInitialized = false;
      _initializationError =
          "Failed to initialize Gemini Model: ${e.toString()}";
    }
  }

  bool get isInitialized => _isInitialized;
  String? get initializationError => _initializationError;

  // Method to send message and get a single response
  // Takes the latest prompt and the history *before* this prompt
  Future<GenerateContentResponse> generateContent(
    String prompt,
    List<Content> history, {
    List<Tool>? tools, // Optional tools parameter
  }) async {
    if (!_isInitialized || _model == null) {
      throw Exception(
        "Error: Gemini service not initialized. $_initializationError",
      );
    }

    try {
      // Construct the full history including the new user prompt
      final userContent = Content.text(prompt);
      final contentForApi = [
        ...history, // History before this turn
        Content('user', userContent.parts), // Current user prompt
      ];

      // Generate content using the non-streaming method
      final response = await _model!.generateContent(
        contentForApi,
        tools: tools, // Pass tools if provided
        // Optional: toolConfig for function calling mode
        // toolConfig: ToolConfig(functionCallingConfig: FunctionCallingConfig(mode: FunctionCallingMode.auto)),
      );
      return response;
    } catch (e) {
      debugPrint("Error calling Gemini generateContent: $e");
      // Rethrow a more specific exception or handle as needed
      throw Exception(
        "Error generating content with AI service: ${e.toString()}",
      );
    }
  }


  // Method to send message and get a stream of responses
  // Takes the latest prompt and the history *before* this prompt
  Stream<GenerateContentResponse> sendMessageStream(
    String prompt,
    List<Content> history,
  ) {
    if (!_isInitialized || _model == null) {
      // Return a stream that immediately emits an error
      return Stream.error(
        Exception(
          "Error: Gemini service not initialized. $_initializationError",
        ),
      );
    }

    try {
      // Construct the full history including the new user prompt
      final userContent = Content.text(prompt);
      final contentForApi = [
        ...history, // History before this turn
        Content('user', userContent.parts), // Current user prompt
      ];

      // Generate content using the stream method
      // NOTE: Function calling might behave differently with streaming.
      // For this plan, we focus on generateContent for the core logic.
      // If using streaming here, aggregation logic would be needed before checking FunctionCall.
      final stream = _model!.generateContentStream(
        contentForApi,
        // Tools can also be passed to the streaming method if needed
        // tools: tools,
        // toolConfig: ToolConfig(functionCallingConfig: FunctionCallingConfig(mode: FunctionCallingMode.auto)),
      );
      return stream;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error initiating Gemini stream: $e");
      }
      // Return a stream that immediately emits the error
      return Stream.error(
        Exception("Error initiating stream with AI service: ${e.toString()}"),
      );
    }
  }
}

// Provider for GeminiService
final geminiServiceProvider = Provider<GeminiService?>((ref) {
  // Watch the correct provider from settings_provider.dart
  final apiKey = ref.watch(geminiApiKeyProvider);
  if (apiKey.isNotEmpty) {
    // Check if the service needs reconfiguration (e.g., API key changed)
    // This simple provider rebuilds the service when the key changes.
    // For more complex scenarios, consider a StateNotifier or managing the instance lifecycle.
    debugPrint("Gemini API Key available, creating/updating GeminiService.");
    return GeminiService(apiKey);
  }
  debugPrint("Gemini API Key is empty, GeminiService is null.");
  return null;
});
