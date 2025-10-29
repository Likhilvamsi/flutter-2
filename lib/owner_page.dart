import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'add_shop_page.dart';
import 'shop_details_page.dart';
import 'login_page.dart'; // 👈 make sure this import points to your login screen

class OwnerPage extends StatefulWidget {
  final int ownerId;
  const OwnerPage({super.key, required this.ownerId});

  @override
  State<OwnerPage> createState() => _OwnerPageState();
}

class _OwnerPageState extends State<OwnerPage> {
  final ApiService api = ApiService();
  List<dynamic> shops = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchShops();
  }

  Future<void> fetchShops() async {
    try {
      final data = await api.getShopsByOwner(widget.ownerId);
      setState(() {
        shops = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      print("Error fetching shops: $e");
    }
  }

  Future<void> _navigateToAddShop() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddShopPage(ownerId: widget.ownerId)),
    );
    if (result == true) {
      fetchShops();
    }
  }

  void _navigateToShopDetails(int shopId, String shopName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShopDetailsPage(shopId: shopId, shopName: shopName),
      ),
    );
  }

  // 🚪 Logout Function
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear stored user data
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()), // 👈 your login page
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDEDF4), // 🌸 Soft pink background
      appBar: AppBar(
        title: const Text(
          "Owner Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF9E1655), // 🌺 Deep pink-maroon
        elevation: 3,
        actions: [
          // 🚪 Logout Button
          IconButton(
            tooltip: "Logout",
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD63384), // lighter pink
                foregroundColor: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: const Icon(Icons.add_business_rounded, color: Colors.white),
              label: const Text(
                "Add Shop",
                style:
                    TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
              ),
              onPressed: _navigateToAddShop,
            ),
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF9E1655)),
            )
          : shops.isEmpty
              ? const Center(
                  child: Text(
                    "No shops found",
                    style: TextStyle(
                      color: Color(0xFF9E1655),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: GridView.builder(
                    itemCount: shops.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                    ),
                    itemBuilder: (context, index) {
                      final shop = shops[index];
                      return InkWell(
                        onTap: () => _navigateToShopDetails(
                          shop['shop_id'] ?? 0,
                          shop['shop_name'] ?? '',
                        ),
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF9E1655), Color(0xFFD63384)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
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
                                shop['shop_name'] ?? 'Unnamed',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                shop['address'] ?? 'No Address',
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
                  ),
                ),
    );
  }
}
