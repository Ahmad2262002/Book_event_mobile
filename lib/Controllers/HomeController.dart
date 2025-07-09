import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Core/Network/DioClient.dart';
import '../Routes/AppRoute.dart';
import '../Models/Event.dart';
import '../Models/Booking.dart';
import '../Models/Testimonial.dart';

class HomeController extends GetxController {
  late final SharedPreferences prefs;
  final prefsInitialized = false.obs;
  final events = <Event>[].obs;
  final bookings = <Booking>[].obs;
  final testimonials = <Testimonial>[].obs;
  final isLoading = true.obs;
  final isBookingLoading = false.obs;
  final isTestimonialLoading = false.obs;
  Timer? _timer;
  final currentTabIndex = 0.obs;

  final userProfile = <String, dynamic>{}.obs;
  final isUpdatingProfile = false.obs;
  final _profilePicturePath = ''.obs;
  final testimonialController = TextEditingController();

  String? get profilePicturePath => _profilePicturePath.value.isEmpty ? null : _profilePicturePath.value;
  set profilePicturePath(String? value) => _profilePicturePath.value = value ?? '';

  @override
  Future<void> onInit() async {
    super.onInit();
    try {
      prefs = await SharedPreferences.getInstance();
      prefsInitialized.value = true;
      // Load saved theme
      isDarkMode.value = prefs.getBool('isDarkMode') ?? Get.isDarkMode;
      await loadUserProfile();
      await getEvents();
      await getBookings();
      await getTestimonials();

      _timer = Timer.periodic(const Duration(minutes: 1), (timer) async {
        await getEvents();
        await getBookings();
      });
    } catch (e) {
      Get.snackbar('Initialization Error', 'Failed to initialize: ${e.toString()}');
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    testimonialController.dispose();
    super.onClose();
  }

  Future<void> loadUserProfile() async {
    final userData = prefs.getString('user');
    if (userData != null) {
      userProfile.value = jsonDecode(userData);
      profilePicturePath = userProfile['profile_picture'];
    }
  }

  Future<void> getEvents() async {
    try {
      isLoading(true);
      final token = prefs.getString('token');
      if (token == null) throw 'Authentication required';

      final dioClient = DioClient(token: token);
      final response = await dioClient.get<List<Event>>(
        '/events',
        fromJsonT: (json) => (json['events'] as List).map((e) => Event.fromJson(e)).toList(),
      );

      if (response.success) {
        // Sort events by startDate (newest first)
        final eventList = response.data ?? [];
        eventList.sort((a, b) => b.startDate.compareTo(a.startDate));
        events.assignAll(eventList);
      } else {
        throw Exception(response.message ?? 'Failed to load events');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load events: ${e.toString()}');
    } finally {
      isLoading(false);
    }
  }

  Future<void> getBookings() async {
    try {
      isBookingLoading(true);
      final token = prefs.getString('token');
      if (token == null) throw 'Authentication required';

      final userId = userProfile['id'];
      if (userId == null) throw 'User ID not available';

      final dioClient = DioClient(token: token);
      final response = await dioClient.get<List<Booking>>(
        '/users/$userId/bookings',  // هنا الطلب الجديد
        fromJsonT: (json) => (json['bookings'] as List).map((e) => Booking.fromJson(e)).toList(),
      );

      if (response.success) {
        bookings.assignAll(response.data ?? []);
      } else {
        throw Exception(response.message ?? 'Failed to load bookings');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load bookings: ${e.toString()}');
    } finally {
      isBookingLoading(false);
    }
  }

  Future<void> getTestimonials() async {
    try {
      isTestimonialLoading(true);
      final token = prefs.getString('token');
      if (token == null) throw 'Authentication required';

      final dioClient = DioClient(token: token);
      final response = await dioClient.get<List<Testimonial>>(
        '/testimonials',
        fromJsonT: (json) => (json['testimonials'] as List).map((e) => Testimonial.fromJson(e)).toList(),
      );

      if (response.success) {
        testimonials.assignAll(response.data ?? []);
      } else {
        throw Exception(response.message ?? 'Failed to load testimonials');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load testimonials: ${e.toString()}');
    } finally {
      isTestimonialLoading(false);
    }
  }

  Future<void> bookEvent(int eventId) async {
    try {
      final userId = userProfile['id'];
      if (userId == null) {
        Get.snackbar('Error', 'User not authenticated');
        return;
      }

      final dioClient = DioClient(token: prefs.getString('token'));
      final response = await dioClient.post<bool>(
        '/bookings',
        data: {
          'user_id': userId,
          'event_id': eventId,
          'payment_status': 'completed', // Mark payment as completed
        },
        fromJsonT: (json) => true,
      );

      if (response.success) {
        await getEvents();
        await getBookings();
        _showSuccessAlert('🎉 Booking Confirmed!',
            'Your booking has been successfully processed.');
      } else {
        throw Exception(response.message ?? 'Failed to book event');
      }
    } catch (e) {
      _showErrorAlert('❌ Booking Failed', e.toString());
      rethrow;
    }
  }

  Future<void> submitTestimonial() async {
    try {
      if (testimonialController.text.isEmpty) {
        throw Exception('Please enter your feedback');
      }

      final dioClient = DioClient(token: prefs.getString('token'));
      final response = await dioClient.post<bool>(
        '/testimonials',
        data: {
          'user_id': userProfile['id'],
          'user_name': userProfile['full_name'],
          'content': testimonialController.text,
        },
        fromJsonT: (json) => true,
      );

      if (response.success) {
        testimonialController.clear();
        await getTestimonials();
        _showSuccessAlert('🌟 Thank You!',
            'Your testimonial has been submitted for review.');
      } else {
        throw Exception(response.message ?? 'Failed to submit testimonial');
      }
    } catch (e) {
      _showErrorAlert('❌ Submission Failed', e.toString());
    }
  }

  void _showSuccessAlert(String title, String message) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Text(title),
            const SizedBox(width: 8),
            const Icon(Icons.check_circle, color: Colors.green),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text('OK', style: TextStyle(color: Get.theme.primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showErrorAlert(String title, String message) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Text(title),
            const SizedBox(width: 8),
            const Icon(Icons.error, color: Colors.red),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text('OK', style: TextStyle(color: Get.theme.primaryColor)),
          ),
        ],
      ),
    );
  }

  Future<void> logout() async {
    try {
      await prefs.clear();
      events.clear();
      bookings.clear();
      testimonials.clear();
      Get.offAllNamed(AppRoute.login);
      Get.snackbar(
        'Success',
        'Logged out successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to logout: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Add this observable
  final isDarkMode = false.obs;

// Update toggleTheme method
  Future<void> toggleTheme() async {
    isDarkMode.value = !isDarkMode.value;
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
    await prefs.setBool('isDarkMode', isDarkMode.value);
  }


  String formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return DateFormat('MMM d, y • h:mm a').format(date);
  }

  bool isEventActive(Event event) {
    final now = DateTime.now();
    return now.isAfter(event.startDate) && now.isBefore(event.endDate);
  }
  bool isEventExpired(Event event) {
    return DateTime.now().isAfter(event.endDate);
  }
}