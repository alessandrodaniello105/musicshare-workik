import 'dart:convert';
import 'package:http/http.dart' as http;

class YoutubeService {
  final String apiKey;

  YoutubeService(this.apiKey);

  /// Searches YouTube for the query and returns the URL of the first video found.
  /// Returns null if none found or error occurs.
  Future<String?> searchFirstVideo(String query) async {
    final url = Uri.https('www.googleapis.com', '/youtube/v3/search', {
      'part': 'snippet',
      'q': query,
      'type': 'video',
      'maxResults': '1',
      'key': apiKey,
    });

    try {
      final response = await http.get(url);
      if (response.statusCode != 200) {
        return null;
      }
      final jsonBody = json.decode(response.body) as Map<String, dynamic>;
      final items = jsonBody['items'] as List<dynamic>?;

      if (items == null || items.isEmpty) {
        return null;
      }

      final videoId = items[0]['id']?['videoId'];
      if (videoId == null) {
        return null;
      }

      return 'https://www.youtube.com/watch?v=$videoId';
    } catch (e) {
      return null;
    }
  }
}
