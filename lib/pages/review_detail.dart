import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'spot_detail.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewDetailPage extends StatelessWidget {
  final DocumentSnapshot review;
  final DocumentSnapshot spot;

  const ReviewDetailPage({Key? key, required this.review, required this.spot})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(spot['name'],
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                elevation: 10,
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
                                      '投稿日: ${DateFormat('yyyy年MM月dd日 HH時mm分').format(review['timestamp'].toDate())}',
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
                                              FirebaseAuth.instance.currentUser?.uid)
                                            ListTile(
                                              leading: const Icon(Icons.delete,
                                                  color: Colors.red),
                                              title: const Text('削除する',
                                                  style:
                                                      TextStyle(color: Colors.red)),
                                              onTap: () async {
                                                final bool? confirmDelete =
                                                    await showDialog<bool>(
                                                  context: context,
                                                  builder: (BuildContext context) {
                                                    return AlertDialog(
                                                      title: const Text('確認'),
                                                      content: const Text(
                                                          'この口コミを削除してもよろしいですか？'),
                                                      actions: <Widget>[
                                                        TextButton(
                                                          child: const Text('キャンセル'),
                                                          onPressed: () =>
                                                              Navigator.of(context)
                                                                  .pop(false),
                                                        ),
                                                        TextButton(
                                                          child: const Text('削除',
                                                              style: TextStyle(
                                                                  color: Colors.red)),
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
                                                    await FirebaseFirestore.instance
                                                        .collection('reviews')
                                                        .doc(review.id)
                                                        .delete();
                
                                                    Navigator.of(context).pop();
                                                    ScaffoldMessenger.of(context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                          content:
                                                              Text('口コミを削除しました')),
                                                    );
                                                  } catch (e) {
                                                    print('口コミの削除中にエラーが発生しました: $e');
                                                    ScaffoldMessenger.of(context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                          content:
                                                              Text('口コミの削除に失敗しました')),
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
                                              title: const Text('報告する',
                                                  style:
                                                      TextStyle(color: Colors.red)),
                                              onTap: () async {
                                                final String? reportReason =
                                                    await showDialog<String>(
                                                  context: context,
                                                  builder: (BuildContext context) {
                                                    return _ReportDialog();
                                                  },
                                                );
                
                                                if (reportReason != null) {
                                                  try {
                                                    await FirebaseFirestore.instance
                                                        .collection('reports')
                                                        .add({
                                                      'reviewId': review.id,
                                                      'reporterId': FirebaseAuth
                                                          .instance.currentUser?.uid,
                                                      'reason': reportReason,
                                                      'timestamp': FieldValue
                                                          .serverTimestamp(),
                                                    });
                
                                                    ScaffoldMessenger.of(context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                          content:
                                                              Text('報告を受け付けました。')),
                                                    );
                                                  } catch (e) {
                                                    print('報告の送信中にエラーが発生しました: $e');
                                                    ScaffoldMessenger.of(context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                          content:
                                                              Text('報告の送信に失敗しました。')),
                                                    );
                                                  }
                                                }
                                                Navigator.pop(context);
                                              },
                                            ),
                                          ],
                                          ListTile(
                                            leading: const Icon(Icons.cancel),
                                            title: const Text('キャンセル'),
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
                              const Text(': 聖地の満足度'),
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
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SpotDetailPage(spot: spot)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('聖地の詳細を見る',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportDialog extends StatefulWidget {
  @override
  _ReportDialogState createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final List<String> _reportReasons = [
    '不適切なコンテンツ',
    'スパムまたは広告',
    '誤った情報',
    'その他',
  ];
  String? _selectedReason;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('報告理由を選択してください',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
          child: const Text('キャンセル'),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        TextButton(
          child: const Text('報告する'),
          onPressed: () {
            Navigator.of(context).pop(_selectedReason);
          },
        ),
      ],
    );
  }
}
