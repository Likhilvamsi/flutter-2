import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'barber_slots_page.dart'; // ✅ import your slots page
import 'login_page.dart';

class CustomerPage extends StatefulWidget {
  final int customerId;
  const CustomerPage({super.key, required this.customerId});

  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  final ApiService api = ApiService();
  List<dynamic> shops = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchAllShops();
  }

  /// 🏪 Fetch all shops for customers
  Future<void> fetchAllShops() async {
    try {
      final data = await api.getAllShops();
      setState(() {
        shops = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      print("Error fetching shops: $e");
    }
  }

  /// 🚪 Logout and clear session
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  /// ✂️ Navigate to Barber Slots page
  void _navigateToBarberSlots(int shopId, String shopName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BarberSlotsPage(
          customerId: widget.customerId,
          shopId: shopId,
          shopName: shopName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F8FF),
      appBar: AppBar(
        title: const Text(
          "Explore Shops",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0077B6),
        elevation: 4,
        actions: [
          IconButton(
            tooltip: "Logout",
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0077B6)),
            )
          : shops.isEmpty
              ? const Center(
                  child: Text(
                    "No shops available right now!",
                    style: TextStyle(
                      color: Color(0xFF0077B6),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = 2;
                      if (constraints.maxWidth > 1200) {
                        crossAxisCount = 4;
                      } else if (constraints.maxWidth > 800) {
                        crossAxisCount = 3;
                      }

                      return GridView.builder(
                        itemCount: shops.length,
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 1.05,
                        ),
                        itemBuilder: (context, index) {
                          final shop = shops[index];

                          // 🎨 Colorful gradients
                          final gradients = [
                            [const Color(0xFF00B4D8), const Color(0xFF48CAE4)],
                            [const Color(0xFF90E0EF), const Color(0xFF00B4D8)],
                            [const Color(0xFFFFB703), const Color(0xFFFB8500)],
                            [const Color(0xFFB5179E), const Color(0xFFF72585)],
                          ];
                          final gradient = gradients[index % gradients.length];

                          return InkWell(
                            onTap: () => _navigateToBarberSlots(
                              shop['shop_id'] ?? 0,
                              shop['shop_name'] ?? 'Unnamed Shop', // ✅ passing shop name
                            ),
                            borderRadius: BorderRadius.circular(20),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  colors: gradient,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: gradient.last.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(2, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.storefront_rounded,
                                      color: Colors.white, size: 35),
                                  const SizedBox(height: 10),
                                  Text(
                                    shop['shop_name'] ?? 'Unnamed Shop',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    shop['city'] ?? '',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.95),
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    "🕒 ${shop['open_time'] ?? '--:--'} - ${shop['close_time'] ?? '--:--'}",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
