import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PointsState {
  final int totalPoints;
  final bool isLoading;

  PointsState({this.totalPoints = 0, this.isLoading = false});

  PointsState copyWith({int? totalPoints, bool? isLoading}) {
    return PointsState(
      totalPoints: totalPoints ?? this.totalPoints,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class PointsNotifier extends StateNotifier<PointsState> {
  PointsNotifier() : super(PointsState());

  // ポイント情報を読み込む
  Future<void> loadPoints() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    state = state.copyWith(isLoading: true);

    try {
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final userData = await userDoc.get();

      if (userData.exists && userData.data()!.containsKey('points')) {
        state = state.copyWith(
          totalPoints: userData.data()!['points'] ?? 0,
          isLoading: false,
        );
      } else {
        // ポイントフィールドがまだ存在しない場合は0で初期化
        await userDoc.update({'points': 0});
        state = state.copyWith(totalPoints: 0, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  // ポイントを加算する
  Future<void> addPoints(int amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      // トランザクションを使用して安全にポイントを更新
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userDoc);
        final currentPoints = snapshot.data()?['points'] ?? 0;
        transaction.update(userDoc, {'points': currentPoints + amount});
      });

      // ローカルの状態も更新
      state = state.copyWith(totalPoints: state.totalPoints + amount);
    } catch (e) {
      // エラー処理
    }
  }
}

final pointsProvider =
    StateNotifierProvider<PointsNotifier, PointsState>((ref) {
  return PointsNotifier();
});
