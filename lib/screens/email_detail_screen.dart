import 'package:flutter/material.dart';
import '../services/gmail_service.dart';

class EmailDetailScreen extends StatelessWidget {
  final Map email;
  final Function(bool) onToggleSpam;
  final String token;
  final GmailService gmailService;

  const EmailDetailScreen({
    Key? key,
    required this.email,
    required this.onToggleSpam,
    required this.token,
    required this.gmailService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isSpam = email['isSpam'] == true;

    return Scaffold(
      appBar: AppBar(title: const Text("Chi tiết email")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("From: ${email['from']}"),
            const SizedBox(height: 8),
            Text("Subject: ${email['subject']}"),
            const SizedBox(height: 8),
            Text("Date: ${email['date']}"),
            const Divider(),
            Text(email['snippet']),

            const Spacer(),

            // NÚT SPAM
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSpam ? Colors.green : Colors.red,
                ),
                onPressed: () {
                  onToggleSpam(!isSpam);
                  Navigator.pop(context);
                },
                child: Text(
                  isSpam
                      ? "Loại khỏi danh sách Spam"
                      : "Đánh dấu là email spam",
                ),
              ),
            ),

            const SizedBox(height: 10),

            // NÚT XÓA EMAIL
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                ),
                onPressed: () async {
                  try {
                    await gmailService.moveToTrash(email['id'], token);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Đã chuyển vào thùng rác")),
                    );

                    Navigator.pop(context, "deleted"); // gửi tín hiệu về
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
                  }
                },
                child: const Text("Xóa email"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
