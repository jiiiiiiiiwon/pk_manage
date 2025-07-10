import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:capstone_design/api.dart';

class PlaceSearchService {
  // Google Places API 키 (실제 키로 교체 필요)
  static const String apiKey = myapikey;
  
  // 장소 검색 메서드
  static Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    if (query.isEmpty) return [];
    
    try {
      // 플레이스 검색 API 호출
      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/place/textsearch/json',
        {
          'query': query,
          'language': 'ko',
          'region': 'kr',
          'key': apiKey,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          return List<Map<String, dynamic>>.from(data['results']);
        } else {
          print('Places API 오류: ${data['status']}');
          return [];
        }
      } else {
        print('HTTP 오류: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('검색 오류: $e');
      return [];
    }
  }
}