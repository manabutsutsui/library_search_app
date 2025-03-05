import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/points_provider.dart';
class LoginBonusState {
  final int consecutiveDays;
  final DateTime lastLoginDate;
  final bool hasTodayBonus;
  final List<DateTime> loginHistory;

  LoginBonusState({
    this.consecutiveDays = 0,
    DateTime? lastLoginDate,
    this.hasTodayBonus = false,
    List<DateTime>? loginHistory,
  })  : lastLoginDate = lastLoginDate ?? DateTime.now(),
        loginHistory = loginHistory ?? [];
}

class LoginBonusNotifier extends StateNotifier<LoginBonusState> {
  LoginBonusNotifier(this.ref) : super(LoginBonusState());

  final Ref ref;

  Future<void> checkAndUpdateLoginBonus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final userData = await userDoc.get();

    // ログイン履歴を取得
    List<DateTime> loginHistory = [];
    if (userData.exists && userData.data()!.containsKey('loginHistory')) {
      loginHistory = (userData.data()!['loginHistory'] as List<dynamic>)
          .map((timestamp) => (timestamp as Timestamp).toDate())
          .toList();
    }

    if (userData.exists && userData.data()!.containsKey('lastLoginDate')) {
      final lastLoginDate =
          (userData.data()!['lastLoginDate'] as Timestamp).toDate();
      final currentDate = DateTime.now();
      final lastLoginDay =
          DateTime(lastLoginDate.year, lastLoginDate.month, lastLoginDate.day);
      final today =
          DateTime(currentDate.year, currentDate.month, currentDate.day);

      // 日付が変わっている場合
      if (today.isAfter(lastLoginDay)) {
        // 連続ログイン日数の計算
        int consecutiveDays = userData.data()!['consecutiveLoginDays'] ?? 0;

        // 前日のログインなら連続日数を増やす、そうでなければリセット
        final yesterday = DateTime(today.year, today.month, today.day - 1);
        if (lastLoginDay.isAtSameMomentAs(yesterday)) {
          consecutiveDays++;
        } else {
          consecutiveDays = 1;
        }

        // 今日の日付をログイン履歴に追加（重複を避ける）
        if (!loginHistory.any((date) =>
            date.year == today.year &&
            date.month == today.month &&
            date.day == today.day)) {
          loginHistory.add(today);
        }

        // Firestoreを更新
        await userDoc.update({
          'lastLoginDate': Timestamp.now(),
          'consecutiveLoginDays': consecutiveDays,
          'loginHistory':
              loginHistory.map((date) => Timestamp.fromDate(date)).toList(),
        });

        state = LoginBonusState(
          consecutiveDays: consecutiveDays,
          lastLoginDate: currentDate,
          hasTodayBonus: true,
          loginHistory: loginHistory,
        );
      } else {
        // 同日のログインなのでボーナスなし
        state = LoginBonusState(
          consecutiveDays: userData.data()!['consecutiveLoginDays'] ?? 0,
          lastLoginDate: lastLoginDate,
          hasTodayBonus: false,
          loginHistory: loginHistory,
        );
      }
    } else {
      // 初回ログイン
      final today = DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day);
      loginHistory.add(today);

      await userDoc.set({
        'lastLoginDate': Timestamp.now(),
        'consecutiveLoginDays': 1,
        'loginHistory':
            loginHistory.map((date) => Timestamp.fromDate(date)).toList(),
      }, SetOptions(merge: true));

      state = LoginBonusState(
        consecutiveDays: 1,
        hasTodayBonus: true,
        loginHistory: loginHistory,
      );
    }
  }

  // ポイントを付与するメソッド
  Future<void> claimLoginBonus(bool isPremium) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // すでにボーナスを受け取っているかチェック
    if (!state.hasTodayBonus) return;

    // 連続ログイン日数に応じたボーナスポイントを計算
    int pointsToAdd;
    if (state.consecutiveDays % 7 == 0) {
      // 7の倍数日の特別ボーナス
      pointsToAdd = isPremium ? 60 : 30;
    } else {
      // 通常の日のボーナス
      pointsToAdd = isPremium ? 10 : 5;
    }

    // ポイントプロバイダーを使ってポイントを追加
    await ref.read(pointsProvider.notifier).addPoints(pointsToAdd);

    // ボーナス受け取り状態を更新
    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    await userDoc.update({
      'lastBonusClaimed': Timestamp.now(),
    });

    // 状態を更新
    state = LoginBonusState(
      consecutiveDays: state.consecutiveDays,
      lastLoginDate: state.lastLoginDate,
      hasTodayBonus: false, // ボーナスを受け取ったのでfalseに
      loginHistory: state.loginHistory,
    );
  }
}

final loginBonusProvider =
    StateNotifierProvider<LoginBonusNotifier, LoginBonusState>((ref) {
  return LoginBonusNotifier(ref);
});
