import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:budgetlisting/models/location_model.dart';

class LocationService {
  final String baseUrl = 'https://budget-listing.onrender.com/api';

  Future<List<Location>> getAllLocations(String token) async {
    final url = Uri.parse('$baseUrl/locations');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List locationsJson = data['locations'];
      return locationsJson.map((json) => Location.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load locations');
    }
  }

  Future<Map<String, dynamic>> updateLocation({
    required String token,
    required int id,
    required String name,
    required double latitude,
    required double longitude,
  }) async {
    final url = Uri.parse('$baseUrl/locations/$id');
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    final responseBody = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': responseBody['message'],
      };
    } else {
      return {
        'success': false,
        'message': responseBody['error'] ?? 'Terjadi kesalahan saat memperbarui lokasi',
      };
    }
  }

  Future<List<Location>> searchLocations({
    required String token,
    required String query
  }) async {
    final encodedQuery = Uri.encodeComponent(query); // Encode query untuk URL
    final response = await http.get(
      Uri.parse('$baseUrl/api/locations/search?q=$encodedQuery'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['locations'] as List)
          .map((json) => Location.fromJson(json))
          .toList();
    } else {
      throw Exception('Gagal mencari lokasi: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> deleteLocation({
    required String token,
    required int id,
  }) async {
    final url = Uri.parse('$baseUrl/locations/$id');
    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final responseBody = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': responseBody['message'],
      };
    } else {
      return {
        'success': false,
        'message': responseBody['error'] ?? 'Terjadi kesalahan saat menghapus lokasi',
      };
    }
  }
}