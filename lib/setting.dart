import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'account_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_review/in_app_review.dart';
import 'login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_account.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  SettingPageState createState() => SettingPageState();
}

class SettingPageState extends State<SettingPage> {
  final InAppReview inAppReview = InAppReview.instance;

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const CreateAccountPage()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ログアウトに失敗しました: $e')),
      );
    }
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('アカウント削除の確認'),
          content: const Text('本当にアカウントを削除しますか？この操作は取り消せません。'),
          actions: <Widget>[
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('削除', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAccount(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final passwordController = TextEditingController();
    final isPasswordCorrect = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('パスワードの確認'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'パスワードを入力してください'),
        ),
        actions: [
          TextButton(
            child: const Text('キャンセル'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('確認'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (isPasswordCorrect != true) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // ユーザーの再認証
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: passwordController.text,
        );
        await user.reauthenticateWithCredential(credential);

        // ユーザーのレビューを削除
        await FirebaseFirestore.instance
            .collection('reviews')
            .where('userId', isEqualTo: user.uid)
            .get()
            .then((snapshot) {
          for (DocumentSnapshot doc in snapshot.docs) {
            doc.reference.delete();
          }
        });

        // ユーザーのブックマークを削除
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('bookmarks')
            .get()
            .then((snapshot) {
          for (DocumentSnapshot doc in snapshot.docs) {
            doc.reference.delete();
          }
        });

        // ユーザードキュメントを削除
        await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();

        // Firebaseユーザーを削除
        await user.delete();

        // ログイン画面に遷移
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      print('アカウント削除中にエラーが発生しました: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('設定', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('個人情報', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildListItem(
                icon: Icons.person,
                title: 'アカウント',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AccountPage()));
                },
              ),
            ),
            const SizedBox(height: 32),
            const Text('アプリについて', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildListItem(
                    icon: Icons.mail,
                    title: 'お問い合わせ',
                    onTap: () async {
                      final Uri url = Uri.parse('https://tsutsunoidoblog.com/contact/');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      } else {
                        print('Could not launch $url');
                      }
                    },
                  ),
                  _buildDivider(),
                  _buildListItem(
                    icon: Icons.description,
                    title: '利用規約',
                    onTap: () async {
                      final Uri url = Uri.parse('https://tsutsunoidoblog.com/movie_and_anime_holy_land_sns_terms_of_use/');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      } else {
                        print('Could not launch $url');
                      }
                    },
                  ),
                  _buildDivider(),
                  _buildListItem(
                    icon: Icons.shield_outlined,
                    title: 'プライバシーポリシー',
                    onTap: () async {
                      final Uri url = Uri.parse('https://tsutsunoidoblog.com/movie_and_anime_holy_land_sns_privacy_policy/');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      } else {
                        print('Could not launch $url');
                      }
                    },
                  ),
                  _buildDivider(),
                  _buildListItem(
                    icon: Icons.star,
                    title: 'レビューを書く',
                    onTap: () async {
                      if (await inAppReview.isAvailable()) {
                        inAppReview.requestReview();
                      } else {
                        inAppReview.openStoreListing(
                          appStoreId: 'あなたのApp Store ID',
                          microsoftStoreId: 'あなたのMicrosoft Store ID',
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildListItem(
                    icon: Icons.logout,
                    title: 'ログアウト',
                    onTap: () => _logout(context),
                    isBold: true,
                  ),
                  _buildDivider(),
                  _buildListItem(
                    icon: Icons.delete_outline,
                    title: 'アカウント削除',
                    onTap: () => _showDeleteAccountDialog(context),
                    isRed: true,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isBold = false,
    bool isRed = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: isRed ? Colors.red : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: isRed ? Colors.red : Colors.black87,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 1, color: Colors.grey[200]);
  }
}