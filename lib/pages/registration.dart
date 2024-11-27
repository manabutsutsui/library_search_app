import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'other_user_profile.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/seichi_registration.dart';
import 'registration_detail.dart';
import '../utils/seichi_de_dekirukoto.dart';

class RegistrationPage extends ConsumerWidget {
  const RegistrationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(
                child: Text(
                  '聖地登録',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Tab(
                child: Text(
                  'ユーザーランキング',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _VisitedSpotsTab(),
            _UserRankingTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (BuildContext context) => const SeichiRegistrationPage(),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ログインが必要です')),
              );
            }
          },
          child: const Icon(Icons.edit),
        ),
      ),
    );
  }
}

class _VisitedSpotsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return _buildEmptyState(context);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('visited_spots')
          .orderBy('visitDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
        }

        final spots = snapshot.data?.docs ?? [];

        if (spots.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: spots.length,
          itemBuilder: (context, index) {
            final spotDoc = spots[index];
            final spot = {
              ...spotDoc.data() as Map<String, dynamic>,
              'spotId': spotDoc.id,
            };
            final visitDate = (spot['visitDate'] as Timestamp).toDate();
            
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SeichiRegistrationDetail(spot: spot),
                  ),
                );
              },
              child: Card(
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
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(8),
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
                          Text(
                            '訪問日: ${visitDate.year}年${visitDate.month}月${visitDate.day}日',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          if (spot['memo'] != null && spot['memo'].isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              spot['memo'],
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Text(
            'ここにあなたの「聖地記録」の一覧が\n表示されます。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final Uri url = Uri.parse('https://www.tiktok.com/@seichimapapp');
                  if (!await launchUrl(url)) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('URLを開けませんでした')),
                      );
                    }
                  }
                },
                child: const Row(
                  children: [
                    Icon(
                      Icons.videocam,
                      color: Colors.white,
                      size: 32,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Seichiの使い方',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'TikTokで紹介',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 32,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GestureDetector(
              onTap: () {
                SeichiDeDekirukoto.show(context);
              },
              child: Image.asset(
                'assets/registration_page/seichi_de_dekiru.png',
                width: 300,
                height: 300,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserRankingTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').get().asStream(),
      builder: (context, usersSnapshot) {
        if (usersSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (usersSnapshot.hasError) {
          return Center(child: Text('エラーが発生しました: ${usersSnapshot.error}'));
        }

        final users = usersSnapshot.data!.docs;

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: Future.wait(
            users.map((user) async {
              final visitedSpotsSnapshot = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.id)
                  .collection('visited_spots')
                  .get();

              final userData = user.data() as Map<String, dynamic>;

              return {
                'userId': user.id,
                'userName': userData['username'] ?? '名無しユーザー',
                'profileImage': userData['profileImage'],
                'visitedCount': visitedSpotsSnapshot.docs.length,
              };
            }),
          ),
          builder: (context, rankingSnapshot) {
            if (rankingSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (rankingSnapshot.hasError) {
              return Center(
                  child: Text('エラーが発生しました: ${rankingSnapshot.error}'));
            }

            final rankings = rankingSnapshot.data!;
            rankings
                .sort((a, b) => b['visitedCount'].compareTo(a['visitedCount']));

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rankings.length,
              itemBuilder: (context, index) {
                final ranking = rankings[index];
                final isCurrentUser =
                    ranking['userId'] == FirebaseAuth.instance.currentUser?.uid;

                return Card(
                  elevation: isCurrentUser ? 8 : 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => OtherUserProfilePage(
                                userId: ranking['userId'],
                                userName: ranking['userName'],
                                profileImage: ranking['profileImage'])),
                      );
                    },
                    child: ListTile(
                      leading: Container(
                        width: 60,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getRankingColor(index),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}位',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: ranking['profileImage'] != null
                                ? NetworkImage(ranking['profileImage'])
                                : null,
                            child: ranking['profileImage'] == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ranking['userName'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '訪問した聖地: ${ranking['visitedCount']}件',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      tileColor:
                          isCurrentUser ? Colors.blue.withOpacity(0.1) : null,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Color _getRankingColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber;
      case 1:
        return Colors.grey[400]!;
      case 2:
        return Colors.brown[300]!;
      default:
        return Colors.blue;
    }
  }
}
