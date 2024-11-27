import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'create_account_mailaddress.dart';
import 'password_reset.dart';
import 'profile.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showVerificationMessage = false;

  Future<void> _login() async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('メールアドレスの認証が完了していません。認証メールのリンクをクリックしてください。')),
        );
        await FirebaseAuth.instance.signOut();
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ログインに成功しました')),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const ProfilePage(),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ログインに失敗しました: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('ログイン',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'メールアドレス',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'パスワード',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('ログイン',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
            if (_showVerificationMessage)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '認証メールを送信しています。メール内に記載されたURLをクリックし、認証を完了してください。\n※ 「迷惑メールボックス」に入っている場合もあります。',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 16),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'アカウント未登録の方は'),
                  TextSpan(
                    text: 'こちら',
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const CreateAccountMailaddressPage()),
                        );
                        if (result == true) {
                          setState(() {
                            _showVerificationMessage = true;
                          });
                        }
                      },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'パスワードを忘れた方は'),
                  TextSpan(
                    text: 'こちら',
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const PasswordResetPage()),
                        );
                      },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}