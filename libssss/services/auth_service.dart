// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class LoginResult {
  final bool success;
  final String? role;
  final int? userId;
  final String message;

  LoginResult({
    required this.success,
    this.role,
    this.userId,
    required this.message,
  });
}

class AuthService {
  final String baseUrl;
  AuthService({this.baseUrl = "http://127.0.0.1:8000"});

  /// Returns a LoginResult. `client` can be injected for tests.
  Future<LoginResult> loginUser({
    required String email,
    required String password,
    required bool isBarberLogin,
    http.Client? client,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      return LoginResult(success: false, message: "Please fill all fields");
    }

    final c = client ?? http.Client();
    try {
      final response = await c.post(
        Uri.parse("$baseUrl/users/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
          "role": isBarberLogin ? "owner" : "customer",
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["msg"] == "Login successful") {
          return LoginResult(
            success: true,
            role: data["role"],
            userId: data["user_id"],
            message: "Login successful",
          );
        } else {
          return LoginResult(success: false, message: data["msg"] ?? "Invalid credentials");
        }
      } else {
        return LoginResult(success: false, message: "Server error: ${response.statusCode}");
      }
    } catch (e) {
      return LoginResult(success: false, message: "Something went wrong: $e");
    } finally {
      if (client == null) {
        c.close();
      }
    }
  }
}
