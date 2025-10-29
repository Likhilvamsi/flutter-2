import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddShopPage extends StatefulWidget {
  final int ownerId;

  const AddShopPage({super.key, required this.ownerId});

  @override
  State<AddShopPage> createState() => _AddShopPageState();
}

class _AddShopPageState extends State<AddShopPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  TimeOfDay? openTime;
  TimeOfDay? closeTime;

  bool isLoading = false;
  String? successMessage;
  String? errorMessage;

 Future<void> addShop() async {
  if (!_formKey.currentState!.validate()) return;

  if (openTime == null || closeTime == null) {
    setState(() => errorMessage = "Please select both open and close times");
    return;
  }

  setState(() {
    isLoading = true;
    successMessage = null;
    errorMessage = null;
  });

  String formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return "$h:$m:00";
  }

  final uri = Uri.parse("http://localhost:8000/create?owner_id=${widget.ownerId}");

  final body = {
    "shop_name": _shopNameController.text,
    "address": _addressController.text,
    "city": _cityController.text,
    "state": _stateController.text,
    "open_time": formatTime(openTime!),
    "close_time": formatTime(closeTime!),
  };

  try {
    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      setState(() {
        successMessage = data['message'] ?? "Shop created successfully!";
        errorMessage = null;
      });
    } else {
      setState(() {
        errorMessage = data['message'] ?? "Failed to create shop";
        successMessage = null;
      });
    }
  } catch (e) {
    setState(() {
      errorMessage = "Something went wrong: $e";
    });
  } finally {
    setState(() => isLoading = false);
  }
}


  Future<void> pickTime(bool isOpenTime) async {
    final TimeOfDay? picked =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());

    if (picked != null) {
      setState(() {
        if (isOpenTime) {
          openTime = picked;
        } else {
          closeTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6DD5FA), Color(0xFF2980B9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              elevation: 15,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Add Shop",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2980B9),
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _shopNameController,
                        decoration: const InputDecoration(
                          labelText: "Shop Name",
                          prefixIcon: Icon(Icons.store_mall_directory),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? "Enter shop name" : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: "Address",
                          prefixIcon: Icon(Icons.location_on),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? "Enter address" : null,
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              decoration: const InputDecoration(
                                labelText: "City",
                                prefixIcon: Icon(Icons.location_city),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  value!.isEmpty ? "Enter city" : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _stateController,
                              decoration: const InputDecoration(
                                labelText: "State",
                                prefixIcon: Icon(Icons.map),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  value!.isEmpty ? "Enter state" : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => pickTime(true),
                            icon: const Icon(Icons.access_time),
                            label: Text(openTime == null
                                ? "Open Time"
                                : "Open: ${openTime!.format(context)}"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => pickTime(false),
                            icon: const Icon(Icons.lock_clock),
                            label: Text(closeTime == null
                                ? "Close Time"
                                : "Close: ${closeTime!.format(context)}"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      if (errorMessage != null)
                        Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      if (successMessage != null)
                        Text(
                          successMessage!,
                          style: const TextStyle(color: Colors.green),
                        ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : addShop,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2980B9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  "Create Shop",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
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
