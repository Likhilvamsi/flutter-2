import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'add_barber_page.dart';
import 'package:intl/intl.dart';

class ShopDetailsPage extends StatefulWidget {
  final int shopId;
  final String shopName;

  const ShopDetailsPage({
    super.key,
    required this.shopId,
    required this.shopName,
  });

  @override
  State<ShopDetailsPage> createState() => _ShopDetailsPageState();
}

class _ShopDetailsPageState extends State<ShopDetailsPage> {
  final ApiService api = ApiService();
  List<dynamic> barbers = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchBarbers();
  }

  Future<void> fetchBarbers() async {
    try {
      final data = await api.getBarbersByShop(widget.shopId);
      setState(() {
        barbers = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      print("Error fetching barbers: $e");
    }
  }

  Future<void> _navigateToAddBarber() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddBarberPage(shopId: widget.shopId),
      ),
    );
    if (result == true) {
      fetchBarbers();
    }
  }

  // 🧩 DELETE BARBER API CALL
  Future<void> deleteBarber(int barberId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Barber"),
        content: const Text("Are you sure you want to delete this barber?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await api.deleteBarber(barberId, ownerId: 8); // replace with logged-in ownerId
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Barber deleted successfully")),
      );
      fetchBarbers(); // Refresh list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete barber: $e")),
      );
    }
  }

  // 🧩 Edit Barber Dialog with working switches & time pickers
  Future<void> _showEditDialog(Map<String, dynamic> barber) async {
    final nameController = TextEditingController(text: barber['name']);
    final startTimeController =
        TextEditingController(text: barber['start_time'] ?? '');
    final endTimeController =
        TextEditingController(text: barber['end_time'] ?? '');

    bool isAvailable = barber['is_available'] ?? true;
    bool everyday = barber['everyday'] ?? false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> pickTime(TextEditingController controller) async {
              final initialTime = TimeOfDay.now();
              final picked = await showTimePicker(
                context: context,
                initialTime: initialTime,
              );
              if (picked != null) {
                final now = DateTime.now();
                final formatted = DateFormat('HH:mm:ss').format(DateTime(
                  now.year,
                  now.month,
                  now.day,
                  picked.hour,
                  picked.minute,
                ));
                setStateDialog(() => controller.text = formatted);
              }
            }

            return AlertDialog(
              title: const Text("Edit Barber"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Name"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: startTimeController,
                      readOnly: true,
                      onTap: () => pickTime(startTimeController),
                      decoration: const InputDecoration(
                        labelText: "Start Time (HH:mm:ss)",
                        suffixIcon: Icon(Icons.access_time),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: endTimeController,
                      readOnly: true,
                      onTap: () => pickTime(endTimeController),
                      decoration: const InputDecoration(
                        labelText: "End Time (HH:mm:ss)",
                        suffixIcon: Icon(Icons.access_time),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      title: const Text("Available"),
                      value: isAvailable,
                      onChanged: (val) {
                        setStateDialog(() => isAvailable = val);
                      },
                    ),
                    SwitchListTile(
                      title: const Text("Everyday"),
                      value: everyday,
                      onChanged: (val) {
                        setStateDialog(() => everyday = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9E1655),
                  ),
                  child: const Text("Save"),
                  onPressed: () async {
                    try {
                      await api.updateBarber(
                        barber['barber_id'],
                        {
                          "barber_name": nameController.text,
                          "start_time": startTimeController.text,
                          "end_time": endTimeController.text,
                          "is_available": isAvailable,
                          "everyday": everyday,
                        },
                        ownerId: 8,
                      );
                      Navigator.pop(context);
                      fetchBarbers();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Barber updated successfully"),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed to update barber: $e")),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          widget.shopName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF9E1655),
        elevation: 3,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9E1655),
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: const Icon(Icons.person_add_alt_1_rounded,
                  color: Colors.white),
              label: const Text(
                "Add Barber",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              onPressed: _navigateToAddBarber,
            ),
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF9E1655)),
            )
          : barbers.isEmpty
              ? const Center(child: Text("No barbers found"))
              : Padding(
                  padding: const EdgeInsets.all(10),
                  child: GridView.builder(
                    itemCount: barbers.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.3,
                    ),
                    itemBuilder: (context, index) {
                      final barber = barbers[index];
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9E1655), Color(0xFF9E1655)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              blurRadius: 5,
                              offset: const Offset(2, 3),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.person_rounded,
                                color: Colors.white, size: 35),
                            const SizedBox(height: 8),
                            Text(
                              barber['name'] ?? 'Unnamed',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              barber['phone_number'] ?? 'No Contact',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF9E1655),
                                    minimumSize: const Size(60, 30),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () => _showEditDialog(barber),
                                  child: const Text("Edit",
                                      style: TextStyle(fontSize: 12)),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.white),
                                  onPressed: () =>
                                      deleteBarber(barber['barber_id']),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
