import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:book_event/Controllers/RegistrationController.dart';

class Registration extends StatelessWidget {
  final RegistrationController controller = Get.put(RegistrationController());

  Registration({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          "Registration",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Create Account",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Fill in your details to register",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            SizedBox(height: 32),

            // Full Name Field
            _buildTextField("Full Name", controller.fullName),

            // Email Field
            _buildTextField("Email", controller.email,
              hintText: "yourname@example.com",
              keyboardType: TextInputType.emailAddress,
            ),

            // Phone Field
            _buildTextField("Phone Number", controller.phone,
              hintText: "1234567890",
              keyboardType: TextInputType.phone,
            ),

            // Password Fields
            _buildTextField(
              "Password",
              controller.password,
              obscureText: true,
              hintText: "At least 8 characters",
            ),
            _buildTextField(
              "Confirm Password",
              controller.passwordConfirm,
              obscureText: true,
            ),

            SizedBox(height: 24),

            // Register Button
            Obx(() => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.isLoading.value ? null : controller.registerUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: controller.isLoading.value
                    ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Text(
                  "Create Account",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller, {
        bool obscureText = false,
        String? hintText,
        TextInputType? keyboardType,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 16)),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade900,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            hintText: hintText ?? "Enter your ${label.toLowerCase()}",
            hintStyle: TextStyle(color: Colors.white38),
          ),
          style: TextStyle(color: Colors.white),
        ),
        SizedBox(height: 16),
      ],
    );
  }
}