class FeedbackDTO {
  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final String message;
  final DateTime createdAt;
  final int rating; // ⭐️ thêm rating

  FeedbackDTO({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.message,
    required this.createdAt,
    required this.rating,
  });

  Map<String, dynamic> toJson() {
    return {
      "userId": userId,
      "fullName": fullName,
      "email": email,
      "phone": phone,
      "message": message,
      "createdAt": createdAt,
      "rating": rating,
    };
  }
}
