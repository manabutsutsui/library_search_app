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

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  String? _username;
  String? _profileImageUrl;
  late TabController _tabController;
  late Stream<DocumentSnapshot> _userStream;
  late Stream<QuerySnapshot> _reviewsStream;
  late Stream<QuerySnapshot> _visitedSpotsStream;
  int _reviewCount = 0;
  int _visitedSpotsCount = 0;

  @override
  void initState() {
    super.initState();
    _initStreams();
    _tabController = TabController(length: 2, vsync: this);
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
        final uploadTask = imageRef.putFile(File(image.path));
        final snapshot = await uploadTask.whenComplete(() {});
        final downloadUrl = await snapshot.ref.getDownloadURL();
        
        // ユーザードキュメントの更新
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
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
      print('画像のアップロード中にエラーが発生しました: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('プロフィール', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
            return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
          }

          if (snapshot.hasData && snapshot.data != null) {
            final userData = snapshot.data!.data() as Map<String, dynamic>?;
            _username = userData?['username'];
            _profileImageUrl = userData?['profileImage'];
          }

          return Column(
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: _profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null,
                        child: _profileImageUrl == null
                            ? Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey[700])
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _username ?? '名前: 未設定',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildStatItem(Icons.rate_review, '$_reviewCount', '口コミ'),
                            const SizedBox(width: 16),
                            _buildStatItem(Icons.place, '$_visitedSpotsCount', '聖地登録'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: '口コミ'),
                  Tab(text: 'ブックマーク'),
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

  Widget _buildBookmarksTab() {
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
          return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bookmark_border,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'ブックマークはありません',
                  style: TextStyle(
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
                  Text(data['name'] ?? '名称不明', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              subtitle: Text(data['address'] ?? '住所不明'),
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
                    const SnackBar(content: Text('スポット情報が見つかりません')),
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('ログインが必要です'));
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
          return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.rate_review, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('口コミはありません', style: TextStyle(color: Colors.grey, fontSize: 16)),
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
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
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
                                backgroundImage: review['userProfileImage'] != null
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
                                      review['userName'] ?? '名称不明',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '投稿日: ${review['timestamp'] != null ? DateFormat('yyyy年MM月dd日 HH時mm分').format(review['timestamp'].toDate()) : '日付不明'}',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
                                            leading: const Icon(Icons.delete, color: Colors.red),
                                            title: const Text('削除する', style: TextStyle(color: Colors.red)),
                                            onTap: () async {
                                              final bool? confirmDelete = await showDialog<bool>(
                                                context: context,
                                                builder: (BuildContext context) {
                                                  return AlertDialog(
                                                    title: const Text('確認'),
                                                    content: const Text('この口コミを削除してもよろしいですか？', style: TextStyle(fontSize: 12)),
                                                    actions: <Widget>[
                                                      TextButton(
                                                        child: const Text('キャンセル'),
                                                        onPressed: () => Navigator.of(context).pop(false),
                                                      ),
                                                      TextButton(
                                                        child: const Text('削除', style: TextStyle(color: Colors.red)),
                                                        onPressed: () => Navigator.of(context).pop(true),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );

                                              if (confirmDelete == true) {
                                                try {
                                                  await FirebaseFirestore.instance
                                                      .collection('reviews')
                                                      .doc(review.id)
                                                      .delete();

                                                  Navigator.of(context).pop();
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('口コミを削除しました')),
                                                  );
                                                } catch (e) {
                                                  print('口コミの削除中にエラーが発生しました: $e');
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('口コミの削除に失敗しました')),
                                                  );
                                                }
                                              } else {
                                                Navigator.of(context).pop();
                                              }
                                            },
                                          ),
                                          ListTile(
                                            leading: const Icon(Icons.cancel),
                                            title: const Text('キャンセル'),
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
                              const Text(': 聖地の満足度'),
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
