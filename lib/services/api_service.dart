import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // 🧠 Base URL (use HTTPS in production)
  final String baseUrl = "https://135.237.191.7.nip.io";

  // 🧾 User Login
  Future<Map<String, dynamic>?> loginUser(
    String email,
    String password,
    String role,
  ) async {
    final Uri url = Uri.parse('$baseUrl/users/login');

    try {
      print("🌐 Sending POST request to: $url");
      print("📦 Body: ${jsonEncode({
        "email": email,
        "password": password,
        "role": role.toLowerCase(), // Ensure lowercase
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
        print("✅ Login successful!");
        return jsonDecode(response.body);
      } else {
        print("❌ Login failed: ${response.statusCode} ${response.body}");
        return null;
      }
    } catch (e) {
      print("⚠️ Login Exception: $e");
      return null;
    }
  }

  // 🏪 Get Shops by Owner
  Future<List<dynamic>> getShopsByOwner(int ownerId) async {
    final Uri url = Uri.parse('$baseUrl/owner/$ownerId');
    try {
      print("🌐 GET $url");
      final response = await http.get(url);
      print("📩 Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to fetch shops: ${response.statusCode}");
      }
    } catch (e) {
      print("⚠️ getShopsByOwner Exception: $e");
      rethrow;
    }
  }

  // 🆕 Create Shop
  Future<bool> createShop({
    required int ownerId,
    required String shopName,
    required String address,
    required String city,
    required String state,
    required String openTime,
    required String closeTime,
  }) async {
    final Uri url = Uri.parse('$baseUrl/create?owner_id=$ownerId');
    try {
      print("🌐 POST $url");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "shop_name": shopName,
          "address": address,
          "city": city,
          "state": state,
          "open_time": openTime,
          "close_time": closeTime,
        }),
      );
      print("📩 Status: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Shop created successfully");
        return true;
      } else {
        print("❌ Shop creation failed: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("⚠️ createShop Exception: $e");
      return false;
    }
  }

  // 💈 Get Barbers by Shop
  Future<List<dynamic>> getBarbersByShop(int shopId) async {
    final Uri url = Uri.parse('$baseUrl/barbers/available/$shopId');
    try {
      print("🌐 GET $url");
      final response = await http.get(url);
      print("📩 Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load barbers: ${response.statusCode}');
      }
    } catch (e) {
      print("⚠️ getBarbersByShop Exception: $e");
      rethrow;
    }
  }

  // ✏️ Update Barber
  Future<void> updateBarber(
    int barberId,
    Map<String, dynamic> body, {
    required int ownerId,
  }) async {
    final Uri url = Uri.parse('$baseUrl/barbers/update/$barberId?owner_id=$ownerId');
    print("📡 PUT $url");
    print("📦 Body: $body");

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print("📩 Status: ${response.statusCode}");
      if (response.statusCode == 200) {
        print("✅ Barber updated successfully");
      } else {
        print("❌ Failed to update barber: ${response.statusCode} ${response.body}");
        throw Exception('Failed to update barber');
      }
    } catch (e) {
      print("⚠️ updateBarber Exception: $e");
      rethrow;
    }
  }

  // 🗑️ Delete Barber
  Future<void> deleteBarber(int barberId, {required int ownerId}) async {
    final Uri url = Uri.parse('$baseUrl/barbers/delete/$barberId?owner_id=$ownerId');

    try {
      print("🗑️ DELETE $url");
      final response = await http.delete(url);
      print("📩 Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        print("✅ Barber deleted successfully");
      } else {
        print("❌ Delete failed: ${response.statusCode} ${response.body}");
        throw Exception("Failed to delete barber");
      }
    } catch (e) {
      print("⚠️ deleteBarber Exception: $e");
      rethrow;
    }
  }

  // 🏙️ Get All Shops
  Future<List<dynamic>> getAllShops() async {
    final Uri url = Uri.parse('$baseUrl/shops');
    try {
      print("🌐 GET $url");
      final response = await http.get(url);
      print("📩 Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load shops: ${response.statusCode}');
      }
    } catch (e) {
      print("⚠️ getAllShops Exception: $e");
      rethrow;
    }
  }

  // ⏰ Get Slots by Date
  Future<List<dynamic>> getSlots(int shopId, String date) async {
    final Uri url = Uri.parse('$baseUrl/shops/$shopId/slots/?date=$date');
    try {
      print("🌐 GET $url");
      final response = await http.get(
        url,
        headers: {'accept': 'application/json'},
      );
      print("📩 Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch slots: ${response.statusCode}');
      }
    } catch (e) {
      print("⚠️ getSlots Exception: $e");
      rethrow;
    }
  }

  // 📅 Book Slots
  Future<bool> bookSlots(Map<String, dynamic> body) async {
    final Uri url = Uri.parse('$baseUrl/shops/book-slots/');
    try {
      print("🌐 POST $url");
      print("📦 Body: $body");

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print("📩 Status: ${response.statusCode}");
      print("📩 Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Booking successful");
        return true;
      } else {
        print("❌ Booking failed: ${response.statusCode} ${response.body}");
        return false;
      }
    } catch (e) {
      print("⚠️ bookSlots Exception: $e");
      rethrow;
    }
  }
}
