import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'anime_lists.dart';
import 'utils/kuchikomi.dart';
import 'utils/report.dart';
import 'subscription_premium.dart';
import 'providers/subscription_state.dart';
import 'utils/seichi_note.dart';
import 'dart:ui';

class SpotDetailPage extends ConsumerStatefulWidget {
  final DocumentSnapshot spot;

  const SpotDetailPage({super.key, required this.spot});

  @override
  SpotDetailPageState createState() => SpotDetailPageState();
}

class SpotDetailPageState extends ConsumerState<SpotDetailPage> {
  List<DocumentSnapshot> _reviews = [];
  bool _isBookmarked = false;
  double _averageRating = 0.0;

  @override
  void initState() {
    super.initState();
    _getSpotLocation();
    _fetchReviews().then((_) => _calculateAverageRating());
    _checkBookmarkStatus();
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
      throw 'URLを開けませでした: $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
          bottom: const TabBar(
            tabs: [
              Tab(
                child: Text(
                  '情報',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Tab(
                child: Text(
                  'ノート',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
            labelColor: Colors.white,
            indicatorColor: Colors.white,
          ),
        ),
        body: TabBarView(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
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
                        const Text('・聖地メモ',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Consumer(
                          builder: (context, ref, child) {
                            final subscriptionState = ref.watch(subscriptionProvider);
                            
                            return subscriptionState.when(
                              data: (isPro) {
                                if (isPro) {
                                  return FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(FirebaseAuth.instance.currentUser?.uid)
                                        .collection('seichi_notes')
                                        .doc(widget.spot.id)
                                        .get(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const Center(child: CircularProgressIndicator());
                                      }

                                      if (!snapshot.hasData || !snapshot.data!.exists) {
                                        return const SizedBox.shrink();
                                      }

                                      final noteData = snapshot.data!.data() as Map<String, dynamic>;
                                      final note = noteData['note'] as String?;

                                      if (note == null || note.isEmpty) {
                                        return const SizedBox.shrink();
                                      }

                                      return Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey[300]!),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              note,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                height: 1.5,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            const Text(
                                              '※このメモはあなただけに表示されています',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                }
                                return Column(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.blue,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Builder(
                                        builder: (BuildContext context) {
                                          return GestureDetector(
                                            onTap: () {
                                              DefaultTabController.of(context).animateTo(1);
                                            },
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.asset(
                                                'assets/subscription_images/seichi_note.png',
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Center(
                                      child: Text(
                                        '🔐あなたにだけ表示されます。',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color.fromARGB(255, 119, 119, 119),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (_, __) => const SizedBox.shrink(),
                            );
                          },
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
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: 200,
                            child: _spotLocation == null
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : GoogleMap(
                                    initialCameraPosition: CameraPosition(
                                      target: _spotLocation!,
                                      zoom: 15,
                                    ),
                                    markers: _markers,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text('・作品名',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(widget.spot['work'],
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Builder(
                          builder: (context) {
                            final animeInfo =
                                _getAnimeInfo(widget.spot['work']);
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.blue),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Consumer(
                                  builder: (context, ref, child) {
                                    final subscriptionState = ref.watch(subscriptionProvider);
                                    
                                    return subscriptionState.when(
                                      data: (isPro) {
                                        if (isPro) {
                                          return Column(
                                            children: [
                                              if (widget.spot['imageURL'] != null &&
                                                  widget.spot['imageURL'].toString().isNotEmpty) ...[
                                                Image.network(
                                                  widget.spot['imageURL'],
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                ),
                                                const SizedBox(height: 4),
                                                Builder(
                                                  builder: (context) {
                                                    final animeInfo = _getAnimeInfo(widget.spot['work']);
                                                    return InkWell(
                                                      onTap: () => _launchURL(animeInfo?.imageUrl ?? ''),
                                                      child: Center(
                                                        child: Text(
                                                          '出典元: ${animeInfo?.imageUrl ?? ''}',
                                                          style: const TextStyle(
                                                            fontSize: 8,
                                                            color: Colors.blue,
                                                            decoration: TextDecoration.underline,
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
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
                                          );
                                        } else {
                                          return Stack(
                                            children: [
                                              ImageFiltered(
                                                imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
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
                                              Positioned.fill(
                                                child: Center(
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
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 8,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.blue,
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: const Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.lock,
                                                            color: Colors.white,
                                                            size: 32,
                                                          ),
                                                          SizedBox(height: 8),
                                                          Text(
                                                            'Premiumプランで\n登場シーンを見る',
                                                            textAlign: TextAlign.center,
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        }
                                      },
                                      loading: () => const Center(child: CircularProgressIndicator()),
                                      error: (_, __) => const SizedBox.shrink(),
                                    );
                                  },
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
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold))),
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
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    child: Card(
                                      elevation: 10,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                                      backgroundImage: review[
                                                                  'userProfileImage'] !=
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
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            review['userName'],
                                                            style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                          ),
                                                          Text(
                                                            '投稿日: ${DateFormat('yyyy年MM月dd日 HH時mm分').format(review['timestamp'].toDate())}',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .grey[600],
                                                                fontSize: 12),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    IconButton(
                                                      onPressed: () {
                                                        showModalBottomSheet(
                                                          context: context,
                                                          builder: (BuildContext
                                                              context) {
                                                            return Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: <Widget>[
                                                                if (review[
                                                                        'userId'] ==
                                                                    FirebaseAuth
                                                                        .instance
                                                                        .currentUser
                                                                        ?.uid)
                                                                  ListTile(
                                                                    leading: const Icon(
                                                                        Icons
                                                                            .delete,
                                                                        color: Colors
                                                                            .red),
                                                                    title: const Text(
                                                                        '削除する',
                                                                        style: TextStyle(
                                                                            color:
                                                                                Colors.red)),
                                                                    onTap:
                                                                        () async {
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
                                                                            title:
                                                                                const Text('確認'),
                                                                            content:
                                                                                const Text('この口コミを削除してもよろしいですか？'),
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

                                                                      if (confirmDelete ==
                                                                          true) {
                                                                        try {
                                                                          await FirebaseFirestore
                                                                              .instance
                                                                              .collection('reviews')
                                                                              .doc(review.id)
                                                                              .delete();

                                                                          Navigator.of(context)
                                                                              .pop();
                                                                          ScaffoldMessenger.of(context)
                                                                              .showSnackBar(
                                                                            const SnackBar(content: Text('口コミを削除しました')),
                                                                          );
                                                                          _fetchReviews();
                                                                        } catch (e) {
                                                                          print(
                                                                              '口コミの削除中にエラーが発生しました: $e');
                                                                          ScaffoldMessenger.of(context)
                                                                              .showSnackBar(
                                                                            const SnackBar(content: Text('口コミの削除に失敗しました')),
                                                                          );
                                                                        }
                                                                      } else {
                                                                        Navigator.of(context)
                                                                            .pop();
                                                                      }
                                                                    },
                                                                  )
                                                                else ...[
                                                                  ListTile(
                                                                    leading: const Icon(
                                                                        Icons
                                                                            .flag,
                                                                        color: Colors
                                                                            .red),
                                                                    title: const Text(
                                                                        '報告する',
                                                                        style: TextStyle(
                                                                            color:
                                                                                Colors.red)),
                                                                    onTap:
                                                                        () async {
                                                                      final String?
                                                                          reportReason =
                                                                          await showDialog<
                                                                              String>(
                                                                        context:
                                                                            context,
                                                                        builder:
                                                                            (BuildContext
                                                                                context) {
                                                                          return const ReportDialog();
                                                                        },
                                                                      );

                                                                      if (reportReason !=
                                                                          null) {
                                                                        try {
                                                                          await FirebaseFirestore
                                                                              .instance
                                                                              .collection('reports')
                                                                              .add({
                                                                            'reviewId':
                                                                                review.id,
                                                                            'reporterId':
                                                                                FirebaseAuth.instance.currentUser?.uid,
                                                                            'reason':
                                                                                reportReason,
                                                                            'timestamp':
                                                                                FieldValue.serverTimestamp(),
                                                                          });

                                                                          ScaffoldMessenger.of(context)
                                                                              .showSnackBar(
                                                                            const SnackBar(content: Text('報告を受け付けました。')),
                                                                          );
                                                                        } catch (e) {
                                                                          print(
                                                                              '報告の送信中にエラーが発生しました: $e');
                                                                          ScaffoldMessenger.of(context)
                                                                              .showSnackBar(
                                                                            const SnackBar(content: Text('報告の送信失敗しました。')),
                                                                          );
                                                                        }
                                                                      }
                                                                      Navigator.pop(
                                                                          context);
                                                                    },
                                                                  ),
                                                                ],
                                                                ListTile(
                                                                  leading:
                                                                      const Icon(
                                                                          Icons
                                                                              .cancel),
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
                                                      icon: const Icon(
                                                          Icons.more_vert),
                                                    )
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    RatingBarIndicator(
                                                      rating: review['rating']
                                                          .toDouble(),
                                                      itemBuilder:
                                                          (context, index) =>
                                                              const Icon(
                                                        Icons.star,
                                                        color: Colors.orange,
                                                      ),
                                                      itemCount: 5,
                                                      itemSize: 20.0,
                                                      direction:
                                                          Axis.horizontal,
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
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Consumer(
                      builder: (context, ref, child) {
                        final subscriptionState = ref.watch(subscriptionProvider);
                        
                        return subscriptionState.when(
                          data: (isPro) {
                            if (isPro) {
                              return SeichiNote(spotId: widget.spot.id);
                            }
                            return Column(
                              children: [
                                Center(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const SubscriptionPremium(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                    ),
                                    child: const Text(
                                      'PREMIUMプラン 限定機能',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const SubscriptionPremium(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16.0),
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              '👑 PREMIUMプラン限定機能 👑',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 20),
                                        Text(
                                          'PREMIUMプランに加入すると、\n「ノート機能」が使えるようになります❗',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(height: 20),
                                        Text(
                                          '◆ あなただけに表示されるメモ\n◆ 写真を何枚でも保存できる',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(height: 20),
                                        Text(
                                          '<<詳細はこのメモをタップ👆>>',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                GestureDetector(
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
                              ],
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (_, __) => const SizedBox.shrink(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (BuildContext context) {
                    return ReviewForm(spot: widget.spot);
                  },
                ),
              );

              if (result == true) {
                await _fetchReviews();
                await _calculateAverageRating();
              }
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