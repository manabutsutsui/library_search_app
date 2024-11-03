import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'visited_seichi_detail.dart';
import 'subscription_premium.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'provider/subscription_state.dart';

class RegistrationPage extends ConsumerWidget {
  const RegistrationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/home_image.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user?.uid)
                .collection('visited_spots')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
              }

              final visitedSpotsSnapshot = snapshot.data!;
              final visitedSpots = visitedSpotsSnapshot.docs.length;

              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance.collection('spots').get(),
                builder: (context, spotsSnapshot) {
                  if (spotsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (spotsSnapshot.hasError) {
                    return Center(
                        child: Text('エラーが発生しました: ${spotsSnapshot.error}'));
                  }

                  final totalSpots = spotsSnapshot.data!.docs.length;

                  return Column(
                    children: [
                      const SizedBox(height: 64),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '⭐️あなたの訪れた聖地⭐️',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$visitedSpots / $totalSpots 件',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ref.watch(subscriptionProvider).when(
                            data: (isSubscribed) => isSubscribed
                                ? const SizedBox()
                                : Column(
                                    children: [
                                      Stack(
                                        children: [
                                          Container(
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 16),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.blue,
                                                width: 2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Image.asset(
                                              'assets/subscription_images/2.png',
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Positioned(
                                            top: 0,
                                            right: 8,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.blue,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: const Text(
                                                'Premiumプラン',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      ElevatedButton(
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
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 32, vertical: 16),
                                        ),
                                        child: const Text(
                                          'Premiumプランの詳細',
                                          style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                            loading: () => const CircularProgressIndicator(),
                            error: (_, __) => const Text('エラーが発生しました'),
                          ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: visitedSpotsSnapshot.docs.length,
                          itemBuilder: (context, index) {
                            final visitedSpot =
                                visitedSpotsSnapshot.docs[index];
                            final visitedSpotData =
                                visitedSpot.data() as Map<String, dynamic>;
                            final imageUrls =
                                visitedSpotData['imageUrls'] as List<dynamic>?;
                            final visitedDate =
                                visitedSpotData['visitedDate'] as Timestamp?;

                            String formattedVisitedDate = '未設定';

                            if (visitedDate != null) {
                              formattedVisitedDate = DateFormat('yyyy/MM/dd')
                                  .format(visitedDate.toDate());
                            }

                            return Card(
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          VisitedSeichiDetailPage(
                                        visitedSpotData: visitedSpotData,
                                      ),
                                    ),
                                  );
                                },
                                child: Column(
                                  children: [
                                    imageUrls != null && imageUrls.isNotEmpty
                                        ? AspectRatio(
                                            aspectRatio: 16 / 9,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                        top:
                                                            Radius.circular(8)),
                                                image: DecorationImage(
                                                  image: NetworkImage(
                                                      imageUrls.first),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                          )
                                        : const AspectRatio(
                                            aspectRatio: 16 / 9,
                                            child: Icon(Icons.landscape,
                                                size: 100, color: Colors.grey),
                                          ),
                                    ListTile(
                                      title: Text(visitedSpot.id,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              '作品名: ${visitedSpotData['work']}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis),
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
      ),
    );
  }
}
