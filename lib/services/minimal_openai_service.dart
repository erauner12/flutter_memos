import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// --- Simple Data Classes ---
class MinimalCompletionRequest {
  final String model;
  final String prompt;
  final int? maxTokens;
  final double? temperature;
  final List<String>? stop;

  MinimalCompletionRequest({
    required this.model,
    required this.prompt,
    this.maxTokens,
    this.temperature,
    this.stop,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'model': model,
      'prompt': prompt,
    };
    if (maxTokens != null) data['max_tokens'] = maxTokens;
    if (temperature != null) data['temperature'] = temperature;
    if (stop != null && stop!.isNotEmpty) data['stop'] = stop;
    return data;
  }
}

class MinimalCompletionChoice {
  final String text;
  final int? index;
  final String? finishReason;

  MinimalCompletionChoice({
    required this.text,
    this.index,
    this.finishReason,
  });

  factory MinimalCompletionChoice.fromJson(Map<String, dynamic> json) {
    return MinimalCompletionChoice(
      text: json['text'] ?? '',
      index: json['index'],
      finishReason: json['finish_reason'],
    );
  }
}

class MinimalCompletionResponse {
  final List<MinimalCompletionChoice> choices;
  final String? id;
  final String? object;

  MinimalCompletionResponse({
    required this.choices,
    this.id,
    this.object,
  });

  factory MinimalCompletionResponse.fromJson(Map<String, dynamic> json) {
    var choicesList = json['choices'] as List?;
    List<MinimalCompletionChoice> choices = choicesList != null
        ? choicesList.map((i) => MinimalCompletionChoice.fromJson(i)).toList()
        : [];
    return MinimalCompletionResponse(
      choices: choices,
      id: json['id'],
      object: json['object'],
    );
  }
}
// --- End Data Classes ---

class MinimalOpenAiService {
  static final MinimalOpenAiService _instance = MinimalOpenAiService._internal();
  factory MinimalOpenAiService() => _instance;

  String _authToken = '';
  bool _isConfigured = false;
  final http.Client _client;

  // Configuration flags
  static bool verboseLogging = true;

  MinimalOpenAiService._internal() : _client = http.Client();

  bool get isConfigured => _isConfigured;

  void configureService({required String authToken}) {
    if (_authToken == authToken && _isConfigured) {
       if (verboseLogging && kDebugMode) {
         print('[MinimalOpenAiService] Configuration unchanged.');
       }
       return;
    }
    _authToken = authToken;
    _isConfigured = _authToken.isNotEmpty;
    if (verboseLogging && kDebugMode) {
       print('[MinimalOpenAiService] Service configured: ${isConfigured ? "YES" : "NO"}');
    }
  }

  // Health Check
  Future<bool> checkHealth() async {
    if (!isConfigured) return false;
    try {
      // Use a very minimal completion as health check
      await createCompletion(
        request: MinimalCompletionRequest(
          model: 'gpt-3.5-turbo-instruct',
          prompt: 'test',
          maxTokens: 1,
        ),
      );
      if (verboseLogging && kDebugMode) {
        print('[MinimalOpenAiService] Health check successful.');
      }
      return true;
    } catch (e) {
       if (verboseLogging && kDebugMode) {
         print('[MinimalOpenAiService] Health check failed: $e');
       }
       return false;
    }
  }

  // --- Core Completions Method ---
  Future<MinimalCompletionResponse> createCompletion({
    required MinimalCompletionRequest request,
  }) async {
    if (!isConfigured) {
      throw Exception('MinimalOpenAiService not configured with API token.');
    }

    final url = Uri.parse('https://api.openai.com/v1/completions');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_authToken',
    };
    final body = jsonEncode(request.toJson());

    if (verboseLogging && kDebugMode) {
      print('[MinimalOpenAiService] Sending request to ${url.path}');
      // Avoid logging the full body in production
    }

    try {
      final response = await _client.post(
        url,
        headers: headers,
        body: body,
      );

      if (verboseLogging && kDebugMode) {
         print('[MinimalOpenAiService] Received response: ${response.statusCode}');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonResponse = jsonDecode(response.body);
        return MinimalCompletionResponse.fromJson(jsonResponse);
      } else {
        // Parse error from OpenAI response
        String errorMessage = 'HTTP ${response.statusCode}';
        try {
          final errorJson = jsonDecode(response.body);
          if (errorJson['error'] != null && errorJson['error']['message'] != null) {
            errorMessage += ': ${errorJson['error']['message']}';
          } else {
             errorMessage += ': ${response.body}';
          }
        } catch (_) {
          errorMessage += ': ${response.body}';
        }
        if (kDebugMode) {
         print('[MinimalOpenAiService] API Error: $errorMessage');
        }
        throw Exception('OpenAI API Error: $errorMessage');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[MinimalOpenAiService] Network or JSON Error: $e');
      }
      rethrow;
    }
  }

  // Grammar correction helper method
  Future<String> fixGrammar(String text) async {
    if (!isConfigured) {
      throw Exception('MinimalOpenAiService not configured with API token.');
    }
    
    if (kDebugMode) {
      print(
        '[MinimalOpenAiService] Fixing grammar for text (${text.length} chars)',
      );
    }
    
    final request = MinimalCompletionRequest(
      model: 'gpt-3.5-turbo-instruct',
      prompt: 'Correct the grammar and spelling of the following text:\n\n$text\n\nCorrected text:',
      maxTokens: (text.length * 1.5).ceil().clamp(60, 1000),
      temperature: 0.3,
    );
    
    final response = await createCompletion(request: request);
    
    if (response.choices.isEmpty) {
      throw Exception('OpenAI returned no correction.');
    }
    
    final correctedText = response.choices[0].text.trim();

    if (kDebugMode) {
      print(
        '[MinimalOpenAiService] Grammar fix complete. Original: ${text.length} chars, Corrected: ${correctedText.length} chars',
      );
    }

    return correctedText;
  }

  void dispose() {
    _client.close();
  }
}
