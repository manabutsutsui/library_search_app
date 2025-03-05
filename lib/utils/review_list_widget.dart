import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'report.dart';

class ReviewListWidget extends StatelessWidget {
  final List<DocumentSnapshot> reviews;
  final Function(String) onReportTap;

  const ReviewListWidget({
    super.key,
    required this.reviews,
    required this.onReportTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (reviews.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(l10n.noReviews),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final review = reviews[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (review['imageUrl'] != null)
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(8)),
                    child: Image.network(
                      review['imageUrl'],
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: review['userProfileImage'] != null
                                ? NetworkImage(review['userProfileImage'])
                                : null,
                            child: review['userProfileImage'] == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  review['userName'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${l10n.postedDate}: ${DateFormat('yyyy年MM月dd日 HH時mm分').format(review['timestamp'].toDate())}',
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (BuildContext context) {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      if (review['userId'] ==
                                          FirebaseAuth
                                              .instance.currentUser?.uid)
                                        ListTile(
                                          leading: const Icon(Icons.delete,
                                              color: Colors.red),
                                          title: Text(l10n.delete,
                                              style: const TextStyle(
                                                  color: Colors.red)),
                                          onTap: () async {
                                            final bool? confirmDelete =
                                                await showDialog<bool>(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: Text(l10n.confirm),
                                                  content: Text(
                                                      l10n.deleteReviewConfirm,
                                                      style: const TextStyle(
                                                          fontSize: 12)),
                                                  actions: <Widget>[
                                                    TextButton(
                                                      child: Text(l10n.cancel),
                                                      onPressed: () =>
                                                          Navigator.of(context)
                                                              .pop(false),
                                                    ),
                                                    TextButton(
                                                      child: Text(l10n.delete,
                                                          style:
                                                              const TextStyle(
                                                                  color: Colors
                                                                      .red)),
                                                      onPressed: () =>
                                                          Navigator.of(context)
                                                              .pop(true),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );

                                            if (confirmDelete == true) {
                                              try {
                                                // 画像がある場合、Storageから削除
                                                if (review['imageUrl'] !=
                                                    null) {
                                                  try {
                                                    final storageRef =
                                                        FirebaseStorage.instance
                                                            .refFromURL(review[
                                                                'imageUrl']);
                                                    await storageRef.delete();
                                                  } catch (e) {
                                                    // 画像の削除エラー処理
                                                  }
                                                }

                                                // Firestoreから口コミを削除
                                                await FirebaseFirestore.instance
                                                    .collection('reviews')
                                                    .doc(review.id)
                                                    .delete();

                                                Navigator.of(context).pop();
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                      content: Text(
                                                          l10n.reviewDeleted)),
                                                );
                                              } catch (e) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                      content: Text(l10n
                                                          .reviewDeleteError)),
                                                );
                                              }
                                            } else {
                                              Navigator.of(context).pop();
                                            }
                                          },
                                        )
                                      else ...[
                                        ListTile(
                                          leading: const Icon(Icons.flag,
                                              color: Colors.red),
                                          title: Text(l10n.report,
                                              style: const TextStyle(
                                                  color: Colors.red)),
                                          onTap: () async {
                                            final String? reportReason =
                                                await showDialog<String>(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return const ReportDialog();
                                              },
                                            );

                                            if (reportReason != null) {
                                              try {
                                                await FirebaseFirestore.instance
                                                    .collection('reports')
                                                    .add({
                                                  'reviewId': review.id,
                                                  'reporterId': FirebaseAuth
                                                      .instance
                                                      .currentUser
                                                      ?.uid,
                                                  'reason': reportReason,
                                                  'timestamp': FieldValue
                                                      .serverTimestamp(),
                                                });

                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                      content: Text(
                                                          l10n.reportReceived)),
                                                );
                                              } catch (e) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                      content: Text(
                                                          l10n.reportFailed)),
                                                );
                                              }
                                            }
                                            Navigator.pop(context);
                                          },
                                        ),
                                      ],
                                      ListTile(
                                        leading: const Icon(Icons.cancel),
                                        title: Text(l10n.cancel),
                                        onTap: () {
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            icon: const Icon(Icons.more_vert),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          RatingBarIndicator(
                            rating: review['rating'].toDouble(),
                            itemBuilder: (context, index) => const Icon(
                              Icons.star,
                              color: Colors.orange,
                            ),
                            itemCount: 5,
                            itemSize: 20.0,
                            direction: Axis.horizontal,
                          ),
                          const SizedBox(width: 8),
                          Text(': ${l10n.seichitourokuSatisfaction}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        review['review'],
                        style: TextStyle(color: Colors.grey[800]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
