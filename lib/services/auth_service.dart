import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String baseUrl = "http://172.210.139.244:8000"; // Your backend base URL

  // 🔸 Login function
  Future<Map<String, dynamic>> loginUser(
      String email, String password, String role) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/users/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
          "role": role,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Store login info locally (works like cookies)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', data['user_id']);
        await prefs.setString('role', data['role']);
        await prefs.setBool('isLoggedIn', true);

        return {"success": true, "data": data};
      } else {
        return {"success": false, "message": "Invalid credentials"};
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  // 🔸 Get stored user info
  Future<Map<String, dynamic>?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (!isLoggedIn) return null;

    final userId = prefs.getInt('user_id');
    final role = prefs.getString('role');
    return {"user_id": userId, "role": role};
  }

  // 🔸 Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
