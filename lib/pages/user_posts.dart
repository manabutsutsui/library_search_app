import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/comment.dart';
import 'other_user_profile.dart';
import 'package:uuid/uuid.dart';

class UserPostsPage extends StatelessWidget {
  final String userId;

  const UserPostsPage({super.key, required this.userId});

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
      // エラー処理
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

  Future<void> _deletePost(String postId) async {
    try {
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
    } catch (e) {
      // エラー処理
    }
  }

  Future<void> _reportPost(BuildContext context, String postId) async {
    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'postId': postId,
        'reportedAt': FieldValue.serverTimestamp(),
        'reportedBy': FirebaseAuth.instance.currentUser?.uid,
        'type': 'post',
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.reportSent)),
        );
      }
    } catch (e) {
      // エラー処理
    }
  }

  Future<void> _deleteComment(String postId, String commentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .delete();
    } catch (e) {
      // エラー処理
    }
  }

  Future<void> _reportComment(BuildContext context, String commentId) async {
    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'commentId': commentId,
        'reportedAt': FieldValue.serverTimestamp(),
        'reportedBy': FirebaseAuth.instance.currentUser?.uid,
        'type': 'comment',
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.reportSent)),
        );
      }
    } catch (e) {
      // エラー処理
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(l10n.posts,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(l10n.errorOccurred));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data!.docs;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
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
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OtherUserProfilePage(
                                  userId: post['userId'],
                                  userName: post['userName'] ?? l10n.unknown,
                                  profileImage: post['userImage'],
                                ),
                              ),
                            );
                          },
                          child: CircleAvatar(
                            backgroundImage: post['userImage'] != null
                                ? NetworkImage(post['userImage'])
                                : null,
                            child: post['userImage'] == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
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
                                        post['userName'] ?? l10n.unknown,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        timeago.format(createdAt, locale: 'ja'),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    style: const ButtonStyle(
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.more_vert),
                                    onPressed: () {
                                      final currentUser =
                                          FirebaseAuth.instance.currentUser;
                                      final isPostOwner =
                                          currentUser?.uid == post['userId'];

                                      showModalBottomSheet(
                                        context: context,
                                        builder: (context) {
                                          return SafeArea(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (isPostOwner)
                                                  ListTile(
                                                    leading: const Icon(
                                                        Icons.delete,
                                                        color: Colors.red),
                                                    title: Text(l10n.delete),
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      _deletePost(postId);
                                                    },
                                                  )
                                                else
                                                  ListTile(
                                                    leading:
                                                        const Icon(Icons.flag),
                                                    title: Text(l10n.report),
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      _reportPost(
                                                          context, postId);
                                                    },
                                                  ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    },
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
                                      borderRadius: BorderRadius.circular(12.0),
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
                                    Text(
                                      likesCount.toString(),
                                    ),
                                  const SizedBox(width: 16),
                                  IconButton(
                                    style: const ButtonStyle(
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(
                                      Icons.comment_outlined,
                                    ),
                                    onPressed: () {
                                      _showCommentDialog(context, postId);
                                    },
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
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('posts')
                                    .doc(postId)
                                    .collection('comments')
                                    .orderBy('createdAt', descending: false)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const SizedBox.shrink();
                                  }

                                  final comments = snapshot.data!.docs;
                                  if (comments.isEmpty) {
                                    return const SizedBox.shrink();
                                  }

                                  return Column(
                                    children: comments.map((comment) {
                                      final commentData = comment.data()
                                          as Map<String, dynamic>;
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8.0),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        OtherUserProfilePage(
                                                      userId:
                                                          commentData['userId'],
                                                      userName: commentData[
                                                              'userName'] ??
                                                          l10n.unknown,
                                                      profileImage: commentData[
                                                          'userImage'],
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: CircleAvatar(
                                                backgroundImage:
                                                    commentData['userImage'] !=
                                                            null
                                                        ? NetworkImage(
                                                            commentData[
                                                                'userImage'])
                                                        : null,
                                                child: commentData[
                                                            'userImage'] ==
                                                        null
                                                    ? const Icon(Icons.person)
                                                    : null,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        commentData[
                                                                'userName'] ??
                                                            l10n.unknown,
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                      IconButton(
                                                        style:
                                                            const ButtonStyle(
                                                          tapTargetSize:
                                                              MaterialTapTargetSize
                                                                  .shrinkWrap,
                                                        ),
                                                        padding:
                                                            EdgeInsets.zero,
                                                        constraints:
                                                            const BoxConstraints(),
                                                        icon: const Icon(
                                                            Icons.more_vert),
                                                        onPressed: () {
                                                          final currentUser =
                                                              FirebaseAuth
                                                                  .instance
                                                                  .currentUser;
                                                          final isCommentOwner =
                                                              currentUser
                                                                      ?.uid ==
                                                                  commentData[
                                                                      'userId'];

                                                          showModalBottomSheet(
                                                            context: context,
                                                            builder: (context) {
                                                              return SafeArea(
                                                                child: Column(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    if (isCommentOwner)
                                                                      ListTile(
                                                                        leading: const Icon(
                                                                            Icons
                                                                                .delete,
                                                                            color:
                                                                                Colors.red),
                                                                        title: Text(
                                                                            l10n.delete),
                                                                        onTap:
                                                                            () {
                                                                          Navigator.pop(
                                                                              context);
                                                                          _deleteComment(
                                                                              postId,
                                                                              commentData['id']);
                                                                        },
                                                                      )
                                                                    else
                                                                      ListTile(
                                                                        leading:
                                                                            const Icon(Icons.flag),
                                                                        title: Text(
                                                                            l10n.report),
                                                                        onTap:
                                                                            () {
                                                                          Navigator.pop(
                                                                              context);
                                                                          _reportComment(
                                                                              context,
                                                                              commentData['id']);
                                                                        },
                                                                      ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          );
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                  Text(
                                                    commentData['content'] ??
                                                        '',
                                                    style: const TextStyle(
                                                        fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
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
            },
          );
        },
      ),
    );
  }
}
