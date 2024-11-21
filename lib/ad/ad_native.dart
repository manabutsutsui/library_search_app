import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io' show Platform;
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({super.key});

  @override
  NativeAdWidgetState createState() => NativeAdWidgetState();
}

class NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    final String adUnitId = await _getAdUnitId();

    _nativeAd = NativeAd(
      adUnitId: adUnitId,
      factoryId: 'adFactory',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          // print('Native ad failed to load: $error');
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: Colors.white,
        callToActionTextStyle: NativeTemplateTextStyle(
          size: 16.0,
          backgroundColor: Colors.blue,
          style: NativeTemplateFontStyle.bold,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          size: 16.0,
          textColor: Colors.black,
          style: NativeTemplateFontStyle.bold,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          size: 14.0,
          textColor: Colors.black54,
          style: NativeTemplateFontStyle.normal,
        ),
      ),
    );

    await _nativeAd!.load();
  }

  Future<String> _getAdUnitId() async {
    final String configContent = await rootBundle.loadString('assets/config/config.json');
    final Map<String, dynamic> config = json.decode(configContent);
    return Platform.isAndroid ? config['androidNativeAdUnitId'] : config['iosNativeAdUnitId'];
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded) return Container();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          constraints: const BoxConstraints(
            minHeight: 100.0,
            maxHeight: 400.0,
          ),
          child: AdWidget(ad: _nativeAd!),
        );
      },
    );
  }
}
