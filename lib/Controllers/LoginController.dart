import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Core/Network/DioClient.dart';
import '../Core/showErrorDialog.dart';
import '../Core/showSuccessDialog.dart';
import '../Routes/AppRoute.dart';
import '../Views/Home.dart';

class LoginController extends GetxController {
  final email = TextEditingController();
  final password = TextEditingController();
  final isLoading = false.obs;
  final isPasswordVisible = false.obs;
  late final SharedPreferences prefs;

  // Track if controllers are disposed
  bool _emailDisposed = false;
  bool _passwordDisposed = false;

  @override
  void onInit() async {
    super.onInit();
    prefs = await SharedPreferences.getInstance();
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    final token = prefs.getString('token');
    final userJson = prefs.getString('user');
    if (token != null && userJson != null) {
      try {
        final user = jsonDecode(userJson);
        _redirectBasedOnRole(user['role'], user['full_name']);
      } catch (e) {
        await _clearSession();
      }
    }
  }

  Future<void> login() async {
    if (isLoading.value) return;

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
      final token = responseData['token'] ?? 'generated_token_placeholder';
      final user = responseData['user'];
      final role = user['role'] ?? 'user'; // Default to 'user' if role not specified
      final fullName = user['full_name'] ?? 'User';

      // Save user session
      await prefs.setString('token', token);
      await prefs.setString('user', jsonEncode(user));
      // await prefs.setString('user', jsonEncode(userData)); // Store full user dataprefs.setString('user', jsonEncode(userData)); // Store full user data

      await _clearControllers();

      // Show welcome message and redirect based on role
      showSuccessDialog(
        "Login Successful",
        "Welcome back, $fullName!",
            () {
          _redirectBasedOnRole(role, fullName);
        },
      );
    } catch (e) {
      await _clearSession();
      showErrorDialog(
          "Session Error",
          "Couldn't save your session. Please try again"
      );
    }
  }

  void _redirectBasedOnRole(String role, String fullName) {
    if (role == 'admin') {
      Get.offAllNamed(AppRoute.AdminHome);
    } else {
      Get.offAllNamed(AppRoute.Home);
      // Show welcome message for regular users
      Get.snackbar(
        'Welcome',
        'Hello $fullName!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
    }
  }

  Future<void> _clearSession() async {
    await prefs.remove('token');
    await prefs.remove('user');
  }

  Future<void> _clearControllers() async {
    if (!_emailDisposed) {
      email.clear();
    }
    if (!_passwordDisposed) {
      password.clear();
    }
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  @override
  void onClose() {
    _emailDisposed = true;
    _passwordDisposed = true;
    email.dispose();
    password.dispose();
    super.onClose();
  }
}