import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddBarberPage extends StatefulWidget {
  final int shopId;
  final int ownerId; // Owner ID
  const AddBarberPage({super.key, required this.shopId, required this.ownerId});

  @override
  State<AddBarberPage> createState() => _AddBarberPageState();
}

class _AddBarberPageState extends State<AddBarberPage> {
  final _formKey = GlobalKey<FormState>();
  final barberNameController = TextEditingController();
  final startTimeController = TextEditingController();
  final endTimeController = TextEditingController();

  bool isLoading = false;
  List<dynamic> barbers = [];

  @override
  void initState() {
    super.initState();
    fetchBarbers();
  }

  Future<void> fetchBarbers() async {
    try {
      final response = await http.get(
        Uri.parse("http://127.0.0.1:8000/barbers/available/${widget.shopId}"),
      );
      if (response.statusCode == 200) {
        setState(() {
          barbers = jsonDecode(response.body);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch barbers: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching barbers: $e")),
      );
    }
  }

  /// Add Barber API
  Future<void> addBarber() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("http://127.0.0.1:8000/barbers/add/${widget.shopId}"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "barber_name": barberNameController.text.trim(),
          "start_time": "${startTimeController.text.trim()}:00",
          "end_time": "${endTimeController.text.trim()}:00",
        }),
      );

      setState(() => isLoading = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["msg"] == "Barber added") {
          barberNameController.clear();
          startTimeController.clear();
          endTimeController.clear();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Barber added successfully!")),
          );

          await fetchBarbers();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data["msg"] ?? "Failed to add barber")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Something went wrong: $e")),
      );
    }
  }

  /// Delete Barber
  Future<void> deleteBarber(int barberId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Barber"),
        content: const Text("Are you sure you want to delete this barber?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await http.delete(
        Uri.parse(
          "http://127.0.0.1:8000/barbers/delete/$barberId?owner_id=${widget.ownerId}",
        ),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Barber deleted successfully")),
        );
        fetchBarbers(); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete barber: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting barber: $e")),
      );
    }
  }

  /// Pick Time
  Future<void> pickTime(TextEditingController controller) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6A11CB),
              onPrimary: Colors.white,
              onSurface: Color(0xFF6A11CB),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      final formattedTime =
          "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
      controller.text = formattedTime;
    }
  }

  /// Edit Barber
  Future<void> editBarber(Map<String, dynamic> barber) async {
    final editNameController = TextEditingController(text: barber["name"]);
    final editStartController = TextEditingController(text: barber["start_time"]);
    final editEndController = TextEditingController(text: barber["end_time"]);

    final formKey = GlobalKey<FormState>();
    bool isUpdating = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Edit Barber"),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: editNameController,
                  decoration: const InputDecoration(labelText: "Barber Name"),
                  validator: (v) => v == null || v.isEmpty ? "Enter name" : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: editStartController,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: "Start Time"),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                        hour: int.parse(editStartController.text.split(":")[0]),
                        minute: int.parse(editStartController.text.split(":")[1]),
                      ),
                    );
                    if (picked != null) {
                      editStartController.text =
                          "${picked.hour.toString().padLeft(2,'0')}:${picked.minute.toString().padLeft(2,'0')}";
                    }
                  },
                  validator: (v) => v == null || v.isEmpty ? "Select time" : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: editEndController,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: "End Time"),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                        hour: int.parse(editEndController.text.split(":")[0]),
                        minute: int.parse(editEndController.text.split(":")[1]),
                      ),
                    );
                    if (picked != null) {
                      editEndController.text =
                          "${picked.hour.toString().padLeft(2,'0')}:${picked.minute.toString().padLeft(2,'0')}";
                    }
                  },
                  validator: (v) => v == null || v.isEmpty ? "Select time" : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            isUpdating
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => isUpdating = true);

                      try {
                        final response = await http.put(
                          Uri.parse(
                            "http://127.0.0.1:8000/barbers/update/${barber["barber_id"]}?owner_id=${widget.ownerId}",
                          ),
                          headers: {"Content-Type": "application/json"},
                          body: jsonEncode({
                            "barber_name": editNameController.text.trim(),
                            "start_time": "${editStartController.text.trim()}:00",
                            "end_time": "${editEndController.text.trim()}:00",
                            "is_available": true,
                          }),
                        );

                        setState(() => isUpdating = false);
                        if (response.statusCode == 200) {
                          final data = jsonDecode(response.body);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(data["msg"] ?? "Updated successfully")),
                          );
                          await fetchBarbers();
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error: ${response.statusCode}")),
                          );
                        }
                      } catch (e) {
                        setState(() => isUpdating = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Something went wrong: $e")),
                        );
                      }
                    },
                    child: const Text("Update"),
                  ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text(
          "Manage Barbers",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF6A11CB),
        centerTitle: true,
        elevation: 6,
      ),
      body: RefreshIndicator(
        onRefresh: fetchBarbers,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildAddBarberForm(),
              const SizedBox(height: 30),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Barbers List (${barbers.length})",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              barbers.isEmpty
                  ? const Text("No barbers found.", style: TextStyle(color: Colors.black54, fontSize: 16))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: barbers.length,
                      itemBuilder: (context, index) {
                        final barber = barbers[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
                            ],
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFF6A11CB),
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(
                              barber["name"] ?? "",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Text(
                              "Time: ${barber["start_time"]} - ${barber["end_time"]}",
                              style: const TextStyle(color: Colors.black54),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => editBarber(barber),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => deleteBarber(barber["barber_id"]),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddBarberForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 6))],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const Text(
              "Add New Barber",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 20),
            _buildTextField(controller: barberNameController, label: "Barber Name", icon: Icons.person),
            const SizedBox(height: 15),
            _buildTimeField(controller: startTimeController, label: "Start Time", icon: Icons.access_time),
            const SizedBox(height: 15),
            _buildTimeField(controller: endTimeController, label: "End Time", icon: Icons.timer_off),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: addBarber,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF6A11CB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      child: const Text("Add Barber"),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      validator: (value) => value == null || value.isEmpty ? "Please enter $label" : null,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white54),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildTimeField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () => pickTime(controller),
      validator: (value) => value == null || value.isEmpty ? "Please select $label" : null,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white),
        suffixIcon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white54),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
    );
  }
}
