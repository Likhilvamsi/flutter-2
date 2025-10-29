import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import './add_barber_page.dart';
import './add_shop_page.dart';

class OwnerPage extends StatefulWidget {
  final int ownerId;
  const OwnerPage({super.key, required this.ownerId});

  @override
  State<OwnerPage> createState() => _OwnerPageState();
}

class _OwnerPageState extends State<OwnerPage> {
  List<dynamic> shops = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchShops();
  }

  Future<void> fetchShops() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse("http://localhost:8000/owner/${widget.ownerId}"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          shops = data;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading shops: ${response.statusCode}")),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load shops: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1E2A),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          "My Shops 🏪",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddShopPage(ownerId: widget.ownerId),
            ),
          );
        },
        backgroundColor: const Color(0xFF6A5AE0),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Add Shop",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : RefreshIndicator(
              onRefresh: fetchShops,
              child: shops.isEmpty
                  ? const Center(
                      child: Text(
                        "No shops yet.\nTap '+' to add your first shop!",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: shops.length,
                      itemBuilder: (context, index) {
                        final shop = shops[index];

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddBarberPage(
                                  shopId: shop['shop_id'],
                                  ownerId: widget.ownerId,
                                ),
                              ),
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.deepPurpleAccent.withOpacity(0.9),
                                  Colors.indigo.shade600.withOpacity(0.9),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.storefront,
                                          color: Colors.white, size: 40),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          shop['shop_name'] ?? 'Unnamed Shop',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: shop['is_open'] == true
                                              ? Colors.greenAccent
                                                  .withOpacity(0.2)
                                              : Colors.redAccent
                                                  .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: shop['is_open'] == true
                                                ? Colors.greenAccent
                                                : Colors.redAccent,
                                          ),
                                        ),
                                        child: Text(
                                          shop['is_open'] == true
                                              ? "Open"
                                              : "Closed",
                                          style: TextStyle(
                                            color: shop['is_open'] == true
                                                ? Colors.greenAccent
                                                : Colors.redAccent,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined,
                                          color: Colors.white70, size: 20),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          "${shop['city'] ?? ''}, ${shop['state'] ?? ''}",
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time,
                                          color: Colors.white70, size: 20),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Open: ${shop['open_time']}  |  Close: ${shop['close_time']}",
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white12,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.map_outlined,
                                            color: Colors.white70),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            shop['address'] ?? 'No address',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
