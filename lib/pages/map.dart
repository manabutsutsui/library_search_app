import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'spot_detail.dart';
import '../utils/seichi_request.dart';
import '../utils/search_anime.dart';
import '../utils/spot_data.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/seichi_spots.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? mapController;
  LatLng _center = const LatLng(35.6895, 139.6917);
  Set<Marker> _markers = {};
  bool _isLoading = true;
  OverlayEntry? _overlayEntry;

  final TextEditingController _searchController = TextEditingController();
  List<SpotData> _allSpots = [];

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      Position position = await _determinePosition();
      if (mounted) {
        setState(() {
          _center = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });
        _fetchSpots();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('location_service_disabled');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('location_permission_denied');
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

    _updateVisibleMarkers();
  }

  Future<void> _fetchSpots() async {
    _allSpots = seichiSpots
        .map((spot) => SpotData.fromSeichiSpot(spot, false))
        .toList();

    _updateMarkers();
  }

  void _updateMarkers() {
    Set<Marker> newMarkers = {};

    for (var spot in _allSpots) {
      newMarkers.add(Marker(
        markerId: MarkerId(spot.id),
        position: spot.location,
        icon: BitmapDescriptor.defaultMarker,
        onTap: () => _showSpotDetailsFromSeichiSpot(spot.id),
      ));
    }

    setState(() {
      _markers = newMarkers;
    });
  }

  Future<void> _updateVisibleMarkers() async {
    if (mapController == null) return;

    final visibleRegion = await mapController!.getVisibleRegion();
    Set<Marker> newMarkers = {};

    for (var spot in _allSpots) {
      if (_isLocationVisible(
        spot.location,
        visibleRegion.southwest,
        visibleRegion.northeast,
      )) {
        newMarkers.add(Marker(
          markerId: MarkerId(spot.id),
          position: spot.location,
          icon: BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(
            title: spot.name,
            snippet: spot.work,
          ),
          onTap: () => _showSpotDetailsFromSeichiSpot(spot.id),
        ));
      }
    }

    setState(() {
      _markers = newMarkers;
    });
  }

  bool _isLocationVisible(LatLng point, LatLng southwest, LatLng northeast) {
    return point.latitude >= southwest.latitude &&
        point.latitude <= northeast.latitude &&
        point.longitude >= southwest.longitude &&
        point.longitude <= northeast.longitude;
  }

  void _showSpotDetailsFromSeichiSpot(String spotId) {
    _removeOverlay();
    final seichiSpot = seichiSpots.firstWhere((spot) => spot.id == spotId);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 20,
        left: 20,
        right: 20,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          seichiSpot.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        FutureBuilder<QuerySnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('reviews')
                              .where('spotId', isEqualTo: seichiSpot.id)
                              .get(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              );
                            }

                            final reviewCount = snapshot.data?.docs.length ?? 0;

                            return Row(
                              children: [
                                const Icon(Icons.comment, color: Colors.blue),
                                const SizedBox(width: 4),
                                Text(
                                  '$reviewCount${AppLocalizations.of(context)!.reviews}',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${AppLocalizations.of(context)!.workName}: ${seichiSpot.workName}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _removeOverlay();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SpotDetailPage(
                        spot: seichiSpot,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  minimumSize: const Size(double.infinity, 45),
                ),
                child: Text(
                  AppLocalizations.of(context)!.toHolyPlacePage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _center,
                    zoom: 12.0,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  onTap: (_) => _removeOverlay(),
                  onCameraIdle: _updateVisibleMarkers,
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
                      hintText: l10n.searchSpot,
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
                              setState(() {
                                _searchController.text = spot.name;
                              });

                              mapController?.animateCamera(
                                CameraUpdate.newCameraPosition(
                                  CameraPosition(
                                    target: LatLng(
                                      spot.latitude,
                                      spot.longitude,
                                    ),
                                    zoom: 15.0,
                                  ),
                                ),
                              );

                              _showSpotDetailsFromSeichiSpot(spot.id);
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
                    backgroundColor: Colors.blue,
                  ),
                  child: const Icon(Icons.add_location,
                      size: 30, color: Colors.white),
                ),
              ],
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