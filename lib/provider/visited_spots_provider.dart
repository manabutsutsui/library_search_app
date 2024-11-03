import 'package:flutter_riverpod/flutter_riverpod.dart';

final visitedSpotsProvider = StateNotifierProvider<VisitedSpotsNotifier, Set<String>>((ref) {
  return VisitedSpotsNotifier();
});

class VisitedSpotsNotifier extends StateNotifier<Set<String>> {
  VisitedSpotsNotifier() : super({});

  void addVisitedSpot(String spotId) {
    state = {...state, spotId};
  }

  void removeVisitedSpot(String spotId) {
    state = state.where((id) => id != spotId).toSet();
  }

  void setVisitedSpots(List<String> spotIds) {
    state = Set.from(spotIds);
  }
}

