import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'seichi_spots.dart';

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

  factory SpotData.fromSeichiSpot(SeichiSpot spot, bool isVisited) {
    return SpotData(
      id: spot.id,
      name: spot.name,
      work: spot.workName,
      prefecture: spot.prefecture,
      location: LatLng(spot.latitude, spot.longitude),
      isVisited: isVisited,
      imageURL: spot.imageURL,
    );
  }
}
