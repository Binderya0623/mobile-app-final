import 'dart:convert';
import 'package:http/http.dart' as http;

class HttpService {
  final String baseUrl;

  HttpService({required this.baseUrl});

  Future<dynamic> getData(String endpoint, String? token) async {
    try {
      print('Making GET request to: $baseUrl/$endpoint');
      final response = await http.get(
        Uri.parse('$baseUrl/$endpoint'),
        headers: token != null ? {'Authorization': 'Bearer $token', } : null,
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getData: $e');
      throw Exception('Failed to connect to the server: $e');
    }
  }

  Future<dynamic> postData(String endpoint, String? token, dynamic data) async {
    try {
      final url = '$baseUrl/$endpoint';
      print('Making POST request to: $url');
      print('Request data: $data');
      
      final response = await http.post(
        Uri.parse(url),
        body: json.encode(data),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to post data: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in postData: $e');
      throw Exception('Failed to connect to the server: $e');
    }
  }

  Future<dynamic> putData(String endpoint, String? token, dynamic data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$endpoint'),
        body: json.encode(data),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to put data');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server');
    }
  }

  Future<dynamic> deleteData(String endpoint, String? token, dynamic data) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$endpoint'),
        headers: token != null ? {'Authorization': 'Bearer $token'} : null,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to delete data');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server');
    }
  }
}