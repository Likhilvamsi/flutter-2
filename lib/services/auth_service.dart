import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // 🌐 Your FastAPI backend URL
  final String baseUrl = "https://135.237.191.7.nip.io";

  // 🔹 User Login
  Future<Map<String, dynamic>> loginUser(
    String email,
    String password,
    String role,
  ) async {
    final Uri url = Uri.parse("$baseUrl/users/login");

    try {
      print("🌐 Sending POST request to: $url");
      print("📦 Body: ${jsonEncode({
        "email": email,
        "password": password,
        "role": role.toLowerCase(), // ensure lowercase
      })}");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
          "role": role.toLowerCase(),
        }),
      );

      print("📩 Response status: ${response.statusCode}");
      print("📩 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Save user info locally (acts like cookies)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', data['user_id']);
        await prefs.setString('role', data['role']);
        await prefs.setBool('isLoggedIn', true);

        print("✅ Login success for user_id: ${data['user_id']}");
        return {"success": true, "data": data};
      } else {
        print("❌ Login failed: ${response.statusCode} ${response.body}");
        return {
          "success": false,
          "message": "Invalid credentials or server error"
        };
      }
    } catch (e) {
      print("⚠️ Login Exception: $e");
      return {"success": false, "message": e.toString()};
    }
  }

  // 🔹 Retrieve stored user info
  Future<Map<String, dynamic>?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (!isLoggedIn) return null;

    final userId = prefs.getInt('user_id');
    final role = prefs.getString('role');
    print("📦 Retrieved user: id=$userId, role=$role");
    return {"user_id": userId, "role": role};
  }

  // 🔹 Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print("👋 User logged out successfully");
  }
}
