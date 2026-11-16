import 'dart:convert';
import 'package:http/http.dart' as http;

class CloudAiClient {
  const CloudAiClient();

  Future<String?> askOllama({
    required String endpoint,
    required String model,
    required String prompt,
  }) async {
    try {
      final cleanBase = endpoint.endsWith('/')
          ? endpoint.substring(0, endpoint.length - 1)
          : endpoint;
      final uri = Uri.parse('$cleanBase/api/generate');
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': model,
              'prompt': prompt,
              'stream': false,
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['response'] != null) {
          return data['response'].toString().trim();
        }
      }
    } catch (_) {}
    return null;
  }

  Future<String?> askGemini({
    required String apiKey,
    required String prompt,
  }) async {
    if (apiKey.trim().isEmpty) return null;
    try {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${apiKey.trim()}',
      );
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt}
                  ]
                }
              ],
            }),
          )
          .timeout(const Duration(seconds: 25));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final parts = candidates.first['content']?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            return parts.first['text']?.toString().trim();
          }
        }
      }
    } catch (_) {}
    return null;
  }
}
