import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'setting.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/subscription_state.dart';
import 'subscription_premium.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rxdart/rxdart.dart';
import 'user_kuchikomi.dart';
import 'bookmarks.dart';
import 'user_posts.dart';
import 'liked_posts.dart';
import '../utils/seichi_de_dekirukoto.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  String? _username;
  String? _profileImageUrl;
  String? _bio;
  late Stream<DocumentSnapshot> _userStream;
  String? _xAccountUrl;
  String? _instagramAccountUrl;
  String? _tiktokAccountUrl;

  @override
  void initState() {
    super.initState();
    _initStreams();
    _loadSocialAccounts();
  }

  void _initStreams() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots();
    }
  }

  Future<void> _loadSocialAccounts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        _xAccountUrl = userData.data()?['xAccountUrl'];
        _instagramAccountUrl = userData.data()?['instagramAccountUrl'];
        _tiktokAccountUrl = userData.data()?['tiktokAccountUrl'];
      });
    }
  }

  void showSocialAccountDialog({
    required String type,
    required String? currentUrl,
    required String baseUrl,
    required String prefixText,
    required Function(String?) onSave,
  }) {
    final l10n = AppLocalizations.of(context)!;
    String? cleanCurrentUrl;

    switch (type) {
      case 'x':
        cleanCurrentUrl = currentUrl?.replaceAll('https://x.com/', '');
        break;
      case 'instagram':
        cleanCurrentUrl =
            currentUrl?.replaceAll('https://www.instagram.com/', '');
        break;
      case 'tiktok':
        cleanCurrentUrl =
            currentUrl?.replaceAll('https://www.tiktok.com/@', '');
        break;
    }

    final controller = TextEditingController(text: cleanCurrentUrl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _getSocialTitle(type, l10n),
          style: const TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: '$baseUrl@username',
                prefixText: prefixText,
              ),
            ),
            if (type == 'x') ...[
              const SizedBox(height: 4),
              Text(
                l10n.enterXAccountUrl,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
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
              final url = username.isEmpty ? null : '$baseUrl$username';

              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .update({'${type}AccountUrl': url});

              onSave(url);

              if (mounted) {
                Navigator.pop(context);
                _showUpdateSnackBar(type, url, l10n);
              }
            },
            child: Text(l10n.save,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _getSocialTitle(String type, AppLocalizations l10n) {
    switch (type) {
      case 'x':
        return l10n.xAccountSetting;
      case 'instagram':
        return l10n.instagramAccountSetting;
      case 'tiktok':
        return l10n.tiktokAccountSetting;
      default:
        return '';
    }
  }

  void _showUpdateSnackBar(String type, String? url, AppLocalizations l10n) {
    String message;
    switch (type) {
      case 'x':
        message = l10n.xAccountUpdated;
        break;
      case 'tiktok':
        message =
            url == null ? l10n.tiktokAccountDeleted : l10n.tiktokAccountUpdated;
        break;
      default:
        return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message,
              style: const TextStyle(fontWeight: FontWeight.bold))),
    );
  }

  void showXAccountDialog() {
    showSocialAccountDialog(
      type: 'x',
      currentUrl: _xAccountUrl,
      baseUrl: 'https://x.com/',
      prefixText: 'https://x.com/',
      onSave: (url) => setState(() => _xAccountUrl = url),
    );
  }

  void showInstagramAccountDialog() {
    showSocialAccountDialog(
      type: 'instagram',
      currentUrl: _instagramAccountUrl,
      baseUrl: 'https://www.instagram.com/',
      prefixText: 'https://www.instagram.com/',
      onSave: (url) => setState(() => _instagramAccountUrl = url),
    );
  }

  void showTiktokAccountDialog() {
    showSocialAccountDialog(
      type: 'tiktok',
      currentUrl: _tiktokAccountUrl,
      baseUrl: 'https://www.tiktok.com/@',
      prefixText: 'https://www.tiktok.com/@',
      onSave: (url) => setState(() => _tiktokAccountUrl = url),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await _uploadImage(image);
    }
  }

  Future<void> _uploadImage(XFile image) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final storageRef = FirebaseStorage.instance.ref();
        final imageRef = storageRef.child('profile_images/${user.uid}.jpg');

        try {
          await imageRef.delete();
        } catch (e) {
          // print('古い画像の削除中にエラーが発生しました（初回または存在しない場合）: $e');
        }

        final uploadTask = imageRef.putFile(File(image.path));
        final snapshot = await uploadTask.whenComplete(() {});
        final downloadUrl = await snapshot.ref.getDownloadURL();

        // ユーザードキュメントの更新
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'profileImage': downloadUrl,
        });

        // レビューコレクションの更新
        final reviewsQuery = await FirebaseFirestore.instance
            .collection('reviews')
            .where('userId', isEqualTo: user.uid)
            .get();

        final batch = FirebaseFirestore.instance.batch();
        for (var doc in reviewsQuery.docs) {
          batch.update(doc.reference, {
            'userProfileImage': downloadUrl,
          });
        }
        await batch.commit();

        final postsQuery = await FirebaseFirestore.instance
            .collection('posts')
            .where('userId', isEqualTo: user.uid)
            .get();

        final postsBatch = FirebaseFirestore.instance.batch();
        for (var doc in postsQuery.docs) {
          postsBatch.update(doc.reference, {
            'userImage': downloadUrl,
          });
        }
        await postsBatch.commit();

        setState(() {
          _profileImageUrl = downloadUrl;
        });
      }
    } catch (e) {
      // print('画像のアップロード中にエラーが発生しました: $e');
    }
  }

  Widget _buildUserStats(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const SizedBox();
    }

    // 各コレクションのStreamを作成
    final reviewsStream = FirebaseFirestore.instance
        .collection('reviews')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.length);

    final bookmarksStream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .snapshots()
        .map((snap) => snap.docs.length);

    final postsStream = FirebaseFirestore.instance
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.length);

    final favoriteStream = FirebaseFirestore.instance
        .collection('posts')
        .where('likedBy', arrayContains: userId)
        .snapshots()
        .map((snap) => snap.docs.length);

    return StreamBuilder<List<int>>(
      stream: Rx.combineLatest4(
        reviewsStream,
        bookmarksStream,
        postsStream,
        favoriteStream,
        (reviews, bookmarks, posts, favorites) =>
            [reviews, bookmarks, posts, favorites],
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final [reviewCount, bookmarkCount, postCount, favoriteCount] =
            snapshot.data!;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _buildStatItem(
                icon: Icons.rate_review,
                title: l10n.kuchikomi,
                count: reviewCount,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserKuchikomiPage(),
                    ),
                  );
                },
              ),
              Divider(height: 1, color: Colors.grey[300]),
              _buildStatItem(
                icon: Icons.bookmark,
                title: l10n.bookmarks,
                count: bookmarkCount,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BookmarksPage(),
                    ),
                  );
                },
              ),
              Divider(height: 1, color: Colors.grey[300]),
              _buildStatItem(
                icon: Icons.post_add,
                title: l10n.posts,
                count: postCount,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserPostsPage(userId: userId),
                    ),
                  );
                },
              ),
              Divider(height: 1, color: Colors.grey[300]),
              _buildStatItem(
                icon: Icons.favorite,
                title: l10n.favorite,
                count: favoriteCount,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LikedPostsPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required int count,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.blue,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              count.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  void _showBioDialog() {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: _bio);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n.editBio,
          style: const TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          maxLength: 150,
          decoration: InputDecoration(
            hintText: l10n.bioHint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              final newBio = controller.text.trim();
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .update({'bio': newBio});

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.bioUpdated,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }
            },
            child: Text(
              l10n.save,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(l10n.profile,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingPage()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(l10n.errorOccurred));
          }

          if (snapshot.hasData && snapshot.data != null) {
            final userData = snapshot.data!.data() as Map<String, dynamic>?;
            _username = userData?['username'];
            _profileImageUrl = userData?['profileImage'];
            _bio = userData?['bio'];
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SubscriptionPremium(),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.blue,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/subscription_images/premium_image_seichi.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildProfileHeader(context),
                const SizedBox(height: 16),
                _buildUserStats(context),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (context) => const SeichiDeDekirukoto(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                        child: Text(l10n.howToUseSeichi,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                color: Colors.white))),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage: _profileImageUrl != null
                            ? NetworkImage(_profileImageUrl!)
                            : null,
                        child: _profileImageUrl == null
                            ? const Icon(Icons.person, size: 40)
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _username ?? l10n.unknown,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildSocialIcons(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _showBioDialog,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _bio?.isNotEmpty == true ? _bio! : l10n.tapToAddBio,
                  style: TextStyle(
                    color: _bio?.isNotEmpty == true
                        ? Colors.black87
                        : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialIcons() {
    final isPremium = ref.watch(subscriptionProvider).value ?? false;

    return Row(
      children: [
        GestureDetector(
          onTap: () {
            if (!isPremium) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SubscriptionPremium()),
              );
              return;
            }
            if (_xAccountUrl == null) {
              showXAccountDialog();
            } else {
              launchUrl(Uri.parse(_xAccountUrl!),
                  mode: LaunchMode.externalApplication);
            }
          },
          child: Image.asset(
            'assets/sns_icon/x_icon.png',
            width: 24,
            height: 24,
            color: _xAccountUrl != null ? null : Colors.grey,
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () {
            if (!isPremium) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SubscriptionPremium()),
              );
              return;
            }
            if (_instagramAccountUrl == null) {
              showInstagramAccountDialog();
            } else {
              launchUrl(Uri.parse(_instagramAccountUrl!),
                  mode: LaunchMode.externalApplication);
            }
          },
          child: Image.asset(
            'assets/sns_icon/insta_icon.png',
            width: 24,
            height: 24,
            color: _instagramAccountUrl != null ? null : Colors.grey,
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () {
            if (!isPremium) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SubscriptionPremium()),
              );
              return;
            }
            if (_tiktokAccountUrl == null) {
              showTiktokAccountDialog();
            } else {
              launchUrl(Uri.parse(_tiktokAccountUrl!),
                  mode: LaunchMode.externalApplication);
            }
          },
          child: Image.asset(
            'assets/sns_icon/tiktok_icon.png',
            width: 24,
            height: 24,
            color: _tiktokAccountUrl != null ? null : Colors.grey,
          ),
        ),
      ],
    );
  }
}
