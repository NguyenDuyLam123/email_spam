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
      Uri.parse(
        'https://gmail.googleapis.com/gmail/v1/users/me/messages/$id?format=full',
      ),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = json.decode(res.body);

    var headers = data['payload']['headers'];

    String getHeader(String name) {
      return headers.firstWhere(
        (h) => h['name'] == name,
        orElse: () => {'value': ''},
      )['value'];
    }

    return {
      'id': id,
      'snippet': data['snippet'] ?? "",
      'from': getHeader('From'),
      'subject': getHeader('Subject'),
      'date': getHeader('Date'),
    };
  }

  // Xóa email (chuyển vào thùng rác)
  Future<void> moveToTrash(String id, String token) async {
    final res = await http.post(
      Uri.parse(
        'https://gmail.googleapis.com/gmail/v1/users/me/messages/$id/trash',
      ),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode != 200) {
      throw Exception("Không thể chuyển vào thùng rác: ${res.body}");
    }
  }

  Future<List> fetchTrashEmails(String token) async {
    final response = await http.get(
      Uri.parse(
        'https://gmail.googleapis.com/gmail/v1/users/me/messages?q=in:trash',
      ),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = json.decode(response.body);
    return data['messages'] ?? [];
  }

  Future<void> restoreEmail(String id, String token) async {
    final url = Uri.parse(
      'https://gmail.googleapis.com/gmail/v1/users/me/messages/$id/modify',
    );

    await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "removeLabelIds": ["TRASH"],
      }),
    );
  }
}
