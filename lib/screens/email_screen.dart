import 'package:flutter/material.dart';
import '../services/gmail_service.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import '../screens/email_detail_screen.dart';
import '../utils/spam_detector.dart';
import '../screens/trash_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class EmailScreen extends StatefulWidget {
  final String token;

  const EmailScreen({super.key, required this.token});

  @override
  State<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  final GmailService _gmail = GmailService();
  List emails = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    initUser();
  }

  // Khôi phục user + load email
  void initUser() async {
    await AuthService().trySilentLogin();
    await loadEmails();

    if (!mounted) return;
    setState(() {});
  }

  // =========================
  // LOAD EMAIL
  // =========================
  Future<void> loadEmails() async {
    final data = await _gmail.fetchEmails(widget.token);

    // gọi song song tất cả request
    final futures = data.map((e) {
      return _gmail.getEmailDetail(e['id'], widget.token).then((detail) {
        return {
          'id': e['id'],
          'snippet': detail['snippet'] ?? "",
          'subject': detail['subject'],
          'from': detail['from'],
          'date': detail['date'],
          'isSpam': SpamDetector.isSpam(detail['snippet'] ?? ""),
        };
      });
    }).toList();

    final fullEmails = await Future.wait(futures);

    if (!mounted) return;

    setState(() {
      emails = fullEmails;
      isLoading = false;
    });
  }

  Future<void> openGoogleAccount() async {
    final Uri url = Uri.parse("https://myaccount.google.com/");

    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication, // mở bằng Chrome / Google app
    )) {
      throw 'Không thể mở trang quản lý tài khoản';
    }
  }

  void showAccountMenu() {
    final user = AuthService().currentUser;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar lớn
              CircleAvatar(
                radius: 35,
                backgroundImage: user?.photoUrl != null
                    ? NetworkImage(user!.photoUrl!)
                    : null,
                child: user?.photoUrl == null
                    ? Text(
                        (user?.displayName ?? "U")[0],
                        style: const TextStyle(fontSize: 24),
                      )
                    : null,
              ),

              const SizedBox(height: 10),

              // Tên + Email
              Text(
                user?.displayName ?? "No Name",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(user?.email ?? ""),

              const SizedBox(height: 20),

              // Manage account (giống Google)
              ListTile(
                leading: const Icon(Icons.manage_accounts),
                title: const Text("Quản lý tài khoản"),
                onTap: () {
                  Navigator.pop(context);
                  openGoogleAccount();
                },
              ),

              // Switch account
              ListTile(
                leading: const Icon(Icons.switch_account),
                title: const Text("Chuyển tài khoản"),
                onTap: () async {
                  Navigator.pop(context);
                  await AuthService().signOut();

                  if (!mounted) return;

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),

              // Logout
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text("Đăng xuất"),
                onTap: () async {
                  Navigator.pop(context);
                  await AuthService().signOut();

                  if (!mounted) return;

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================
  // BUILD EMAIL LIST
  // =========================
  Widget buildEmailList(List list) {
    if (list.isEmpty) {
      return const Center(child: Text("Không có email"));
    }

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        var email = list[index];

        return ListTile(
          title: Text(email['subject'] ?? "(No subject)"),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(email['from']),
              Text(email['date'], style: const TextStyle(fontSize: 12)),
            ],
          ),
          isThreeLine: true,

          trailing: Icon(
            email['isSpam'] ? Icons.warning : Icons.check,
            color: email['isSpam'] ? Colors.red : Colors.green,
          ),

          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EmailDetailScreen(
                  email: email,
                  onToggleSpam: (newValue) {
                    setState(() {
                      email['isSpam'] = newValue;
                    });
                  },
                  token: widget.token,
                  gmailService: _gmail,
                ),
              ),
            );

            if (result == "deleted") {
              setState(() {
                emails.remove(email);
              });
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    List normalEmails = emails.where((e) => e['isSpam'] == false).toList();

    List spamEmails = emails.where((e) => e['isSpam'] == true).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("SafeInbox"),
          actions: [
            // Avatar + tên người dùng
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () => showAccountMenu(),
                child: CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  backgroundImage: user?.photoUrl != null
                      ? NetworkImage(user!.photoUrl!)
                      : null,
                  child: user?.photoUrl == null
                      ? Text(
                          (user?.displayName ?? "U")[0],
                          style: const TextStyle(color: Colors.black),
                        )
                      : null,
                ),
              ),
            ),
          ],

          bottom: const TabBar(
            tabs: [
              Tab(text: "Inbox"),
              Tab(text: "Spam"),
            ],
          ),
        ),

        drawer: buildDrawer(),

        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  buildEmailList(normalEmails),
                  buildEmailList(spamEmails),
                ],
              ),
      ),
    );
  }

  // =========================
  // DRAWER
  // =========================
  Widget buildDrawer() {
    final user = AuthService().currentUser;

    return Drawer(
      child: Column(
        children: [
          // HEADER
          UserAccountsDrawerHeader(
            accountName: Text(
              user?.displayName ?? "No Name",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(user?.email ?? "No Email"),

            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage:
                  (user?.photoUrl != null && user!.photoUrl!.isNotEmpty)
                  ? NetworkImage(user.photoUrl!)
                  : null,
              child: (user?.photoUrl == null || user!.photoUrl!.isEmpty)
                  ? Text(
                      (user?.displayName ?? "U")[0],
                      style: const TextStyle(fontSize: 20),
                    )
                  : null,
            ),
          ),

          // CHUYỂN TÀI KHOẢN
          ListTile(
            leading: const Icon(Icons.switch_account),
            title: const Text("Chuyển tài khoản"),
            subtitle: const Text("Đăng nhập bằng Gmail khác"),
            onTap: () async {
              await AuthService().signOut();

              if (!mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),

          // THÙNG RÁC
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text("Thùng rác"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TrashScreen(token: widget.token),
                ),
              );
            },
          ),

          const Spacer(),

          const ListTile(
            leading: Icon(Icons.info),
            title: Text("Phiên bản 1.0.0"),
          ),

          // LOGOUT
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Đăng xuất"),
            onTap: () async {
              await AuthService().signOut();

              if (!mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
