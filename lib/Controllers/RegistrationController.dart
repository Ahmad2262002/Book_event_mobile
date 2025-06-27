import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Core/Network/DioClient.dart';
import '../Core/showSuccessDialog.dart';
import '../Core/showErrorDialog.dart';
import '../Routes/AppRoute.dart';

class RegistrationController extends GetxController {
  // Controllers
  final TextEditingController fullName = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController passwordConfirm = TextEditingController();

  // State
  var isLoading = false.obs;
  var showEmailScreen = true.obs;

  @override
  void onClose() {
    fullName.dispose();
    email.dispose();
    phone.dispose();
    password.dispose();
    passwordConfirm.dispose();
    super.onClose();
  }

  bool _validateEmail(String email) {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
  }

  Future<void> registerUser() async {
    if (isLoading.value) return;

    // Validate all fields
    if (fullName.text.isEmpty) {
      showErrorDialog("Name Required", "Please enter your full name");
      return;
    }

    if (email.text.isEmpty || !_validateEmail(email.text)) {
      showErrorDialog("Invalid Email", "Please enter a valid email address");
      return;
    }

    if (phone.text.isEmpty) {
      showErrorDialog("Phone Required", "Please enter your phone number");
      return;
    }

    if (password.text.length < 8) {
      showErrorDialog(
        "Weak Password",
        "Password must be at least 8 characters long",
      );
      return;
    }

    if (password.text != passwordConfirm.text) {
      showErrorDialog(
        "Password Mismatch",
        "The passwords you entered don't match",
      );
      return;
    }

    isLoading.value = true;
    try {
      final response = await DioClient().instance.post(
        '/register',
        data: {
          'full_name': fullName.text.trim(),
          'email': email.text.trim(),
          'phone': phone.text.trim(),
          'password': password.text.trim(),
          'role': 'user', // Explicitly set role as 'user'
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _handleRegistrationSuccess(response.data);
      } else {
        showErrorDialog(
          "Registration Failed",
          response.data['message'] ?? "Couldn't complete registration",
        );
      }
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      showErrorDialog("Error", "Something went wrong. Please try again.");
    } finally {
      isLoading.value = false;
    }
  }

  void _handleRegistrationSuccess(Map<String, dynamic> responseData) {
    showSuccessDialog(
      "Registration Complete!",
      "Your account has been successfully created",
          () {
        Get.offAllNamed(AppRoute.login);
      },
    );
  }

  void _handleDioError(DioException e) {
    final response = e.response;
    if (response != null) {
      final errorMessage = response.data['message'] ??
          "An error occurred (${response.statusCode})";
      showErrorDialog("Error", errorMessage.toString());
    } else {
      showErrorDialog(
          "Connection Error",
          "Network Issue 🌐, Please check your internet connection and try again"
      );
    }
  }
}