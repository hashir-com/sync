import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  /// Generate event description using Gemini
  static Future<String> generateEventDescription({
    required String title,
    required String date,
    required String time,
    required String duration,
    required String location,
    String? existingDescription,
  }) async {
    try {
      print('🚀 Starting AI generation...');
      print('🔑 API Key: ${_apiKey.isEmpty ? "MISSING" : "Found (${_apiKey.substring(0, 10)}...)"}');
      
      if (_apiKey.isEmpty) {
        throw Exception('API key not found!\n\nPlease add GEMINI_API_KEY to your .env file.');
      }

      final prompt = _buildPrompt(
        title: title,
        date: date,
        time: time,
        duration: duration,
        location: location,
        existingDescription: existingDescription,
      );

      // ✅ Use models that are actually available
      final modelNames = [
        'models/gemini-2.5-flash',
        'models/gemini-flash-latest',
        'models/gemini-2.0-flash',
        'models/gemini-2.5-pro',
      ];

      Exception? lastError;

      for (final modelName in modelNames) {
        try {
          // Use v1beta endpoint with full model path
          final baseUrl = 'https://generativelanguage.googleapis.com/v1beta/$modelName:generateContent';
          final url = Uri.parse('$baseUrl?key=$_apiKey');
          print('📡 Trying: $modelName');
          
          final response = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt}
                  ]
                }
              ],
              'generationConfig': {
                'temperature': 0.7,
                'maxOutputTokens': 500,
                'topP': 0.8,
                'topK': 40,
              },
            }),
          );

          print('📥 Response Status: ${response.statusCode}');

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            
            if (data['candidates'] == null || data['candidates'].isEmpty) {
              print('⚠️ No candidates in response');
              continue;
            }

            final candidate = data['candidates'][0];
            
            if (candidate['finishReason'] == 'SAFETY') {
              throw Exception('Content blocked by safety filters.\n\nPlease try different event details.');
            }

            final text = candidate['content']['parts'][0]['text'] as String;
            print('✅ Success with $modelName! Generated ${text.length} characters');
            return text.trim();
          } else if (response.statusCode == 404) {
            print('⚠️ 404 for $modelName, trying next...');
            continue;
          } else if (response.statusCode == 403) {
            print('❌ 403 Error: ${response.body}');
            throw Exception('API Key Error!\n\nYour API key may be invalid or restricted.');
          } else if (response.statusCode == 429) {
            throw Exception('Too many requests!\n\nPlease wait a few minutes and try again.');
          } else {
            print('❌ Error ${response.statusCode}: ${response.body}');
            lastError = Exception('API Error: ${response.statusCode}');
          }
        } catch (e) {
          print('⚠️ Error with $modelName: $e');
          lastError = e as Exception?;
          continue;
        }
      }

      throw lastError ?? Exception('All models failed. Please try again.');
      
    } catch (e) {
      print('❌ AI Service Error: $e');
      rethrow;
    }
  }

  /// Generate event ideas
  static Future<String> generateEventIdeas({
    required String title,
    required String date,
    required String location,
  }) async {
    try {
      print('🚀 Generating ideas...');
      
      if (_apiKey.isEmpty) {
        throw Exception('API key not found!\n\nPlease add GEMINI_API_KEY to your .env file.');
      }

      final prompt = '''
Generate creative ideas and suggestions for this event:

Event: $title
Date: $date
Location: $location

Provide:
1. Engaging activities or programs
2. Potential attractions or highlights
3. Tips to make it memorable
4. Target audience suggestions

Keep it concise and exciting (max 200 words). Do not use markdown formatting.
''';

      final modelNames = [
        'models/gemini-2.5-flash',
        'models/gemini-flash-latest',
        'models/gemini-2.0-flash',
      ];

      for (final modelName in modelNames) {
        try {
          final baseUrl = 'https://generativelanguage.googleapis.com/v1beta/$modelName:generateContent';
          final url = Uri.parse('$baseUrl?key=$_apiKey');
          print('📡 Trying: $modelName');
          
          final response = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt}
                  ]
                }
              ],
              'generationConfig': {
                'temperature': 0.8,
                'maxOutputTokens': 400,
              }
            }),
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            
            if (data['candidates'] == null || data['candidates'].isEmpty) {
              continue;
            }

            final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
            print('✅ Success! Generated ${text.length} characters');
            return text.trim();
          } else if (response.statusCode == 404) {
            continue;
          } else if (response.statusCode == 429) {
            throw Exception('Too many requests!\n\nPlease wait a few minutes.');
          }
        } catch (e) {
          print('⚠️ Error with $modelName: $e');
          continue;
        }
      }

      throw Exception('Failed to generate ideas. Please try again.');
    } catch (e) {
      print('❌ AI Service Error: $e');
      rethrow;
    }
  }

  static String _buildPrompt({
    required String title,
    required String date,
    required String time,
    required String duration,
    required String location,
    String? existingDescription,
  }) {
    if (existingDescription != null && existingDescription.isNotEmpty) {
      return '''
Improve and enhance this event description:

Event: $title
Date: $date
Time: $time
Duration: $duration
Location: $location

Current Description:
$existingDescription

Please:
1. Make it more engaging and compelling
2. Add excitement and energy
3. Highlight key benefits of attending
4. Keep it concise (max 150 words)

Write in a friendly, inviting tone. Do not use markdown formatting or special characters.
''';
    } else {
      return '''
Create an engaging event description for:

Event: $title
Date: $date
Time: $time
Duration: $duration
Location: $location

Please write a compelling description that:
1. Captures attention immediately
2. Explains what attendees can expect
3. Creates excitement and anticipation
4. Is concise (max 150 words)

Write in a friendly, inviting tone. Do not use markdown formatting or special characters.
''';
    }
  }
}