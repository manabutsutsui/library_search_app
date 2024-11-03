import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'seichi_registration.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'provider/subscription_state.dart';
import 'anime_lists.dart';
import 'provider/visited_spots_provider.dart';
import 'subscription_premium.dart';

class SpotDetailPage extends ConsumerStatefulWidget {
  final DocumentSnapshot spot;

  const SpotDetailPage({super.key, required this.spot});

  @override
  SpotDetailPageState createState() => SpotDetailPageState();
}

class SpotDetailPageState extends ConsumerState<SpotDetailPage> {
  List<DocumentSnapshot> _reviews = [];
  bool _isBookmarked = false;
  bool _isVisited = false;
  double _averageRating = 0.0;

  @override
  void initState() {
    super.initState();
    _getSpotLocation();
    _fetchReviews().then((_) => _calculateAverageRating());
    _checkBookmarkStatus();
    _checkVisitedStatus();
  }

  LatLng? _spotLocation;
  final Set<Marker> _markers = {};

  Future<void> _getSpotLocation() async {
    try {
      GeoPoint location = widget.spot['location'];
      setState(() {
        _spotLocation = LatLng(location.latitude, location.longitude);
        _markers.add(Marker(
          markerId: MarkerId(widget.spot.id),
          position: _spotLocation!,
        ));
      });
    } catch (e) {
      print('エラーが発生しました: $e');
    }
  }

  Future<void> _fetchReviews() async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('reviews')
        .where('spotId', isEqualTo: widget.spot.id)
        .orderBy('timestamp', descending: true)
        .get();
    setState(() {
      _reviews = snapshot.docs;
    });
  }

  Future<void> _checkBookmarkStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final bookmarkRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('bookmarks')
          .doc(widget.spot.id);

      final bookmarkDoc = await bookmarkRef.get();
      setState(() {
        _isBookmarked = bookmarkDoc.exists;
      });
    }
  }

  Future<void> _checkVisitedStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final visitedRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('visited_spots')
          .doc(widget.spot.id);

      final visitedDoc = await visitedRef.get();
      setState(() {
        _isVisited = visitedDoc.exists;
      });
    }
  }

  Future<void> _calculateAverageRating() async {
    if (_reviews.isEmpty) {
      setState(() {
        _averageRating = 0.0;
      });
      return;
    }

    double totalRating = 0;
    for (var review in _reviews) {
      totalRating += review['rating'];
    }
    setState(() {
      _averageRating = totalRating / _reviews.length;
    });
  }

  AnimeList? _getAnimeInfo(String workName) {
    return animeList.firstWhere(
      (anime) => anime.name == workName,
      orElse: () => AnimeList(name: '', imageAsset: '', imageUrl: ''),
    );
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(widget.spot['name'],
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(
              _isVisited ? Icons.favorite : Icons.favorite_border,
              color: Colors.white,
            ),
            onPressed: () async {
              final isSubscribed = ref.read(subscriptionProvider).value == true;
              if (!isSubscribed) {
                final bool? shouldNavigate = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text(
                        '👑Premiumプラン👑',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      content: const Text(
                        '訪れた聖地として登録するには、Premiumプランへの登録が必要です。\n\nPremiumプランの詳細を確認しますか？',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('キャンセル'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text(
                            '詳細を見る',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );

                if (shouldNavigate == true) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SubscriptionPremium()),
                  );
                }
                return;
              }

              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                final visitedRef = FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('visited_spots')
                    .doc(widget.spot.id);

                if (_isVisited) {
                  // 登録解除の確認ダイアログを表示
                  bool? confirmUnregister = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text(
                          '登録解除の確認',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        content: const Text(
                          'この聖地の登録を解除してもよろしいですか？',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(false); // キャンセル
                            },
                            child: const Text(
                              'キャンセル',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(true); // 解除を確定
                            },
                            child: const Text(
                              '解除',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red),
                            ),
                          ),
                        ],
                      );
                    },
                  );

                  // ユーザーが解除を確定した場合のみ実行
                  if (confirmUnregister == true) {
                    try {
                      await visitedRef.delete();
                      ref
                          .read(visitedSpotsProvider.notifier)
                          .removeVisitedSpot(widget.spot.id);
                      setState(() {
                        _isVisited = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('聖地の登録を解除しました')),
                      );
                    } catch (e) {
                      print('登録解除中にエラーが発生しました: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('登録解除に失敗しました')),
                      );
                    }
                  }
                } else {
                  await visitedRef.set({
                    'spotId': widget.spot.id,
                    'name': widget.spot['name'],
                    'address': widget.spot['address'],
                    'work': widget.spot['work'],
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                  ref
                      .read(visitedSpotsProvider.notifier)
                      .addVisitedSpot(widget.spot.id);
                  setState(() {
                    _isVisited = true;
                  });

                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text(
                          '登録完了',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                        content: const Text(
                          '訪れた聖地に登録しました！\nこの聖地の記録を書きますか？',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SeichiRegistrationPage(spot: widget.spot),
                                ),
                              );
                            },
                            child: const Text(
                              '記録を書く',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('後で'),
                          ),
                        ],
                      );
                    },
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('訪れた聖地として登録するにはログインが必要です')),
                );
              }
            },
          ),
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: Colors.white,
            ),
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                final bookmarkRef = FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('bookmarks')
                    .doc(widget.spot.id);

                if (_isBookmarked) {
                  await bookmarkRef.delete();
                } else {
                  await bookmarkRef.set({
                    'spotId': widget.spot.id,
                    'name': widget.spot['name'],
                    'address': widget.spot['address'],
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                }

                setState(() {
                  _isBookmarked = !_isBookmarked;
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ブックマークするにはログインが必要です')),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 250,
              child: _spotLocation == null
                  ? const Center(child: CircularProgressIndicator())
                  : GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _spotLocation!,
                        zoom: 15,
                      ),
                      markers: _markers,
                    ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.spot['name'],
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: _averageRating,
                        itemBuilder: (context, index) => const Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        itemCount: 5,
                        itemSize: 20.0,
                        direction: Axis.horizontal,
                      ),
                      Text(
                        ' (${_averageRating.toStringAsFixed(1)})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text('・基本情報',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const Divider(color: Colors.grey),
                  _buildInfoRow('住所', widget.spot['address']),
                  const SizedBox(height: 8),
                  const Divider(color: Colors.grey),
                  _buildInfoRow('地図', 'Google Mapsを開く'),
                  const SizedBox(height: 8),
                  const Divider(color: Colors.grey),
                  const SizedBox(height: 32),
                  const Text('・作品名',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(widget.spot['work'],
                      style: const TextStyle(
                          fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final animeInfo = _getAnimeInfo(widget.spot['work']);
                      if (animeInfo != null) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset(
                              animeInfo.imageAsset,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: () => _launchURL(animeInfo.imageUrl),
                              child: Text(
                                '出典元: ${animeInfo.imageUrl}',
                                style: const TextStyle(
                                  fontSize: 8,
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 16),
                  Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            children: [
                              if (widget.spot['imageURL'] != null && 
                                  widget.spot['imageURL'].toString().isNotEmpty) ...[
                                Image.network(
                                  widget.spot['imageURL'],
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                                const SizedBox(height: 16),
                              ] else ...[
                                Container(
                                  width: double.infinity,
                                  height: 200,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              Text(
                                widget.spot['detail'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '登場シーン',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Center(
                      child: Text('口コミ ${_reviews.length}件',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 32),
                  _reviews.isEmpty
                      ? const Center(
                          child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Text('口コミはありません'),
                        ))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _reviews.length,
                          itemBuilder: (context, index) {
                            final review = _reviews[index];
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Card(
                                elevation: 10,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (review['imageUrl'] != null)
                                      ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                backgroundImage:
                                                    review['userProfileImage'] !=
                                                            null
                                                        ? NetworkImage(review[
                                                            'userProfileImage'])
                                                        : null,
                                                child:
                                                    review['userProfileImage'] ==
                                                            null
                                                        ? const Icon(
                                                            Icons.person)
                                                        : null,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      review['userName'],
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                    Text(
                                                      '投稿日: ${DateFormat('yyyy年MM月dd日 HH時mm分').format(review['timestamp'].toDate())}',
                                                      style: TextStyle(
                                                          color:
                                                              Colors.grey[600],
                                                          fontSize: 12),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              IconButton(
                                                onPressed: () {
                                                  showModalBottomSheet(
                                                    context: context,
                                                    builder:
                                                        (BuildContext context) {
                                                      return Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: <Widget>[
                                                          if (review[
                                                                  'userId'] ==
                                                              FirebaseAuth
                                                                  .instance
                                                                  .currentUser
                                                                  ?.uid)
                                                            ListTile(
                                                              leading: const Icon(
                                                                  Icons.delete,
                                                                  color: Colors
                                                                      .red),
                                                              title: const Text(
                                                                  '削除する',
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .red)),
                                                              onTap: () async {
                                                                final bool?
                                                                    confirmDelete =
                                                                    await showDialog<
                                                                        bool>(
                                                                  context:
                                                                      context,
                                                                  builder:
                                                                      (BuildContext
                                                                          context) {
                                                                    return AlertDialog(
                                                                      title: const Text(
                                                                          '確認'),
                                                                      content:
                                                                          const Text(
                                                                              'この口コミを削除してもよろしいですか？'),
                                                                      actions: <Widget>[
                                                                        TextButton(
                                                                          child:
                                                                              const Text('キャンセル'),
                                                                          onPressed: () =>
                                                                              Navigator.of(context).pop(false),
                                                                        ),
                                                                        TextButton(
                                                                          child: const Text(
                                                                              '削除',
                                                                              style: TextStyle(color: Colors.red)),
                                                                          onPressed: () =>
                                                                              Navigator.of(context).pop(true),
                                                                        ),
                                                                      ],
                                                                    );
                                                                  },
                                                                );

                                                                if (confirmDelete ==
                                                                    true) {
                                                                  try {
                                                                    await FirebaseFirestore
                                                                        .instance
                                                                        .collection(
                                                                            'reviews')
                                                                        .doc(review
                                                                            .id)
                                                                        .delete();

                                                                    Navigator.of(
                                                                            context)
                                                                        .pop();
                                                                    ScaffoldMessenger.of(
                                                                            context)
                                                                        .showSnackBar(
                                                                      const SnackBar(
                                                                          content:
                                                                              Text('口コミを削除しました')),
                                                                    );
                                                                    _fetchReviews();
                                                                  } catch (e) {
                                                                    print(
                                                                        '口コミの削除中にエラーが発生しました: $e');
                                                                    ScaffoldMessenger.of(
                                                                            context)
                                                                        .showSnackBar(
                                                                      const SnackBar(
                                                                          content:
                                                                              Text('口コミの削除に失敗しました')),
                                                                    );
                                                                  }
                                                                } else {
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop();
                                                                }
                                                              },
                                                            )
                                                          else ...[
                                                            ListTile(
                                                              leading: const Icon(
                                                                  Icons.flag,
                                                                  color: Colors
                                                                      .red),
                                                              title: const Text(
                                                                  '報告する',
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .red)),
                                                              onTap: () async {
                                                                final String?
                                                                    reportReason =
                                                                    await showDialog<
                                                                        String>(
                                                                  context:
                                                                      context,
                                                                  builder:
                                                                      (BuildContext
                                                                          context) {
                                                                    return _ReportDialog();
                                                                  },
                                                                );

                                                                if (reportReason !=
                                                                    null) {
                                                                  try {
                                                                    await FirebaseFirestore
                                                                        .instance
                                                                        .collection(
                                                                            'reports')
                                                                        .add({
                                                                      'reviewId':
                                                                          review
                                                                              .id,
                                                                      'reporterId': FirebaseAuth
                                                                          .instance
                                                                          .currentUser
                                                                          ?.uid,
                                                                      'reason':
                                                                          reportReason,
                                                                      'timestamp':
                                                                          FieldValue
                                                                              .serverTimestamp(),
                                                                    });

                                                                    ScaffoldMessenger.of(
                                                                            context)
                                                                        .showSnackBar(
                                                                      const SnackBar(
                                                                          content:
                                                                              Text('報告を受け付けました。')),
                                                                    );
                                                                  } catch (e) {
                                                                    print(
                                                                        '報告の送信中にエラーが発生しました: $e');
                                                                    ScaffoldMessenger.of(
                                                                            context)
                                                                        .showSnackBar(
                                                                      const SnackBar(
                                                                          content:
                                                                              Text('報告の送信失敗しました。')),
                                                                    );
                                                                  }
                                                                }
                                                                Navigator.pop(
                                                                    context);
                                                              },
                                                            ),
                                                          ],
                                                          ListTile(
                                                            leading: const Icon(
                                                                Icons.cancel),
                                                            title: const Text(
                                                                'キャンセル'),
                                                            onTap: () {
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                },
                                                icon:
                                                    const Icon(Icons.more_vert),
                                              )
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              RatingBarIndicator(
                                                rating:
                                                    review['rating'].toDouble(),
                                                itemBuilder: (context, index) =>
                                                    const Icon(
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
                                            style: TextStyle(
                                                color: Colors.grey[800]),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (BuildContext context) {
                  return ReviewForm(spot: widget.spot);
                },
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
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child:
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: label == '地図'
              ? GestureDetector(
                  onTap: () => _launchMaps(widget.spot['address']),
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                )
              : Text(value),
        ),
      ],
    );
  }

  Future<void> _launchMaps(String address) async {
    final url = Uri.encodeFull(
        'https://www.google.com/maps/search/?api=1&query=$address');
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw '地図を開けませんでした: $url';
    }
  }
}

class ReviewForm extends StatefulWidget {
  final DocumentSnapshot spot;

  const ReviewForm({super.key, required this.spot});

  @override
  ReviewFormState createState() => ReviewFormState();
}

class ReviewFormState extends State<ReviewForm> {
  final _formKey = GlobalKey<FormState>();
  final _reviewController = TextEditingController();
  int _rating = 1;
  XFile? _image;
  bool _isPickingImage = false;
  bool _showImageError = false; // 追加

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    setState(() {
      _isPickingImage = true;
      _showImageError = false; // 画像を選択した際にエラーをリセット
    });

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      setState(() {
        _image = image;
      });
    } catch (e) {
      print('画像選択中にエラーが発生しました: $e');
    } finally {
      setState(() {
        _isPickingImage = false;
      });
    }
  }

  Future<String?> _uploadImage(XFile image) async {
    try {
      final storageRef = FirebaseStorage.instance.ref();
      final imageRef = storageRef
          .child('images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = imageRef.putFile(File(image.path));
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('画像のアップロード中にエラーが発生しました: $e');
      return null;
    }
  }

  Future<void> _submitReview() async {
    setState(() {
      _showImageError = _image == null;
    });

    if (_formKey.currentState!.validate() && _image != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String? imageUrl;
        if (_image != null) {
          imageUrl = await _uploadImage(_image!);
        }

        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final userName = userDoc['username'];
        final userProfileImage = userDoc['profileImage'];

        await FirebaseFirestore.instance.collection('reviews').add({
          'userId': user.uid,
          'userName': userName,
          'userProfileImage': userProfileImage,
          'spotId': widget.spot.id,
          'work': widget.spot['work'],
          'rating': _rating,
          'review': _reviewController.text,
          'imageUrl': imageUrl,
          'timestamp': FieldValue.serverTimestamp(),
        });
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('口コミを投稿',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('写真を追加',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _image == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo,
                                    size: 64, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('タップして写真を追加',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            )
                          : Image.file(
                              File(_image!.path),
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  if (_showImageError)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '画像を選択してください。',
                        style: TextStyle(color: Colors.red[700], fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text('聖地の評価',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  RatingBar.builder(
                    initialRating: _rating.toDouble(),
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: false,
                    itemCount: 5,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                    itemBuilder: (context, _) => const Icon(
                      Icons.star,
                      color: Colors.orange,
                    ),
                    onRatingUpdate: (rating) {
                      setState(() {
                        _rating = rating.toInt();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('口コミの内容',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _reviewController,
                    decoration: const InputDecoration(
                      hintText: '聖地の感想を書いてください',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '口コミの内容を入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('投稿する',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportDialog extends StatefulWidget {
  @override
  _ReportDialogState createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final List<String> _reportReasons = [
    '不適なコンテンツ',
    'スパムまたは広告',
    '誤った情報',
    'その他',
  ];
  String? _selectedReason;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('報告理由を選択してください',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_reportReasons.length, (index) {
          return RadioListTile<String>(
            title: Text(_reportReasons[index]),
            value: _reportReasons[index],
            groupValue: _selectedReason,
            onChanged: (String? value) {
              setState(() {
                _selectedReason = value;
              });
            },
          );
        }),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('キャンセル'),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        TextButton(
          child: const Text('報告する'),
          onPressed: () {
            Navigator.of(context).pop(_selectedReason);
          },
        ),
      ],
    );
  }
}