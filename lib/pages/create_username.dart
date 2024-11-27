import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile.dart';

class CreateUserNamePage extends StatefulWidget {
  const CreateUserNamePage({super.key});

  @override
  CreateUserNamePageState createState() => CreateUserNamePageState();
}

class CreateUserNamePageState extends State<CreateUserNamePage> {
  final _usernameController = TextEditingController();

  Future<void> _saveUsername() async {
    if (_usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ユーザー名を入力してください')),
      );
      return;
    }

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'username': _usernameController.text.trim(),
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
          'profileImage': null,
        });

        await user.updateDisplayName(_usernameController.text.trim());

        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const ProfilePage(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ユーザー名の設定',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Text(
              'ユーザー名を設定してください',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'ユーザー名',
                border: OutlineInputBorder(),
                hintText: 'ユーザー名を入力してください',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveUsername,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                '完了',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }
}
