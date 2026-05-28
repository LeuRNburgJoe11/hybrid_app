import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hybrid_app/core/constants.dart';

class ApiService {
  final http.Client _client;

  ApiService(this._client);

  /// Requests the backend to create a new WebRTC session (initiated by chatbot)
  Future<Map<String, dynamic>> createSession(String userId) async {
    final response = await _client.post(
      Uri.parse('${AppConstants.baseUrl}/api/webrtc/session/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create WebRTC session: ${response.body}');
    }
  }

  /// Polls or fetches the current status of an ongoing session
  Future<Map<String, dynamic>> fetchSessionStatus(String roomId) async {
    final response = await _client.get(
      Uri.parse('${AppConstants.baseUrl}/api/webrtc/session/status/$roomId'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch session status');
    }
  }
}