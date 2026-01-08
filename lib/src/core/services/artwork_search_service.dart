import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ArtworkSearchService {
  final String _baseUrl =
      'https://itunes.apple.com/search?term={TERM}&entity=song&limit=1';

  Future<String?> searchArtwork(String title, String artist) async {
    final query = _cleanQuery('$title $artist');
    final url = _baseUrl.replaceAll('{TERM}', Uri.encodeComponent(query));

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['resultCount'] > 0) {
          // Get a higher resolution image
          return data['results'][0]['artworkUrl100']
              .toString()
              .replaceAll('100x100', '600x600');
        }
      }
    } catch (e) {
      // Handle exceptions, e.g., network errors
      debugPrint('Error searching for artwork: $e');
    }
    return null;
  }

  String _cleanQuery(String query) {
    // Remove content in brackets (e.g., [Official Video])
    query = query.replaceAll(RegExp(r'\[.*?\]'), '');
    // Remove content in parentheses (e.g., (Remastered))
    query = query.replaceAll(RegExp(r'\(.*?\)'), '');
    // Remove common keywords that don't help the search
    query = query.replaceAll(
        RegExp(
            r'official|video|audio|lyric|visualizer|remastered|hd|hq|explicit',
            caseSensitive: false),
        '');
    // Remove extra whitespace
    query = query.trim().replaceAll(RegExp(r'\s+'), ' ');
    return query;
  }
}
