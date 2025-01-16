import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserKuchikomiPage extends StatelessWidget {
  const UserKuchikomiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          l10n.myKuchikomi,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: userId == null
          ? Center(child: Text(l10n.needLogin))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reviews')
                  .where('userId', isEqualTo: userId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text(l10n.errorOccurred));
                }

                final reviews = snapshot.data?.docs ?? [];

                if (reviews.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rate_review_outlined,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noKuchikomi,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: reviews.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final review =
                        reviews[index].data() as Map<String, dynamic>;
                    final timestamp =
                        (review['timestamp'] as Timestamp).toDate();
                    final formattedDate =
                        DateFormat('yyyy年MM月dd日 HH時mm分').format(timestamp);

                    return Card(
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (review['imageUrl'] != null)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8)),
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
                                      backgroundImage:
                                          review['userProfileImage'] != null
                                              ? NetworkImage(
                                                  review['userProfileImage'])
                                              : null,
                                      child: review['userProfileImage'] == null
                                          ? const Icon(Icons.person)
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                review['userName'] ??
                                                    l10n.unknown,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              Text(
                                                '${l10n.postedDate}: $formattedDate',
                                                style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12),
                                              ),
                                            ],
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              showModalBottomSheet(
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: <Widget>[
                                                      if (review['userId'] ==
                                                          FirebaseAuth.instance
                                                              .currentUser?.uid)
                                                        ListTile(
                                                          leading: const Icon(
                                                              Icons.delete,
                                                              color:
                                                                  Colors.red),
                                                          title: Text(
                                                              l10n.delete,
                                                              style: const TextStyle(
                                                                  color: Colors
                                                                      .red)),
                                                          onTap: () async {
                                                            final bool?
                                                                confirmDelete =
                                                                await showDialog<
                                                                    bool>(
                                                              context: context,
                                                              builder:
                                                                  (BuildContext
                                                                      context) {
                                                                return AlertDialog(
                                                                  title: Text(l10n
                                                                      .confirm),
                                                                  content: Text(
                                                                      l10n.deleteReviewConfirm),
                                                                  actions: <Widget>[
                                                                    TextButton(
                                                                      child: Text(
                                                                          l10n.cancel),
                                                                      onPressed:
                                                                          () =>
                                                                              Navigator.of(context).pop(false),
                                                                    ),
                                                                    TextButton(
                                                                      child: Text(
                                                                          l10n
                                                                              .delete,
                                                                          style:
                                                                              const TextStyle(color: Colors.red)),
                                                                      onPressed:
                                                                          () =>
                                                                              Navigator.of(context).pop(true),
                                                                    ),
                                                                  ],
                                                                );
                                                              },
                                                            );

                                                            if (confirmDelete ==
                                                                true) {
                                                              try {
                                                                // 画像がある場合、Storageから削除
                                                                if (review[
                                                                        'imageUrl'] !=
                                                                    null) {
                                                                  try {
                                                                    final storageRef = FirebaseStorage
                                                                        .instance
                                                                        .refFromURL(
                                                                            review['imageUrl']);
                                                                    await storageRef
                                                                        .delete();
                                                                  } catch (e) {
                                                                    // print('画像の削除中にエラーが発生しました: $e');
                                                                  }
                                                                }

                                                                // Firestoreから口コミを削除
                                                                await FirebaseFirestore
                                                                    .instance
                                                                    .collection(
                                                                        'reviews')
                                                                    .doc(reviews[
                                                                            index]
                                                                        .id)
                                                                    .delete();

                                                                Navigator.of(
                                                                        context)
                                                                    .pop();
                                                                Navigator.of(
                                                                        context)
                                                                    .pop(); // 詳細画面を閉じる
                                                                ScaffoldMessenger.of(
                                                                        context)
                                                                    .showSnackBar(
                                                                  SnackBar(
                                                                      content:
                                                                          Text(l10n
                                                                              .reviewDeleted)),
                                                                );
                                                              } catch (e) {
                                                                // print('口コミの削除中にエラーが発生しました: $e');
                                                                ScaffoldMessenger.of(
                                                                        context)
                                                                    .showSnackBar(
                                                                  SnackBar(
                                                                      content:
                                                                          Text(l10n
                                                                              .reviewDeleteError)),
                                                                );
                                                              }
                                                            } else {
                                                              Navigator.of(
                                                                      context)
                                                                  .pop();
                                                            }
                                                          },
                                                        )
                                                      else ...[
                                                        ListTile(
                                                          leading: const Icon(
                                                              Icons.flag,
                                                              color:
                                                                  Colors.red),
                                                          title: Text(
                                                              l10n.report,
                                                              style: const TextStyle(
                                                                  color: Colors
                                                                      .red)),
                                                          onTap: () async {
                                                            final String?
                                                                reportReason =
                                                                await showDialog<
                                                                    String>(
                                                              context: context,
                                                              builder:
                                                                  (BuildContext
                                                                      context) {
                                                                return _ReportDialog();
                                                              },
                                                            );

                                                            if (reportReason !=
                                                                null) {
                                                              try {
                                                                await FirebaseFirestore
                                                                    .instance
                                                                    .collection(
                                                                        'reports')
                                                                    .add({
                                                                  'reviewId':
                                                                      reviews[index]
                                                                          .id,
                                                                  'reporterId':
                                                                      FirebaseAuth
                                                                          .instance
                                                                          .currentUser
                                                                          ?.uid,
                                                                  'reason':
                                                                      reportReason,
                                                                  'timestamp':
                                                                      FieldValue
                                                                          .serverTimestamp(),
                                                                });

                                                                ScaffoldMessenger.of(
                                                                        context)
                                                                    .showSnackBar(
                                                                  SnackBar(
                                                                      content:
                                                                          Text(l10n
                                                                              .reportReceived)),
                                                                );
                                                              } catch (e) {
                                                                ScaffoldMessenger.of(
                                                                        context)
                                                                    .showSnackBar(
                                                                  SnackBar(
                                                                      content:
                                                                          Text(l10n
                                                                              .reportFailed)),
                                                                );
                                                              }
                                                            }
                                                            Navigator.pop(
                                                                context);
                                                          },
                                                        ),
                                                      ],
                                                      ListTile(
                                                        leading: const Icon(
                                                            Icons.cancel),
                                                        title:
                                                            Text(l10n.cancel),
                                                        onTap: () {
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                            icon: const Icon(Icons.more_vert),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    RatingBarIndicator(
                                      rating:
                                          (review['rating'] ?? 0).toDouble(),
                                      itemBuilder: (context, index) =>
                                          const Icon(
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
                                  review['review'] ?? '',
                                  style: TextStyle(color: Colors.grey[800]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _ReportDialog extends StatefulWidget {
  @override
  _ReportDialogState createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  late List<String> _reportReasons;
  String? _selectedReason;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;
    _reportReasons = [
      l10n.inappropriateContent,
      l10n.spamOrAdvertisement,
      l10n.incorrectInformation,
      l10n.other,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.selectReportReason,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_reportReasons.length, (index) {
          return RadioListTile<String>(
            title: Text(_reportReasons[index]),
            value: _reportReasons[index],
            groupValue: _selectedReason,
            onChanged: (String? value) {
              setState(() {
                _selectedReason = value;
              });
            },
          );
        }),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(l10n.cancel),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        TextButton(
          child: Text(l10n.report),
          onPressed: () {
            Navigator.of(context).pop(_selectedReason);
          },
        ),
      ],
    );
  }
}
