import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:book_event/Routes/AppRoute.dart';
import '../Core/Network/DioClient.dart';

class RegistrationController extends GetxController {
  // Form controllers
  final fullName = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();
  final passwordConfirm = TextEditingController();

  // State variables
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;

  // Dio client instance
  final DioClient _dioClient = Get.find<DioClient>();

  @override
  void onClose() {
    fullName.dispose();
    email.dispose();
    phone.dispose();
    password.dispose();
    passwordConfirm.dispose();
    super.onClose();
  }

  // Validation logic
  bool validateForm() {
    errorMessage.value = '';

    if (fullName.text.isEmpty) {
      errorMessage.value = 'Please enter your full name';
      return false;
    }

    if (email.text.isEmpty || !GetUtils.isEmail(email.text)) {
      errorMessage.value = 'Please enter a valid email';
      return false;
    }

    if (phone.text.isEmpty) {
      errorMessage.value = 'Please enter your phone number';
      return false;
    }

    if (password.text.isEmpty || password.text.length < 8) {
      errorMessage.value = 'Password must be at least 8 characters';
      return false;
    }

    if (password.text != passwordConfirm.text) {
      errorMessage.value = 'Passwords do not match';
      return false;
    }

    return true;
  }

  // Registration API call with hardcoded "user" role
  Future<void> registerUser() async {
    if (!validateForm()) return;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final response = await _dioClient.post(
        '/register',
        data: {
          'full_name': fullName.text.trim(),
          'email': email.text.trim(),
          'phone': phone.text.trim(),
          'password': password.text,
          'role': 'user', // Hardcoded role
        },
        fromJsonT: (json) => json,
      ).timeout(const Duration(seconds: 30));

      if (response.success) {
        Get.offNamed(AppRoute.login);
        Get.snackbar(
          'Success',
          'Registration successful! Please login',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        errorMessage.value = response.message ?? 'Registration failed';
        Get.snackbar(
          'Error',
          errorMessage.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } on TimeoutException {
      errorMessage.value = 'Request timed out';
      Get.snackbar(
        'Error',
        'Connection timeout. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } on DioException catch (e) {
      errorMessage.value = e.response?.data?['message'] ??
          e.message ??
          'Registration failed';
      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      errorMessage.value = 'An unexpected error occurred';
      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }
}