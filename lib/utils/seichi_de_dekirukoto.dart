import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

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

  final List<Map<String, String>> _features = [
    {
      'title': '「Seichi」とは?',
      'description': '当アプリ「Seichi」をダウンロードしていただき、誠にありがとうございます! 「Seichi」は、聖地巡礼をより楽しく、より便利にするアプリです。',
      'image': 'assets/registration_page/dekiru_00.png',
    },
    {
      'title': '作品から聖地を探そう',
      'description':
          '数多くの「作品」から、あなたの理想の聖地を見つけることができます。 「Seichi」は現在もアップデートを続けていて、日々新しい聖地が登録されています。',
      'image': 'assets/registration_page/dekiru_01.png',
    },
    {
      'title': '地図で聖地を探そう',
      'description': '聖地を地図で探すことができます。 あなたの周辺の聖地を見つけられるかもしれません!',
      'image': 'assets/registration_page/dekiru_02.png',
    },
    {
      'title': '口コミを見て聖地を探そう',
      'description': '口コミを見て、聖地を探すことができます。 他のユーザーの投稿を参考に、あなたの理想の聖地を見つけましょう!',
      'image': 'assets/registration_page/dekiru_03.png',
    },
    {
      'title': '訪れた聖地を登録しよう',
      'description': '訪れた聖地を写真と共に登録できます。思い出と共に保存しましょう!',
      'image': 'assets/registration_page/dekiru_04.png',
    },
    {
      'title': 'Premiumに登録して、\n「Seichi」をもっと楽しもう',
      'description': 'Premiumに登録すると、より多くの限定機能を利用することができます! 「Seichi」であなたの聖地巡礼ライフをもっと楽しんでください!',
      'image': 'assets/registration_page/dekiru_05.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
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
                    child: const Text('閉じる'),
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
