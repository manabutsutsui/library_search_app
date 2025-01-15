import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/anime_lists.dart';
import '../utils/kuchikomi.dart';
import '../utils/report.dart';
import 'subscription_premium.dart';
import '../providers/subscription_state.dart';
import '../utils/seichi_note.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
      // print('${l10n.errorOccurred}: $e');
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
      orElse: () =>
          AnimeList(name: '', genre: '', imageAsset: '', imageUrl: ''),
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
          bottom: TabBar(
            tabs: [
              Tab(
                child: Text(
                  AppLocalizations.of(context)!.information,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Tab(
                child: Text(
                  AppLocalizations.of(context)!.note,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
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
                        Text(AppLocalizations.of(context)!.basicInformation,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        const Divider(color: Colors.grey),
                        _buildInfoRow(AppLocalizations.of(context)!.address,
                            widget.spot['address']),
                        const SizedBox(height: 8),
                        const Divider(color: Colors.grey),
                        _buildInfoRow(AppLocalizations.of(context)!.map,
                            'Google Mapsを開く'),
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
                        Text('・${AppLocalizations.of(context)!.workName}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
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
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      animeInfo.imageAsset,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  InkWell(
                                    onTap: () => _launchURL(animeInfo.imageUrl),
                                    child: Text(
                                      '${AppLocalizations.of(context)!.sourceImage}: ${animeInfo.imageUrl}',
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
                                child: Column(
                                  children: [
                                    if (widget.spot['imageURL'] != null &&
                                        widget.spot['imageURL']
                                            .toString()
                                            .isNotEmpty) ...[
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          widget.spot['imageURL'],
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Builder(
                                        builder: (context) {
                                          return InkWell(
                                            onTap: () => _launchURL(
                                                widget.spot['source']),
                                            child: Text(
                                              '${AppLocalizations.of(context)!.sourceImage}: ${widget.spot['source'] ?? ''}',
                                              style: const TextStyle(
                                                fontSize: 8,
                                                color: Colors.blue,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                              textAlign: TextAlign.center,
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
                                child: Text(
                                  AppLocalizations.of(context)!.scene,
                                  style: const TextStyle(
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
                            child: Text(
                                '${AppLocalizations.of(context)!.kuchikomi} ${_reviews.length}${AppLocalizations.of(context)!.reviews}',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold))),
                        const SizedBox(height: 32),
                        _reviews.isEmpty
                            ? Center(
                                child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16.0),
                                child: Text(
                                    AppLocalizations.of(context)!.noReviews),
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
                                                            '${AppLocalizations.of(context)!.postedDate}: ${DateFormat('yyyy年MM月dd日 HH時mm分').format(review['timestamp'].toDate())}',
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
                                                                    title: Text(
                                                                        AppLocalizations.of(context)!
                                                                            .delete,
                                                                        style: const TextStyle(
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
                                                                                Text(AppLocalizations.of(context)!.confirm),
                                                                            content:
                                                                                Text(AppLocalizations.of(context)!.deleteReviewConfirm, style: const TextStyle(fontSize: 12)),
                                                                            actions: <Widget>[
                                                                              TextButton(
                                                                                child: Text(AppLocalizations.of(context)!.cancel),
                                                                                onPressed: () => Navigator.of(context).pop(false),
                                                                              ),
                                                                              TextButton(
                                                                                child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red)),
                                                                                onPressed: () => Navigator.of(context).pop(true),
                                                                              ),
                                                                            ],
                                                                          );
                                                                        },
                                                                      );

                                                                      if (confirmDelete ==
                                                                          true) {
                                                                        try {
                                                                          // 画像がある場合、Storageから削除
                                                                          if (review['imageUrl'] !=
                                                                              null) {
                                                                            try {
                                                                              final storageRef = FirebaseStorage.instance.refFromURL(review['imageUrl']);
                                                                              await storageRef.delete();
                                                                            } catch (e) {
                                                                              // print('画像の削除中にエラーが発生しました: $e');
                                                                            }
                                                                          }

                                                                          // Firestoreから口コミを削除
                                                                          await FirebaseFirestore
                                                                              .instance
                                                                              .collection('reviews')
                                                                              .doc(review.id)
                                                                              .delete();

                                                                          Navigator.of(context)
                                                                              .pop();
                                                                          ScaffoldMessenger.of(context)
                                                                              .showSnackBar(
                                                                            SnackBar(content: Text(AppLocalizations.of(context)!.reviewDeleted)),
                                                                          );
                                                                          _fetchReviews();
                                                                        } catch (e) {
                                                                          // print('口コミの削除中にエラーが発生しました: $e');
                                                                          ScaffoldMessenger.of(context)
                                                                              .showSnackBar(
                                                                            SnackBar(content: Text(AppLocalizations.of(context)!.reviewDeleteError)),
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
                                                                    title: Text(
                                                                        AppLocalizations.of(context)!
                                                                            .report,
                                                                        style: const TextStyle(
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
                                                                            SnackBar(content: Text(AppLocalizations.of(context)!.reportReceived)),
                                                                          );
                                                                        } catch (e) {
                                                                          // print(
                                                                          //     '報告の送信中にエラーが発生しました: $e');
                                                                          ScaffoldMessenger.of(context)
                                                                              .showSnackBar(
                                                                            SnackBar(content: Text(AppLocalizations.of(context)!.reportFailed)),
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
                                                                  title: Text(
                                                                      AppLocalizations.of(
                                                                              context)!
                                                                          .cancel),
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
                                                    Text(
                                                        ': ${AppLocalizations.of(context)!.seichitourokuSatisfaction}'),
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
                        final subscriptionState =
                            ref.watch(subscriptionProvider);

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
                                          builder: (context) =>
                                              const SubscriptionPremium(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                    ),
                                    child: Text(
                                      AppLocalizations.of(context)!
                                          .premiumPlanLimitedFunction,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const SubscriptionPremium(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16.0),
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              '👑 ${AppLocalizations.of(context)!.premiumPlanLimitedFunction} 👑',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          AppLocalizations.of(context)!
                                              .premiumPlanLimitedFunctionDescription,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          AppLocalizations.of(context)!
                                              .premiumPlanLimitedFunctionDescription2,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          '<<${AppLocalizations.of(context)!.premiumPlanLimitedFunctionDescription3}>>',
                                          style: const TextStyle(
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
                                        builder: (context) =>
                                            const SubscriptionPremium(),
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
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
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
                SnackBar(
                    content: Text(AppLocalizations.of(context)!.loginRequired)),
              );
            }
          },
          backgroundColor: Colors.blue,
          child: const Icon(Icons.edit, color: Colors.white),
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
          child: label == AppLocalizations.of(context)!.map
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
