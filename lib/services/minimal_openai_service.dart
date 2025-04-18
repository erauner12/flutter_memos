import 'dart:async'; // Keep async import

import 'package:flutter_memos/utils/logger.dart'; // Assuming logger exists
import 'package:openai_dart/openai_dart.dart';

// A simple structure for passing messages to createChatCompletion
// (We can keep it or rename it; this is an internal helper for mapping.)
class OpenAiChatMessage {
  final String role; // 'system', 'user', 'assistant'
  final String content;
  OpenAiChatMessage({required this.role, required this.content});
}

class MinimalOpenAiService {
  static final MinimalOpenAiService _instance = MinimalOpenAiService._internal();
  factory MinimalOpenAiService() => _instance;

  late OpenAIClient _openAIClient;
  String _authToken = '';
  bool _isConfigured = false;

  late final Logger _logger;
  static bool verboseLogging = true;

  MinimalOpenAiService._internal() {
    _logger = Logger('MinimalOpenAI', enabled: verboseLogging);
    _openAIClient = OpenAIClient(apiKey: '');
  }

  bool get isConfigured => _isConfigured;

  void configureService({required String authToken}) {
    if (_authToken == authToken && _isConfigured) {
      if (verboseLogging) {
        _logger.info('Configuration unchanged.');
      }
      return;
    }
    _authToken = authToken;
    _isConfigured = _authToken.isNotEmpty;

    _openAIClient = OpenAIClient(apiKey: _authToken);

    if (verboseLogging) {
      _logger.info('Service configured: ${isConfigured ? "YES" : "NO"}');
    }
  }

  /// A quick health check using listModels
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
      await _openAIClient.listModels();
      if (verboseLogging) {
        _logger.info('Health check successful.');
      }
      return true;
    } on OpenAIClientException catch (e) {
      if (verboseLogging) {
        _logger.error('Health check failed: ${e.message} (Code: ${e.code})');
      }
      return false;
    } catch (e) {
      if (verboseLogging) {
        _logger.error('Health check failed with unexpected error: $e');
      }
      return false;
    }
  }

  /// Fetches and filters suitable *completion* models from OpenAI (not chat).
  /// If you only do chat completions, you can skip or remove this logic.
  Future<List<String>> listCompletionModels() async {
    if (!isConfigured) {
      _logger.info('Cannot list models: Service not configured.');
      return [];
    }
    try {
      if (verboseLogging) {
        _logger.info('Fetching models from OpenAI...');
      }
      final ListModelsResponse response = await _openAIClient.listModels();

      // Example filter logic - adapt as needed
      final suitableModels =
          response.data
              .where(
                (model) =>
                    model.id.contains('instruct') ||
                    model.id.startsWith('babbage') ||
                    model.id.startsWith('davinci') ||
                    model.id.startsWith('gpt-3.5'),
              )
              .map((model) => model.id)
              .toSet()
              .toList();

      const defaultModel = 'gpt-3.5-turbo-instruct';
      if (suitableModels.contains(defaultModel)) {
        suitableModels.remove(defaultModel);
        suitableModels.insert(0, defaultModel);
      } else if (response.data.any((m) => m.id == defaultModel)) {
        suitableModels.insert(0, defaultModel);
      }

      if (verboseLogging) {
        _logger.info('Found ${suitableModels.length} suitable models.');
      }

      if (suitableModels.length > 1) {
        final first = suitableModels.first;
        final rest = suitableModels.sublist(1);
        rest.sort();
        suitableModels
          ..clear()
          ..add(first)
          ..addAll(rest);
      }
      return suitableModels;
    } on OpenAIClientException catch (e) {
      _logger.error(
        'OpenAI API Error listing models: ${e.message} (Code: ${e.code})',
      );
      return [];
    } catch (e) {
      _logger.error('Unexpected error listing models: $e');
      return [];
    }
  }

  /// Grammar correction helper method using the Completions API
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
      _logger.info(
        'Fixing grammar for text (${text.length} chars) using model: $modelId',
      );
    }

    final promptText =
        'Correct the grammar and spelling of the following text:\n\n$text\n\nCorrected text:';

    final request = CreateCompletionRequest(
      model: CompletionModel.modelId(modelId),
      prompt: CompletionPrompt.string(promptText),
      maxTokens: (text.length * 1.5).ceil().clamp(60, 1000),
      temperature: 0.3,
    );

    try {
      final CreateCompletionResponse response = await _openAIClient
          .createCompletion(request: request);

      if (response.choices.isEmpty || response.choices.first.text.isEmpty) {
        _logger.info('OpenAI returned no correction choices.');
        return text;
      }

      final correctedText = response.choices.first.text.trim();
      if (verboseLogging) {
        _logger.info(
          'Grammar fix complete. Original: ${text.length} chars, Corrected: ${correctedText.length} chars',
        );
      }

      if (correctedText == text.trim()) {
        if (verboseLogging) {
          _logger.info('Correction identical to original.');
        }
        return text;
      }

      return correctedText;
    } on OpenAIClientException catch (e) {
      _logger.error(
        'OpenAI API Error during grammar fix: ${e.message} (Code: ${e.code})',
      );
      throw Exception('Failed to fix grammar using OpenAI: ${e.message}');
    } catch (e) {
      _logger.error('Unexpected error during grammar fix: $e');
      rethrow;
    }
  }

  /// Create a chat completion using the Chat API
  Future<String> createChatCompletion(
    List<OpenAiChatMessage> messages, {
    String model = 'gpt-4o',
    double? temperature,
    int? maxTokens,
  }) async {
    if (!isConfigured) {
      throw Exception('MinimalOpenAiService not configured with API token.');
    }
    if (messages.isEmpty) {
      throw ArgumentError('Cannot create chat completion with empty messages.');
    }

    if (verboseLogging) {
      _logger.info(
        'Creating chat completion with ${messages.length} messages using model: $model',
      );
    }

    // Convert local OpenAiChatMessage to openai_dart ChatCompletionMessage
    final openAiDartMessages =
        messages.map((m) {
          // Map string role -> ChatMessageRole
          ChatMessageRole openAiRole;
          switch (m.role) {
            case 'system':
              openAiRole = ChatMessageRole.system;
              break;
            case 'assistant':
              openAiRole = ChatMessageRole.assistant;
              break;
            case 'user':
              openAiRole = ChatMessageRole.user;
              break;
            default:
              // For other roles, throw or fallback
              throw ArgumentError('Unsupported role: ${m.role}');
          }

          // In openai_dart, the 'content' is directly a string
          // Use ChatCompletionMessage from openai_dart
          return ChatCompletionMessage(
            role: openAiRole,
            content: m.content, // Content is directly a string
          );
        }).toList();

    final request = CreateChatCompletionRequest(
      model: ChatCompletionModel.modelId(model),
      messages: openAiDartMessages,
      temperature: temperature,
      maxTokens: maxTokens,
    );

    try {
      final CreateChatCompletionResponse response = await _openAIClient
          .createChatCompletion(request: request);

      // Correctly extract the content string.
      // The content is directly on the message object.
      final returnedMsg = response.choices.firstOrNull?.message.content ?? '';

      if (returnedMsg.isEmpty) {
        _logger.info('OpenAI returned no content in chat completion.');
        return '';
      }

      if (verboseLogging) {
        _logger.info(
          'Chat completion successful. Response length: ${returnedMsg.length}',
        );
      }

      return returnedMsg;
    } on OpenAIClientException catch (e) {
      _logger.error(
        'OpenAI API Error during chat completion: ${e.message} (Code: ${e.code})',
      );
      throw Exception(
        'Failed to get chat completion from OpenAI: ${e.message}',
      );
    } catch (e) {
      _logger.error('Unexpected error during chat completion: $e');
      rethrow;
    }
  }

  void dispose() {
    if (verboseLogging) {
      _logger.info('Service disposed.');
    }
  }
}
