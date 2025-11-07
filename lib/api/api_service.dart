import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://36.91.103.196:8000/api/';

   static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: const {
        'Accept': 'application/json',
      },
    ),
  );

  static Map<String, dynamic> _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.badCertificate ||
        e.type == DioExceptionType.connectionError) {
      return {
        'error':
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda dan coba lagi.',
      };
    }

    if (e.response != null) {
      final statusCode = e.response?.statusCode ?? 500;
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'] ?? data['error'] ??
            'Terjadi kesalahan pada server (Kode: $statusCode).';
        return {
          'status': statusCode,
          'message': message,
        };
      }
      return {
        'status': statusCode,
        'message': 'Terjadi kesalahan pada server (Kode: $statusCode).',
      };
    }

    return {
      'error': 'Terjadi kesalahan yang tidak diketahui. Silakan coba lagi nanti.'
    };
  }

  // Login method
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await _dio.post(
        'auth/login',
        data: {'email': email, 'password': password, 'role': 1},
      );
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return {
        'error':
            'Terjadi kesalahan yang tidak diketahui. Silakan coba lagi nanti.',
      };
    }
  }

  // Register method
  static Future<Map<String, dynamic>> register(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post('auth/register', data: data);
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return {
        'error':
            'Terjadi kesalahan yang tidak diketahui. Silakan coba lagi nanti.',
      };
    }
  }

  // Simpan Token
  static Future<void> saveToken(String token, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('auth_email', email);
  }

  // get Token
  static Future<Map<String, dynamic>?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return token != null ? jsonDecode(token) : null;
  }

  // logout method
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_email');
  }
}
