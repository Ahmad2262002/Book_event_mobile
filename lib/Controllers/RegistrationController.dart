import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;
import 'package:shared_preferences/shared_preferences.dart';
import '../Core/Network/DioClient.dart';
import '../Routes/AppRoute.dart';

class RegistrationController extends GetxController {
  final isLoading = false.obs;
  final agreeToTerms = false.obs;
  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;

  final fullName = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();
  final passwordConfirm = TextEditingController();

  void togglePasswordVisibility() => isPasswordVisible.toggle();
  void toggleConfirmPasswordVisibility() => isConfirmPasswordVisible.toggle();

  // Validation messages with emojis
  final validationMessages = {
    'fullName': '👤 Please enter your full name',
    'email': '📧 Please enter a valid email',
    'phone': '📱 Please enter a valid phone number (10-15 digits)',
    'password': '🔒 Password must be at least 8 characters',
    'passwordMatch': '🔑 Passwords do not match',
    'terms': '📝 Please accept the terms and conditions',
  };

  String? validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return validationMessages['fullName'];
    }
    if (value.length < 3) {
      return '👤 Name too short (min 3 characters)';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return validationMessages['email'];
    }
    if (!GetUtils.isEmail(value)) {
      return validationMessages['email'];
    }
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return validationMessages['phone'];
    }
    if (!RegExp(r'^[0-9]{10,15}$').hasMatch(value)) {
      return validationMessages['phone'];
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return validationMessages['password'];
    }
    if (value.length < 8) {
      return validationMessages['password'];
    }
    return null;
  }

  String? validatePasswordConfirm(String? value) {
    if (value == null || value.isEmpty) {
      return '🔑 Please confirm your password';
    }
    if (value != password.text) {
      return validationMessages['passwordMatch'];
    }
    return null;
  }

  Future<void> registerUser() async {
    try {
      isLoading(true);

      final dioClient = DioClient();
      final response = await dioClient.post<Map<String, dynamic>>(
        '/register',
        data: {
          'full_name': fullName.text.trim(),
          'email': email.text.trim(),
          'phone': phone.text.trim(),
          'password': password.text,
        },
        fromJsonT: (json) => json as Map<String, dynamic>,
      );

      if (response.success) {
        // Save user data and token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', response.data?['token'] ?? '');
        await prefs.setString('user', jsonEncode(response.data?['user']));

        // Show success and navigate
        Get.snackbar(
          '🎉 Registration Successful!',
          'Welcome to our app!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        await Future.delayed(Duration(seconds: 1));
        Get.offAllNamed(AppRoute.login);
      } else {
        throw Exception(response.message ?? 'Registration failed');
      }
    } catch (e) {
      Get.snackbar(
        '❌ Registration Failed',
        _getErrorMessage(e),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('email already exists')) {
      return '📧 This email is already registered';
    } else if (error.toString().contains('phone already exists')) {
      return '📱 This phone number is already registered';
    } else if (error.toString().contains('network')) {
      return '📡 Network error - please check your connection';
    }
    return error.toString();
  }

  @override
  void onClose() {
    // Clear controllers but don't dispose them to prevent the error
    fullName.clear();
    email.clear();
    phone.clear();
    password.clear();
    passwordConfirm.clear();
    super.onClose();
  }
}