import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "http://172.210.139.244:8000";

  Future<Map<String, dynamic>?> loginUser(
    String email,
    String password,
    String role,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/login'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password, "role": role}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

  Future<List<dynamic>> getShopsByOwner(int ownerId) async {
    final response = await http.get(Uri.parse('$baseUrl/owner/$ownerId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch shops");
    }
  }

  // 🆕 Create Shop API
  Future<bool> createShop({
    required int ownerId,
    required String shopName,
    required String address,
    required String city,
    required String state,
    required String openTime,
    required String closeTime,
  }) async {
    final url = Uri.parse('$baseUrl/create?owner_id=$ownerId');

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

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  Future<List<dynamic>> getBarbersByShop(int shopId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/barbers/available/$shopId'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load barbers');
    }
  }

  Future<void> updateBarber(
    int barberId,
    Map<String, dynamic> body, {
    required int ownerId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/barbers/update/$barberId?owner_id=$ownerId',
    );
    print("📡 PUT $url");
    print("📦 Body: $body");

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      print("✅ Barber updated successfully");
    } else {
      print("❌ Failed with status: ${response.statusCode}");
      print("Response: ${response.body}");
      throw Exception('Failed to update barber');
    }
  }
  Future<void> deleteBarber(int barberId, {required int ownerId}) async {
    final url = Uri.parse('$baseUrl/barbers/delete/$barberId?owner_id=$ownerId');

    final response = await http.delete(url);

    if (response.statusCode == 200) {
      print("Barber deleted successfully");
    } else {
      print("Failed to delete barber: ${response.statusCode} ${response.body}");
      throw Exception("Failed to delete barber");
    }
  }
Future<List<dynamic>> getAllShops() async {
  final response = await http.get(Uri.parse('$baseUrl/shops'));
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to load shops');
  }
}

Future<List<dynamic>> getSlots(int shopId, String date) async {
  final response = await http.get(
    Uri.parse('$baseUrl/shops/$shopId/slots/?date=$date'),
    headers: {'accept': 'application/json'},
  );
  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Failed to fetch slots');
  }
}
Future<bool> bookSlots(Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl/shops/book-slots/');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      // optionally return false with more details
      throw Exception('Booking failed: ${response.statusCode} ${response.body}');
    }
  }
}
