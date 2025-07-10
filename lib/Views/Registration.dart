import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:book_event/Controllers/RegistrationController.dart';
import '../Routes/AppRoute.dart';

class Registration extends StatelessWidget {
  final RegistrationController controller = Get.put(RegistrationController());
  final _formKey = GlobalKey<FormState>();

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
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Create Account",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Fill in your details to get started",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              SizedBox(height: 32),

              // Full Name Field
              _buildTextField(
                label: "Full Name",
                controller: controller.fullName,
                validator: controller.validateFullName,
                prefixIcon: Icons.person_outline,
              ),

              // Email Field
              _buildTextField(
                label: "Email",
                controller: controller.email,
                validator: controller.validateEmail,
                hintText: "yourname@example.com",
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),

              // Phone Field
              _buildTextField(
                label: "Phone Number",
                controller: controller.phone,
                validator: controller.validatePhone,
                hintText: "1234567890",
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_android_outlined,
              ),

              // Password Field
              Obx(() => _buildTextField(
                label: "Password",
                controller: controller.password,
                validator: controller.validatePassword,
                obscureText: !controller.isPasswordVisible.value,
                hintText: "At least 8 characters",
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.isPasswordVisible.value
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.white54,
                  ),
                  onPressed: controller.togglePasswordVisibility,
                ),
              )),

              // Confirm Password Field
              Obx(() => _buildTextField(
                label: "Confirm Password",
                controller: controller.passwordConfirm,
                validator: controller.validatePasswordConfirm,
                obscureText: !controller.isConfirmPasswordVisible.value,
                prefixIcon: Icons.lock_reset_outlined,
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.isConfirmPasswordVisible.value
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.white54,
                  ),
                  onPressed: controller.toggleConfirmPasswordVisibility,
                ),
              )),

              SizedBox(height: 16),

              // Terms and Conditions Checkbox
              Obx(() => Row(
                children: [
                  Checkbox(
                    value: controller.agreeToTerms.value,
                    onChanged: (value) => controller.agreeToTerms.value = value!,
                    fillColor: MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                        if (states.contains(MaterialState.selected)) {
                          return Colors.blueAccent;
                        }
                        return Colors.grey.shade800;
                      },
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "I agree to the Terms and Conditions and Privacy Policy",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              )),

              SizedBox(height: 24),

              // Register Button
              Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : () {
                    if (_formKey.currentState!.validate()) {
                      if (controller.agreeToTerms.value) {
                        controller.registerUser();
                      } else {
                        Get.snackbar(
                          "⚠️ Attention",
                          "Please accept the terms and conditions",
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.orange,
                          colorText: Colors.white,
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: controller.isLoading.value
                      ? CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  )
                      : Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )),

              SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () => Get.offNamed(AppRoute.login),
                  child: RichText(
                    text: TextSpan(
                      text: "Already have an account? ",
                      style: TextStyle(color: Colors.white70),
                      children: [
                        TextSpan(
                          text: "Login",
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String? Function(String?)? validator,
    required IconData prefixIcon,
    bool obscureText = false,
    String? hintText,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade900,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade800),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blueAccent, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red, width: 1.5),
            ),
            hintText: hintText ?? "Enter your ${label.toLowerCase()}",
            hintStyle: TextStyle(color: Colors.white38),
            prefixIcon: Icon(prefixIcon, color: Colors.white54),
            suffixIcon: suffixIcon,
            errorStyle: TextStyle(color: Colors.red),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }
}