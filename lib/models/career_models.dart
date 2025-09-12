import 'package:cloud_firestore/cloud_firestore.dart';

// ==================== USER MODEL ====================
class User {
  final String userId;
  final String name;
  final String email;
  final String password;
  final String phone;
  final String tier;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.userId,
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    required this.tier,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      userId: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      password: data['password'] ?? '',
      phone: data['phone'] ?? '',
      tier: data['tier'] ?? 'basic',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'tier': tier,
    };
  }

  User copyWith({
    String? name,
    String? email,
    String? password,
    String? phone,
    String? tier,
  }) {
    return User(
      userId: userId,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      tier: tier ?? this.tier,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

// ==================== CAREER BANK MODEL ====================
class CareerBank {
  final String careerId;
  final String title;
  final String industry;
  final String description;
  final List<String> skills;
  final String salaryRange;
  final EducationPath? educationPath;
  final String? imageUrl; // thêm ảnh
  final DateTime createdAt;
  final DateTime updatedAt;

  CareerBank({
    required this.careerId,
    required this.title,
    required this.industry,
    required this.description,
    required this.skills,
    required this.salaryRange,
    this.educationPath,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CareerBank.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    EducationPath? educationPath;
    if (data['educationPath'] != null) {
      educationPath = EducationPath.fromMap(Map<String, dynamic>.from(data['educationPath']));
    }

    DateTime createdAt = DateTime.now();
    if (data.containsKey('createdAt') && data['createdAt'] != null) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    }

    DateTime updatedAt = DateTime.now();
    if (data.containsKey('updatedAt') && data['updatedAt'] != null) {
      updatedAt = (data['updatedAt'] as Timestamp).toDate();
    }

    return CareerBank(
      careerId: doc.id,
      title: data['title'] ?? '',
      industry: data['industry'] ?? '',
      description: data['description'] ?? '',
      skills: data['skills'] != null ? List<String>.from(data['skills']) : [],
      salaryRange: data['salaryRange'] ?? '',
      educationPath: educationPath,
      imageUrl: data['imageUrl'],
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'industry': industry,
      'description': description,
      'skills': skills,
      'salaryRange': salaryRange,
      'educationPath': educationPath?.toMap(),
      'imageUrl': imageUrl,
    };
  }
}

class EducationPath {
  final String degree;
  final List<String> courses;
  final List<String> certificates;
  final String duration;
  final String careerLevel;
  final String estimatedCost;

  EducationPath({
    required this.degree,
    required this.courses,
    required this.certificates,
    required this.duration,
    required this.careerLevel,
    required this.estimatedCost,
  });

  factory EducationPath.fromMap(Map<String, dynamic> map) {
    return EducationPath(
      degree: map['degree'] ?? '',
      courses: List<String>.from(map['courses'] ?? []),
      certificates: List<String>.from(map['certificates'] ?? []),
      duration: map['duration'] ?? '',
      careerLevel: map['career_level'] ?? '',
      estimatedCost: map['estimated_cost'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'degree': degree,
      'courses': courses,
      'certificates': certificates,
      'duration': duration,
      'career_level': careerLevel,
      'estimated_cost': estimatedCost,
    };
  }
}
// ==================== QUIZ MODEL ====================
class Quiz {
  final String questionId;
  final String questionText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final Map<String, int> scoreMap; // Map từ option đến điểm số
  final DateTime createdAt;
  final DateTime updatedAt;

  Quiz({
    required this.questionId,
    required this.questionText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.scoreMap,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Quiz.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Quiz(
      questionId: doc.id,
      questionText: data['questionText'] ?? '',
      optionA: data['optionA'] ?? '',
      optionB: data['optionB'] ?? '',
      optionC: data['optionC'] ?? '',
      optionD: data['optionD'] ?? '',
      scoreMap: Map<String, int>.from(data['scoreMap'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'questionText': questionText,
      'optionA': optionA,
      'optionB': optionB,
      'optionC': optionC,
      'optionD': optionD,
      'scoreMap': scoreMap,
    };
  }

  Quiz copyWith({
    String? questionText,
    String? optionA,
    String? optionB,
    String? optionC,
    String? optionD,
    Map<String, int>? scoreMap,
  }) {
    return Quiz(
      questionId: questionId,
      questionText: questionText ?? this.questionText,
      optionA: optionA ?? this.optionA,
      optionB: optionB ?? this.optionB,
      optionC: optionC ?? this.optionC,
      optionD: optionD ?? this.optionD,
      scoreMap: scoreMap ?? this.scoreMap,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

// ==================== TESTIMONIAL MODEL ====================
class Testimonial {
  final String testimonialId;
  final String name;
  final String imageUrl;
  final String tier;
  final String story;
  final DateTime createdAt;
  final DateTime updatedAt;

  Testimonial({
    required this.testimonialId,
    required this.name,
    required this.imageUrl,
    required this.tier,
    required this.story,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Testimonial.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Testimonial(
      testimonialId: doc.id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      tier: data['tier'] ?? '',
      story: data['story'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'tier': tier,
      'story': story,
    };
  }

  Testimonial copyWith({
    String? name,
    String? imageUrl,
    String? tier,
    String? story,
  }) {
    return Testimonial(
      testimonialId: testimonialId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      tier: tier ?? this.tier,
      story: story ?? this.story,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

// ==================== FEEDBACK MODEL ====================
class Feedback {
  final String feedbackId;
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String message;
  final DateTime subDateTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  Feedback({
    required this.feedbackId,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.message,
    required this.subDateTime,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Feedback.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Feedback(
      feedbackId: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      message: data['message'] ?? '',
      subDateTime: (data['subDateTime'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'message': message,
      'subDateTime': subDateTime,
    };
  }

  Feedback copyWith({
    String? userId,
    String? name,
    String? email,
    String? phone,
    String? message,
    DateTime? subDateTime,
  }) {
    return Feedback(
      feedbackId: feedbackId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      message: message ?? this.message,
      subDateTime: subDateTime ?? this.subDateTime,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
