import 'dart:convert';
import 'package:http/http.dart' as http;

class RemoteDatasource {
  final String baseUrl;
  final http.Client _client;

  RemoteDatasource({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<List<dynamic>> getList(String endpoint) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: _headers,
    );
    _checkResponse(response);
    return jsonDecode(response.body) as List<dynamic>;
  }

  Future<Map<String, dynamic>?> getOne(String endpoint) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: _headers,
    );
    if (response.statusCode == 404) return null;
    _checkResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> body) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: _headers,
      body: jsonEncode(body),
    );
    _checkResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> put(
      String endpoint, Map<String, dynamic> body) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/$endpoint'),
      headers: _headers,
      body: jsonEncode(body),
    );
    _checkResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> delete(String endpoint) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/$endpoint'),
      headers: _headers,
    );
    _checkResponse(response);
  }

  void _checkResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RemoteException(response.statusCode, response.body);
    }
  }
}

class RemoteException implements Exception {
  final int statusCode;
  final String body;
  RemoteException(this.statusCode, this.body);

  @override
  String toString() => 'RemoteException($statusCode): $body';
}
