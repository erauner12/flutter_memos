import 'dart:async'; // Keep async import

import 'package:flutter_memos/utils/logger.dart'; // Assuming logger exists
// Remove http import
// import 'package:http/http.dart' as http;
// Add openai_dart import
import 'package:openai_dart/openai_dart.dart';

// --- Remove Simple Data Classes (MinimalCompletionRequest, etc.) ---
// These are now replaced by the schema from openai_dart

class MinimalOpenAiService {
  static final MinimalOpenAiService _instance = MinimalOpenAiService._internal();
  factory MinimalOpenAiService() => _instance;

  // Replace manual client with OpenAIClient
  late OpenAIClient _openAIClient;
  String _authToken = '';
  bool _isConfigured = false;
  // Remove manual http.Client
  // final http.Client _client;

  // Logger instance
  late final Logger _logger;

  // Configuration flags
  static bool verboseLogging = true;

  MinimalOpenAiService._internal() {
    _logger = Logger('MinimalOpenAI', enabled: verboseLogging);
    // Initialize with an empty client initially
    _openAIClient = OpenAIClient(apiKey: '');
  }

  bool get isConfigured => _isConfigured;

  void configureService({required String authToken}) {
    // Check if token actually changed to avoid unnecessary client recreation
    if (_authToken == authToken && _isConfigured) {
      if (verboseLogging) {
        _logger.info('Configuration unchanged.');
       }
       return;
    }
    _authToken = authToken;
    _isConfigured = _authToken.isNotEmpty;

    // Recreate the client with the new token
    _openAIClient = OpenAIClient(apiKey: _authToken);

    if (verboseLogging) {
      _logger.info('Service configured: ${isConfigured ? "YES" : "NO"}');
    }
  }

  // Health Check using listModels
  Future<bool> checkHealth() async {
    if (!isConfigured) {
      if (verboseLogging) {
        _logger.info('Health check skipped: Not configured.');
      }
      return false;
    }
    try {
      if (verboseLogging) {
        _logger.info('Performing health check (listModels)...');
      }
      // Use listModels as a lightweight health check
      await _openAIClient.listModels();
      if (verboseLogging) {
        _logger.info('Health check successful.');
      }
      return true;
    } on OpenAIClientException catch (e) {
      // Catch specific exception from openai_dart
      if (verboseLogging) {
        _logger.error('Health check failed: ${e.message} (Code: ${e.code})');
        // Optionally log e.body if needed
      }
      return false;
    } catch (e) {
      // Catch other potential errors
      if (verboseLogging) {
        _logger.error('Health check failed with unexpected error: $e');
      }
      return false;
    }
  }

  /// Fetches and filters suitable completion models from OpenAI.
  Future<List<String>> listCompletionModels() async {
    if (!isConfigured) {
      _logger.info('Cannot list models: Service not configured.');
      return []; // Return empty list if not configured
    }
    try {
      if (verboseLogging) {
        _logger.info('Fetching models from OpenAI...');
      }
      final ListModelsResponse response = await _openAIClient.listModels();
      // Filter models - adjust this logic based on desired models
      // Example: Include instruct models and potentially newer base models if compatible
      final suitableModels =
          response.data
              .where(
                (model) =>
                    model.id.contains('instruct') || // Keep instruct models
                    // model.id.startsWith('gpt-4') || // Example: Allow GPT-4 variants (might not support completion endpoint)
                    model.id.startsWith('babbage') || // Allow babbage
                    model.id.startsWith('davinci') || // Allow davinci
                    model.id.startsWith('gpt-3.5'),
              ) // Keep base GPT-3.5 (some might work)
              .map((model) => model.id) // Extract only the ID
              .toSet() // Use a Set to handle potential duplicates from filtering rules
              .toList(); // Convert back to list

      // Ensure a default is always present if available and move it to the top
      const defaultModel = 'gpt-3.5-turbo-instruct';
      if (suitableModels.contains(defaultModel)) {
        // Move default to the top if it exists
        suitableModels.remove(defaultModel);
        suitableModels.insert(0, defaultModel);
      } else if (response.data.any((m) => m.id == defaultModel)) {
        suitableModels.insert(
          0,
          defaultModel,
        ); // Add default if missing but available API lists it
      }

      if (verboseLogging) {
        _logger.info('Found ${suitableModels.length} suitable models.');
      }
      // Sort alphabetically after the potential default model insertion
      if (suitableModels.length > 1) {
        final first = suitableModels.first; // Keep potential default at top
        final rest = suitableModels.sublist(1);
        rest.sort();
        suitableModels.clear();
        suitableModels.add(first);
        suitableModels.addAll(rest);
      }
      return suitableModels;
    } on OpenAIClientException catch (e) {
      _logger.error(
        'OpenAI API Error listing models: ${e.message} (Code: ${e.code})',
      );
      return []; // Return empty list on error
    } catch (e) {
      _logger.error('Unexpected error listing models: $e');
      return []; // Return empty list on error
    }
  }


// --- Remove Core Completions Method (createCompletion) ---
  // This manual implementation is replaced by fixGrammar using the client directly

  // Grammar correction helper method using openai_dart
  // Change signature to accept modelId
  Future<String> fixGrammar(String text, {required String modelId}) async {
    if (!isConfigured) {
      throw Exception('MinimalOpenAiService not configured with API token.');
    }
    if (text.trim().isEmpty) {
      if (verboseLogging) {
        _logger.info('Skipping grammar fix for empty text.');
      }
      return text;
    }

    if (verboseLogging) {
      // Update log message
      _logger.info(
        'Fixing grammar for text (${text.length} chars) using model: $modelId',
      );
    }

    final promptText =
        'Correct the grammar and spelling of the following text:\n\n$text\n\nCorrected text:';

    // Create request using openai_dart's schema
    final request = CreateCompletionRequest(
      // Use the passed modelId
      model: CompletionModel.modelId(modelId),
      prompt: CompletionPrompt.string(promptText),
      maxTokens: (text.length * 1.5).ceil().clamp(
        60,
        1000,
      ), // Estimate max tokens
      temperature: 0.3, // Lower temperature for factual correction
    );

    try {
      // Use the openai_dart client
      final CreateCompletionResponse response = await _openAIClient
          .createCompletion(request: request);

      if (response.choices.isEmpty || response.choices.first.text.isEmpty) {
        // Use info or error instead of warning
        _logger.info('OpenAI returned no correction choices.');
        // Decide whether to throw or return original text
        return text; // Return original text if no correction provided
        // throw Exception('OpenAI returned no correction.');
      }

      final correctedText = response.choices.first.text.trim();

      if (verboseLogging) {
        _logger.info(
          'Grammar fix complete. Original: ${text.length} chars, Corrected: ${correctedText.length} chars',
        );
      }

      // Return original if correction is identical or effectively empty
      if (correctedText == text.trim()) {
        if (verboseLogging) {
          _logger.info('Correction identical to original, returning original.');
        }
        return text;
      }

      return correctedText;

    } on OpenAIClientException catch (e) {
      _logger.error(
        'OpenAI API Error during grammar fix: ${e.message} (Code: ${e.code})',
      );
      // Rethrow a more specific error or the original
      throw Exception('Failed to fix grammar using OpenAI: ${e.message}');
    } catch (e) {
      _logger.error('Unexpected error during grammar fix: $e');
      rethrow; // Rethrow unexpected errors
    }
  }

  // Dispose method might not be needed as OpenAIClient handles its internal client.
  // If you passed a custom client to OpenAIClient, dispose it here.
  void dispose() {
    // _client.close(); // Remove if using default client in OpenAIClient
    if (verboseLogging) {
      _logger.info('Service disposed.');
    }
  }
}
