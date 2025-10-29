import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EmpDetailsPage extends StatefulWidget {
  final String email;
  const EmpDetailsPage({Key? key, required this.email}) : super(key: key);
  @override
  _EmpDetailsPageState createState() => _EmpDetailsPageState();
}
class _EmpDetailsPageState extends State<EmpDetailsPage> {
  Map<String, dynamic>? empData;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchEmpData();
  }

  Future<void> fetchEmpData() async {
    var url = Uri.parse(
        'http://127.0.0.1:8000/auth/employee/details?email=${Uri.encodeComponent(widget.email)}');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        empData = jsonDecode(response.body);
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch employee data')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: Text("Employee Details"),
        backgroundColor: Colors.blue.shade700,
        elevation: 5,
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: Colors.blue))
          : empData == null
              ? Center(
                  child: Text(
                    "No data available",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Profile Card
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue.shade400, Colors.blue.shade700],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.white,
                                child: Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              SizedBox(height: 15),
                              Text(
                                empData!['name'] ?? "N/A",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                empData!['email'] ?? "N/A",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 30),

                      // Details Card
                      Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildDetailRow(Icons.work, "Designation",
                                  empData!['designation'] ?? "N/A"),
                              Divider(),
                              buildDetailRow(Icons.business, "Department",
                                  empData!['department'] ?? "N/A"),
                              Divider(),
                              buildDetailRow(Icons.account_balance, "Bank Name",
                                  empData!['bank_name'] ?? "N/A"),
                              Divider(),
                              buildDetailRow(Icons.credit_card, "Account No",
                                  empData!['account_number'] ?? "N/A"),
                              Divider(),
                              buildDetailRow(Icons.badge, "Employee ID",
                                  empData!['employee_id']?.toString() ?? "N/A"),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade700),
          SizedBox(width: 15),
          Text(
            "$label: ",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
