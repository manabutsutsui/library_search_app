import 'package:flutter/material.dart';

class RegistrationDefaultPage extends StatelessWidget {
  const RegistrationDefaultPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('聖地登録', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Text(
              '⭐️プレミアムプラン限定機能⭐️',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Icon(
              Icons.location_on,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 8),
            const Text(
              '聖地登録機能',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text(
              'あなたが訪れた聖地を登録し、\n思い出を記録しましょう!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'プレミアムプランにアップグレードすると、以下の機能が利用できます：',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildFeatureItem('訪れた聖地の登録'),
            _buildFeatureItem('聖地への訪問日の記録'),
            _buildFeatureItem('聖地での思い出や感想の記録'),
            _buildFeatureItem('訪問した聖地の統計情報'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // プレミアムプランへのアップグレード処理をここに実装
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                'プレミアムプランの詳細',
                style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

