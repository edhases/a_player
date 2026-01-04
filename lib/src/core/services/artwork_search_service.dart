import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ArtworkSearchService {
  Future<String?> searchArtwork(String artist, String title) async {
    try {
      final query = '$artist $title';
      final url = Uri.parse(
          'https://itunes.apple.com/search?term=$query&limit=1&media=music');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final results = json['results'] as List;
        if (results.isNotEmpty) {
          final artworkUrl = results[0]['artworkUrl100'] as String?;
          if (artworkUrl != null) {
            return artworkUrl.replaceAll('100x100', '500x500');
          }
        }
      }
    } catch (e) {
      debugPrint('Error searching for artwork: $e');
    }
    return null;
  }
}
