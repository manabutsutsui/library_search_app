import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/subscription_state.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SubscriptionPremium extends ConsumerStatefulWidget {
  const SubscriptionPremium({super.key});

  @override
  ConsumerState<SubscriptionPremium> createState() =>
      _SubscriptionPremiumState();
}

class _SubscriptionPremiumState extends ConsumerState<SubscriptionPremium> {
  bool _isLoading = false;
  Offering? _offering;
  Package? _selectedPackage;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<String> _featureImages = [
    'assets/subscription_images/1.png',
    'assets/subscription_images/2.png',
    'assets/subscription_images/3.png',
    'assets/subscription_images/4.png',
    'assets/subscription_images/5.png',
  ];

  @override
  void initState() {
    super.initState();
    _fetchOfferings();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      setState(() {
        _offering = offerings.current;
        _selectedPackage = _offering?.monthly;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _purchasePackage(Package package) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await Purchases.purchasePackage(package);
      ref.read(subscriptionProvider.notifier).checkSubscription();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!.purchaseSuccess)),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Purchase failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.purchaseFailed)),
        );
      }
    }
  }

  Future<void> _launchURL(String urlString) async {
    final l10n = AppLocalizations.of(context)!;
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.urlCannotBeOpened),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            title: Text(l10n.premiumPlan02,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            backgroundColor: Colors.blue,
            iconTheme: const IconThemeData(color: Colors.white),
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
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          l10n.premiumPlanEnjoy,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
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
                            Text(
                              '${l10n.monthlyPlan} ・${l10n.premiumMonthlyPlanPrice}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _isLoading || _selectedPackage == null
                                  ? null
                                  : () => _purchasePackage(_selectedPackage!),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    l10n.trialPeriod,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(l10n.cancelAnytime),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                                '${l10n.premiumMonthlyPlanPrice} ・${l10n.affordablePrice}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
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
                                Text(
                                  l10n.annualPlan,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: _isLoading ||
                                          _offering?.annual == null
                                      ? null
                                      : () =>
                                          _purchasePackage(_offering!.annual!),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 12),
                                  ),
                                  child: Text(
                                    l10n.premiumAnnualPlanPrice,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                    '${l10n.premiumAnnualPlanPrice} ・${l10n.affordablePrice}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
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
                              child: Text(
                                l10n.twoMonthDiscount,
                                style: const TextStyle(
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.premiumPlanNotApplied,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.premiumPlanPrice,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.premiumPlanOldPrice,
                            style: const TextStyle(fontSize: 12),
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
                            child: Text(
                              l10n.termsOfService,
                              style: const TextStyle(
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
                            child: Text(
                              l10n.privacyPolicy,
                              style: const TextStyle(
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
                          Text(l10n.faq1,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(l10n.answer1, textAlign: TextAlign.left),
                          const SizedBox(height: 16),
                          Text(l10n.faq2,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(l10n.answer2, textAlign: TextAlign.left),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () => _launchURL('https://x.com/gaku29189'),
                            child: Text(
                              l10n.developerTwitter,
                              style: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(l10n.faq3,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(l10n.answer3, textAlign: TextAlign.left),
                          const SizedBox(height: 16),
                          Text(l10n.faq4,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(l10n.answer4, textAlign: TextAlign.left),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () => _launchURL(
                                'https://support.apple.com/ja-jp/118428'),
                            child: Text(
                              l10n.cancellationProcedure,
                              style: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(l10n.faq5,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(l10n.answer5, textAlign: TextAlign.left),
                          const SizedBox(height: 16),
                          Text(l10n.faq6,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(l10n.answer6, textAlign: TextAlign.left),
                          const SizedBox(height: 16),
                          Text(l10n.faq7,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(l10n.answer7, textAlign: TextAlign.left),
                          const SizedBox(height: 16),
                          Text(l10n.faq8,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(l10n.answer8, textAlign: TextAlign.left),
                          const SizedBox(height: 16),
                          Text(l10n.faq9,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(l10n.answer9, textAlign: TextAlign.left),
                          const SizedBox(height: 16),
                          Text(l10n.faq10,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(l10n.answer10, textAlign: TextAlign.left),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () => _launchURL(
                                'https://tsutsunoidoblog.com/contact/'),
                            child: Text(
                              l10n.contactForm,
                              style: const TextStyle(
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
