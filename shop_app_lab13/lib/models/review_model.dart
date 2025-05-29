class ReviewModel {
  final String userId;
  final String userName;
  final String title;
  final String content;
  final double rating;
  final int timestamp;

  ReviewModel({
    required this.userId,
    required this.userName,
    required this.title,
    required this.content,
    required this.rating,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'title': title,
      'content': content,
      'rating': rating,
      'timestamp': timestamp,
    };
  }

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      userId: map['userId'] as String,
      userName: map['userName'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      rating: (map['rating'] as num).toDouble(),
      timestamp: (map['timestamp'] as num).toInt(),
    );
  }
}