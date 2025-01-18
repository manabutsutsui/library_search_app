import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:uuid/uuid.dart';
import '../utils/comment.dart';

class OtherUserProfilePage extends StatefulWidget {
  final String userId;
  final String userName;
  final String? profileImage;

  const OtherUserProfilePage({
    super.key,
    required this.userId,
    required this.userName,
    this.profileImage,
  });

  @override
  State<OtherUserProfilePage> createState() => _OtherUserProfilePageState();
}

class _OtherUserProfilePageState extends State<OtherUserProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _xAccountUrl;
  String? _instagramAccountUrl;
  String? _tiktokAccountUrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSocialAccounts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSocialAccounts() async {
    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
    setState(() {
      _xAccountUrl = userData.data()?['xAccountUrl'];
      _instagramAccountUrl = userData.data()?['instagramAccountUrl'];
      _tiktokAccountUrl = userData.data()?['tiktokAccountUrl'];
    });
  }

  Widget _buildSocialIcons() {
    return Row(
      children: [
        GestureDetector(
          onTap: _xAccountUrl != null
              ? () async {
                  if (await canLaunch(_xAccountUrl!)) {
                    await launch(_xAccountUrl!);
                  }
                }
              : null,
          child: Image.asset(
            'assets/sns_icon/x_icon.png',
            width: 24,
            height: 24,
            color: _xAccountUrl != null ? null : Colors.grey,
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: _instagramAccountUrl != null
              ? () async {
                  if (await canLaunch(_instagramAccountUrl!)) {
                    await launch(_instagramAccountUrl!);
                  }
                }
              : null,
          child: Image.asset(
            'assets/sns_icon/insta_icon.png',
            width: 24,
            height: 24,
            color: _instagramAccountUrl != null ? null : Colors.grey,
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: _tiktokAccountUrl != null
              ? () async {
                  if (await canLaunch(_tiktokAccountUrl!)) {
                    await launch(_tiktokAccountUrl!);
                  }
                }
              : null,
          child: Image.asset(
            'assets/sns_icon/tiktok_icon.png',
            width: 24,
            height: 24,
            color: _tiktokAccountUrl != null ? null : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('userId', isEqualTo: widget.userId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
              child: Text(
                  '${AppLocalizations.of(context)!.errorOccurred}: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.rate_review, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.noReviews,
                    style: const TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final review = snapshot.data!.docs[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Card(
                elevation: 2,
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
                                backgroundImage: review['userProfileImage'] !=
                                        null
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
                                      review['userName'] ??
                                          AppLocalizations.of(context)!
                                              .unknownUser,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      AppLocalizations.of(context)!.reviewDate(
                                        DateFormat('yyyy年MM月dd日 HH時mm分').format(
                                            review['timestamp'].toDate()),
                                      ),
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12),
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
                              Text(AppLocalizations.of(context)!
                                  .satisfactionLevel),
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
      },
    );
  }

  Future<void> _toggleLike(
      String postId, bool isLiked, List<String> likedBy) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);

    try {
      if (isLiked) {
        await postRef.update({
          'likedBy': FieldValue.arrayRemove([user.uid]),
          'likes': FieldValue.increment(-1),
        });
      } else {
        await postRef.update({
          'likedBy': FieldValue.arrayUnion([user.uid]),
          'likes': FieldValue.increment(1),
        });
      }
    } catch (e) {
      // print('Error toggling like: $e');
    }
  }

  void _showCommentDialog(BuildContext context, String postId) {
    final l10n = AppLocalizations.of(context)!;
    final TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: commentController,
                  decoration: InputDecoration(
                    hintText: l10n.writeComment,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.cancel),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (commentController.text.trim().isNotEmpty) {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          final userDoc = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .get();

                          final comment = Comment(
                            id: const Uuid().v4(),
                            userId: user.uid,
                            userName: userDoc['username'],
                            userImage: userDoc['profileImage'],
                            content: commentController.text.trim(),
                            createdAt: DateTime.now(),
                          );

                          await FirebaseFirestore.instance
                              .collection('posts')
                              .doc(postId)
                              .collection('comments')
                              .doc(comment.id)
                              .set(comment.toMap());

                          Navigator.pop(context);
                        }
                      }
                    },
                    child: Text(l10n.posts,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPostsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: widget.userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final posts = snapshot.data!.docs;
          if (posts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.post_add, size: 64, color: Colors.grey),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              try {
                final post = posts[index].data() as Map<String, dynamic>;
                final postId = posts[index].id;
                final timestamp = post['createdAt'] as Timestamp?;
                final createdAt = timestamp?.toDate() ?? DateTime.now();

                final likedBy = List<String>.from(post['likedBy'] ?? []);
                final currentUser = FirebaseAuth.instance.currentUser;
                final isLiked =
                    currentUser != null && likedBy.contains(currentUser.uid);
                final likesCount = post['likes'] ?? 0;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundImage: widget.profileImage != null
                                ? NetworkImage(widget.profileImage!)
                                : null,
                            child: widget.profileImage == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          widget.userName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          timeago.format(createdAt,
                                              locale: 'ja'),
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (post['text']?.isNotEmpty ?? false)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Text(post['text']),
                                  ),
                                if (post['imageUrl'] != null)
                                  Column(
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                        child: Image.network(
                                          post['imageUrl'],
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  ),
                                Row(
                                  children: [
                                    IconButton(
                                      style: const ButtonStyle(
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: Icon(
                                        isLiked
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: isLiked
                                            ? Colors.red
                                            : Colors.grey[600],
                                      ),
                                      onPressed: () =>
                                          _toggleLike(postId, isLiked, likedBy),
                                    ),
                                    if (likesCount > 0)
                                      Text(likesCount.toString()),
                                    const SizedBox(width: 16),
                                    IconButton(
                                      style: const ButtonStyle(
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(Icons.comment_outlined),
                                      onPressed: () =>
                                          _showCommentDialog(context, postId),
                                      color: Colors.grey[600],
                                    ),
                                    StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection('posts')
                                          .doc(postId)
                                          .collection('comments')
                                          .snapshots(),
                                      builder: (context, snapshot) {
                                        int commentCount = snapshot.hasData
                                            ? snapshot.data!.docs.length
                                            : 0;
                                        return commentCount > 0
                                            ? Text('$commentCount')
                                            : const SizedBox.shrink();
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1),
                  ],
                );
              } catch (e, stackTrace) {
                print('Error rendering post at index $index: $e');
                print('Stack trace: $stackTrace');
                return const SizedBox.shrink();
              }
            },
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          '${widget.userName} ${l10n.sProfile}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userDocument = snapshot.data!.data() as Map<String, dynamic>?;

          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.only(top: 16.0, right: 16.0, left: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: widget.profileImage != null
                                  ? NetworkImage(widget.profileImage!)
                                  : null,
                              child: widget.profileImage == null
                                  ? const Icon(Icons.person, size: 50)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.userName,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildSocialIcons(),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            userDocument?['bio'] ?? '',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabController,
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(text: l10n.kuchikomi),
                  Tab(text: l10n.posts),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildReviewsTab(),
                    _buildPostsTab(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
