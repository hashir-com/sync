// ai_services.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AIService {
  // ✅ Description Generation
  static Future<String> generateEventDescription({
    required String title,
    required String date,
    required String time,
    required String duration,
    required String location,
    String? existingDescription,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User must be signed in to use AI features');
      }

      final callable = FirebaseFunctions.instance
          .httpsCallable('generateEventDescription');

      final prompt = '''
You are an expert event copywriter. Output ONLY the event description (250-350 words). NO intros like "Of course" or "Here is". NO markdown like #, **, or *. Use plain text only.

Write a warm, exciting, readable description with:
- Short paragraphs
- Friendly tone
- Emojis where natural (max 4-5)
- Storytelling style
- Strong Call-to-Action at end

Details:
Title: $title
Date: $date
Time: $time
Duration: $duration
Location: $location
${existingDescription != null ? 'Improve existing (no repeat): $existingDescription' : ''}

Start directly with the description.
''';

final result = await callable.call({
  'prompt': prompt,
});


      return result.data['text'] as String;
      
    } on FirebaseFunctionsException catch (e) {
      print('FirebaseFunctionsException: ${e.code} - ${e.message}');
      
      switch (e.code) {
        case 'unauthenticated':
          throw Exception('Please sign in to use AI features');
        case 'invalid-argument':
          throw Exception('Missing required information');
        case 'failed-precondition':
          throw Exception('AI service not configured');
        default:
          throw Exception('AI service error: ${e.message ?? e.code}');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Failed to generate description');
    }
  }

  // 💡 Ideas Generation
  static Future<String> generateEventIdeas({
    required String title,
    required String date,
    required String location,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User must be signed in to use AI features');
      }

      final callable = FirebaseFunctions.instance
          .httpsCallable('generateEventIdeas');

      final result = await callable.call({
        'title': title,
        'date': date,
        'location': location,
      });

      return result.data['text'] as String;
      
    } on FirebaseFunctionsException catch (e) {
      switch (e.code) {
        case 'unauthenticated':
          throw Exception('Please sign in to use AI features');
        case 'invalid-argument':
          throw Exception('Missing required information');
        case 'failed-precondition':
          throw Exception('AI service not configured');
        default:
          throw Exception('AI service error: ${e.message ?? e.code}');
      }
    } catch (e) {
      throw Exception('Failed to generate ideas');
    }
  }
}