import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class OtherUserProfilePage extends StatefulWidget {
  final String userId;
  final String userName;
  final String? profileImage;

  const OtherUserProfilePage({
    super.key,
    required this.userId,
    required this.userName,
    this.profileImage,
  });

  @override
  State<OtherUserProfilePage> createState() => _OtherUserProfilePageState();
}

class _OtherUserProfilePageState extends State<OtherUserProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
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
    _tabController = TabController(length: 2, vsync: this);
    _initStreams();
    _loadSocialAccounts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initStreams() {
    _reviewsStream = FirebaseFirestore.instance
        .collection('reviews')
        .where('userId', isEqualTo: widget.userId)
        .orderBy('timestamp', descending: true)
        .snapshots();

    _reviewsStream.listen((snapshot) {
      if (mounted) {
        setState(() {
          _reviewCount = snapshot.docs.length;
        });
      }
    });

    _visitedSpotsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('visited_spots')
        .snapshots();

    _visitedSpotsStream.listen((snapshot) {
      if (mounted) {
        setState(() {
          _visitedSpotsCount = snapshot.docs.length;
        });
      }
    });
  }

  Future<void> _loadSocialAccounts() async {
    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
    setState(() {
      _xAccountUrl = userData.data()?['xAccountUrl'];
      _instagramAccountUrl = userData.data()?['instagramAccountUrl'];
      _tiktokAccountUrl = userData.data()?['tiktokAccountUrl'];
    });
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

  Widget _buildSocialIcons() {
    return Row(
      children: [
        GestureDetector(
          onTap: _xAccountUrl != null ? () async {
            if (await canLaunch(_xAccountUrl!)) {
              await launch(_xAccountUrl!);
            }
          } : null,
          child: Image.asset(
            'assets/sns_icon/x_icon.png',
            width: 24,
            height: 24,
            color: _xAccountUrl != null ? null : Colors.grey,
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: _instagramAccountUrl != null ? () async {
            if (await canLaunch(_instagramAccountUrl!)) {
              await launch(_instagramAccountUrl!);
            }
          } : null,
          child: Image.asset(
            'assets/sns_icon/insta_icon.png',
            width: 24,
            height: 24,
            color: _instagramAccountUrl != null ? null : Colors.grey,
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: _tiktokAccountUrl != null ? () async {
            if (await canLaunch(_tiktokAccountUrl!)) {
              await launch(_tiktokAccountUrl!);
            }
          } : null,
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

  Widget _buildReviewsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('userId', isEqualTo: widget.userId)
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
                                      '投稿日: ${DateFormat('yyyy年MM月dd日 HH時mm分').format(review['timestamp'].toDate())}',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    ),
                                  ],
                                ),
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

  Widget _buildVisitedSpotsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('visited_spots')
          .orderBy('visitDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final spots = snapshot.data!.docs;
          if (spots.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.place, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('聖地登録はありません', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: spots.length,
            itemBuilder: (context, index) {
              try {
                final spot = spots[index].data() as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (spot['imageUrl'] != null)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          child: Image.network(
                            spot['imageUrl'],
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const SizedBox(
                                height: 200,
                                child: Center(child: Icon(Icons.error)),
                              );
                            },
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on),
                                Text(
                                  spot['spotName'] ?? '不明な聖地',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            if (spot['visitDate'] != null)
                              Text(
                                '訪問日: ${(spot['visitDate'] as Timestamp).toDate().year}年'
                                '${(spot['visitDate'] as Timestamp).toDate().month}月'
                                '${(spot['visitDate'] as Timestamp).toDate().day}日',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              spot['memo'] ?? '',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              } catch (e, stackTrace) {
                print('Error rendering spot at index $index: $e');
                print('Stack trace: $stackTrace');
                return const SizedBox.shrink();
              }
            },
          );
        }
        // データ待ち
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          '${widget.userName}のプロフィール',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: widget.profileImage != null
                      ? NetworkImage(widget.profileImage!)
                      : null,
                  child: widget.profileImage == null
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.userName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        _buildStatItem(Icons.rate_review, '$_reviewCount', '口コミ'),
                        const SizedBox(width: 16),
                        _buildStatItem(Icons.place, '$_visitedSpotsCount', '聖地登録'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildSocialIcons(),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: '口コミ'),
              Tab(text: '聖地登録'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildReviewsTab(),
                _buildVisitedSpotsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}