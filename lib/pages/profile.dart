import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'spot_detail.dart';
import 'setting.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/subscription_state.dart';
import 'subscription_premium.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with SingleTickerProviderStateMixin {
  String? _username;
  String? _profileImageUrl;
  late TabController _tabController;
  late Stream<DocumentSnapshot> _userStream;
  late Stream<QuerySnapshot> _reviewsStream;
  late Stream<QuerySnapshot> _visitedSpotsStream;
  int _reviewCount = 0;
  int _visitedSpotsCount = 0;
  String? _xAccountUrl;
  String? _instagramAccountUrl;
  String? _tiktokAccountUrl;

  @override
  void initState() {
    super.initState();
    _initStreams();
    _tabController = TabController(length: 2, vsync: this);
    _loadSocialAccounts();
  }

  void _initStreams() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots();

      _reviewsStream = FirebaseFirestore.instance
          .collection('reviews')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .snapshots();

      _visitedSpotsStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('visited_spots')
          .snapshots();

      _reviewsStream.listen((snapshot) {
        if (mounted) {
          setState(() {
            _reviewCount = snapshot.docs.length;
          });
        }
      });

      _visitedSpotsStream.listen((snapshot) {
        if (mounted) {
          setState(() {
            _visitedSpotsCount = snapshot.docs.length;
          });
        }
      });
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

  void _showXAccountDialog() {
    final l10n = AppLocalizations.of(context)!;
    final TextEditingController controller =
        TextEditingController(text: _xAccountUrl);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.xAccountSetting,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold)),
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
            const SizedBox(height: 4),
            Text(
              l10n.enterXAccountUrl,
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
              final url = 'https://x.com/$username';
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .update({'xAccountUrl': url});
              setState(() {
                _xAccountUrl = url;
              });
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(l10n.xAccountUpdated,
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                );
              }
            },
            child: Text(l10n.save, style: const TextStyle(fontWeight: FontWeight.bold)),
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
        title: Text(l10n.instagramAccountSetting,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
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

              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .update({'instagramAccountUrl': url});

              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: Text(l10n.save, style: const TextStyle(fontWeight: FontWeight.bold)),
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
        title: Text(l10n.tiktokAccountSetting,
            style: const TextStyle(fontWeight: FontWeight.bold)),
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

              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .update({'tiktokAccountUrl': url});

              setState(() {
                _tiktokAccountUrl = url;
              });

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(url == null
                        ? l10n.tiktokAccountDeleted
                        : l10n.tiktokAccountUpdated),
                  ),
                );
              }
            },
            child: Text(l10n.save, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

        setState(() {
          _profileImageUrl = downloadUrl;
        });
      }
    } catch (e) {
      // print('画像のアップロード中にエラーが発生しました: $e');
    }
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
          }

          return Column(
            children: [
              const SizedBox(height: 16),
              _buildProfileHeader(context),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: l10n.kuchikomi),
                  Tab(text: l10n.bookmarks),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildReviewsTab(),
                      _buildBookmarksTab(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
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
                Row(
                  children: [
                    _buildStatItem(
                        Icons.rate_review, '$_reviewCount', l10n.kuchikomi),
                    const SizedBox(width: 16),
                    _buildStatItem(
                        Icons.place, '$_visitedSpotsCount', l10n.seichitouroku),
                  ],
                ),
                const SizedBox(height: 8),
                _buildSocialIcons(),
              ],
            ),
          ),
        ],
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
            if (_xAccountUrl != null) {
              launchUrl(Uri.parse(_xAccountUrl!));
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
            if (_instagramAccountUrl != null) {
              launchUrl(Uri.parse(_instagramAccountUrl!));
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
            if (_tiktokAccountUrl != null) {
              launchUrl(Uri.parse(_tiktokAccountUrl!));
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

  Widget _buildBookmarksTab() {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('bookmarks')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text(l10n.errorOccurred));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.bookmark_border,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.noBookmarks,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Icon(Icons.place, size: 24, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(data['name'] ?? l10n.unknown,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              subtitle: Text('${l10n.address}: ${data['address'] ?? l10n.unknownAddress}',
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () async {
                final spotDoc = await FirebaseFirestore.instance
                    .collection('spots')
                    .doc(data['spotId'])
                    .get();

                if (spotDoc.exists) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SpotDetailPage(spot: spotDoc),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.spotNotFound)),
                  );
                }
              },
              trailing: const Icon(Icons.chevron_right),
            );
          },
        );
      },
    );
  }

  Widget _buildReviewsTab() {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(child: Text(l10n.loginRequired));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text(l10n.errorOccurred));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.rate_review, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(l10n.noReviews,
                    style: const TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final review = snapshot.data!.docs[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (review['imageUrl'] != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8)),
                        child: Image.network(
                          review['imageUrl'],
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: review['userProfileImage'] !=
                                        null
                                    ? NetworkImage(review['userProfileImage'])
                                    : null,
                                child: review['userProfileImage'] == null
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      review['userName'] ?? l10n.unknown,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${l10n.postedDate}: ${review['timestamp'] != null ? DateFormat('yyyy年MM月dd日 HH時mm分').format(review['timestamp'].toDate()) : l10n.unknownDate}',
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          ListTile(
                                            leading: const Icon(Icons.delete,
                                                color: Colors.red),
                                            title: Text(l10n.delete,
                                                style: const TextStyle(
                                                    color: Colors.red)),
                                            onTap: () async {
                                              final bool? confirmDelete =
                                                  await showDialog<bool>(
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return AlertDialog(
                                                    title: Text(l10n.confirm),
                                                    content: Text(
                                                        l10n.deleteReviewConfirm,
                                                        style: const TextStyle(
                                                            fontSize: 12)),
                                                    actions: <Widget>[
                                                      TextButton(
                                                        child: Text(l10n.cancel),
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(false),
                                                      ),
                                                      TextButton(
                                                        child: Text(l10n.delete,
                                                            style: const TextStyle(
                                                                color: Colors
                                                                    .red)),
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(true),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );

                                              if (confirmDelete == true) {
                                                try {
                                                  if (review['imageUrl'] !=
                                                      null) {
                                                    try {
                                                      final storageRef =
                                                          FirebaseStorage
                                                              .instance
                                                              .refFromURL(review[
                                                                  'imageUrl']);
                                                      await storageRef.delete();
                                                    } catch (e) {
                                                      // print(
                                                          // '画像の削除中にエラーが発生しました: $e');
                                                    }
                                                  }
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('reviews')
                                                      .doc(review.id)
                                                      .delete();

                                                  Navigator.of(context).pop();
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                        content:
                                                            Text(l10n.reviewDeleted)),
                                                  );
                                                } catch (e) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                        content: Text(
                                                            l10n.reviewDeleteError)),
                                                  );
                                                }
                                              } else {
                                                Navigator.of(context).pop();
                                              }
                                            },
                                          ),
                                          ListTile(
                                            leading: const Icon(Icons.cancel),
                                            title: Text(l10n.cancel),
                                            onTap: () {
                                              Navigator.pop(context);
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                icon: const Icon(Icons.more_vert),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              RatingBarIndicator(
                                rating: review['rating'].toDouble(),
                                itemBuilder: (context, index) => const Icon(
                                  Icons.star,
                                  color: Colors.orange,
                                ),
                                itemCount: 5,
                                itemSize: 20.0,
                                direction: Axis.horizontal,
                              ),
                              const SizedBox(width: 8),
                              Text(': ${l10n.seichitourokuSatisfaction}'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            review['review'],
                            style: TextStyle(color: Colors.grey[800]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatItem(IconData icon, String count, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blue),
        const SizedBox(width: 4),
        Text(
          count,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
