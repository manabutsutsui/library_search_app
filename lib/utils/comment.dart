class Comment {
  final String id;
  final String userId;
  final String userName;
  final String? userImage;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.userId,
    required this.userName,
    this.userImage,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'content': content,
      'createdAt': createdAt,
    };
  }
}
