import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/anime_lists.dart';
import '../utils/review_form.dart';
import 'subscription_premium.dart';
import '../providers/subscription_state.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../ad/ad_reward.dart';
import 'dart:ui';
import '../utils/seichi_spots.dart';
import '../utils/review_list_widget.dart';
import '../utils/report.dart';

class SpotDetailPage extends ConsumerStatefulWidget {
  final SeichiSpot spot;

  const SpotDetailPage({super.key, required this.spot});

  @override
  SpotDetailPageState createState() => SpotDetailPageState();
}

class SpotDetailPageState extends ConsumerState<SpotDetailPage> {
  List<DocumentSnapshot> _reviews = [];
  bool _isBookmarked = false;
  double _averageRating = 0.0;
  final RewardAdManager _rewardAdManager = RewardAdManager();
  bool _hasWatchedAd = false;

  @override
  void initState() {
    super.initState();
    _getSpotLocation();
    _fetchReviews().then((_) => _calculateAverageRating());
    _checkBookmarkStatus();
    _rewardAdManager.initialize().then((_) {}).catchError((error) {});

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bool isReward = widget.spot.isReward;
      final isPremium = ref.read(subscriptionProvider).value ?? false;

      if (isReward && !_hasWatchedAd && !isPremium) {
        _showRewardAdDialog();
      }
    });
  }

  LatLng? _spotLocation;
  final Set<Marker> _markers = {};

  Future<void> _getSpotLocation() async {
    try {
      setState(() {
        _spotLocation = LatLng(widget.spot.latitude, widget.spot.longitude);
        _markers.add(Marker(
          markerId: MarkerId(widget.spot.id),
          position: _spotLocation!,
        ));
      });
    } catch (e) {
      // エラー処理
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

  Future<void> _showRewardAdDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.watchAdToUnlock,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(l10n.premiumAdFree,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '👑PREMIUM PLAN👑',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.cancel),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text(l10n.watchAd,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (result == true) {
      try {
        final bool adWatched = await _rewardAdManager.showRewardedAd();

        if (adWatched) {
          setState(() {
            _hasWatchedAd = true;
          });
        } else {
          _rewardAdManager.loadRewardedAd();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.adLoadError)),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.adLoadError)),
          );
        }
      }
    } else {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _showReportDialog(String reviewId) async {
    final l10n = AppLocalizations.of(context)!;
    final String? reportReason = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return const ReportDialog();
      },
    );

    if (reportReason != null) {
      try {
        await FirebaseFirestore.instance.collection('reports').add({
          'reviewId': reviewId,
          'reporterId': FirebaseAuth.instance.currentUser?.uid,
          'reason': reportReason,
          'timestamp': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.reportReceived)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.reportFailed)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isReward = widget.spot.isReward;
    final isPremium = ref.watch(subscriptionProvider).value ?? false;

    return DefaultTabController(
      length: 2,
      child: Stack(children: [
        Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            title: Text(widget.spot.name,
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
                        'name': widget.spot.name,
                        'address': widget.spot.address,
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
                    AppLocalizations.of(context)!.photos,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              labelColor: Colors.white,
              indicatorColor: Colors.white,
            ),
            iconTheme: const IconThemeData(color: Colors.white),
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
                            widget.spot.name,
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              widget.spot.imageURL,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 4),
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
                                ' ${_averageRating.toStringAsFixed(1)}',
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
                          const Divider(color: Colors.black),
                          _buildInfoRow(AppLocalizations.of(context)!.address,
                              widget.spot.address),
                          const SizedBox(height: 8),
                          const Divider(color: Colors.black),
                          _buildInfoRow(AppLocalizations.of(context)!.map,
                              'Google Mapsを開く'),
                          const SizedBox(height: 8),
                          const Divider(color: Colors.black),
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
                          Text(widget.spot.workName,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Builder(
                            builder: (context) {
                              final animeInfo =
                                  _getAnimeInfo(widget.spot.workName);
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
                                      onTap: () =>
                                          _launchURL(animeInfo.imageUrl),
                                      child: Text(
                                        '${AppLocalizations.of(context)!.sourceImage}: ${animeInfo.imageUrl}',
                                        style: const TextStyle(
                                          fontSize: 8,
                                          color: Colors.blue,
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
                                margin:
                                    const EdgeInsets.symmetric(vertical: 16),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 16),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.blue, width: 2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Column(
                                    children: [
                                      if (widget.spot.imageURL.isNotEmpty) ...[
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.network(
                                            widget.spot.imageURL,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        InkWell(
                                          onTap: () =>
                                              _launchURL(widget.spot.source),
                                          child: Text(
                                            '${AppLocalizations.of(context)!.sourceImage}: ${widget.spot.source}',
                                            style: const TextStyle(
                                              fontSize: 8,
                                              color: Colors.blue,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
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
                                        widget.spot.detail,
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
                          GestureDetector(
                            onTap: () => _launchURL(
                                'https://tr.affiliate-sp.docomo.ne.jp/cl/d0000002559/3326/215'),
                            child: Image.network(
                              'https://img.affiliate-sp.docomo.ne.jp/ad/d0000002559/215.png',
                              width: double.infinity,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Center(
                              child: Text(
                                  '${AppLocalizations.of(context)!.kuchikomi} ${_reviews.length}${AppLocalizations.of(context)!.reviews}',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold))),
                          const SizedBox(height: 32),
                          ReviewListWidget(
                            reviews: _reviews,
                            onReportTap: (reviewId) {
                              _showReportDialog(reviewId);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [],
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
                      content:
                          Text(AppLocalizations.of(context)!.loginRequired)),
                );
              }
            },
            backgroundColor: Colors.blue,
            child: const Icon(Icons.edit, color: Colors.white),
          ),
        ),
        if (isReward && !_hasWatchedAd && !isPremium)
          BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 10.0,
              sigmaY: 10.0,
            ),
            child: Container(
              color: Colors.white.withOpacity(0.5),
              child: const SizedBox.expand(),
            ),
          ),
      ]),
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
                  onTap: () => _launchMaps(widget.spot.address),
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

  @override
  void dispose() {
    _rewardAdManager.dispose();
    super.dispose();
  }
}
