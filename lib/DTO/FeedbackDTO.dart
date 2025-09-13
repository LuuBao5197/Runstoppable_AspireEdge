class FeedbackDTO {
  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final String message;
  final DateTime createdAt;

  FeedbackDTO({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.message,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      "userId": userId,
      "fullName": fullName,
      "email": email,
      "phone": phone,
      "message": message,
      "createdAt": createdAt.toIso8601String(),
    };
  }
}