import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'spot_detail.dart';

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  RankingPageState createState() => RankingPageState();
}

class RankingPageState extends State<RankingPage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _rankedSpotsByRating = [];
  List<Map<String, dynamic>> _rankedSpotsByCount = [];
  bool _isLoading = true;
  bool _isExpandedRating = false;
  bool _isExpandedCount = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _fetchRankedSpots();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _fetchRankedSpots() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final spotsSnapshot = await FirebaseFirestore.instance.collection('spots').get();
      final spots = spotsSnapshot.docs;

      List<Map<String, dynamic>> rankedSpots = [];

      for (var spot in spots) {
        final reviewsSnapshot = await FirebaseFirestore.instance
            .collection('reviews')
            .where('spotId', isEqualTo: spot.id)
            .get();

        final reviews = reviewsSnapshot.docs;
        double totalRating = 0;
        int reviewCount = reviews.length;

        for (var review in reviews) {
          totalRating += review['rating']?.toDouble() ?? 0.0;
        }

        double averageRating = reviewCount > 0 ? totalRating / reviewCount : 0.0;

        rankedSpots.add({
          'id': spot.id,
          'name': spot['name'] ?? '名称不明',
          'address': spot['address'] ?? '住所不明',
          'work': spot['work'] ?? '作品不明',
          'averageRating': averageRating,
          'reviewCount': reviewCount,
        });
      }

      // 平均評価でソート
      List<Map<String, dynamic>> sortedByRating = List.from(rankedSpots);
      sortedByRating.sort((a, b) => b['averageRating'].compareTo(a['averageRating']));

      // 口コミ数でソート
      List<Map<String, dynamic>> sortedByCount = List.from(rankedSpots);
      sortedByCount.sort((a, b) => b['reviewCount'].compareTo(a['reviewCount']));

      setState(() {
        _rankedSpotsByRating = sortedByRating;
        _rankedSpotsByCount = sortedByCount;
        _isLoading = false;
      });
    } catch (e) {
      print('ランキングデータの取得中にエラーが発生しました: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildList(List<Map<String, dynamic>> spots, bool isRatingTab, bool isExpanded) {
    int displayCount = isExpanded
        ? (spots.length >= 15 ? 15 : spots.length)
        : (spots.length >= 3 ? 3 : spots.length);
    bool showMore = !isExpanded && spots.length > 3;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: showMore ? displayCount + 1 : displayCount,
      itemBuilder: (context, index) {
        if (showMore && index == displayCount) {
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isRatingTab) {
                  _isExpandedRating = true;
                } else {
                  _isExpandedCount = true;
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'もっと見る',
                  style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        }

        final spot = spots[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getRankColor(index),
              child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
            ),
            title: Text(
              spot['name'] ?? '名称不明',
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              spot['work'] ?? '作品不明',
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                isRatingTab
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.orange, size: 16),
                          Text(spot['averageRating'].toStringAsFixed(1),
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      )
                    : Text('${spot['reviewCount']}件の口コミ', style: const TextStyle(fontSize: 12)),
              ],
            ),
            onTap: () async {
              final spotDoc = await FirebaseFirestore.instance.collection('spots').doc(spot['id']).get();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SpotDetailPage(spot: spotDoc),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Colors.yellow[700]!; // 金色
      case 1:
        return Colors.grey[400]!; // 銀色
      case 2:
        return Colors.brown[300]!; // 銅色
      default:
        return Colors.blue; // それ以外は青色
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          tabs: const [
            Tab(text: 'レビューランキング', icon: Icon(Icons.star)),
            Tab(text: '口コミ数ランキング', icon: Icon(Icons.comment)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                SingleChildScrollView(
                  child: _buildList(_rankedSpotsByRating, true, _isExpandedRating),
                ),
                SingleChildScrollView(
                  child: _buildList(_rankedSpotsByCount, false, _isExpandedCount),
                ),
              ],
            ),
    );
  }
}