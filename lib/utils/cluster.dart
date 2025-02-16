import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClusterManager {
  static const double clusterZoomThreshold = 10.0;

  static Map<String, List<SpotData>> createClusters(List<SpotData> spots, double zoom) {
    if (zoom > clusterZoomThreshold) {
      return {};
    }

    Map<String, List<SpotData>> clusters = {};
    
    for (var spot in spots) {
      String prefecture = spot.prefecture;
      if (!clusters.containsKey(prefecture)) {
        clusters[prefecture] = [];
      }
      clusters[prefecture]!.add(spot);
    }

    return clusters;
  }
}

class SpotData {
  final String id;
  final String name;
  final String work;
  final String prefecture;
  final LatLng location;
  final bool isVisited;
  final String imageURL;

  SpotData({
    required this.id,
    required this.name,
    required this.work,
    required this.prefecture,
    required this.location,
    required this.isVisited,
    required this.imageURL,
  });

  factory SpotData.fromFirestore(DocumentSnapshot doc, bool isVisited) {
    final data = doc.data() as Map<String, dynamic>;
    final GeoPoint location = data['location'];
    
    return SpotData(
      id: doc.id,
      name: data['name'],
      work: data['work'],
      prefecture: data['prefecture'] ?? '不明',
      location: LatLng(location.latitude, location.longitude),
      isVisited: isVisited,
      imageURL: data['imageURL'] ?? '',
    );
  }
}
