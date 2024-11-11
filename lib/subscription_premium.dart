import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'provider/subscription_state.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionPremium extends ConsumerStatefulWidget {
  const SubscriptionPremium({super.key});

  @override
  ConsumerState<SubscriptionPremium> createState() =>
      _SubscriptionPremiumState();
}

class _SubscriptionPremiumState extends ConsumerState<SubscriptionPremium> {
  bool _isLoading = false;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<String> _featureImages = [
    'assets/subscription_images/1.png',
    'assets/subscription_images/2.png',
    'assets/subscription_images/3.png',
    'assets/subscription_images/4.png',
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handlePurchase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current == null) {
        throw Exception('利用可能なプランがありません');
      }

      Package? packageToPurchase;
      final possibleIds = ['sa_399_1m', 'premium_monthly', 'sa_400_1m'];

      for (var id in possibleIds) {
        try {
          packageToPurchase = offerings.current!.availablePackages.firstWhere(
              (package) =>
                  package.identifier == id ||
                  package.storeProduct.identifier == id);
          debugPrint('Found package with ID: ${packageToPurchase.identifier}');
          break;
        } catch (e) {
          continue;
        }
      }

      if (packageToPurchase == null &&
          offerings.current!.availablePackages.isNotEmpty) {
        packageToPurchase = offerings.current!.availablePackages.first;
        debugPrint(
            'Using first available package: ${packageToPurchase.identifier}');
      }

      if (packageToPurchase == null) {
        throw Exception('利用可能なパッケージが見つかりません');
      }

      final purchaserInfo = await Purchases.purchasePackage(packageToPurchase);
      final hasActiveEntitlement = purchaserInfo.entitlements.active.isNotEmpty;

      if (hasActiveEntitlement) {
        ref.read(subscriptionProvider.notifier).checkSubscription();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('プレミアムプランの購入が完了しました！'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Purchase error: $e');
      if (!mounted) return;

      String errorMessage = '購入処理中にエラーが発生しました';

      if (e.toString().contains('PlatformException')) {
        errorMessage = 'ストアとの通信中にエラーが発生しました';
      } else if (e.toString().contains('UserCancelled')) {
        errorMessage = '購入がキャンセルされました';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('URLを開けませんでした'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium プラン',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 0.46 * MediaQuery.of(context).size.height,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _featureImages.length,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  return Container(
                    width: MediaQuery.of(context).size.width,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                    child: Image.asset(
                      _featureImages[index],
                      fit: BoxFit.contain,
                      width: double.infinity,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _featureImages.length,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: CircleAvatar(
                      radius: 4,
                      backgroundColor: _currentPage == index
                          ? Colors.blue
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Premiumプランで\nSeichiをもっと楽しもう!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 16, bottom: 8),
                    padding: const EdgeInsets.all(8),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 225, 254, 255),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '月額プラン',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handlePurchase,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  '¥500/月',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          _launchURL('https://tsutsunoidoblog.com/movie_and_anime_holy_land_sns_terms_of_use/');
                        },
                        child: const Text(
                          '利用規約',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _launchURL('https://tsutsunoidoblog.com/movie_and_anime_holy_land_sns_privacy_policy/');
                        },
                        child: const Text(
                          'プライバシーポリシー',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
