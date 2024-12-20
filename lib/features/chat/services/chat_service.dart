import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:fyp_scaneat_cc/services/ticket_service.dart';

class ChatService {
  static const String apiKey = 'AIzaSyAr-Y2j4EDzhAs0qFrto47owTtuRQTwKGE';
  late final GenerativeModel _model;
  final TicketService _ticketService = TicketService();

  ChatService() {
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: apiKey,
    );
  }

  Future<String> getChatResponse(String prompt, {
    String? imagePath,
    String? currentLocation,
    Map<String, dynamic>? userInfo,
  }) async {
    try {
      String enhancedPrompt = '''
You are a helpful restaurant assistant for ScanEat app in Hong Kong. 
Provide a concise and helpful response to the user's question.
Keep the response focused and under 3 sentences if possible.

User's question: $prompt
''';
      
      // Add ticket information if available
      final ticketInfo = _ticketService.getTicketInfoForChat();
      if (ticketInfo != null) {
        String ticketContext = '\nTicket Information:\n';
        ticketInfo.forEach((key, value) {
          ticketContext += '$key: $value\n';
        });
        enhancedPrompt = '$ticketContext\n$enhancedPrompt';
      }
      
      // Add location context if available
      if (currentLocation != null) {
        enhancedPrompt = 'Current Location: $currentLocation\n$enhancedPrompt';
      }

      // Add user info context if available
      if (userInfo != null) {
        String userContext = 'User Information:\n';
        userInfo.forEach((key, value) {
          userContext += '$key: $value\n';
        });
        enhancedPrompt = '$userContext\n$enhancedPrompt';
      }

      // Get main response
      final content = [Content.text(enhancedPrompt)];
      final response = await _model.generateContent(content);
      final mainResponse = response.text ?? 'I apologize, but I could not generate a response.';

      // Generate follow-up questions from user's perspective
      final followUpPrompt = '''
Based on your response about restaurants in Hong Kong, generate 2-3 natural follow-up questions that a user might want to ask next.
The questions should be from the user's perspective (first person) and be conversational.
Make them specific to Hong Kong food culture, restaurants, or dining preferences.

Examples of good follow-up questions:
• "Can you recommend some signature dishes I should try?"
• "What's the best time to visit to avoid crowds?"
• "How much should I expect to spend there?"
• "Is it easy to get there by MTR?"

User's original question: $prompt
Your response: $mainResponse

Format each question with a bullet point (•).
''';

      final followUpContent = [Content.text(followUpPrompt)];
      final followUpResponse = await _model.generateContent(followUpContent);
      final followUpQuestions = followUpResponse.text ?? '';

      // Combine main response with follow-up questions
      return '''
$mainResponse

You might also want to ask:
$followUpQuestions''';
    } catch (e) {
      print('Error getting chat response: $e');
      return '''
**Error Processing Request**

I apologize, but there was an error processing your request. Please try again later.

*Error details:* ${e.toString()}
''';
    }
  }
} 