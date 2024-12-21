import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/subscription_state.dart';
import 'subscription_premium.dart';

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
  String? _xAccountUrl;
  String? _instagramAccountUrl;
  String? _tiktokAccountUrl;
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
        _xAccountUrl = userData?['xAccountUrl'];
        _instagramAccountUrl = userData?['instagramAccountUrl'];
        _tiktokAccountUrl = userData?['tiktokAccountUrl'];
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

      setState(() {
        _username = _usernameController.text;
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.usernameUpdated)),
      );
    }
  }

  void _showXAccountDialog() {
    final l10n = AppLocalizations.of(context)!;
    final TextEditingController controller = TextEditingController(
        text: _xAccountUrl?.replaceAll('https://x.com/', ''));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.xAccount),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'https://x.com/@username',
                prefixText: 'https://x.com/',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.enterUsername,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              String username = controller.text.trim();
              if (username.startsWith('@')) {
                username = username.substring(1);
              }
              final url = username.isEmpty ? null : 'https://x.com/$username';

              await _firestore
                  .collection('users')
                  .doc(_auth.currentUser?.uid)
                  .update({'xAccountUrl': url});

              setState(() {
                _xAccountUrl = url;
              });

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text(url == null ? 'Xアカウントを削除しました' : 'Xアカウントを更新しました'),
                  ),
                );
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showInstagramAccountDialog() {
    final l10n = AppLocalizations.of(context)!;
    final TextEditingController controller = TextEditingController(
        text:
            _instagramAccountUrl?.replaceAll('https://www.instagram.com/', ''));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.instagramAccount),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'https://www.instagram.com/username',
                prefixText: 'https://www.instagram.com/',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.enterUsername,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              String username = controller.text.trim();
              if (username.startsWith('@')) {
                username = username.substring(1);
              }
              final url = username.isEmpty
                  ? null
                  : 'https://www.instagram.com/$username';

              await _firestore
                  .collection('users')
                  .doc(_auth.currentUser?.uid)
                  .update({'instagramAccountUrl': url});

              setState(() {
                _instagramAccountUrl = url;
              });

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(url == null
                        ? '${l10n.instagramAccount}${l10n.accountDeleted}'
                        : '${l10n.instagramAccount}${l10n.accountUpdated}'),
                  ),
                );
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showTiktokAccountDialog() {
    final l10n = AppLocalizations.of(context)!;
    final TextEditingController controller = TextEditingController(
        text: _tiktokAccountUrl?.replaceAll('https://www.tiktok.com/@', ''));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.tiktokAccount),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'https://www.tiktok.com/@username',
                prefixText: 'https://www.tiktok.com/@',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              String username = controller.text.trim();
              if (username.startsWith('@')) {
                username = username.substring(1);
              }
              final url =
                  username.isEmpty ? null : 'https://www.tiktok.com/@$username';

              await _firestore
                  .collection('users')
                  .doc(_auth.currentUser?.uid)
                  .update({'tiktokAccountUrl': url});

              setState(() {
                _tiktokAccountUrl = url;
              });

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(url == null
                        ? 'TikTokアカウントを削除しました'
                        : 'TikTokアカウントを更新しました'),
                  ),
                );
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPremium = ref.watch(subscriptionProvider).value ?? false;

    void handleSNSButtonPress(VoidCallback onPremium) {
      if (!isPremium) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SubscriptionPremium()),
        );
        return;
      }
      onPremium();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(l10n.accountSettings,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
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
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.email,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(_email ?? l10n.notSet, style: const TextStyle(fontSize: 18)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.xAccount,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    if (_xAccountUrl != null) ...[
                      GestureDetector(
                        onTap: () async {
                          if (await canLaunch(_xAccountUrl!)) {
                            await launch(_xAccountUrl!);
                          }
                        },
                        child: Text(
                          _xAccountUrl!.replaceAll('https://x.com/', '@'),
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () =>
                            handleSNSButtonPress(_showXAccountDialog),
                      ),
                    ] else
                      TextButton(
                        onPressed: () =>
                            handleSNSButtonPress(_showXAccountDialog),
                        child: Text(l10n.set),
                      ),
                  ],
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.instagramAccount,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    if (_instagramAccountUrl != null) ...[
                      GestureDetector(
                        onTap: () async {
                          if (await canLaunch(_instagramAccountUrl!)) {
                            await launch(_instagramAccountUrl!);
                          }
                        },
                        child: Text(
                          _instagramAccountUrl!
                              .replaceAll('https://www.instagram.com/', '@'),
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () =>
                            handleSNSButtonPress(_showInstagramAccountDialog),
                      ),
                    ] else
                      TextButton(
                        onPressed: () =>
                            handleSNSButtonPress(_showInstagramAccountDialog),
                        child: Text(l10n.set),
                      ),
                  ],
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.tiktokAccount,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    if (_tiktokAccountUrl != null) ...[
                      GestureDetector(
                        onTap: () async {
                          if (await canLaunch(_tiktokAccountUrl!)) {
                            await launch(_tiktokAccountUrl!);
                          }
                        },
                        child: Text(
                          _tiktokAccountUrl!
                              .replaceAll('https://www.tiktok.com/@', '@'),
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () =>
                            handleSNSButtonPress(_showTiktokAccountDialog),
                      ),
                    ] else
                      TextButton(
                        onPressed: () =>
                            handleSNSButtonPress(_showTiktokAccountDialog),
                        child: Text(l10n.set),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
