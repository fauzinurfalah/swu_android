import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = ''; 

  // Login method
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await Dio().post(
        "${baseUrl}auth/login",
        data: {
          "email": email,
          "password": password,
        },
      );

      return response.data;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Register method
  static Future<Map<String, dynamic>> register(
    Map<String, dynamic> data,
    ) async{
    try{
      final response = await Dio().post(
        "${baseUrl}auth/register",
        data: data,
      );
      return response.data;
    } catch(e){
      return {'error': e.toString()};
    }
  }

  // Simpan token
  static Future<void> saveToken(String token, String email) async{
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('auth_token', email);
  }

  // logout method
  static Future<void> logout() async{
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('email');
  }
}


