import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'spot_detail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/visited_spots_provider.dart';
import '../utils/seichi_request.dart';
import '../utils/search_anime.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  GoogleMapController? mapController;
  LatLng _center = const LatLng(35.6895, 139.6917);
  Set<Marker> _markers = {};
  bool _isLoading = true;
  OverlayEntry? _overlayEntry;

  final TextEditingController _searchController = TextEditingController();
  bool _showOnlyVisited = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _fetchVisitedSpots();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await _determinePosition();
      setState(() {
        _center = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
      _fetchSpots();
    } catch (e) {
      print('エラーが発生しました: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('位置情報サービスが無効です。');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('位置情報の権限が永久に拒否されました。設定から変更してください。');
    }

    return await Geolocator.getCurrentPosition();
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
    });
    controller.setMapStyle('''
      [
        {
          "featureType": "poi",
          "elementType": "labels",
          "stylers": [
            {
              "visibility": "off"
            }
          ]
        }
      ]
    ''');
  }

  Future<void> _fetchSpots() async {
    Query spotsQuery = FirebaseFirestore.instance.collection('spots');

    QuerySnapshot snapshot = await spotsQuery.get();
    Set<Marker> newMarkers = {};
    final visitedSpots = ref.read(visitedSpotsProvider);

    for (var doc in snapshot.docs) {
      try {
        GeoPoint location = doc['location'];
        bool isVisited = visitedSpots.containsKey(doc.id);

        if (!_showOnlyVisited || isVisited) {
          newMarkers.add(Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(location.latitude, location.longitude),
            icon: isVisited
                ? BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueBlue)
                : BitmapDescriptor.defaultMarker,
            infoWindow: InfoWindow(
              title: doc['name'],
              snippet: doc['work'],
            ),
            onTap: () => _showSpotDetails(doc),
          ));
        }
      } catch (e) {
        print('エラーが発生しました: ${doc['name']} - $e');
      }
    }

    setState(() {
      _markers = newMarkers;
      _isLoading = false;
    });
  }

  void _showSpotDetails(DocumentSnapshot spot) async {
    _removeOverlay();
    int reviewCount = await _getReviewCount(spot.id);
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 30,
        left: 20,
        right: 20,
        child: Material(
          elevation: 4.0,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  spot['name'],
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(spot['address']),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                    const SizedBox(width: 5),
                    Text('$reviewCount件',
                        style: const TextStyle(color: Colors.blue)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '作品名: ${spot['work']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    _removeOverlay();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SpotDetailPage(spot: spot)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('聖地ページへ',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  Future<int> _getReviewCount(String spotId) async {
    QuerySnapshot reviewSnapshot = await FirebaseFirestore.instance
        .collection('reviews')
        .where('spotId', isEqualTo: spotId)
        .get();
    return reviewSnapshot.docs.length;
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _fetchVisitedSpots() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final visitedSpotsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('visited_spots')
          .get();

      final visitedSpots = visitedSpotsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'spotId': data['spotId'],
          'spotName': data['spotName'],
        };
      }).toList();

      ref.read(visitedSpotsProvider.notifier).setVisitedSpots(visitedSpots);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(visitedSpotsProvider, (previous, next) {
      _fetchSpots();
    });

    return Scaffold(
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _center,
                    zoom: 10.0,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  onTap: (_) => _removeOverlay(),
                ),
          Positioned(
            top: 50,
            left: 10,
            right: 10,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: '聖地名、作品名で検索',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          fullscreenDialog: true,
                          builder: (BuildContext context) =>
                              AnimeSearchBottomSheet(
                            onSpotSelected: (spot) {
                              final data = spot.data() as Map<String, dynamic>;
                              final location = data['location'] as GeoPoint;
                              
                              setState(() {
                                _searchController.text = data['name'] ?? '';
                              });

                              mapController?.animateCamera(
                                CameraUpdate.newCameraPosition(
                                  CameraPosition(
                                    target: LatLng(
                                      location.latitude,
                                      location.longitude,
                                    ),
                                    zoom: 15.0,
                                  ),
                                ),
                              );

                              _showSpotDetails(spot);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return const SpotRequestDialog();
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(15),
                  ),
                  child: const Icon(Icons.add_location, size: 30),
                ),
              ],
            ),
          ),
          Positioned(
            top: 110,
            left: 10,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _showOnlyVisited = !_showOnlyVisited;
                });
                _fetchSpots();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _showOnlyVisited ? Colors.blue : Colors.grey,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '登録済み',
                    style: TextStyle(
                      color: Colors.white,
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

  @override
  void dispose() {
    _removeOverlay();
    _searchController.dispose();
    mapController?.dispose();
    super.dispose();
  }
}