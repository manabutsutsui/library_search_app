import 'package:flutter_riverpod/flutter_riverpod.dart';

class VisitedSpot {
  final String id;
  final String name;

  VisitedSpot({required this.id, required this.name});
}

final visitedSpotsProvider = StateNotifierProvider<VisitedSpotsNotifier, Map<String, VisitedSpot>>((ref) {
  return VisitedSpotsNotifier();
});

class VisitedSpotsNotifier extends StateNotifier<Map<String, VisitedSpot>> {
  VisitedSpotsNotifier() : super({});

  void addVisitedSpot(String spotId, String spotName) {
    state = {
      ...state,
      spotId: VisitedSpot(id: spotId, name: spotName),
    };
  }

  void removeVisitedSpot(String spotId) {
    final newState = Map<String, VisitedSpot>.from(state);
    newState.remove(spotId);
    state = newState;
  }

  void setVisitedSpots(List<Map<String, dynamic>> spots) {
    final newState = <String, VisitedSpot>{};
    for (var spot in spots) {
      newState[spot['spotId']] = VisitedSpot(
        id: spot['spotId'],
        name: spot['spotName'],
      );
    }
    state = newState;
  }
}

