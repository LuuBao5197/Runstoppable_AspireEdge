import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/career_models.dart';

class CareerFirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==================== USER OPERATIONS ====================
  
  /// Tạo user mới
  static Future<void> createUser({
    required String userId,
    required String name,
    required String email,
    required String password,
    required String phone,
    String tier = 'basic',
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'tier': tier,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error creating user: $e');
    }
  }

  /// Lấy thông tin user
  static Future<User?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return User.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error getting user: $e');
    }
  }

  /// Cập nhật thông tin user
  static Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error updating user: $e');
    }
  }

  /// Lấy tất cả users
  static Stream<QuerySnapshot> getAllUsers() {
    return _firestore.collection('users').orderBy('createdAt', descending: true).snapshots();
  }

  // ==================== CAREER BANK OPERATIONS ====================
  
  /// Tạo career mới
  static Future<void> createCareer({
    required String title,
    required String industry,
    required String description,
    required List<String> skills,
    required String salaryRange,
    required String educationPath,
  }) async {
    try {
      await _firestore.collection('careers').add({
        'title': title,
        'industry': industry,
        'description': description,
        'skills': skills,
        'salaryRange': salaryRange,
        'educationPath': educationPath,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error creating career: $e');
    }
  }

  /// Lấy career theo ID
  static Future<CareerBank?> getCareer(String careerId) async {
    try {
      final doc = await _firestore.collection('careers').doc(careerId).get();
      if (doc.exists) {
        return CareerBank.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error getting career: $e');
    }
  }

  /// Lấy tất cả careers
  static Stream<QuerySnapshot> getAllCareers() {
    return _firestore.collection('careers').orderBy('createdAt', descending: true).snapshots();
  }

  /// Tìm kiếm careers theo industry
  static Stream<QuerySnapshot> getCareersByIndustry(String industry) {
    return _firestore
        .collection('careers')
        .where('industry', isEqualTo: industry)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Tìm kiếm careers theo skills
  static Stream<QuerySnapshot> getCareersBySkills(List<String> skills) {
    return _firestore
        .collection('careers')
        .where('skills', arrayContainsAny: skills)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Cập nhật career
  static Future<void> updateCareer(String careerId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('careers').doc(careerId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error updating career: $e');
    }
  }

  /// Xóa career
  static Future<void> deleteCareer(String careerId) async {
    try {
      await _firestore.collection('careers').doc(careerId).delete();
    } catch (e) {
      throw Exception('Error deleting career: $e');
    }
  }

  // ==================== QUIZ OPERATIONS ====================
  
  /// Tạo quiz question mới
  static Future<void> createQuizQuestion({
    required String questionText,
    required String optionA,
    required String optionB,
    required String optionC,
    required String optionD,
    required Map<String, int> scoreMap,
  }) async {
    try {
      await _firestore.collection('quiz_questions').add({
        'questionText': questionText,
        'optionA': optionA,
        'optionB': optionB,
        'optionC': optionC,
        'optionD': optionD,
        'scoreMap': scoreMap,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error creating quiz question: $e');
    }
  }

  /// Lấy quiz question theo ID
  static Future<Quiz?> getQuizQuestion(String questionId) async {
    try {
      final doc = await _firestore.collection('quiz_questions').doc(questionId).get();
      if (doc.exists) {
        return Quiz.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error getting quiz question: $e');
    }
  }

  /// Lấy tất cả quiz questions
  static Stream<QuerySnapshot> getAllQuizQuestions() {
    return _firestore.collection('quiz_questions').orderBy('createdAt', descending: true).snapshots();
  }

  /// Cập nhật quiz question
  static Future<void> updateQuizQuestion(String questionId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('quiz_questions').doc(questionId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error updating quiz question: $e');
    }
  }

  /// Xóa quiz question
  static Future<void> deleteQuizQuestion(String questionId) async {
    try {
      await _firestore.collection('quiz_questions').doc(questionId).delete();
    } catch (e) {
      throw Exception('Error deleting quiz question: $e');
    }
  }

  // ==================== TESTIMONIAL OPERATIONS ====================
  
  /// Tạo testimonial mới
  static Future<void> createTestimonial({
    required String name,
    required String imageUrl,
    required String tier,
    required String story,
  }) async {
    try {
      await _firestore.collection('testimonials').add({
        'name': name,
        'imageUrl': imageUrl,
        'tier': tier,
        'story': story,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error creating testimonial: $e');
    }
  }

  /// Lấy testimonial theo ID
  static Future<Testimonial?> getTestimonial(String testimonialId) async {
    try {
      final doc = await _firestore.collection('testimonials').doc(testimonialId).get();
      if (doc.exists) {
        return Testimonial.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error getting testimonial: $e');
    }
  }

  /// Lấy tất cả testimonials
  static Stream<QuerySnapshot> getAllTestimonials() {
    return _firestore.collection('testimonials').orderBy('createdAt', descending: true).snapshots();
  }

  /// Lấy testimonials theo tier
  static Stream<QuerySnapshot> getTestimonialsByTier(String tier) {
    return _firestore
        .collection('testimonials')
        .where('tier', isEqualTo: tier)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Cập nhật testimonial
  static Future<void> updateTestimonial(String testimonialId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('testimonials').doc(testimonialId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error updating testimonial: $e');
    }
  }

  /// Xóa testimonial
  static Future<void> deleteTestimonial(String testimonialId) async {
    try {
      await _firestore.collection('testimonials').doc(testimonialId).delete();
    } catch (e) {
      throw Exception('Error deleting testimonial: $e');
    }
  }

  // ==================== FEEDBACK OPERATIONS ====================
  
  /// Tạo feedback mới
  static Future<void> createFeedback({
    required String userId,
    required String name,
    required String email,
    required String phone,
    required String message,
  }) async {
    try {
      await _firestore.collection('feedbacks').add({
        'userId': userId,
        'name': name,
        'email': email,
        'phone': phone,
        'message': message,
        'subDateTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error creating feedback: $e');
    }
  }

  /// Lấy feedback theo ID
  static Future<Feedback?> getFeedback(String feedbackId) async {
    try {
      final doc = await _firestore.collection('feedbacks').doc(feedbackId).get();
      if (doc.exists) {
        return Feedback.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error getting feedback: $e');
    }
  }

  /// Lấy tất cả feedbacks
  static Stream<QuerySnapshot> getAllFeedbacks() {
    return _firestore.collection('feedbacks').orderBy('subDateTime', descending: true).snapshots();
  }

  /// Lấy feedbacks theo user
  static Stream<QuerySnapshot> getFeedbacksByUser(String userId) {
    return _firestore
        .collection('feedbacks')
        .where('userId', isEqualTo: userId)
        .orderBy('subDateTime', descending: true)
        .snapshots();
  }

  /// Cập nhật feedback
  static Future<void> updateFeedback(String feedbackId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('feedbacks').doc(feedbackId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error updating feedback: $e');
    }
  }

  /// Xóa feedback
  static Future<void> deleteFeedback(String feedbackId) async {
    try {
      await _firestore.collection('feedbacks').doc(feedbackId).delete();
    } catch (e) {
      throw Exception('Error deleting feedback: $e');
    }
  }

  // ==================== UTILITY METHODS ====================
  
  /// Lấy thống kê tổng quan
  static Future<Map<String, int>> getStatistics() async {
    try {
      final usersCount = await _firestore.collection('users').get();
      final careersCount = await _firestore.collection('careers').get();
      final quizCount = await _firestore.collection('quiz_questions').get();
      final testimonialsCount = await _firestore.collection('testimonials').get();
      final feedbacksCount = await _firestore.collection('feedbacks').get();

      return {
        'users': usersCount.docs.length,
        'careers': careersCount.docs.length,
        'quiz_questions': quizCount.docs.length,
        'testimonials': testimonialsCount.docs.length,
        'feedbacks': feedbacksCount.docs.length,
      };
    } catch (e) {
      throw Exception('Error getting statistics: $e');
    }
  }
}
