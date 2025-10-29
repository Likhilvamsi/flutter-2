// test/auth_service_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_app/services/auth_service.dart';

void main() {
  group('AuthService.loginUser', () {
    final auth = AuthService(baseUrl: "http://127.0.0.1:8000");
    test('returns error when fields are empty', () async {
      final res = await auth.loginUser(email: '', password: '', isBarberLogin: false);
      expect(res.success, isFalse);
      expect(res.message, contains('Please fill all fields'));
    });
    test('successful customer login', () async {
      final mockClient = MockClient((http.Request request) async {
        final body = {
          "msg": "Login successful",
          "role": "customer",
          "user_id": 42,
        };
        return http.Response(jsonEncode(body), 200);
      });

      final res = await auth.loginUser(
        email: 'a@b.com',
        password: 'pass',
        isBarberLogin: false,
        client: mockClient,
      );

      expect(res.success, isTrue);
      expect(res.role, 'customer');
      expect(res.userId, 42);
    });

    test('successful owner login', () async {
      final mockClient = MockClient((http.Request request) async {
        final body = {
          "msg": "Login successful",
          "role": "owner",
          "user_id": 7,
        };
        return http.Response(jsonEncode(body), 200);
      });

      final res = await auth.loginUser(
        email: 'owner@barber.com',
        password: 'pass',
        isBarberLogin: true,
        client: mockClient,
      );

      expect(res.success, isTrue);
      expect(res.role, 'owner');
      expect(res.userId, 7);
    });

    test('invalid credentials (200 but msg not success)', () async {
      final mockClient = MockClient((http.Request request) async {
        final body = {"msg": "Invalid credentials"};
        return http.Response(jsonEncode(body), 200);
      });

      final res = await auth.loginUser(
        email: 'x@x.com',
        password: 'wrong',
        isBarberLogin: false,
        client: mockClient,
      );

      expect(res.success, isFalse);
      expect(res.message, contains('Invalid credentials'));
    });

    test('server returns non-200', () async {
      final mockClient = MockClient((http.Request request) async {
        return http.Response('Server Error', 500);
      });

      final res = await auth.loginUser(
        email: 'a@b.com',
        password: 'p',
        isBarberLogin: false,
        client: mockClient,
      );

      expect(res.success, isFalse);
      expect(res.message, contains('Server error: 500'));
    });

    test('network exception thrown', () async {
      final mockClient = MockClient((http.Request request) async {
        throw Exception('No Internet');
      });

      final res = await auth.loginUser(
        email: 'a@b.com',
        password: 'p',
        isBarberLogin: false,
        client: mockClient,
      );

      expect(res.success, isFalse);
      expect(res.message, contains('Something went wrong'));
    });
  });
}
