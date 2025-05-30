class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final String? fcmToken;
  UserModel({
    required this.uid,
    required this.email,
    this.displayName = '',
    this.photoUrl = '',
    this.fcmToken,
  });
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      if (fcmToken != null) 'fcmToken': fcmToken,
    };
  }
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String? ?? '',
      photoUrl: map['photoUrl'] as String? ?? '',
      fcmToken: map['fcmToken'] as String?,
    );
  }
}