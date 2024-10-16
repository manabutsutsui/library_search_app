import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'seichi_registration_edit.dart';

class VisitedSeichiDetailPage extends StatelessWidget {
  final Map<String, dynamic> visitedSpotData;

  const VisitedSeichiDetailPage({super.key, required this.visitedSpotData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(visitedSpotData['name'] ?? '聖地詳細', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailItem('聖地名', visitedSpotData['name'] ?? '不明'),
            const Divider(color: Colors.grey),
            _buildDetailItem('作品名', visitedSpotData['work'] ?? '不明'),
            const Divider(color: Colors.grey),
            _buildDetailItem('住所', visitedSpotData['address'] ?? '不明'),
            const Divider(color: Colors.grey),
            _buildDetailItem('訪問日', _formatDate(visitedSpotData['visitedDate'])),
            const Divider(color: Colors.grey),
            _buildDetailItem('メモ', visitedSpotData['memo'] ?? ''),
            const Divider(color: Colors.grey),
            const SizedBox(height: 16),
            const Text('写真', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildImageGrid(visitedSpotData['imageUrls'] ?? []),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SeichiRegistrationEditPage(
                        visitedSpotData: {
                          ...visitedSpotData,
                          'id': visitedSpotData['spotId'], // ここでidを追加
                        },
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: const Text('編集', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date is Timestamp) {
      return DateFormat('yyyy/MM/dd').format(date.toDate());
    }
    return '未設定';
  }

  Widget _buildImageGrid(List<dynamic> imageUrls) {
    return Column(
      children: [
        ...imageUrls.map((url) => 
          Column(
            children: [
              Image.network(
                url,
                width: double.infinity,
              ),
              const SizedBox(height: 8),
            ],
          )
        ),
      ],
    );
  }
}
