import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'dart:convert';

class RewardAdManager {
  RewardedAd? _rewardedAd;
  bool _isLoading = false;
  final Completer<void> _initCompleter = Completer<void>();
  String? _androidAdUnitId;
  String? _iosAdUnitId;

  Future<void> initialize() async {
    try {
      final configString =
          await rootBundle.loadString('assets/config/config.json');
      final configJson = jsonDecode(configString);
      _androidAdUnitId = configJson['androidAdRewardId'];
      _iosAdUnitId = configJson['iosAdRewardId'];
      await loadRewardedAd(); // 非同期処理として待機
      _initCompleter.complete();
    } catch (e) {
      _initCompleter.completeError(e);
    }
  }

  Future<void> loadRewardedAd() async {
    if (_isLoading || _rewardedAd != null) {
      return;
    }

    _isLoading = true;

    try {
      final completer = Completer<void>();

      await RewardedAd.load(
        adUnitId: Platform.isAndroid
            ? _androidAdUnitId ?? '' // nullの場合は空文字を使用
            : _iosAdUnitId ?? '',
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isLoading = false;
            completer.complete();
          },
          onAdFailedToLoad: (error) {
            _isLoading = false;
            _rewardedAd = null;
            completer.completeError(error);
          },
        ),
      );

      await completer.future;
    } catch (e) {
      _isLoading = false;
      _rewardedAd = null;
      rethrow;
    }
  }

  Future<bool> showRewardedAd() async {
    await _initCompleter.future;

    if (_rewardedAd == null) {
      try {
        await loadRewardedAd();
      } catch (e) {
        return false;
      }
    }

    if (_rewardedAd == null) {
      return false;
    }

    final completer = Completer<bool>();

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd(); // 次回のために再読み込み
        completer.complete(false);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        completer.complete(false);
      },
    );

    try {
      await _rewardedAd!.setImmersiveMode(true);
      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          completer.complete(true);
        },
      );
    } catch (e) {
      completer.complete(false);
    }

    return completer.future;
  }

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
