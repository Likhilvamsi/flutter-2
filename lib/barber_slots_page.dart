import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class BarberSlotsPage extends StatefulWidget {
  final int shopId;
  final int customerId;
  final String shopName;

  const BarberSlotsPage({
    super.key,
    required this.shopId,
    required this.customerId,
    required this.shopName,
  });

  @override
  State<BarberSlotsPage> createState() => _BarberSlotsPageState();
}

class _BarberSlotsPageState extends State<BarberSlotsPage> {
  final ApiService api = ApiService();

  List<dynamic> slots = [];
  bool isLoading = false;
  String? error;

  late List<String> next7Days;
  late String selectedDate;
  Map<String, List<Map<String, dynamic>>> selectedSlotsPerDate = {};

  @override
  void initState() {
    super.initState();
    next7Days = _generateNext7Days();
    selectedDate = next7Days[0];
    selectedSlotsPerDate[selectedDate] = [];
    _fetchSlots(selectedDate);
  }

  List<String> _generateNext7Days() {
    final now = DateTime.now();
    final fmt = DateFormat('yyyy-MM-dd');
    return List<String>.generate(7, (i) => fmt.format(now.add(Duration(days: i))));
  }

  Future<void> _fetchSlots(String date) async {
    setState(() {
      isLoading = true;
      error = null;
      slots = [];
    });

    try {
      final data = await api.getSlots(widget.shopId, date);
      setState(() {
        slots = data;
        selectedSlotsPerDate.putIfAbsent(date, () => []);
      });
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _toggleSlot(Map<String, dynamic> slot) {
    final date = selectedDate;
    selectedSlotsPerDate.putIfAbsent(date, () => []);
    final list = selectedSlotsPerDate[date]!;

    final idx = list.indexWhere((s) => s['slot_id'] == slot['slot_id']);
    setState(() {
      if (idx >= 0) {
        list.removeAt(idx);
      } else {
        list.add(slot);
      }
    });
  }

  bool _isSlotSelected(Map<String, dynamic> slot) {
    final list = selectedSlotsPerDate[selectedDate] ?? [];
    return list.any((s) => s['slot_id'] == slot['slot_id']);
  }

  Color _slotColor(String status, {bool selected = false}) {
    final st = status.toLowerCase();
    if (st == 'available') {
      return selected ? const Color(0xFF1B9C85) : const Color(0xFFE0F7EF);
    } else if (st == 'booked') {
      return const Color(0xFFF44336);
    } else {
      return Colors.grey.shade400;
    }
  }

  Future<void> _bookSelectedSlots() async {
    final allSelected = selectedSlotsPerDate.entries
        .expand((e) => e.value)
        .toList(growable: false);

    if (allSelected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No slots selected")),
      );
      return;
    }

    final barberId = allSelected.first['barber_id'];
    final allBarberSame = allSelected.every((s) => s['barber_id'] == barberId);
    if (!allBarberSame) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select slots for the same barber.")),
      );
      return;
    }

    final slotIds = allSelected.map((s) => s['slot_id']).toList();
    final body = {
      "user_id": widget.customerId,
      "barber_id": barberId,
      "shop_id": widget.shopId,
      "slot_ids": slotIds,
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final success = await api.bookSlots(body);
      Navigator.pop(context);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Booking successful")),
        );
        setState(() {
          selectedSlotsPerDate.clear();
          selectedSlotsPerDate[selectedDate] = [];
        });
        await _fetchSlots(selectedDate);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Booking failed")),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error booking: $e")),
      );
    }
  }

  void _showReviewDialog() {
    final allSelected = selectedSlotsPerDate.entries
        .expand((entry) => entry.value.map((slot) => {
              "date": entry.key,
              "slot_time": slot["slot_time"],
              "barber_name": slot["barber_name"],
            }))
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Selected slots"),
        content: SizedBox(
          width: double.maxFinite,
          child: allSelected.isEmpty
              ? const Text("No slots selected")
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: allSelected.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, i) {
                    final info = allSelected[i];
                    return ListTile(
                      title: Text("${info['date']} • ${info['slot_time']}"),
                      subtitle: Text(info['barber_name'] ?? ""),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _bookSelectedSlots();
            },
            child: const Text("Confirm & Book"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBFF),
      appBar: AppBar(
        title: Text(widget.shopName),
        backgroundColor: const Color(0xFF0077B6),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 📅 Day Selector
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                height: 68,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  itemCount: next7Days.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final date = next7Days[idx];
                    final isSelected = date == selectedDate;
                    final dt = DateTime.parse(date);
                    return GestureDetector(
                      onTap: () async {
                        if (date == selectedDate) return;
                        setState(() {
                          selectedDate = date;
                          error = null;
                          slots = [];
                        });
                        await _fetchSlots(date);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: 80,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF0077B6) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('E').format(dt),
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              dt.day.toString(),
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 💈 Compact Button-style Slots
            if (isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (error != null)
              Expanded(child: Center(child: Text(error!, style: TextStyle(color: Colors.red))))
            else if (slots.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    "No slots available for $selectedDate",
                    style: const TextStyle(color: Colors.black54, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: slots.map((slot) {
                      final status = (slot['status'] ?? '').toString();
                      final selected = _isSlotSelected(slot);
                      final disabled = status.toLowerCase() != 'available';
                      final bg = _slotColor(status, selected: selected);

                      return GestureDetector(
                        onTap: disabled ? null : () => _toggleSlot(slot),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    )
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.schedule,
                                  color: disabled
                                      ? Colors.white70
                                      : selected
                                          ? Colors.white
                                          : Colors.black54,
                                  size: 18),
                              const SizedBox(width: 6),
                              Text(
                                slot['slot_time'] ?? '--:--',
                                style: TextStyle(
                                  color: disabled
                                      ? Colors.white70
                                      : selected
                                          ? Colors.white
                                          : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                slot['barber_name'] ?? '',
                                style: TextStyle(
                                  color: disabled
                                      ? Colors.white70
                                      : selected
                                          ? Colors.white
                                          : Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

            if (selectedSlotsPerDate.values.any((l) => l.isNotEmpty))
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0077B6),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.list),
                          label: const Text("Review Selected"),
                          onPressed: _showReviewDialog,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF06D6A0),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        onPressed: _bookSelectedSlots,
                        child: const Text("Book Now"),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
