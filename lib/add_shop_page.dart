import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AddShopPage extends StatefulWidget {
  final int ownerId;
  const AddShopPage({super.key, required this.ownerId});

  @override
  State<AddShopPage> createState() => _AddShopPageState();
}

class _AddShopPageState extends State<AddShopPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController shopNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController openTimeController = TextEditingController();
  final TextEditingController closeTimeController = TextEditingController();

  final ApiService api = ApiService();
  bool isLoading = false;

  @override
  void dispose() {
    shopNameController.dispose();
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    openTimeController.dispose();
    closeTimeController.dispose();
    super.dispose();
  }

  Future<void> _addShop() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final success = await api.createShop(
      ownerId: widget.ownerId,
      shopName: shopNameController.text.trim(),
      address: addressController.text.trim(),
      city: cityController.text.trim(),
      state: stateController.text.trim(),
      openTime: openTimeController.text.trim(),
      closeTime: closeTimeController.text.trim(),
    );

    setState(() => isLoading = false);

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Shop added successfully")),
      );
      Navigator.pop(context, true);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to add shop")),
      );
    }
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: now,
      builder: (context, child) {
        // dark themed time picker to match app
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF758C),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted = _formatTimeOfDay(picked);
      controller.text = formatted;
    }
  }

  String _formatTimeOfDay(TimeOfDay t) {
    // returns HH:MM:SS (seconds = 00)
    final hour = t.hour.toString().padLeft(2, '0');
    final minute = t.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  InputDecoration _inputDecoration({required String label, IconData? icon}) {
    return InputDecoration(
      prefixIcon: icon != null ? Icon(icon, color: Colors.white70) : null,
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.18)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF758C)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // gradient background matching app theme
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF758C), Color(0xFFFF7EB3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    width: 380, // compact width
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.14)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.12),
                                ),
                                child: const Icon(
                                  Icons.storefront_rounded,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  "Create New Shop",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // Shop Name
                          TextFormField(
                            controller: shopNameController,
                            style: const TextStyle(color: Colors.white),
                            decoration:
                                _inputDecoration(label: "Shop Name", icon: Icons.store),
                            validator: (val) =>
                                val == null || val.trim().isEmpty ? "Enter shop name" : null,
                          ),

                          const SizedBox(height: 12),

                          // Address
                          TextFormField(
                            controller: addressController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration(label: "Address", icon: Icons.location_on),
                            validator: (val) =>
                                val == null || val.trim().isEmpty ? "Enter address" : null,
                          ),

                          const SizedBox(height: 12),

                          // Row: City & State
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: cityController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _inputDecoration(label: "City", icon: Icons.location_city),
                                  validator: (val) =>
                                      val == null || val.trim().isEmpty ? "Enter city" : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: stateController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _inputDecoration(label: "State", icon: Icons.map),
                                  validator: (val) =>
                                      val == null || val.trim().isEmpty ? "Enter state" : null,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Row: Open & Close Time (with pickers)
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: openTimeController,
                                  readOnly: true,
                                  onTap: () => _pickTime(openTimeController),
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _inputDecoration(label: "Open Time", icon: Icons.access_time),
                                  validator: (val) =>
                                      val == null || val.trim().isEmpty ? "Select open time" : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: closeTimeController,
                                  readOnly: true,
                                  onTap: () => _pickTime(closeTimeController),
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _inputDecoration(label: "Close Time", icon: Icons.access_time_outlined),
                                  validator: (val) =>
                                      val == null || val.trim().isEmpty ? "Select close time" : null,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 22),

                          // Button row
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFFF758C), Color(0xFFFF7EB3)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.18),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: isLoading ? null : _addShop,
                                      child: isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text(
                                              "Create Shop",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),
                          // small hint text
                          const Text(
                            "Shop timings will be saved in HH:MM:SS format",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
