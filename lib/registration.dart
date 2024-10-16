import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'visited_seichi_detail.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  RegistrationPageState createState() => RegistrationPageState();
}

class RegistrationPageState extends State<RegistrationPage> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          '聖地登録',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: user == null
            ? const Center(child: Text('ログインが必要です'))
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('visited_spots')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                        child: Text('エラーが発生しました: ${snapshot.error}'));
                  }

                  final visitedSpotsSnapshot = snapshot.data!;
                  final visitedSpots = visitedSpotsSnapshot.docs.length;

                  return FutureBuilder<QuerySnapshot>(
                    future:
                        FirebaseFirestore.instance.collection('spots').get(),
                    builder: (context, spotsSnapshot) {
                      if (spotsSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (spotsSnapshot.hasError) {
                        return Center(
                            child:
                                Text('エラーが発生しました: ${spotsSnapshot.error}'));
                      }

                      final totalSpots = spotsSnapshot.data!.docs.length;

                      return Column(
                        children: [
                          Center(
                            child: Column(
                              children: [
                                const Text(
                                  '⭐️あなたの訪れた聖地⭐️',
                                  style: TextStyle(
                                      fontSize: 24, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$visitedSpots / $totalSpots 件',
                                  style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Expanded(
                            child: ListView.builder(
                              itemCount: visitedSpotsSnapshot.docs.length,
                              itemBuilder: (context, index) {
                                final visitedSpot = visitedSpotsSnapshot.docs[index];
                                final visitedSpotData = visitedSpot.data() as Map<String, dynamic>;
                                final imageUrls = visitedSpotData['imageUrls'] as List<dynamic>?;
                                final visitedDate = visitedSpotData['visitedDate'] as Timestamp?;
                                
                                String formattedVisitedDate = '未設定';
                                
                                if (visitedDate != null) {
                                  formattedVisitedDate = DateFormat('yyyy/MM/dd').format(visitedDate.toDate());
                                }
                                
                                return Card(
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => VisitedSeichiDetailPage(
                                            visitedSpotData: visitedSpotData,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Column(
                                      children: [
                                        imageUrls != null && imageUrls.isNotEmpty
                                          ? Image.network(
                                              imageUrls.first,
                                              width: double.infinity,
                                              errorBuilder: (context, error, stackTrace) {
                                                return const Icon(Icons.image, size: 200, color: Colors.grey);
                                              },
                                            )
                                          : const Icon(Icons.landscape, size: 200, color: Colors.grey),
                                        ListTile(
                                          title: Text(visitedSpot.id, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('作品名: ${visitedSpotData['work']}'),
                                              Text('訪問日: $formattedVisitedDate'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
