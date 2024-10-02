import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'spot_detail.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  GoogleMapController? mapController;
  LatLng _center = const LatLng(35.6895, 139.6917);
  Set<Marker> _markers = {};
  bool _isLoading = true;
  OverlayEntry? _overlayEntry;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
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
  }

  Future<void> _fetchSpots() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('spots').get();
    Set<Marker> newMarkers = {};

    for (var doc in snapshot.docs) {
      try {
        String address = doc['address'];
        List<Location> locations = await locationFromAddress(address);
        if (locations.isNotEmpty) {
          newMarkers.add(Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(locations.first.latitude, locations.first.longitude),
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
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(spot['address']),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, color: Colors.orange),
                    const SizedBox(width: 5),
                    Text('$reviewCount件', style: const TextStyle(color: Colors.orange)),
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
                    _removeOverlay(); // オーバーレイを削除
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SpotDetailPage(spot: spot)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('聖地ページへ', style: TextStyle(color: Colors.white)),
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

  @override
  Widget build(BuildContext context) {
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
                  child: GestureDetector(
                    onTap: () {
                      showSearch(
                        context: context,
                        delegate: CustomSearchDelegate(spots: _markers),
                      );
                    },
                    child: AbsorbPointer(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: '映画名・アニメ名、聖地名',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
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
        ],
      ),
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _searchController.dispose();
    super.dispose();
  }
}

class CustomSearchDelegate extends SearchDelegate<String> {
  final Set<Marker> spots;

  CustomSearchDelegate({required this.spots});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<List<QuerySnapshot>>(
      future: Future.wait([
        FirebaseFirestore.instance.collection('spots')
            .where('name', isGreaterThanOrEqualTo: query)
            .where('name', isLessThan: query + 'z')
            .get(),
        FirebaseFirestore.instance.collection('spots')
            .where('work', isGreaterThanOrEqualTo: query)
            .where('work', isLessThan: query + 'z')
            .get(),
      ]),
      builder: (BuildContext context, AsyncSnapshot<List<QuerySnapshot>> snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('エラーが発生しました'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        List<DocumentSnapshot> allDocs = [];
        snapshot.data![0].docs.forEach((doc) => allDocs.add(doc));
        snapshot.data![1].docs.forEach((doc) => allDocs.add(doc));

        // 重複を削除
        allDocs = allDocs.toSet().toList();

        return ListView(
          children: allDocs.map((DocumentSnapshot document) {
            Map<String, dynamic> data = document.data() as Map<String, dynamic>;
            return ListTile(
              title: Text('聖地名: ${data['name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('作品名: ${data['work']}'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SpotDetailPage(spot: document)),
                );
              },
              trailing: const Icon(Icons.arrow_forward_ios),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '聖地名、または映画・アニメ名を入力して下さい。',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<QuerySnapshot>>(
            future: Future.wait([
              FirebaseFirestore.instance.collection('spots')
                  .where('name', isGreaterThanOrEqualTo: query)
                  .where('name', isLessThan: query + 'z')
                  .limit(3)
                  .get(),
              FirebaseFirestore.instance.collection('spots')
                  .where('work', isGreaterThanOrEqualTo: query)
                  .where('work', isLessThan: query + 'z')
                  .limit(3)
                  .get(),
            ]),
            builder: (BuildContext context, AsyncSnapshot<List<QuerySnapshot>> snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('エラーが発生しました'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              List<DocumentSnapshot> allDocs = [];
              snapshot.data![0].docs.forEach((doc) => allDocs.add(doc));
              snapshot.data![1].docs.forEach((doc) => allDocs.add(doc));

              // 重複を削除
              allDocs = allDocs.toSet().toList();

              return ListView(
                children: allDocs.map((DocumentSnapshot document) {
                  Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text('聖地名: ${data['name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('作品名: ${data['work']}'),
                    onTap: () {
                      query = data['name'];
                      showResults(context);
                    },
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}

class SpotRequestDialog extends StatefulWidget {
  const SpotRequestDialog({super.key});

  @override
  SpotRequestDialogState createState() => SpotRequestDialogState();
}

class SpotRequestDialogState extends State<SpotRequestDialog> {
  final TextEditingController _spotNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _workNameController = TextEditingController();
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: Colors.grey[900],
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text(
                '聖地をリクエスト',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_location,
                      size: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    const Text('あなたが追加したい聖地をリクエストできます。', style: TextStyle(color: Colors.white, fontSize: 16)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _spotNameController,
                      decoration: const InputDecoration(
                        hintText: '聖地名',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        hintText: '住所',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _workNameController,
                      decoration: const InputDecoration(
                        hintText: '作品名',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          _errorMessage = '';
                        });
                        if (_spotNameController.text.isNotEmpty &&
                            _addressController.text.isNotEmpty &&
                            _workNameController.text.isNotEmpty) {
                          try {
                            await FirebaseFirestore.instance.collection('spot_requests').add({
                              'spotName': _spotNameController.text,
                              'address': _addressController.text,
                              'workName': _workNameController.text,
                              'timestamp': FieldValue.serverTimestamp(),
                            });
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('リクエストが送信されました')),
                            );
                          } catch (e) {
                            setState(() {
                              _errorMessage = 'エラーが発生しました: $e';
                            });
                          }
                        } else {
                          setState(() {
                            _errorMessage = 'すべてのフィールドを入力してください';
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      child: const Text('リクエスト申請', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
