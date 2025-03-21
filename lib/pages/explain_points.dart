import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/subscription_state.dart';
import 'subscription_premium.dart';

class ExplainPointsPage extends ConsumerWidget {
  const ExplainPointsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final l10n = AppLocalizations.of(context)!;
    final isPremium = ref.watch(subscriptionProvider).value ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ポイントについて',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ポイントとは',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '「Seichi」では、様々な活動でポイントを獲得できます。獲得したポイントは将来的に特典と交換することができるようになります。',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              const Text(
                'ポイントの獲得方法',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildPointCard(
                context,
                title: 'レビュー投稿',
                description: '訪問した聖地にレビューを投稿すると、ポイントが獲得できます。',
                pointsNormal: '10ポイント',
                pointsPremium: '20ポイント',
                icon: Icons.rate_review,
                isPremium: isPremium,
              ),
              _buildPointCard(
                context,
                title: 'ログインボーナス',
                description: '毎日アプリにログインすると、ポイントが獲得できます。',
                pointsNormal: '5ポイント',
                pointsPremium: '10ポイント',
                icon: Icons.calendar_today,
                isPremium: isPremium,
              ),
              _buildPointCard(
                context,
                title: '7日連続ログインボーナス',
                description: '7日連続でログインすると、特別ボーナスが獲得できます。',
                pointsNormal: '30ポイント',
                pointsPremium: '60ポイント',
                icon: Icons.calendar_month,
                isPremium: isPremium,
              ),
              const SizedBox(height: 24),
              const Text(
                'ポイントの使い方',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '今後のアップデートで追加予定の機能',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• 限定アバターやプロフィール装飾との交換\n'
                        '• 聖地巡礼グッズとの交換\n'
                        '• 特別なバッジやステータスの獲得\n'
                        '• 抽選イベントへの参加権',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'プレミアムプランの特典',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber),
                          SizedBox(width: 8),
                          Text(
                            'プレミアム会員特典',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '• 全ての活動で獲得ポイントが2倍\n'
                        '• 広告なしでポイント獲得可能\n'
                        '• 将来的な特別イベントへの優先参加権',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      if (!isPremium)
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const SubscriptionPremium()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('プレミアムプランを見る',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Center(
                child: Text(
                  'ポイントを貯めて、アニメ聖地巡礼をもっと楽しみましょう！',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPointCard(
    BuildContext context, {
    required String title,
    required String description,
    required String pointsNormal,
    required String pointsPremium,
    required IconData icon,
    required bool isPremium,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  '獲得ポイント: ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPremium
                        ? Colors.amber.shade100
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isPremium ? pointsPremium : pointsNormal,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isPremium ? Colors.amber.shade800 : Colors.black87,
                    ),
                  ),
                ),
                if (isPremium)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Text(
                      '(プレミアム特典)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
