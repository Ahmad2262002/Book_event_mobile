import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../Core/Network/DioClient.dart';
import '../Models/Admin.dart';
import '../Routes/AppRoute.dart';
import '../Models/Event.dart' hide Booking;
import '../Models/Booking.dart';
import '../Models/User.dart';
import '../Models/Testimonial.dart';

class AdminHomeController extends GetxController {
  late SharedPreferences prefs;
  var events = <Event>[].obs;
  var bookings = <Booking>[].obs;
  var users = <User>[].obs;
  var testimonials = <Testimonial>[].obs;
  var isLoading = false.obs;
  var stats = AdminStats(
    totalEvents: 0,
    totalUsers: 0,
    totalBookings: 0,
    totalRevenue: 0,
  ).obs;
  var selectedBookingFilter = 'pending'.obs;
  var selectedTab = 0.obs;
  var isDarkMode = false.obs;
  Timer? _refreshTimer;

  // In AdminHomeController.dart, modify onInit
  @override
  void onInit() async {
    super.onInit();
    log('🔄 AdminHomeController initialized');
    try {
      prefs = await SharedPreferences.getInstance();
      log('🔑 SharedPreferences loaded successfully');
      isDarkMode.value = prefs.getBool('darkMode') ?? false;

      // Add this line to set initial theme
      Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);

      await loadData();
      startAutoRefresh();
    } catch (e) {
      log('❌ Error in onInit: $e', error: e);
    }
  }

  @override
  void onClose() {
    log('⏹️ AdminHomeController disposed');
    _refreshTimer?.cancel();
    super.onClose();
  }

  void toggleDarkMode() {
    isDarkMode.value = !isDarkMode.value;
    prefs.setBool('darkMode', isDarkMode.value);
    log('🌓 Dark mode toggled: ${isDarkMode.value}');

    // Add this line to force theme update
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  void startAutoRefresh() {
    log('⏱️ Starting auto-refresh timer');
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      log('🔄 Auto-refresh triggered');
      loadData();
    });
  }

  Future<void> loadData() async {
    log('📥 Starting data load');
    try {
      isLoading(true);
      await Future.wait([
        fetchEvents(),
        fetchBookings(),
        fetchStats(),
        fetchUsers(),
        fetchTestimonials(),
      ]);
      log('✅ Data loaded successfully');
    } catch (e) {
      log('❌ Error in loadData: $e', error: e);
      Get.snackbar('Error', 'Failed to load data: ${e.toString()}');
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchEvents() async {
    log('🎫 Starting events fetch');
    try {
      isLoading(true);
      final token = prefs.getString('token');
      if (token == null) throw 'Authentication required';

      final dioClient = DioClient(token: token);
      log('🌐 Making API request to /events');
      final response = await dioClient.get<List<Event>>(
        '/events',
        fromJsonT: (json) {
          log('📦 Raw events JSON: $json');
          if (json['events'] == null) {
            log('⚠️ No events field in response');
            return <Event>[];
          }

          final eventsList = (json['events'] as List).map((e) {
            try {
              final event = Event.fromJson(e);
              log('✔️ Parsed event: ${event.id} (Title: ${event.title})');
              return event;
            } catch (parseError) {
              log('❌ Error parsing event: $parseError\nEvent data: $e');
              rethrow;
            }
          }).toList();

          log('📊 Total events parsed: ${eventsList.length}');
          return eventsList;
        },
      );

      log('🎯 Events API response - success: ${response.success}');

      if (response.success) {
        log('📥 Received ${response.data?.length ?? 0} events');
        events.assignAll(response.data ?? []);
        log('🔄 Events list updated. Current count: ${events.length}');
      } else {
        log('❌ Events API error: ${response.message}');
        throw Exception(response.message ?? 'Failed to load events');
      }
    } catch (e) {
      log('❌ Error loading events: $e', error: e);
      Get.snackbar('Error', 'Failed to load events: ${e.toString()}');
    } finally {
      isLoading(false);
      log('🏁 Events fetch completed');
    }
  }

  // In AdminHomeController.dart
  Future<void> fetchBookings() async {
    try {
      isLoading(true);
      final token = prefs.getString('token');
      final userJson = prefs.getString('user');

      if (token == null || userJson == null) {
        throw 'Authentication required';
      }

      final user = User.fromJson(jsonDecode(userJson));
      final dioClient = DioClient(token: token);

      final response = await dioClient.get<List<Booking>>(
        '/users/${user.id}/bookings',
        fromJsonT: (json) => (json['bookings'] as List)
            .map((e) => Booking.fromJson(e))
            .toList(),
      );

      if (response.success) {
        bookings.assignAll(response.data ?? []);
      } else {
        throw Exception(response.message ?? 'Failed to load bookings');
      }
    } catch (e) {
      // Error handling
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchStats() async {
    log('📊 Starting stats fetch');
    try {
      isLoading(true);
      final token = prefs.getString('token');
      if (token == null) throw 'Authentication required';

      final dioClient = DioClient(token: token);
      final response = await dioClient.get<AdminStats>(
        '/admin/stats',
        fromJsonT: (json) {
          // Debug the raw response
          log('📦 Raw stats response: $json');

          // Handle both direct response and nested 'stats' object
          final statsData = json['stats'] ?? json;

          if (statsData is! Map<String, dynamic>) {
            throw Exception('Invalid stats data format');
          }

          log('🔢 Parsing stats data: $statsData');
          return AdminStats.fromJson(statsData);
        },
      );

      if (response.success) {
        stats.value = response.data ?? AdminStats(
          totalEvents: 0,
          totalUsers: 0,
          totalBookings: 0,
          totalRevenue: 0,
        );
        log('📈 Stats updated: ${stats.value}');
      } else {
        log('❌ Stats API error: ${response.message}');
        throw Exception(response.message ?? 'Failed to load stats');
      }
    } catch (e) {
      log('❌ Error loading stats: $e', error: e);
      Get.snackbar('Error', 'Failed to load stats: ${e.toString()}');
    } finally {
      isLoading(false);
      log('🏁 Stats fetch completed');
    }
  }

  Future<void> fetchUsers() async {
    log('👥 Starting users fetch');
    try {
      isLoading(true);
      final token = prefs.getString('token');
      if (token == null) throw 'Authentication required';

      final dioClient = DioClient(token: token);
      final response = await dioClient.get<List<User>>(
        '/users',
        fromJsonT: (json) {
          log('📦 Raw users JSON: ${json.toString()}');

          // Change from json['data'] to json['users']
          if (json['users'] == null) {
            log('⚠️ No users array in response');
            return <User>[];
          }

          final usersList = (json['users'] as List).map((e) {
            try {
              final user = User.fromJson(e);
              log('✔️ Parsed user: ${user.id} (${user.fullName})');
              return user;
            } catch (e) {
              log('❌ Error parsing user: $e\nData: $e');
              return User(
                id: 0,
                fullName: 'Invalid User',
                email: '',
                phone: '',
                role: 'user',
              );
            }
          }).toList();

          log('📊 Total users parsed: ${usersList.length}');
          return usersList;
        },
      );

      if (response.success) {
        users.assignAll(response.data ?? []);
        log('🔄 Users list updated. Current count: ${users.length}');
        if (users.isNotEmpty) {
          log('First user sample: ${users.first}');
        }
      } else {
        throw Exception(response.message ?? 'Failed to load users');
      }
    } catch (e) {
      log('❌ Error loading users: $e', error: e);
      Get.snackbar('Error', 'Failed to load users: ${e.toString()}');
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchTestimonials() async {
    log('💬 Starting testimonials fetch');
    try {
      isLoading(true);
      final token = prefs.getString('token');
      if (token == null) throw 'Authentication required';

      final dioClient = DioClient(token: token);
      final response = await dioClient.get<List<Testimonial>>(
        '/testimonials',
        fromJsonT: (json) {
          log('📦 Raw testimonials JSON: ${json.toString()}');

          // Change from json['data'] to json['testimonials']
          if (json['testimonials'] == null) {
            log('⚠️ No testimonials array in response');
            return <Testimonial>[];
          }

          final testimonialsList = (json['testimonials'] as List).map((e) {
            try {
              final testimonial = Testimonial.fromJson(e);
              log('✔️ Parsed testimonial: ${testimonial.id} (${testimonial.userName})');
              return testimonial;
            } catch (e) {
              log('❌ Error parsing testimonial: $e\nData: $e');
              return Testimonial(
                id: 0,
                userId: 0,
                userName: 'Error',
                content: 'Invalid testimonial',
                approved: false,
                createdAt: DateTime.now(),
              );
            }
          }).toList();

          log('📊 Total testimonials parsed: ${testimonialsList.length}');
          return testimonialsList;
        },
      );

      if (response.success) {
        testimonials.assignAll(response.data ?? []);
        log('🔄 Testimonials list updated. Current count: ${testimonials.length}');
        if (testimonials.isNotEmpty) {
          log('First testimonial sample: ${testimonials.first}');
        }
      } else {
        throw Exception(response.message ?? 'Failed to load testimonials');
      }
    } catch (e) {
      log('❌ Error loading testimonials: $e', error: e);
      Get.snackbar('Error', 'Failed to load testimonials: ${e.toString()}');
    } finally {
      isLoading(false);
    }
  }

  Future<bool> createEvent({
    required String title,
    required String description,
    required String location,
    required DateTime startDate,
    required DateTime endDate,
    required double price,
    required int totalSeats,
    required String imagePath,
  }) async {
    try {
      isLoading(true);
      log('🚀 Starting event creation process');

      // Validate authentication
      final token = prefs.getString('token');
      if (token == null) {
        log('🔒 No authentication token found');
        Get.snackbar('Error', 'Please login again');
        return false;
      }

      // Validate required fields
      if (title.isEmpty || description.isEmpty || location.isEmpty) {
        log('❌ Missing required fields');
        Get.snackbar('Error', 'Please fill in all required fields');
        return false;
      }

      // Validate dates
      if (endDate.isBefore(startDate)) {
        log('❌ Invalid date range');
        Get.snackbar('Error', 'End date must be after start date');
        return false;
      }

      // Validate image
      final file = File(imagePath);
      if (!await file.exists()) {
        log('❌ Image file not found');
        Get.snackbar('Error', 'Selected image file not found');
        return false;
      }

      // Format dates
      final formattedStartDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(startDate);
      final formattedEndDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(endDate);

      // Generate unique filename
      final extension = path.extension(imagePath).toLowerCase();
      final filename = 'event_${DateTime.now().millisecondsSinceEpoch}$extension';

      // Create form data
      final formData = FormData.fromMap({
        'title': title,
        'description': description,
        'location': location,
        'start_date': formattedStartDate,
        'end_date': formattedEndDate,
        'price': price.toStringAsFixed(2),
        'total_seats': totalSeats.toString(),
        'image': await MultipartFile.fromFile(
          imagePath,
          filename: filename,
        ),
      });

      log('📦 Prepared form data for upload');

      // Initialize Dio client
      final dioClient = DioClient(token: token, useLocalBaseUrl: false);

      log('🌐 Sending request to /events endpoint');

      // Make the API call with timeout
      final response = await dioClient.upload<Map<String, dynamic>>(
        '/events',
        formData: formData,
        fromJsonT: (json) => json,
      ).timeout(const Duration(seconds: 30));

      log('🎯 Received response: ${response.data}');

      if (response.success) {
        log('✅ Event created successfully');
        Get.snackbar('Success', 'Event created successfully');
        await fetchEvents();
        return true;
      } else {
        log('❌ API error: ${response.message}');
        Get.snackbar('Error', response.message ?? 'Failed to create event');
        return false;
      }
    } on DioException catch (e) {
      log('❌ Dio error: ${e.message}');
      log('❌ Response: ${e.response?.data}');
      log('❌ Status: ${e.response?.statusCode}');

      String errorMessage = 'Failed to create event';
      if (e.response?.data != null) {
        if (e.response!.data is Map && e.response!.data['message'] != null) {
          errorMessage = e.response!.data['message'];
        } else if (e.response!.data is String) {
          errorMessage = e.response!.data;
        }
      }

      Get.snackbar('Error', errorMessage);
      return false;
    } catch (e) {
      log('❌ Unexpected error: $e');
      Get.snackbar('Error', 'An unexpected error occurred');
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<bool> updateBookingStatus(int bookingId, String status) async {
    log('🔄 Updating booking status to $status');
    try {
      isLoading(true);
      final token = prefs.getString('token');
      if (token == null) throw 'Authentication required';

      final dioClient = DioClient(token: token);
      final endpoint = status == 'confirmed'
          ? '/bookings/$bookingId/confirm'
          : '/bookings/$bookingId/cancel';

      final response = await dioClient.put<bool>(
        endpoint,
        fromJsonT: (json) => true,
      );

      if (response.success) {
        log('✅ Booking $status successfully');
        Get.snackbar('Success', 'Booking $status successfully');
        await fetchBookings();
        return true;
      } else {
        log('❌ Failed to update booking: ${response.message}');
        throw Exception(response.message ?? 'Failed to update booking');
      }
    } catch (e) {
      log('❌ Error updating booking: $e', error: e);
      Get.snackbar('Error', 'Failed to update booking: ${e.toString()}');
      return false;
    } finally {
      isLoading(false);
      log('🏁 Booking status update completed');
    }
  }

  Future<bool> deleteUser(int userId) async {
    try {
      isLoading(true);

      // Check if user has bookings
      final hasBookings = await hasUserBookings(userId);
      if (hasBookings) {
        Get.snackbar(
          'Cannot Delete User',
          'User has active bookings that must be canceled first',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return false;
      }

      final token = prefs.getString('token');
      if (token == null) {
        Get.snackbar(
          'Authentication Required',
          'Please login again',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      final dioClient = DioClient(token: token);
      final response = await dioClient.delete<bool>(
        '/users/$userId',
        fromJsonT: (json) => true,
      );

      if (response.success) {
        await fetchUsers();
        Get.snackbar(
          'Success',
          'User deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        return true;
      } else {
        // Only show snackbar if there's a specific error message
        if (response.message != null && response.message!.isNotEmpty) {
          Get.snackbar(
            'Error',
            response.message!,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
        return false;
      }
    } catch (e) {
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<bool> deleteEvent(String eventId) async {
    try {
      isLoading(true);

      // Check if event has bookings
      final hasBookings = await hasEventBookings(eventId);
      if (hasBookings) {
        Get.snackbar(
          'Cannot Delete Event',
          'Event has active bookings that must be canceled first',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return false;
      }

      final token = prefs.getString('token');
      if (token == null) {
        Get.snackbar(
          'Authentication Required',
          'Please login again',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      final dioClient = DioClient(token: token);
      final response = await dioClient.delete<bool>(
        '/events/$eventId',
        fromJsonT: (json) => true,
      );

      if (response.success) {
        await fetchEvents();
        Get.snackbar(
          'Success',
          'Event deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        return true;
      } else {
        Get.snackbar(
          'Error',
          response.message ?? 'Failed to delete event',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete event',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading(false);
    }
  }

// Helper method to check if user has bookings
  Future<bool> hasUserBookings(int userId) async {
    try {
      final token = prefs.getString('token');
      if (token == null) return false;

      final dioClient = DioClient(token: token);
      final response = await dioClient.get<List<Booking>>(
        '/bookings?user_id=$userId',
        fromJsonT: (json) => (json['bookings'] as List).map((e) => Booking.fromJson(e)).toList(),
      );

      return response.data?.isNotEmpty ?? false;
    } catch (e) {
      return false;
    }
  }



  Future<bool> approveTestimonial(int testimonialId) async {
    log('👍 Approving testimonial $testimonialId');
    try {
      isLoading(true);
      final token = prefs.getString('token');
      if (token == null) throw 'Authentication required';

      final dioClient = DioClient(token: token);
      final response = await dioClient.put<bool>(
        '/testimonials/$testimonialId/approve',
        fromJsonT: (json) => true,
      );

      if (response.success) {
        log('✅ Testimonial approved successfully');
        await fetchTestimonials();
        return true;
      } else {
        log('❌ Failed to approve testimonial: ${response.message}');
        throw Exception(response.message ?? 'Failed to approve testimonial');
      }
    } catch (e) {
      log('❌ Error approving testimonial: $e', error: e);
      Get.snackbar('Error', 'Failed to approve testimonial: ${e.toString()}');
      return false;
    } finally {
      isLoading(false);
      log('🏁 Testimonial approval completed');
    }
  }

  Future<bool> deleteTestimonial(int testimonialId) async {
    log('🗑️ Deleting testimonial $testimonialId');
    try {
      isLoading(true);
      final token = prefs.getString('token');
      if (token == null) throw 'Authentication required';

      final dioClient = DioClient(token: token);
      final response = await dioClient.delete<bool>(
        '/testimonials/$testimonialId',
        fromJsonT: (json) => true,
      );

      if (response.success) {
        log('✅ Testimonial deleted successfully');
        await fetchTestimonials();
        return true;
      } else {
        log('❌ Failed to delete testimonial: ${response.message}');
        throw Exception(response.message ?? 'Failed to delete testimonial');
      }
    } catch (e) {
      log('❌ Error deleting testimonial: $e', error: e);
      Get.snackbar('Error', 'Failed to delete testimonial: ${e.toString()}');
      return false;
    } finally {
      isLoading(false);
      log('🏁 Testimonial deletion completed');
    }
  }

  Future<void> logout() async {
    log('👋 Logging out');
    try {
      await prefs.clear();
      log('✅ Logout successful');
      Get.offAllNamed(AppRoute.login);
    } catch (e) {
      log('❌ Error logging out: $e', error: e);
      Get.snackbar('Error', 'Failed to logout: ${e.toString()}');
    }
  }

  List<Booking> get filteredBookings {
    log('🔍 Filtering bookings by: ${selectedBookingFilter.value}');
    if (selectedBookingFilter.value == 'all') {
      log('📊 Showing all ${bookings.length} bookings');
      return bookings;
    }
    final filtered = bookings.where((b) => b.status == selectedBookingFilter.value).toList();
    log('📊 Filtered to ${filtered.length} ${selectedBookingFilter.value} bookings');
    return filtered;
  }




  Future<bool> hasEventBookings(String eventId) async {
    try {
      final token = prefs.getString('token');
      if (token == null) throw 'Authentication required';

      final dioClient = DioClient(token: token);
      final response = await dioClient.get<List<Booking>>(
        '/events/$eventId/bookings',
        fromJsonT: (json) {
          if (json['bookings'] == null) return <Booking>[];
          return (json['bookings'] as List).map((e) => Booking.fromJson(e)).toList();
        },
      );

      return response.success && (response.data?.isNotEmpty ?? false);
    } catch (e) {
      log('Error checking event bookings: $e');
      return false;
    }
  }

  Future<bool> updateUser(User user) async {
    try {
      isLoading(true);
      final token = prefs.getString('token');
      if (token == null) throw 'Authentication required';

      final dioClient = DioClient(token: token);
      final response = await dioClient.put<bool>(
        '/users/${user.id}',
        data: {
          'full_name': user.fullName,
          'email': user.email,
          'phone': user.phone,
          'role': user.role,
        },
        fromJsonT: (json) => true,
      );

      if (response.success) {
        await fetchUsers();
        Get.snackbar(
          'Success',
          'User updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        return true;
      } else {
        Get.snackbar(
          'Error',
          response.message ?? 'Failed to update user',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update user',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<bool> updateEvent({
    required String eventId,
    required String title,
    required String description,
    required String location,
    required DateTime startDate,
    required DateTime endDate,
    required double price,
    required int totalSeats,
    String? imagePath,
  }) async {
    try {
      isLoading(true);
      final token = prefs.getString('token');
      if (token == null) {
        Get.snackbar('Error', 'Authentication required');
        return false;
      }

      // Format dates
      final formattedStartDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(startDate);
      final formattedEndDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(endDate);

      // Create form data
      final formData = FormData.fromMap({
        'title': title,
        'description': description,
        'location': location,
        'start_date': formattedStartDate,
        'end_date': formattedEndDate,
        'price': price.toString(),
        'total_seats': totalSeats.toString(),
        '_method': 'PUT',
      });

      // Only add image if it's a new file path (not a URL)
      if (imagePath != null && !imagePath.startsWith('http')) {
        formData.files.add(MapEntry(
          'image',
          await MultipartFile.fromFile(
            imagePath,
            filename: 'event_${DateTime.now().millisecondsSinceEpoch}${path.extension(imagePath)}',
            contentType: MediaType('image', path.extension(imagePath).replaceAll('.', '')),
          ),
        ));
      } else if (imagePath == null) {
        // Explicitly indicate to keep existing image
        formData.fields.add(MapEntry('keep_image', 'true'));
      }

      final dioClient = DioClient(token: token);
      final response = await dioClient.upload<Map<String, dynamic>>(
        '/events/$eventId',
        formData: formData,
        fromJsonT: (json) => json,
      ).timeout(const Duration(seconds: 30));

      if (response.success) {
        Get.snackbar('Success', 'Event updated successfully');
        await fetchEvents();
        return true;
      } else {
        Get.snackbar('Error', response.message ?? 'Failed to update event');
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update event: ${e.toString()}');
      return false;
    } finally {
      isLoading(false);
    }
  }
}