import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
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
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      setState(() {
        _username = userData?['username'];
        _email = user.email;
        _profileImageUrl = userData?['profileImage'];
        _usernameController.text = _username ?? '';
      });
    }
  }

  Future<void> _updateUsername() async {
    final l10n = AppLocalizations.of(context)!;

    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'username': _usernameController.text,
      });

      final reviewsQuery = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: user.uid)
          .get();

      final batch = _firestore.batch();
      for (var doc in reviewsQuery.docs) {
        batch.update(doc.reference, {
          'userName': _usernameController.text,
        });
      }
      await batch.commit();

      final postsQuery = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: user.uid)
          .get();

      final postsBatch = _firestore.batch();
      for (var doc in postsQuery.docs) {
        postsBatch.update(doc.reference, {
          'userName': _usernameController.text,
        });
      }
      await postsBatch.commit();

      setState(() {
        _username = _usernameController.text;
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.usernameUpdated)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(l10n.accountSettings,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _profileImageUrl != null
                    ? NetworkImage(_profileImageUrl!)
                    : null,
                child: _profileImageUrl == null
                    ? const Icon(Icons.person, size: 50)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.username,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
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
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) =>
                                    FocusScope.of(context).unfocus(),
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
                          Text(_username ?? l10n.notSet,
                              style: const TextStyle(fontSize: 18)),
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
            const SizedBox(height: 24),
            Text(l10n.email,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(_email ?? l10n.notSet, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
