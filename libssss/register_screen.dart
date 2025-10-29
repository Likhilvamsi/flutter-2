import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart'; // <-- added for inputFormatters
import 'dart:convert';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  bool isLoading = false;
  bool otpSent = false;
  bool otpVerified = false;

  /// Send OTP to email
  Future<void> sendOtp() async {
    if (emailController.text.isEmpty ||
        !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Enter a valid email first")),
      );
      return;
    }

    try {
      var url = Uri.parse("http://127.0.0.1:8000/auth/send-verification-otp");
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": emailController.text}),
      );

      if (response.statusCode == 200) {
        setState(() => otpSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("OTP sent to your email")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send OTP")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Network error")),
      );
    }
  }

  /// Verify OTP
  Future<void> verifyOtp() async {
    try {
      var url = Uri.parse("http://127.0.0.1:8000/auth/verify-email");
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": emailController.text,
          "otp": otpController.text,
        }),
      );

      if (response.statusCode == 200) {
        setState(() => otpVerified = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("OTP Verified! You can register now.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Invalid OTP")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Network error")),
      );
    }
  }

  /// Register User
  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate() || !otpVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please verify OTP before registering")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      var url = Uri.parse('http://127.0.0.1:8000/auth/register');
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": usernameController.text,
          "email": emailController.text,
          "password": passwordController.text,
          "phone_number": phoneController.text,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Registration successful!")),
        );
      } else {
        final body = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(body['message'] ?? "Registration failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Network error. Please try again.")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// Compact Text Input
  Widget buildTextInput({
    required String label,
    required TextEditingController controller,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters, // <-- added
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        validator: validator,
        inputFormatters: inputFormatters, // <-- applied here
        style: TextStyle(fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 13),
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(maxWidth: 1000),
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                /// Left Side Image
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Image.asset(
                      'assets/illustration.png',
                      height: 300,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(width: 60),

                /// Right Side Form
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFFCACAD3), width: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildTextInput(
                            label: "Username",
                            controller: usernameController,
                            validator: (value) =>
                                value!.isEmpty ? "Enter username" : null,
                          ),
                          buildTextInput(
                            label: "Email",
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter email';
                              }
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                  .hasMatch(value)) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),

                          /// Send OTP Button
                          Row(
                            children: [
                              Expanded(
                                child: buildTextInput(
                                  label: "Enter OTP",
                                  controller: otpController,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: sendOtp,
                                child: Text("Send"),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: Size(60, 36),
                                ),
                              ),
                              SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: verifyOtp,
                                child: Text("Verify"),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: Size(70, 36),
                                ),
                              ),
                            ],
                          ),

                          /// Phone number field with validation + limit
                          buildTextInput(
                            label: "Phone Number",
                            controller: phoneController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter phone number';
                              }
                              if (value.length != 10) {
                                return 'Phone number must be exactly 10 digits';
                              }
                              return null;
                            },
                          ),

                          buildTextInput(
                            label: "Password",
                            controller: passwordController,
                            obscure: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.cyan,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              onPressed: isLoading ? null : registerUser,
                              child: isLoading
                                  ? CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    )
                                  : Text(
                                      "Register",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 14),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
