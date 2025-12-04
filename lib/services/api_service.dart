import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/question.dart';
import '../models/challenge.dart';

class ApiService {
  static const String baseUrl = 'https://clhealeljrtyuyqhuknc.supabase.co/rest/v1';
  static const String apiKey = 'sb_publishable_LlptEh1uoP-HzAEFDrf9hA_PlhVVMsM';
  
  static Map<String, String> get headers => {
    'apikey': apiKey,
    'Authorization': 'Bearer $apiKey',
    'Content-Type': 'application/json',
    'Prefer': 'return=minimal',
  };

  // Get all questions
  static Future<List<Question>> getQuestions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/questions?select=*'),
        headers: {
          'apikey': apiKey,
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Question.fromJson(json)).toList();
      } else {
        throw Exception('فشل في جلب البيانات: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  // Insert a new question
  static Future<void> insertQuestion(Question question) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/questions'),
        headers: headers,
        body: json.encode(question.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      } else {
        throw Exception('فشل في إضافة السؤال: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  // Delete a question by ID
  static Future<void> deleteQuestion(int questionId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/questions?question_id=eq.$questionId'),
        headers: {
          'apikey': apiKey,
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      } else {
        throw Exception('فشل في حذف السؤال: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  // Update a question by ID
  static Future<void> updateQuestion(int questionId, Question question) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/questions?question_id=eq.$questionId'),
        headers: headers,
        body: json.encode(question.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      } else {
        throw Exception('فشل في تحديث السؤال: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  // Get all challenges
  static Future<List<Challenge>> getChallenges() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/challenges?select=*&order=created_at.desc'),
        headers: {
          'apikey': apiKey,
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) {
          try {
            return Challenge.fromJson(json);
          } catch (e) {
            print('Error parsing challenge: $e, JSON: $json');
            rethrow;
          }
        }).toList();
      } else {
        print('Failed to get challenges: ${response.statusCode}, Body: ${response.body}');
        throw Exception('فشل في جلب التحديات: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error getting challenges: $e');
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  // Insert a daily challenge question
  static Future<void> insertDailyChallengeQuestion(Question question) async {
    try {
      if (question.challengeId == null) {
        throw Exception('challenge_id مطلوب لإضافة سؤال التحدي اليومي');
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/daily_challenge_questions'),
        headers: headers,
        body: json.encode(question.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      } else {
        throw Exception('فشل في إضافة سؤال التحدي اليومي: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  // Insert a new challenge
  static Future<void> insertChallenge(Challenge challenge) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/challenges'),
        headers: headers,
        body: json.encode(challenge.toJsonForInsert()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      } else {
        throw Exception('فشل في إضافة التحدي: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  // Update a challenge by ID
  static Future<void> updateChallenge(int challengeId, Challenge challenge) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/challenges?challenge_id=eq.$challengeId'),
        headers: headers,
        body: json.encode(challenge.toJsonForInsert()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      } else {
        throw Exception('فشل في تحديث التحدي: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  // Delete a challenge by ID
  static Future<void> deleteChallenge(int challengeId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/challenges?challenge_id=eq.$challengeId'),
        headers: {
          'apikey': apiKey,
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      } else {
        throw Exception('فشل في حذف التحدي: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  // Get daily challenge questions by challenge ID
  static Future<List<Question>> getDailyChallengeQuestions(int challengeId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/daily_challenge_questions?challenge_id=eq.$challengeId&select=*'),
        headers: {
          'apikey': apiKey,
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Question.fromJson(json)).toList();
      } else {
        throw Exception('فشل في جلب أسئلة التحدي: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  // Update a daily challenge question by ID
  static Future<void> updateDailyChallengeQuestion(int questionId, Question question) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/daily_challenge_questions?question_id=eq.$questionId'),
        headers: headers,
        body: json.encode(question.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      } else {
        throw Exception('فشل في تحديث سؤال التحدي: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  // Delete a daily challenge question by ID
  static Future<void> deleteDailyChallengeQuestion(int questionId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/daily_challenge_questions?question_id=eq.$questionId'),
        headers: {
          'apikey': apiKey,
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      } else {
        throw Exception('فشل في حذف سؤال التحدي: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال: $e');
    }
  }
}

