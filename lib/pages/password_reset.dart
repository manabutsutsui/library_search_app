import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PasswordResetPage extends StatefulWidget {
  const PasswordResetPage({Key? key}) : super(key: key);

  @override
  _PasswordResetPageState createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage> {
  final TextEditingController _emailController = TextEditingController();

  Future<void> _resetPassword() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('パスワードリセットメールを送信しました')),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラー: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('パスワードリセット', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: '登録メールアドレス',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _resetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('パスワードをリセット', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
            const Text(
              '登録されたメールアドレスにメールが届きます',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
