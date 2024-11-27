import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'review_detail.dart';
import 'reviews_lists.dart';
import 'recommended_products_lists.dart';
import 'anime_lists.dart';
import 'anime_detail.dart';
import 'anime_more.dart';
import 'ranking_review.dart';
import 'ranking_comment.dart';
import 'subscription_premium.dart';
import '../ad/ad_banner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/subscription_state.dart';
import 'spot_detail.dart';
import 'new_seichi.dart';

class Home extends ConsumerStatefulWidget {
  const Home({super.key});

  @override
  HomeState createState() => HomeState();
}

class HomeState extends ConsumerState<Home> {
  Future<String> _loadRakutenApplicationId() async {
    final String jsonString =
        await rootBundle.loadString('assets/config/config.json');
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    return jsonMap['rakutenApplicationId'];
  }

  Future<List<dynamic>> fetchRakutenItems() async {
    final String applicationId = await _loadRakutenApplicationId();
    final String keyword = Uri.encodeComponent('人気アニメ グッズ');
    final response = await http.get(Uri.parse(
        'https://app.rakuten.co.jp/services/api/IchibaItem/Search/20170706?applicationId=$applicationId&keyword=$keyword&hits=10'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['Items'];
    } else {
      throw Exception('楽天APIからデータの取得に失敗しました');
    }
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'URLを開けませんでした: $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionState = ref.watch(subscriptionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.asset(
                'assets/images/home_image.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          subscriptionState.when(
            data: (isPro) => isPro
                ? const SliverToBoxAdapter(child: SizedBox.shrink())
                : SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          const EdgeInsets.only(top: 16, left: 16, right: 16),
                      child: GestureDetector(
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
                    ),
                  ),
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => SliverToBoxAdapter(
              child: Center(child: Text('エラーが発生しました: $error')),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'おすすめ作品',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AnimeMorePage()),
                      );
                    },
                    child: const Text('作品一覧'),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    final anime = animeList[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AnimeDetailPage(anime: anime),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.only(right: 8),
                        width: 200,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                anime.imageAsset,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              anime.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '新着口コミ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ReviewsListPage()),
                      );
                    },
                    child: const Text('もっと見る'),
                  ),
                ],
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('reviews')
                .orderBy('timestamp', descending: true)
                .limit(4)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return SliverToBoxAdapter(
                  child: Center(child: Text('エラーが発生しました: ${snapshot.error}')),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(child: Text('口コミはありません')),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      var review = snapshot.data!.docs[index];
                      return _buildReviewItem(context, review);
                    },
                    childCount: snapshot.data!.docs.length,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ReviewsListPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: const Text('口コミ一覧',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '新着聖地',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const NewSeichiPage()),
                      );
                    },
                    child: const Text('もっと見る'),
                  ),
                ],
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('spots')
                .orderBy('createdAt', descending: true)
                .limit(4)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return SliverToBoxAdapter(
                  child: Center(child: Text('エラーが発生しました: ${snapshot.error}')),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(child: Text('聖地はまだありません')),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.0,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      var spot = snapshot.data!.docs[index];
                      return GestureDetector(
                        onTap: () {
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
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                spot['imageURL'] ?? '',
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 120,
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    spot['name'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    spot['work'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: snapshot.data!.docs.length,
                  ),
                ),
              );
            },
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'おすすめ商品',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const RecommendedProductsListPage()),
                      );
                    },
                    child: const Text('もっと見る'),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: SizedBox(
                height: 200,
                child: FutureBuilder<List<dynamic>>(
                  future: fetchRakutenItems(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                          child: Text('エラーが発生しました: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('商品が見つかりませんでした'));
                    }

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final item = snapshot.data![index]['Item'];
                        return GestureDetector(
                          onTap: () => _launchURL(item['itemUrl']),
                          child: Container(
                            width: 150,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Image.network(
                                  item['mediumImageUrls'][0]['imageUrl'],
                                  height: 100,
                                  width: 150,
                                  fit: BoxFit.cover,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item['itemName'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  '¥${item['itemPrice']}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'ランキング',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const RankingReviewPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.star, color: Colors.white, size: 30),
                        SizedBox(height: 8),
                        Text(
                          '全国聖地ランキング',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        ),
                        Text(' by レビュー',
                            style:
                                TextStyle(color: Colors.white, fontSize: 16)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const RankingCommentPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.comment, color: Colors.white, size: 30),
                        SizedBox(height: 8),
                        Text(
                          '全国聖地ランキング',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        ),
                        Text(' by 口コミ数',
                            style:
                                TextStyle(color: Colors.white, fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          subscriptionState.when(
            data: (isPro) => isPro
                ? const SliverToBoxAdapter(child: SizedBox.shrink())
                : const SliverToBoxAdapter(
                    child: AdBanner(),
                  ),
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => SliverToBoxAdapter(
              child: Center(child: Text('エラーが発生しました: $error')),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _launchURL('https://x.com/Seichi_map_app'),
                    child: Image.asset(
                      'assets/images/x_icon.png',
                    ),
                  ),
                  const Text(
                    '公式',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(BuildContext context, DocumentSnapshot review) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('spots')
          .doc(review['spotId'])
          .get(),
      builder: (context, spotSnapshot) {
        if (spotSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (spotSnapshot.hasError || !spotSnapshot.hasData) {
          return const SizedBox();
        }

        var spot = spotSnapshot.data!;

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ReviewDetailPage(review: review, spot: spot),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: review['imageUrl'] != null
                    ? Image.network(
                        review['imageUrl'],
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[200],
                        ),
                        height: 120,
                        width: double.infinity,
                        child: const Icon(
                          Icons.photo_outlined,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spot['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      spot['work'],
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundImage: review['userProfileImage'] != null
                              ? NetworkImage(review['userProfileImage'])
                              : null,
                          child: review['userProfileImage'] == null
                              ? const Icon(Icons.person, size: 16)
                              : null,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            review['userName'] ?? '名無しユーザー',
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _buildRatingStars(review['rating']),
                    const SizedBox(height: 4),
                    Text(
                      review['review'],
                      style: const TextStyle(fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRatingStars(dynamic rating) {
    final int ratingValue = rating is int ? rating : (rating as double).round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < ratingValue ? Icons.star : Icons.star_border,
          color: Colors.orange,
          size: 16,
        );
      }),
    );
  }
}