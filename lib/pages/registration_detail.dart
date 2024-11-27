import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'spot_detail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/visited_spots_provider.dart';

class SeichiRegistrationDetail extends ConsumerWidget {
  final Map<String, dynamic> spot;

  const SeichiRegistrationDetail({
    super.key,
    required this.spot,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitDate = spot['visitDate'] as Timestamp;
    final formattedDate =
        '${visitDate.toDate().year}年${visitDate.toDate().month}月${visitDate.toDate().day}日';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          '登録した聖地',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        title: const Text(
                          '削除する',
                          style: TextStyle(color: Colors.red),
                        ),
                        onTap: () async {
                          try {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .collection('visited_spots')
                                  .doc(spot['spotId'])
                                  .delete();

                              if (context.mounted) {
                                ref.read(visitedSpotsProvider.notifier)
                                   .removeVisitedSpot(spot['spotId']);

                                Navigator.of(context).pop(); // モーダルを閉じる
                                Navigator.of(context).pop(); // 詳細画面を閉じる
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('聖地の登録を削除しました')),
                                );
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('削除中にエラーが発生しました')),
                              );
                            }
                          }
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.close),
                        title: const Text('キャンセル'),
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    spot['spotName'] ?? '不明な聖地',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (spot['imageUrl'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  spot['imageUrl'],
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 8),
            _buildInfoRow('訪問日', formattedDate),
            const SizedBox(height: 16),
            if (spot['memo'] != null && spot['memo'].isNotEmpty) ...[
              const Text(
                'メモ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  spot['memo'],
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final spotDoc = await FirebaseFirestore.instance
                    .collection('spots')
                    .doc(spot['spotName'])
                    .get();

                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SpotDetailPage(spot: spotDoc),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                '聖地の詳細を見る',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
