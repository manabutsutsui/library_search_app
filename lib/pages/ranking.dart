import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/seichi_spots.dart';
import 'spot_detail.dart';

class RankingPage extends ConsumerStatefulWidget {
  const RankingPage({super.key});

  @override
  ConsumerState<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends ConsumerState<RankingPage>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  List<Map<String, dynamic>> _rankedSpotsByRating = [];

  List<Map<String, dynamic>> _rankedSpotsByCount = [];

  List<Map<String, dynamic>> _rankedUsers = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchRankingData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _fetchRankingData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .get(const GetOptions(source: Source.serverAndCache));

      Map<String, List<double>> ratings = {};
      Map<String, int> reviewCounts = {};
      Map<String, int> userReviewCounts = {};

      for (var review in reviewsSnapshot.docs) {
        final spotId = review['spotId'];
        final rating = review['rating']?.toDouble() ?? 0.0;
        final userId = review['userId'];

        if (!ratings.containsKey(spotId)) {
          ratings[spotId] = [];
        }
        ratings[spotId]!.add(rating);

        reviewCounts[spotId] = (reviewCounts[spotId] ?? 0) + 1;

        userReviewCounts[userId] = (userReviewCounts[userId] ?? 0) + 1;
      }

      List<Map<String, dynamic>> rankedSpotsByRating = seichiSpots.map((spot) {
        final spotRatings = ratings[spot.id] ?? [];
        final averageRating = spotRatings.isNotEmpty
            ? spotRatings.reduce((a, b) => a + b) / spotRatings.length
            : 0.0;

        return {
          'id': spot.id,
          'name': spot.name,
          'address': spot.address,
          'work': spot.workName,
          'averageRating': averageRating,
          'reviewCount': spotRatings.length,
          'imageURL': spot.imageURL,
        };
      }).toList();

      List<Map<String, dynamic>> rankedSpotsByCount = seichiSpots.map((spot) {
        return {
          'id': spot.id,
          'name': spot.name,
          'address': spot.address,
          'work': spot.workName,
          'reviewCount': reviewCounts[spot.id] ?? 0,
          'imageURL': spot.imageURL,
        };
      }).toList();

      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      final rankedUsers = <Map<String, dynamic>>[];

      for (var doc in usersSnapshot.docs) {
        final userData = doc.data();
        final userId = doc.id;
        final profileImage = userData['profileImage'] ?? '';
        final userName =
            userData['username'] ?? AppLocalizations.of(context)!.unknownUser;
        final userPoints = userData['points'] ?? 0;

        rankedUsers.add({
          'id': userId,
          'profileImage': profileImage,
          'username': userName,
          'points': userPoints,
        });
      }

      rankedUsers.sort((a, b) => b['points'].compareTo(a['points']));

      if (!mounted) return;
      setState(() {
        _rankedSpotsByRating = rankedSpotsByRating;
        _rankedSpotsByCount = rankedSpotsByCount;
        _rankedUsers = rankedUsers;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildRankIcon(int index) {
    String crownImage;
    switch (index) {
      case 0:
        crownImage = 'assets/crowns/crown_gold.png';
        break;
      case 1:
        crownImage = 'assets/crowns/crown_silver.png';
        break;
      case 2:
        crownImage = 'assets/crowns/crown_copper.png';
        break;
      default:
        crownImage = 'assets/crowns/crown_blue.png';
        break;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Image.asset(
          crownImage,
          width: 40,
          height: 40,
        ),
        Text(
          '${index + 1}',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount:
          _rankedSpotsByRating.length > 15 ? 15 : _rankedSpotsByRating.length,
      itemBuilder: (context, index) {
        final spot = _rankedSpotsByRating[index];
        return GestureDetector(
          onTap: () {
            final spot = seichiSpots.firstWhere(
              (s) => s.id == _rankedSpotsByRating[index]['id'],
              orElse: () => throw Exception('Spot not found'),
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SpotDetailPage(spot: spot),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    _buildRankIcon(index),
                    const SizedBox(width: 8),
                    Text(
                      spot['name'] ?? '名称不明',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    spot['imageURL'] ?? 'https://via.placeholder.com/150',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(child: Icon(Icons.error));
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          spot['averageRating'].toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Text(
                      spot['work'] ?? '作品不明',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentList() {
    final l10n = AppLocalizations.of(context)!;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount:
          _rankedSpotsByCount.length > 15 ? 15 : _rankedSpotsByCount.length,
      itemBuilder: (context, index) {
        final spot = _rankedSpotsByCount[index];
        return GestureDetector(
          onTap: () {
            final spot = seichiSpots.firstWhere(
              (s) => s.id == _rankedSpotsByCount[index]['id'],
              orElse: () => throw Exception('Spot not found'),
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SpotDetailPage(spot: spot),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    _buildRankIcon(index),
                    const SizedBox(width: 8),
                    Text(
                      spot['name'] ?? '名称不明',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    spot['imageURL'] ?? 'https://via.placeholder.com/150',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(child: Icon(Icons.error));
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.comment, color: Colors.blue, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '${spot['reviewCount']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.reviews,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Text(
                      spot['work'] ?? '作品不明',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _rankedUsers.length > 15 ? 15 : _rankedUsers.length,
      itemBuilder: (context, index) {
        final user = _rankedUsers[index];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  _buildRankIcon(index),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: (user['profileImage'] != null &&
                            user['profileImage'].toString().isNotEmpty)
                        ? NetworkImage(user['profileImage'] as String)
                        : null,
                    child: (user['profileImage'] == null ||
                            user['profileImage'].toString().isEmpty)
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    user['username'] ?? '名称不明',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${user['points']} Pt',
                      style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16)
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: l10n.userRanking, icon: const Icon(Icons.person)),
            Tab(text: l10n.rankingReview, icon: const Icon(Icons.star)),
            Tab(text: l10n.rankingComment, icon: const Icon(Icons.comment)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _buildUserList(),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _buildRatingList(),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _buildCommentList(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
