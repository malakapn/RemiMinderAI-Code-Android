import 'package:http/http.dart' as http;

import '../config/environment.dart';

class UserApiService {
  Future<void> deleteAccount(String accessToken) async {
    final response = await http.delete(
      Uri.parse('${Environment.apiBaseUrl}/api/users/me'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 204) {
      final body = response.body.isNotEmpty
          ? response.body
          : 'HTTP ${response.statusCode}';
      throw Exception('Account deletion failed: $body');
    }
  }
}
