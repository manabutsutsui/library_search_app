import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/subscription_state.dart';
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

  Future<void> _handlePurchase({bool isAnnual = false}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current == null) {
        throw Exception('利用可能なプランがありません');
      }

      Package? packageToPurchase;
      final possibleIds = isAnnual ? ['sa_28.86_1y'] : ['sa_399_1m'];

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
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
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
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 16, bottom: 8),
                        padding: const EdgeInsets.all(16),
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
                              child: const Text(
                                '¥500/月',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text('・¥500/月 お手頃価格',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 16, bottom: 8),
                            padding: const EdgeInsets.all(16),
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
                                  '年間プラン',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () => _handlePurchase(isAnnual: true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 12),
                                  ),
                                  child: const Text(
                                    '￥5,000/年',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text('・年間契約でお得に利用可能',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 16,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '２ヶ月分お得',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '※ 購入後に「特典（限定機能）」が反映されない場合、一度アプリを再起動してください。もしくは、数分ほど時間を空けてください。',
                            style: TextStyle(fontSize: 12),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '※ 月額プラン ¥500/月 | 年割プラン ¥5,000/年',
                            style: TextStyle(fontSize: 12),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '※ 旧料金で購入している場合、プラン料金は購入時のままで変更はありません',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {
                              _launchURL(
                                  'https://tsutsunoidoblog.com/movie_and_anime_holy_land_sns_terms_of_use/');
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
                              _launchURL(
                                  'https://tsutsunoidoblog.com/movie_and_anime_holy_land_sns_privacy_policy/');
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
                      const SizedBox(height: 24),
                      const Text('🌸 FAQ',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('購入するプランで特典の違いはありますか？',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text(
                              'はい、特典は全て同じ内容です。月額プランでも年額プランでも、全て同じ内容の特典をご利用いただけます。',
                              textAlign: TextAlign.left),
                          const SizedBox(height: 16),
                          const Text('今後も開発は続けますか？',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text(
                              'Seichiは未完成アプリです。開発者の構想を実現するために、今も新機能を続々開発中。また、聖地スポットも日々追加しています!その様子はTwitterよりご確認ください。',
                              textAlign: TextAlign.left),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () => _launchURL('https://x.com/gaku29189'),
                            child: const Text(
                              '開発者Twitter',
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text('購入後に特典が反映されません',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text(
                              'Premiumプランの特典が反映されるまで、少し時間がかかる場合があります。一度アプリをスワイプして終了してみてください。',
                              textAlign: TextAlign.left),
                          const SizedBox(height: 16),
                          const Text('途中で解約はできますか？',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text('いつでも可能です。ご解約の方法については以下のページをご覧ください。',
                              textAlign: TextAlign.left),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () => _launchURL(
                                'https://support.apple.com/ja-jp/118428'),
                            child: const Text(
                              '解約の手順',
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text('アプリを削除すると解約されますか？',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text(
                              'アプリを削除しても、Premiumプランは解約されません。上記の手順より解約手続きをお願いします。',
                              textAlign: TextAlign.left),
                          const SizedBox(height: 16),
                          const Text('購入後の返金はできますか？',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text('購入後の返金はお受けできません。ご了承ください。'),
                          const SizedBox(height: 16),
                          const Text('Premiumプランは自動更新ですか？',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text(
                              '契約期間終了の24時間以内に解約（自動更新の解除）をされない場合、自動更新されます。',
                              textAlign: TextAlign.left),
                          const SizedBox(height: 16),
                          const Text('契約期間を教えて下さい',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text('上記の解約方法と同じ手順でご確認できます。',
                              textAlign: TextAlign.left),
                          const SizedBox(height: 16),
                          const Text('プランの変更はできますか？',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text('途中でプランを変更したい場合、現在のプランの解約が必要になります。',
                              textAlign: TextAlign.left),
                          const SizedBox(height: 16),
                          const Text('お問い合わせ先を教えて下さい',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text('以下のフォームまでご連絡ください。'),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () => _launchURL(
                                'https://tsutsunoidoblog.com/contact/'),
                            child: const Text(
                              'お問い合わせフォーム',
                              style: TextStyle(
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
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}
