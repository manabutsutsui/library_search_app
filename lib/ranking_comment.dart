import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'spot_detail.dart';

class RankingCommentPage extends StatefulWidget {
  const RankingCommentPage({Key? key}) : super(key: key);

  @override
  RankingCommentPageState createState() => RankingCommentPageState();
}

class RankingCommentPageState extends State<RankingCommentPage> {
  List<Map<String, dynamic>> _rankedSpotsByCount = [];
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

        final reviewCount = reviewsSnapshot.docs.length;

        rankedSpots.add({
          'id': spot.id,
          'name': spot['name'] ?? '名称不明',
          'address': spot['address'] ?? '住所不明',
          'work': spot['work'] ?? '作品不明',
          'reviewCount': reviewCount,
        });
      }

      rankedSpots.sort((a, b) => b['reviewCount'].compareTo(a['reviewCount']));

      if (!mounted) return;  // この行を追加
      setState(() {
        _rankedSpotsByCount = rankedSpots;
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
        ? (_rankedSpotsByCount.length >= 15 ? 15 : _rankedSpotsByCount.length)
        : (_rankedSpotsByCount.length >= 3 ? 3 : _rankedSpotsByCount.length);
    bool showMore = !_isExpanded && _rankedSpotsByCount.length > 3;

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

        final spot = _rankedSpotsByCount[index];
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
            trailing: Text('${spot['reviewCount']}件の口コミ', style: const TextStyle(fontSize: 12)),
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
        title: const Text('口コミ数ランキング', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: _buildList(),
            ),
    );
  }
}