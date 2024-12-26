import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/subscription_state.dart';

class AppOpenAdManager {
  AppOpenAdManager({required this.ref});
  final WidgetRef ref;
  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  static bool isLoaded = false;

  Future<void> loadAd() async {
    final isPremium = ref.read(subscriptionProvider).value ?? false;
    if (isPremium) {
      return;
    }

    if (_appOpenAd != null) {
      return;
    }

    final String adUnitId = await _getAdUnitId();

    try {
      await AppOpenAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _appOpenAd = ad;
            isLoaded = true;
          },
          onAdFailedToLoad: (error) {
            print('アプリ起動広告の読み込みに失敗: $error');
            isLoaded = false;
          },
        ),
      );
    } catch (e) {
      print('アプリ起動広告のロード中にエラーが発生: $e');
    }
  }

  void showAdIfAvailable() {
    final isPremium = ref.read(subscriptionProvider).value ?? false;
    if (isPremium) {
      return;
    }

    if (!isLoaded || _isShowingAd || _appOpenAd == null) {
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd();
      },
    );

    _appOpenAd!.show();
  }

  Future<String> _getAdUnitId() async {
    final String configString = await rootBundle.loadString('assets/config/config.json');
    final Map<String, dynamic> config = json.decode(configString);
    
    if (Platform.isAndroid) {
      return config['androidAppLaunchAdUnitId'] as String;
    } else if (Platform.isIOS) {
      return config['iosAppLaunchAdUnitId'] as String;
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  void dispose() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
  }
}
