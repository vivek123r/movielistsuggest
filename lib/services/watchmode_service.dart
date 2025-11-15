import 'package:http/http.dart' as http;
import 'dart:convert';

class WatchmodeService {
  static const String apiKey = '3GYO1RVtvWUKa7wgS6QTalLb1y4T6IaoB8Mb3WGH';
  static const String baseUrl = 'https://api.watchmode.com/v1';

  // Get streaming sources for a title
  Future<Map<String, dynamic>> getStreamingSources(String tmdbId, String type) async {
    try {
      // First, search for the title to get Watchmode ID
      final searchUrl = Uri.parse('$baseUrl/search/?apiKey=$apiKey&search_field=id&search_value=$tmdbId&types=$type');
      final searchResponse = await http.get(searchUrl);

      if (searchResponse.statusCode == 200) {
        final searchData = json.decode(searchResponse.body);
        
        if (searchData['title_results'] != null && searchData['title_results'].isNotEmpty) {
          final watchmodeId = searchData['title_results'][0]['id'];
          
          // Get sources for this title
          final sourcesUrl = Uri.parse('$baseUrl/title/$watchmodeId/sources/?apiKey=$apiKey');
          final sourcesResponse = await http.get(sourcesUrl);
          
          if (sourcesResponse.statusCode == 200) {
            return json.decode(sourcesResponse.body);
          }
        }
      }
    } catch (e) {
      print('Error fetching streaming sources: $e');
    }
    return {};
  }

  // Get all available streaming services
  Future<List<Map<String, dynamic>>> getStreamingServices() async {
    try {
      final url = Uri.parse('$baseUrl/sources/?apiKey=$apiKey');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('Error fetching streaming services: $e');
    }
    return [];
  }

  // Search for titles on Watchmode
  Future<List<Map<String, dynamic>>> searchTitles(String query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse('$baseUrl/autocomplete-search/?apiKey=$apiKey&search_value=$encodedQuery');
      print('🔍 Searching Watchmode for: $query');
      print('📡 URL: $url');
      
      final response = await http.get(url);
      print('📥 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📄 Response data: $data');
        
        if (data['results'] != null) {
          final results = (data['results'] as List).cast<Map<String, dynamic>>();
          print('✅ Found ${results.length} results');
          return results;
        }
      } else {
        print('❌ Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error searching titles: $e');
    }
    return [];
  }

  // Get title details
  Future<Map<String, dynamic>> getTitleDetails(int watchmodeId) async {
    try {
      final url = Uri.parse('$baseUrl/title/$watchmodeId/details/?apiKey=$apiKey');
      print('🎬 Fetching details for Watchmode ID: $watchmodeId');
      print('📡 URL: $url');
      
      final response = await http.get(url);
      print('📥 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📄 Title details received');
        print('🔗 Sources count: ${data['sources']?.length ?? 0}');
        
        return data;
      } else {
        print('❌ Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error fetching title details: $e');
    }
    return {};
  }
}
