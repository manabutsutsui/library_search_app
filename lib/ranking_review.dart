import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'spot_detail.dart';

class RankingReviewPage extends StatefulWidget {
  const RankingReviewPage({super.key});

  @override
  RankingReviewPageState createState() => RankingReviewPageState();
}

class RankingReviewPageState extends State<RankingReviewPage> {
  List<Map<String, dynamic>> _rankedSpotsByRating = [];
  bool _isLoading = true;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _fetchRankedSpots();
  }

  Future<void> _fetchRankedSpots() async {
    if (!mounted) return;  // この行を追加
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

      rankedSpots.sort((a, b) => b['averageRating'].compareTo(a['averageRating']));

      if (!mounted) return;  // この行を追加
      setState(() {
        _rankedSpotsByRating = rankedSpots;
        _isLoading = false;
      });
    } catch (e) {
      print('ランキングデータの取得中にエラーが発生しました: $e');
      if (!mounted) return;  // この行を追加
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildList() {
    int displayCount = _isExpanded
        ? (_rankedSpotsByRating.length >= 15 ? 15 : _rankedSpotsByRating.length)
        : (_rankedSpotsByRating.length >= 3 ? 3 : _rankedSpotsByRating.length);
    bool showMore = !_isExpanded && _rankedSpotsByRating.length > 3;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: showMore ? displayCount + 1 : displayCount,
      itemBuilder: (context, index) {
        if (showMore && index == displayCount) {
          return GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = true;
              });
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'もっと見る',
                  style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        }

        final spot = _rankedSpotsByRating[index];
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.orange, size: 16),
                Text(spot['averageRating'].toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
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
        title: const Text('レビューランキング', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: _buildList(),
            ),
    );
  }
}
