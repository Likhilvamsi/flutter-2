import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class SlotsBookingPage extends StatefulWidget {
  final int shopId;
  final String shopName;

  const SlotsBookingPage({
    super.key,
    required this.shopId,
    required this.shopName,
  });

  @override
  State<SlotsBookingPage> createState() => _SlotsBookingPageState();
}

class _SlotsBookingPageState extends State<SlotsBookingPage> {
  List<dynamic> slots = [];
  bool isLoading = false;
  String? error;
  late List<String> next7Days;
  String selectedDate = "";

  Map<String, List<Map<String, dynamic>>> selectedSlotsPerDate = {};

  @override
  void initState() {
    super.initState();
    next7Days = _generateNext7Days();
    selectedDate = next7Days[0];
    selectedSlotsPerDate[selectedDate] = [];
    fetchSlots(selectedDate);
  }

  List<String> _generateNext7Days() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd');
    return List.generate(7, (i) => formatter.format(now.add(Duration(days: i))));
  }

  Future<void> fetchSlots(String date) async {
    setState(() {
      isLoading = true;
      error = null;
      slots = [];
    });

    final url = 'http://127.0.0.1:8000/shops/${widget.shopId}/slots/?date=$date';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          slots = jsonDecode(response.body);
          isLoading = false;
          selectedSlotsPerDate.putIfAbsent(date, () => []);
        });
      } else {
        setState(() {
          error = "Failed to load slots (${response.statusCode})";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = "Error: $e";
        isLoading = false;
      });
    }
  }

  void toggleSlot(Map<String, dynamic> slot) {
    final date = selectedDate;
    selectedSlotsPerDate.putIfAbsent(date, () => []);
    final existingIndex = selectedSlotsPerDate[date]!
        .indexWhere((s) => s["slot_id"] == slot["slot_id"]);

    setState(() {
      if (existingIndex >= 0) {
        selectedSlotsPerDate[date]!.removeAt(existingIndex);
      } else {
        selectedSlotsPerDate[date]!.add(slot);
      }
    });
  }

  Future<void> bookSlots() async {
    final allSelectedSlots = selectedSlotsPerDate.values.expand((list) => list).toList();

    if (allSelectedSlots.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("No slots selected")));
      return;
    }

    final int barberId = allSelectedSlots.first["barber_id"];
    final allSelectedSlotIds = allSelectedSlots.map((slot) => slot["slot_id"]).toList();

    final body = {
      "user_id": 1,
      "barber_id": barberId,
      "shop_id": widget.shopId,
      "slot_ids": allSelectedSlotIds,
    };

    try {
      final response = await http.post(
        Uri.parse("http://127.0.0.1:8000/shops/book-slots/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Booking successful")));
        setState(() {
          selectedSlotsPerDate.clear();
          fetchSlots(selectedDate);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Booking failed: ${response.statusCode}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void showSelectedSlotsDialog() {
    final allSelected = selectedSlotsPerDate.entries
        .expand((entry) => entry.value.map((slot) => {
              "date": entry.key,
              "slot_time": slot["slot_time"],
              "slot_id": slot["slot_id"],
              "barber_name": slot["barber_name"],
            }))
        .toList();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Selected Slots"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: allSelected.length,
            itemBuilder: (context, index) {
              final slotInfo = allSelected[index];
              return ListTile(
                title: Text("${slotInfo["date"]} - ${slotInfo["slot_time"]}"),
                subtitle: Text(slotInfo["barber_name"]),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      selectedSlotsPerDate[slotInfo["date"]]!
                          .removeWhere((s) => s["slot_id"] == slotInfo["slot_id"]);
                    });
                    Navigator.pop(context);
                    showSelectedSlotsDialog(); 
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                bookSlots();
              },
              child: const Text("Confirm"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.shopName} Slots")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Date buttons
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: next7Days.length,
                itemBuilder: (context, index) {
                  final date = next7Days[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            selectedDate == date ? Colors.blue : Colors.grey[300],
                        foregroundColor:
                            selectedDate == date ? Colors.white : Colors.black,
                      ),
                      onPressed: () {
                        setState(() => selectedDate = date);
                        fetchSlots(date);
                      },
                      child: Text(date),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            if (isLoading)
              const CircularProgressIndicator()
            else if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red))
            else if (slots.isEmpty)
              const Text("No slots available for this date")
            else
              // Horizontal scrollable slots with barber names
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: slots.length,
                  itemBuilder: (context, index) {
                    final slot = slots[index];
                    final isSelected = selectedSlotsPerDate[selectedDate]!
                        .any((s) => s["slot_id"] == slot["slot_id"]);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: slot["status"] == "available"
                              ? (isSelected ? Colors.green[300] : Colors.green[100])
                              : Colors.grey[300],
                          foregroundColor:
                              slot["status"] == "available" ? Colors.black : Colors.white,
                        ),
                        onPressed: slot["status"] == "available"
                            ? () => toggleSlot(slot)
                            : null,
                        child: Text("${slot["slot_time"]} - ${slot["barber_name"]}"),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),

            if (selectedSlotsPerDate.values.any((list) => list.isNotEmpty))
              ElevatedButton(
                onPressed: showSelectedSlotsDialog,
                child: const Text("Review & Book Selected Slots"))
          ],
        ),
      ),
    );
  }
}
