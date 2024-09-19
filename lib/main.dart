import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Library',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Library'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  GoogleMapController? mapController;
  LatLng _center = const LatLng(35.6895, 139.6917);
  Set<Marker> _markers = {};
  bool _isLoading = true;
  String? _placeApiKey;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final String configString = await rootBundle.loadString('assets/config/config.json');
    final Map<String, dynamic> config = json.decode(configString);
    setState(() {
      _placeApiKey = config['place_api_key'];
    });
    _getCurrentLocationAndNearbyLibraries();
  }

  Future<void> _getCurrentLocationAndNearbyLibraries() async {
    try {
      Position position = await _determinePosition();
      setState(() {
        _center = LatLng(position.latitude, position.longitude);
      });
      await _getNearbyLibraries();
      setState(() {
        _isLoading = false;
      });
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

  Future<void> _getNearbyLibraries() async {
    if (_placeApiKey == null) {
      print('Place APIキーが読み込まれていません');
      return;
    }

    final url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?'
        'location=${_center.latitude},${_center.longitude}'
        '&radius=5000'
        '&type=library'
        '&language=ja'
        '&key=$_placeApiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List<dynamic>;

      setState(() {
        _markers = results.map((place) {
          final location = place['geometry']['location'];
          return Marker(
            markerId: MarkerId(place['place_id']),
            position: LatLng(location['lat'], location['lng']),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: place['name'],
            ),
          );
        }).toSet();
      });
    } else {
      print('図書館データの取得に失敗しました');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
    });
    // 'addListener' メソッドは存在しないため、以下の行を削除します
    // controller.addListener(_onCameraMove);
  }

  void _onCameraMove() {
    if (mapController != null) {
      mapController!.getVisibleRegion().then((visibleRegion) {
        LatLng center = LatLng(
          (visibleRegion.northeast.latitude + visibleRegion.southwest.latitude) / 2,
          (visibleRegion.northeast.longitude + visibleRegion.southwest.longitude) / 2,
        );
        _updateNearbyLibraries(center);
      });
    }
  }

  Future<void> _updateNearbyLibraries(LatLng center) async {
    setState(() {
      _center = center;
    });
    await _getNearbyLibraries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 13.0,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onCameraIdle: _onCameraMove, // カメラの移動が停止したときに呼び出される
            ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
        ],
        currentIndex: 0,
        onTap: (index) {
          
        },
      ),
    );
  }
}
