import 'dart:async';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Core/Network/DioClient.dart';
import '../Models/Admin.dart';
import '../Routes/AppRoute.dart';
import '../Models/Event.dart' hide Booking;
import '../Models/Booking.dart';

class AdminHomeController extends GetxController {
  late SharedPreferences prefs;
  var events = <Event>[].obs;
  var bookings = <Booking>[].obs;
  var isLoading = false.obs;
  var stats = AdminStats(
    totalEvents: 0,
    totalUsers: 0,
    totalBookings: 0,
    totalRevenue: 0,
  ).obs;
  var selectedBookingFilter = 'pending'.obs;
  Timer? _refreshTimer;

  @override
  void onInit() async {
    super.onInit();
    prefs = await SharedPreferences.getInstance();
    await loadData();
    startAutoRefresh();
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }

  void startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) => loadData());
  }

  Future<void> loadData() async {
    try {
      isLoading(true);
      await Future.wait([
        fetchEvents(),
        fetchBookings(),
        fetchStats(),
      ]);
    } catch (e) {
      log('Error in loadData: $e', error: e);
      Get.snackbar('Error', 'Failed to load data: ${e.toString()}');
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchEvents() async {
    try {
      isLoading(true);
      final token = prefs.getString('token');
      if (token == null) throw 'Authentication required';

      final dioClient = DioClient(token: token);
      final response = await dioClient.get<List<Event>>(
        '/events',
        fromJsonT: (json) {
          if (json['events'] == null) return <Event>[];
          return (json['events'] as List).map((e) => Event.fromJson(e)).toList();
        },
      );

      if (response.success) {
        events.assignAll(response.data ?? []);
      } else {
        throw Exception(response.message ?? 'Failed to load events');
      }
    } catch (e) {
      log('Error loading events: $e', error: e);
      Get.snackbar('Error', 'Failed to load events: ${e.toString()}');
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchBookings() async {
    try {
      isLoading(true);
      final token = prefs.getString('token');
      if (token == null) throw 'Authentication required';

      final dioClient = DioClient(token: token);
      final response = await dioClient.get<List<Booking>>(
        '/bookings',
        fromJsonT: (json) {
          if (json['bookings'] == null) return <Booking>[];
          return (json['bookings'] as List).map((e) => Booking.fromJson(e)).toList();
        },
      );

      if (response.success) {
        bookings.assignAll(response.data ?? []);
      } else {
        throw Exception(response.message ?? 'Failed to load bookings');
      }
    } catch (e) {
      log('Error loading bookings: $e', error: e);
      Get.snackbar('Error', 'Failed to load bookings: ${e.toString()}');
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchStats() async {
    try {
      isLoading(true);
      final token = prefs.getString('token');
      if (token == null) throw 'Authentication required';

      final dioClient = DioClient(token: token);
      final response = await dioClient.get<AdminStats>(
        '/admin/stats',
        fromJsonT: (json) => AdminStats.fromJson(json['stats'] ?? {}),
      );

      if (response.success) {
        stats.value = response.data ?? AdminStats(
          totalEvents: 0,
          totalUsers: 0,
          totalBookings: 0,
          totalRevenue: 0,
        );
      }
    } catch (e) {
      log('Error loading stats: $e', error: e);
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
      final token = prefs.getString('token');
      if (token == null) throw 'Authentication required';

      final dioClient = DioClient(token: token);

      // Format dates to match API format: "YYYY-MM-DD HH:MM:SS"
      final formattedStartDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(startDate);
      final formattedEndDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(endDate);

      // Create form data for multipart request
      final formData = FormData.fromMap({
        'title': title,
        'description': description,
        'location': location,
        'start_date': formattedStartDate,
        'end_date': formattedEndDate,
        'price': price.toString(),
        'total_seats': totalSeats.toString(),
        'available_seats': totalSeats.toString(),
        'image': await MultipartFile.fromFile(
          imagePath,
          filename: 'event_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      final response = await dioClient.post<int>(
        '/events',
        data: formData,
        fromJsonT: (json) => json['event_id'] as int,
      );

      if (response.success) {
        Get.snackbar('Success', 'Event created successfully');
        await fetchEvents();
        return true;
      } else {
        throw Exception(response.message ?? 'Failed to create event');
      }
    } catch (e) {
      log('Error creating event: $e', error: e);
      Get.snackbar('Error', 'Failed to create event: ${e.toString()}');
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<bool> updateBookingStatus(int bookingId, String status) async {
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
        Get.snackbar('Success', 'Booking $status successfully');
        await fetchBookings();
        return true;
      } else {
        throw Exception(response.message ?? 'Failed to update booking');
      }
    } catch (e) {
      log('Error updating booking: $e', error: e);
      Get.snackbar('Error', 'Failed to update booking: ${e.toString()}');
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<void> logout() async {
    try {
      await prefs.clear();
      Get.offAllNamed(AppRoute.login);
    } catch (e) {
      log('Error logging out: $e', error: e);
      Get.snackbar('Error', 'Failed to logout: ${e.toString()}');
    }
  }

  List<Booking> get filteredBookings {
    if (selectedBookingFilter.value == 'all') return bookings;
    return bookings.where((b) => b.status == selectedBookingFilter.value).toList();
  }
}