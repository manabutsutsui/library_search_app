import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  AccountPageState createState() => AccountPageState();
}

class AccountPageState extends State<AccountPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _username;
  String? _email;
  String? _profileImageUrl;
  final TextEditingController _usernameController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        _username = userDoc['username'];
        _email = user.email;
        _profileImageUrl = userDoc['profileImage'];
        _usernameController.text = _username ?? '';
      });
    }
  }

  Future<void> _updateUsername() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'username': _usernameController.text,
      });
      setState(() {
        _username = _usernameController.text;
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ユーザー名を更新しました')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('アカウント', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null,
                child: _profileImageUrl == null ? const Icon(Icons.person, size: 50) : null,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ユーザー名', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 32),
                _isEditing
                    ? Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _usernameController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: '新しいユーザー名を入力',
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.check),
                              onPressed: _updateUsername,
                            ),
                          ],
                        ),
                      )
                    : Row(
                        children: [
                          Text(_username ?? '未設定', style: const TextStyle(fontSize: 18)),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              setState(() {
                                _isEditing = true;
                              });
                            },
                          ),
                        ],
                      ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('メールアドレス', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(_email ?? '未設定', style: const TextStyle(fontSize: 18)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
