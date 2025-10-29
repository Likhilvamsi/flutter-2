import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SlotBookingPage extends StatefulWidget {
  @override
  _SlotBookingPageState createState() => _SlotBookingPageState();
}

class _SlotBookingPageState extends State<SlotBookingPage> {
  DateTime selectedDate = DateTime(2025, 09, 24);
  List<Map<String, dynamic>> slots = [];
  List<Map<String, dynamic>> selectedSlots = []; // store selected slots

  final List<DateTime> weekDates =
      List.generate(7, (i) => DateTime(2025, 09, 24).add(Duration(days: i)));

  Future<void> fetchSlots(DateTime date) async {
    final url =
        Uri.parse("http://127.0.0.1:8000/barber/slots/?date=${date.toIso8601String().split('T')[0]}");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        slots = List<Map<String, dynamic>>.from(json.decode(response.body));
      });
    } else {
      setState(() {
        slots = [];
      });
    }
  }

  void toggleSlot(Map<String, dynamic> slot) {
    setState(() {
      if (selectedSlots.any((s) => s['slot_id'] == slot['slot_id'])) {
        selectedSlots.removeWhere((s) => s['slot_id'] == slot['slot_id']);
      } else {
        selectedSlots.add(slot);
      }
    });
  }

  Future<void> confirmBooking() async {
  final url = Uri.parse("http://127.0.0.1:8000/booking/book-slots/");
  final body = {
    "user_id": 1, // static
    "barber_id": 5, // static
    "shop_id": 1, // static
    "slot_ids": selectedSlots.map((s) => s['slot_id']).toList(),
  };

  final response = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(body),
  );

  if (response.statusCode == 200) {
    final res = jsonDecode(response.body);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res["message"] ?? "Booking successful")),
    );

    // ✅ Clear selection
    setState(() {
      selectedSlots.clear();
    });

    Navigator.pop(context); // close popup

    // ✅ Refresh slots for the current date
    fetchSlots(selectedDate);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Booking failed. Try again.")),
    );
  }
}

  void showSelectedPopup() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Confirm Your Slots"),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selectedSlots.isEmpty)
                  Text("No slots selected."),
                if (selectedSlots.isNotEmpty)
                  ...selectedSlots.map(
                    (slot) => ListTile(
                      title: Text("${slot['slot_time']} - ${slot['barber_name']}"),
                      subtitle: Text("Slot ID: ${slot['slot_id']}"),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            selectedSlots.remove(slot);
                          });
                          Navigator.pop(ctx);
                          showSelectedPopup(); // refresh popup
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.pop(ctx),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text("Confirm"),
              onPressed: confirmBooking,
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    fetchSlots(selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Slot Booking"),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          // Date Picker Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: weekDates.map((date) {
                final isSelected = selectedDate == date;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedDate = date;
                    });
                    fetchSlots(date);
                  },
                  child: Container(
                    margin: EdgeInsets.all(6),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.teal : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text("${date.day}/${date.month}",
                            style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Slots Grid
          Expanded(
            child: slots.isEmpty
                ? Center(child: Text("No slots available"))
                : GridView.builder(
                    padding: EdgeInsets.all(10),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      childAspectRatio: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: slots.length,
                    itemBuilder: (ctx, i) {
                      final slot = slots[i];
                      final isSelected = selectedSlots
                          .any((s) => s['slot_id'] == slot['slot_id']);
                      final isAvailable = slot['status'] == "available";

                      return GestureDetector(
                        onTap: isAvailable ? () => toggleSlot(slot) : null,
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: !isAvailable
                                ? Colors.red.shade300
                                : isSelected
                                    ? Colors.teal
                                    : Colors.green.shade300,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            slot['slot_time'],
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Show Popup Button
          if (selectedSlots.isNotEmpty)
            Padding(
              padding: EdgeInsets.all(12),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text("Review & Confirm"),
                onPressed: showSelectedPopup,
              ),
            ),
        ],
      ),
    );
  }
}
