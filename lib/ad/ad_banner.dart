import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  AdBannerState createState() => AdBannerState();
}

class AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  @override
  void initState() {
    super.initState();
    _loadAdConfig();
  }

  Future<void> _loadAdConfig() async {
    final configString = await rootBundle.loadString('assets/config/config.json');
    final configJson = jsonDecode(configString);
    _initBannerAd(
      androidAdUnitId: configJson['androidAdUnitId'],
      iosAdUnitId: configJson['iosAdUnitId']
    );
  }

  void _initBannerAd({required String androidAdUnitId, required String iosAdUnitId}) {
    _bannerAd = BannerAd(
      adUnitId: Platform.isAndroid ? androidAdUnitId : iosAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print('Ad failed to load: $error');
          ad.dispose();
        },
      ),
    );

    _bannerAd?.load();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: _bannerAd?.size.height.toDouble() ?? 0,
      alignment: Alignment.center,
      child: _isBannerAdReady ? AdWidget(ad: _bannerAd!) : const SizedBox(),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }
}
