import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/question.dart';

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
}

