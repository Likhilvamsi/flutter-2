import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddBarberPage extends StatefulWidget {
  final int shopId;

  const AddBarberPage({super.key, required this.shopId});

  @override
  State<AddBarberPage> createState() => _AddBarberPageState();
}

class _AddBarberPageState extends State<AddBarberPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _barberNameController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  bool _isAvailable = true;
  bool _everyday = false;
  bool loading = false;

  Future<void> _addBarber() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);
    final url = Uri.parse('http://localhost:8000/barbers/add/${widget.shopId}');
    final body = jsonEncode({
      "barber_name": _barberNameController.text.trim(),
      "start_time": _startTimeController.text.trim(),
      "end_time": _endTimeController.text.trim(),
      "is_available": _isAvailable,
      "everyday": _everyday,
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      setState(() => loading = false);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Barber added successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to add barber: ${response.body}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      controller.text =
          "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4E4EC), // 🌸 Soft rose background
      appBar: AppBar(
        title: const Text(
          "Add Barber",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF9E1655), // Deep rose header
        elevation: 3,
      ),
      body: Center(
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF9E1655), // 💖 Deep rose form background
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(3, 3),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cut_rounded, color: Colors.white, size: 40),
                const SizedBox(height: 10),
                const Text(
                  "Add Barber Details",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _barberNameController,
                  decoration: _inputDecoration("Barber Name", Icons.person),
                  validator: (v) => v!.isEmpty ? "Enter barber name" : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _startTimeController,
                  readOnly: true,
                  onTap: () => _pickTime(_startTimeController),
                  decoration: _inputDecoration("Start Time", Icons.access_time),
                  validator: (v) => v!.isEmpty ? "Select start time" : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _endTimeController,
                  readOnly: true,
                  onTap: () => _pickTime(_endTimeController),
                  decoration: _inputDecoration("End Time", Icons.access_time_filled),
                  validator: (v) => v!.isEmpty ? "Select end time" : null,
                ),
                const SizedBox(height: 15),
                _buildSwitch("Available", _isAvailable, (v) {
                  setState(() => _isAvailable = v);
                }),
                _buildSwitch("Everyday", _everyday, (v) {
                  setState(() => _everyday = v);
                }),
                const SizedBox(height: 25),
                loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF9E1655),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                        ),
                        onPressed: _addBarber,
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        label: const Text(
                          "Add Barber",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white),
      prefixIcon: Icon(icon, color: Colors.white),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white70),
        borderRadius: BorderRadius.circular(15),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white),
        borderRadius: BorderRadius.circular(15),
      ),
    );
  }

  Widget _buildSwitch(String text, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 16)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: const Color(0xFFEFBAD7),
        ),
      ],
    );
  }
}
