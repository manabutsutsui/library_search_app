import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SeichiDeDekirukoto extends StatefulWidget {
  const SeichiDeDekirukoto({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SeichiDeDekirukoto(),
    );
  }

  @override
  State<SeichiDeDekirukoto> createState() => _SeichiDeDekirukotoState();
}

class _SeichiDeDekirukotoState extends State<SeichiDeDekirukoto> {
  int _currentIndex = 0;
  late List<Map<String, String>> _features;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;
    _features = [
      {
        'title': l10n.whatIsSeichi,
        'description': l10n.whatIsSeichiDescription,
        'image': 'assets/registration_page/dekiru_00.png',
      },
      {
        'title': l10n.whatIsSeichiDescription2,
        'description': l10n.whatIsSeichiDescription3,
        'image': 'assets/registration_page/dekiru_01.png',
      },
      {
        'title': l10n.whatIsSeichiDescription4,
        'description': l10n.whatIsSeichiDescription5,
        'image': 'assets/registration_page/dekiru_02.png',
      },
      {
        'title': l10n.whatIsSeichiDescription6,
        'description': l10n.whatIsSeichiDescription7,
        'image': 'assets/registration_page/dekiru_03.png',
      },
      {
        'title': l10n.whatIsSeichiDescription10,
        'description': l10n.whatIsSeichiDescription11,
        'image': 'assets/registration_page/dekiru_04.png',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.9,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(l10n.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CarouselSlider.builder(
                itemCount: _features.length,
                options: CarouselOptions(
                  height: double.infinity,
                  viewportFraction: 0.9,
                  enlargeCenterPage: true,
                  enableInfiniteScroll: false,
                  onPageChanged: (index, reason) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                ),
                itemBuilder: (context, index, realIndex) {
                  final feature = _features[index];
                  return _buildFeatureItem(
                    feature['title']!,
                    feature['description']!,
                    feature['image']!,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            AnimatedSmoothIndicator(
              activeIndex: _currentIndex,
              count: _features.length,
              effect: const WormEffect(
                dotHeight: 8,
                dotWidth: 8,
                spacing: 8,
                dotColor: Colors.grey,
                activeDotColor: Colors.blue,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description, String imagePath) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          imagePath,
          width: double.infinity,
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
