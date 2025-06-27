import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Core/Network/DioClient.dart';
import '../Core/showErrorDialog.dart';
import '../Core/showSuccessDialog.dart';
import '../Routes/AppRoute.dart';

class LoginController extends GetxController {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final isLoading = false.obs;
  final RxBool isPasswordVisible = false.obs;
  late final SharedPreferences prefs;

  @override
  void onInit() async {
    super.onInit();
    prefs = await SharedPreferences.getInstance();
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    final token = prefs.getString('token');
    if (token != null) {
      // User is already logged in, redirect to home
      Get.offNamed(AppRoute.home);
    }
  }

  Future<void> login() async {
    if (isLoading.value) return;

    // Basic validation
    if (email.text.isEmpty || password.text.isEmpty) {
      showErrorDialog("Missing Fields", "Please enter both email and password");
      return;
    }

    if (!GetUtils.isEmail(email.text)) {
      showErrorDialog("Invalid Email", "Please enter a valid email address");
      return;
    }

    isLoading(true);

    try {
      final response = await DioClient().instance.post(
        "/login",
        data: {
          'email': email.text.trim(),
          'password': password.text.trim(),
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        await _handleLoginSuccess(response.data);
      } else {
        final errorMessage = response.data['message'] ?? "Login failed";
        showErrorDialog("Login Error", errorMessage);
      }
    } on SocketException {
      showErrorDialog(
          "Connection Error",
          "Please check your internet connection and try again"
      );
    } on TimeoutException {
      showErrorDialog(
          "Timeout Error",
          "Server is taking too long to respond. Please try again"
      );
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ??
          "An error occurred during login";
      showErrorDialog("Login Error", errorMessage);
    } catch (e) {
      showErrorDialog(
          "Unexpected Error",
          "Something went wrong. Please try again"
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> _handleLoginSuccess(Map<String, dynamic> responseData) async {
    try {
      // Generate a token if not provided by the server
      final token = responseData['token'] ?? 'generated_token_placeholder';

      // Save user data to shared preferences
      await prefs.setString('token', token);
      await prefs.setString('user', jsonEncode(responseData['user']));

      // Show success message and redirect
      showSuccessDialog(
        "Login Successful",
        "Welcome back, ${responseData['user']['full_name']}!",
            () {
          // Redirect based on user role if needed
          Get.offNamed(AppRoute.AminHome);
        },
      );
    } catch (e) {
      // Clear any partial saved data if error occurs
      await prefs.remove('token');
      await prefs.remove('user');
      showErrorDialog(
          "Session Error",
          "Couldn't save your session. Please try again"
      );
    }
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  @override
  void onClose() {
    email.dispose();
    password.dispose();
    super.onClose();
  }
}