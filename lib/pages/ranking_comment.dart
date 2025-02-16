import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'spot_detail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/subscription_state.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
class RankingCommentPage extends ConsumerStatefulWidget {
  const RankingCommentPage({Key? key}) : super(key: key);

  @override
  ConsumerState<RankingCommentPage> createState() => RankingCommentPageState();
}

class RankingCommentPageState extends ConsumerState<RankingCommentPage> {
  List<Map<String, dynamic>> _rankedSpotsByCount = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRankedSpots();
  }

  Future<void> _fetchRankedSpots() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final spotsSnapshot = await FirebaseFirestore.instance
          .collection('spots')
          .get(const GetOptions(source: Source.serverAndCache));
      
      final spots = spotsSnapshot.docs;
      final List<Future<QuerySnapshot>> reviewQueries = spots.map((spot) =>
        FirebaseFirestore.instance
            .collection('reviews')
            .where('spotId', isEqualTo: spot.id)
            .get(const GetOptions(source: Source.serverAndCache))
      ).toList();

      final reviewSnapshots = await Future.wait(reviewQueries);

      List<Map<String, dynamic>> rankedSpots = [];
      for (var i = 0; i < spots.length; i++) {
        final spot = spots[i];
        final reviews = reviewSnapshots[i].docs;

        rankedSpots.add({
          'id': spot.id,
          'name': spot['name'] ?? '名称不明',
          'address': spot['address'] ?? '住所不明',
          'work': spot['work'] ?? '作品不明',
          'reviewCount': reviews.length,
        });
      }

      rankedSpots.sort((a, b) => b['reviewCount'].compareTo(a['reviewCount']));

      if (!mounted) return;
      setState(() {
        _rankedSpotsByCount = rankedSpots;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildList(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final subscriptionState = ref.watch(subscriptionProvider);
    
    int displayCount = subscriptionState.when(
      data: (isPro) => isPro 
          ? (_rankedSpotsByCount.length >= 30 ? 30 : _rankedSpotsByCount.length)
          : (_rankedSpotsByCount.length >= 15 ? 15 : _rankedSpotsByCount.length),
      loading: () => _rankedSpotsByCount.length >= 15 ? 15 : _rankedSpotsByCount.length,
      error: (_, __) => _rankedSpotsByCount.length >= 15 ? 15 : _rankedSpotsByCount.length,
    );

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayCount,
      itemBuilder: (context, index) {
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
            trailing: Text('${spot['reviewCount']} ${l10n.reviewsCount}', style: const TextStyle(fontSize: 12)),
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
    final l10n = AppLocalizations.of(context)!;
    final subscriptionState = ref.watch(subscriptionProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(l10n.rankingComment, 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  subscriptionState.when(
                    data: (isPro) => isPro 
                        ? const SizedBox.shrink()
                        : Text(
                            l10n.premiumPlan,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  _buildList(context),
                ],
              ),
            ),
    );
  }
}