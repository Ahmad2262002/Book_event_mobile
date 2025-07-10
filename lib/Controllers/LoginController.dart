import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Core/Network/DioClient.dart';
import '../Routes/AppRoute.dart';

class LoginController extends GetxController {
  final email = TextEditingController();
  final password = TextEditingController();
  final isLoading = false.obs;
  final isPasswordVisible = false.obs;
  late final SharedPreferences prefs;

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
      Get.snackbar(
        'Missing Fields',
        'Please enter both email and password',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    if (!GetUtils.isEmail(email.text)) {
      Get.snackbar(
        'Invalid Email',
        'Please enter a valid email address',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
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
        Get.snackbar(
          'Login Error',
          errorMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } on SocketException {
      Get.snackbar(
        'Connection Error',
        'Please check your internet connection and try again',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } on TimeoutException {
      Get.snackbar(
        'Timeout Error',
        'Server is taking too long to respond. Please try again',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ??
          "An error occurred during login";
      Get.snackbar(
        'Login Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Unexpected Error',
        'Something went wrong. Please try again',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> _handleLoginSuccess(Map<String, dynamic> responseData) async {
    try {
      final token = responseData['token'] ?? 'generated_token_placeholder';
      final user = responseData['user'];
      final role = user['role'] ?? 'user';
      final fullName = user['full_name'] ?? 'User';

      await prefs.setString('token', token);
      await prefs.setString('user', jsonEncode(user));

      email.clear();
      password.clear();

      Get.snackbar(
        'Login Successful',
        'Welcome back, $fullName!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );

      await Future.delayed(Duration(seconds: 1));
      _redirectBasedOnRole(role, fullName);
    } catch (e) {
      await _clearSession();
      Get.snackbar(
        'Session Error',
        'Couldn\'t save your session. Please try again',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _redirectBasedOnRole(String role, String fullName) {
    if (role == 'admin') {
      Get.offAllNamed(AppRoute.AdminHome);
    } else {
      Get.offAllNamed(AppRoute.Home);
    }
  }

  Future<void> _clearSession() async {
    await prefs.remove('token');
    await prefs.remove('user');
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  @override
  void onClose() {
    // Clear controllers but don't dispose them
    email.clear();
    password.clear();
    super.onClose();
  }
}