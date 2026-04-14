import 'dart:convert';
import 'package:http/http.dart' as http;

class GmailService {
  Future<List> fetchEmails(String token) async {
    final response = await http.get(
      Uri.parse(
        'https://gmail.googleapis.com/gmail/v1/users/me/messages?maxResults=10',
      ),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = json.decode(response.body);
    return data['messages'] ?? [];
  }

  Future<Map> getEmailDetail(String id, String token) async {
    final res = await http.get(
      Uri.parse('https://gmail.googleapis.com/gmail/v1/users/me/messages/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return json.decode(res.body);
  }
}
