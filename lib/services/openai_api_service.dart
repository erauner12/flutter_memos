import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_memos/openai_api/lib/api.dart' as openai; // Use alias
import 'package:flutter_memos/utils/logger.dart';

class OpenaiApiService {
  static final OpenaiApiService _instance = OpenaiApiService._internal();
  factory OpenaiApiService() => _instance;

  // Use generated API client and specific API (CompletionsApi based on file map)
  late openai.ApiClient _apiClient;
  late openai.CompletionsApi _completionsApi;
  // If ModelsApi was generated and needed for health check:
  // late openai.ModelsApi _modelsApi;

  String _authToken = '';
  bool _isInitialized = false;
  
  // Logger instance
  late final Logger _logger;

  // Configuration flags
  static bool verboseLogging = true;

  OpenaiApiService._internal() {
    _logger = Logger('OpenAI API', enabled: verboseLogging);
    // Initial setup with empty token, configureService will set the real one
    _initializeClient('');
  }

  /// Configure the service with the OpenAI API key
  void configureService({required String authToken}) {
    if (_authToken == authToken && _isInitialized) {
      if (verboseLogging) {
        _logger.info('Configuration unchanged, skipping re-initialization.');
      }
      return;
    }

    if (verboseLogging) {
      _logger.info(
        'Updating configuration with ${authToken.isNotEmpty ? "new token" : "empty token"}.',
      );
    }

    _authToken = authToken;
    _initializeClient(_authToken);
  }

  /// Initialize the API client with the given auth token
  void _initializeClient(String token) {
    try {
      // Standard OpenAI base path
      const String basePath = 'https://api.openai.com/v1';

      _apiClient = openai.ApiClient(
        basePath: basePath,
        authentication: openai.HttpBearerAuth()..accessToken = token,
      );

      // Initialize the specific API endpoint class(es) needed
      _completionsApi = openai.CompletionsApi(_apiClient);
      // If ModelsApi was generated:
      // _modelsApi = openai.ModelsApi(_apiClient);

      _isInitialized = true;

      if (verboseLogging) {
        _logger.info('Successfully initialized client for $basePath.',
        );
      }
    } catch (e) {
      _isInitialized = false; // Mark as not initialized on error
      _logger.error('Error initializing client', e);
      // Optionally rethrow or handle more gracefully
      // throw Exception('Failed to initialize OpenAI API client: $e');
    }
  }

  /// Check if the service has been configured with an API key.
  bool get isConfigured => _authToken.isNotEmpty && _isInitialized;

  /// Check API health by making a simple request (e.g., list models or simple completion)
  Future<bool> checkHealth() async {
    if (!isConfigured) {
      if (verboseLogging) {
        _logger.info('Health check skipped: Service not configured.');
      }
      return false;
    }

    if (verboseLogging) {
      _logger.info('Performing health check...');
    }

    try {
      // Option 1: Use listModels if ModelsApi is available
      // await _modelsApi.listModels();

      // Option 2: Use a very cheap completion request as a fallback health check
      final model = openai.CreateCompletionRequestModel.fromJson('gpt-3.5-turbo-instruct');
      final prompt = openai.CreateCompletionRequestPrompt.fromJson('Test');

      if (model == null || prompt == null) {
        throw Exception("Failed to create request components for health check.");
      }

      // Correctly create the request object with required parameters
      final healthCheckRequest = openai.CreateCompletionRequest(
        model: model, // Pass the model object
        prompt: prompt, // Pass the prompt object
        maxTokens: 1,
      );

      // Use direct createCompletion instead of createCompletionWithHttpInfo
      final response = await _completionsApi.createCompletion(
        healthCheckRequest,
      );

      if (verboseLogging) {
        _logger.info('Health check successful: received valid response');
      }
      
      // If we got a non-null response without exceptions, consider it healthy
      return response != null;

    } catch (e) {
      _handleApiError('Health Check', e);
      return false;
    }
  }

  /// Correct grammar and spelling of the input text using OpenAI Completions API
  Future<String> fixGrammar(String text) async {
    if (!isConfigured) {
      throw Exception('OpenAI API service is not configured with an API key.');
    }
    if (text.trim().isEmpty) {
      return text; // Return original text if empty or whitespace
    }

    if (verboseLogging) {
      _logger.info('Requesting grammar fix for text...');
    }

    // Construct the prompt for grammar correction
    final promptText =
        'Correct the grammar and spelling of the following text:\n\n$text\n\nCorrected text:';

    // Create the request object using the generated model
    final model = openai.CreateCompletionRequestModel.fromJson('gpt-3.5-turbo-instruct');
    final requestPrompt = openai.CreateCompletionRequestPrompt.fromJson(
      promptText,
    );

    if (model == null || requestPrompt == null) {
        throw Exception("Failed to create request components for grammar fix.");
    }

    // Correctly create the request object with required parameters
    // Renamed variable to avoid conflict
    final grammarFixRequest = openai.CreateCompletionRequest(
      // Use a model suitable for instruction following, like davinci-instruct or gpt-3.5-turbo-instruct
      // Check OpenAI documentation for current best/cheapest model for this task.
      model: model, // Pass the model object
      prompt: requestPrompt, // Pass the prompt object
      maxTokens: (text.length * 1.5).ceil().clamp(60, 1000), // Estimate max tokens needed
      temperature: 0.3, // Lower temperature for more deterministic correction
      // stop: ['\n'], // Optional: Stop generation at newline if needed
    );

    try {
      final openai.CreateCompletionResponse? response =
          await _completionsApi
          .createCompletion(grammarFixRequest); // Use renamed request

      if (response == null || response.choices.isEmpty) {
        throw Exception('OpenAI API returned an empty response.');
      }

      // Extract the corrected text - remove unnecessary null check since trim() returns non-null
      String correctedText = response.choices[0].text.trim();

      if (verboseLogging) {
        _logger.info('Grammar fix successful. Corrected text received.');
        // _logger.info('Corrected Text: $correctedText'); // Potentially log corrected text
      }

      // Basic check to return original if correction is empty or identical
      if (correctedText.isEmpty || correctedText == text.trim()) {
        if (verboseLogging) {
          _logger.info(
            'No significant correction made, returning original text.',
          );
        }
        return text;
      }

      return correctedText;

    } catch (e) {
      _handleApiError('Fix Grammar', e);
      // Rethrow a more user-friendly exception or the original
      throw Exception('Failed to fix grammar using OpenAI: $e');
    }
  }

  /// Helper to log API errors
  void _handleApiError(String context, dynamic error) {
    if (kDebugMode) {
      _logger.error('Error - $context', error);
      if (error is openai.ApiException) {
        _logger.error('  Code: ${error.code}');
        _logger.error('  Message: ${error.message}');
        if (error.innerException != null) {
          _logger.error('  Inner Exception: ${error.innerException}');
        }
        if (error.stackTrace != null) {
          _logger.error('  Stack Trace: ${error.stackTrace}');
        }
      }
    }
  }
}
