// import 'dart:async';
// import 'dart:convert';
// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart' hide FormData, MultipartFile, Response;
// import 'package:image_picker/image_picker.dart';
// import '../Core/Network/DioClient.dart';
// import '../Routes/AppRoute.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:mime_type/mime_type.dart';
//
// class HomeController extends GetxController {
//   late SharedPreferences prefs;
//   var events = [].obs;
//   var isLoading = true.obs;
//   Timer? _timer;
//
//   var staff = <String, dynamic>{}.obs;
//   var userProfile = <String, dynamic>{}.obs;
//   var isUpdatingProfile = false.obs;
//   final RxString _profilePicturePath = ''.obs;
//
//   String? get profilePicturePath => _profilePicturePath.value.isEmpty ? null : _profilePicturePath.value;
//   set profilePicturePath(String? value) => _profilePicturePath.value = value ?? '';
//
//   @override
//   void onInit() async {
//     super.onInit();
//     await loadSharedPreferences();
//     _loadArguments();
//     await getEvents();
//
//     _timer = Timer.periodic(Duration(minutes: 1), (timer) async {
//       await getEvents();
//     });
//   }
//
//   @override
//   void onClose() {
//     _timer?.cancel();
//     super.onClose();
//   }
//
//   final tempUsername = RxString('');
//   final tempEmail = RxString('');
//
//   Future<void> loadSharedPreferences() async {
//     prefs = await SharedPreferences.getInstance();
//     final staffData = prefs.getString('staff');
//     final userData = prefs.getString('userProfile');
//
//     if (staffData != null) {
//       staff.value = jsonDecode(staffData);
//       tempUsername.value = staff['username'];
//       tempEmail.value = staff['email'] ?? '';
//     }
//     if (userData != null) {
//       userProfile.value = jsonDecode(userData);
//       tempEmail.value = staff['email'];
//       profilePicturePath = userProfile['profile_picture'];
//     }
//   }
//
//   void _loadArguments() {
//     final arguments = Get.arguments;
//     if (arguments != null) {
//       staff.value = arguments['staff'] ?? {};
//       userProfile.value = arguments['userProfile'] ?? {};
//       profilePicturePath = userProfile['profile_picture'];
//     }
//   }
//
//   Future<void> getEvents() async {
//     try {
//       isLoading(true);
//       events.clear();
//
//       final token = prefs.getString('token');
//       if (token == null) {
//         Get.snackbar('Error', 'No token found. Please log in again.');
//         return;
//       }
//
//       final dio = DioClient(token: token).instance;
//       final response = await dio.get('/events');
//
//       if (response.statusCode == 200) {
//         events.value = response.data['data'] as List;
//       } else {
//         throw Exception('Failed to load events');
//       }
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to load events: ${e.toString()}');
//     } finally {
//       isLoading(false);
//     }
//   }
//
//   Future<void> bookEvent(int eventId) async {
//     try {
//       final userId = userProfile['user_id'];
//       if (userId == null) {
//         Get.snackbar('Error', 'User not authenticated');
//         return;
//       }
//
//       final response = await DioClient(token: prefs.getString('token'))
//           .instance
//           .post(
//         '/bookings',
//         data: {
//           'user_id': userId,
//           'event_id': eventId,
//         },
//       );
//
//       if (response.statusCode == 201) {
//         Get.snackbar('Success', 'Event booked successfully!');
//         await getEvents(); // Refresh events list
//       } else {
//         throw Exception(response.data['message'] ?? 'Failed to book event');
//       }
//     } catch (e) {
//       Get.snackbar('Error', e.toString());
//     }
//   }
//
//   Future<void> logout() async {
//     try {
//       final token = prefs.getString('token');
//       if (token == null) {
//         Get.snackbar('Error', 'No token found. Please log in again.');
//         return;
//       }
//
//       final response = await DioClient(token: token).instance.post('/logout');
//       if (response.statusCode == 200) {
//         await prefs.clear();
//         events.clear();
//         Get.offNamed(AppRoute.login);
//         Get.snackbar('Success', 'Logged out successfully!');
//       } else {
//         throw Exception('Failed to logout: ${response.statusCode}');
//       }
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to logout: $e');
//     }
//   }
//
//   void toggleTheme() {
//     Get.changeThemeMode(Get.isDarkMode ? ThemeMode.light : ThemeMode.dark);
//   }
//
//   Future<XFile?> pickImage() async {
//     try {
//       final pickedFile = await ImagePicker().pickImage(
//         source: ImageSource.gallery,
//         imageQuality: 85,
//         maxWidth: 800,
//       );
//       return pickedFile;
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to pick image: ${e.toString()}');
//       return null;
//     }
//   }
//
//   Future<Map<String, dynamic>?> updateUserProfile({XFile? imageFile}) async {
//     try {
//       isUpdatingProfile(true);
//       final dio = DioClient(token: prefs.getString('token')!).instance;
//       final Map<String, dynamic> requestData = {};
//
//       if (tempUsername.value != staff['username']) {
//         requestData['username'] = tempUsername.value;
//       }
//       if (tempEmail.value != staff['email']) {
//         requestData['email'] = tempEmail.value;
//       }
//
//       if (imageFile != null) {
//         final sizeInMB = (await imageFile.length()) / (1024 * 1024);
//         if (sizeInMB > 5) {
//           throw Exception('Image must be less than 5MB');
//         }
//
//         final bytes = await imageFile.readAsBytes();
//         final mimeType = mime(imageFile.path) ?? 'image/jpeg';
//         final base64Image = base64Encode(bytes);
//         requestData['profile_picture'] = 'data:$mimeType;base64,$base64Image';
//       }
//
//       if (requestData.isEmpty) {
//         return null;
//       }
//
//       final response = await dio.put(
//         '/profile',
//         data: requestData,
//         options: Options(contentType: Headers.jsonContentType),
//       );
//
//       if (response.statusCode == 200) {
//         final data = response.data['data'];
//         staff.value = data['staff'];
//         userProfile.value = data['user'];
//         profilePicturePath = data['user']['profile_picture'];
//
//         tempUsername.value = data['staff']['username'];
//         tempEmail.value = data['staff']['email'];
//
//         await prefs.setString('staff', jsonEncode(data['staff']));
//         await prefs.setString('userProfile', jsonEncode(data['user']));
//
//         return data;
//       }
//       return null;
//     } catch (e) {
//       tempUsername.value = staff['username'];
//       tempEmail.value = staff['email'];
//       rethrow;
//     } finally {
//       isUpdatingProfile(false);
//     }
//   }
//
//   Future<bool> changePassword({
//     required String currentPassword,
//     required String newPassword,
//     required String confirmPassword,
//   }) async {
//     try {
//       if (newPassword != confirmPassword) {
//         throw Exception('New passwords do not match');
//       }
//
//       final token = prefs.getString('token');
//       if (token == null) throw Exception('No token found');
//
//       final response = await DioClient(token: token).instance.put(
//         '/profile/password',
//         data: {
//           'current_password': currentPassword,
//           'password': newPassword,
//           'password_confirmation': confirmPassword,
//         },
//       );
//
//       return response.statusCode == 200;
//     } on DioException catch (e) {
//       throw Exception(e.response?.data?['message'] ?? 'Failed to change password');
//     }
//   }
//
//   Future<void> deleteAccount() async {
//     try {
//       final token = prefs.getString('token');
//       if (token == null) throw Exception('No token found');
//
//       Get.dialog(
//         const Center(child: CircularProgressIndicator()),
//         barrierDismissible: false,
//       );
//
//       final dio = DioClient(token: token).instance;
//       final response = await dio.delete('/delete-account');
//
//       Get.back();
//
//       if (response.statusCode == 200) {
//         await prefs.clear();
//         events.clear();
//         Get.offAllNamed(AppRoute.login);
//         Get.snackbar('Success', 'Your account has been deleted successfully');
//       } else {
//         throw Exception(response.data['message'] ?? 'Failed to delete account');
//       }
//     } on DioException catch (e) {
//       Get.back();
//       final errorMessage = e.response?.data['message'] ?? 'Failed to delete account';
//       Get.snackbar('Error', errorMessage);
//     } catch (e) {
//       Get.back();
//       Get.snackbar('Error', e.toString());
//     }
//   }
//
//   void showDeleteAccountConfirmation() {
//     Get.dialog(
//       AlertDialog(
//         title: const Text('Delete Account'),
//         content: const Text(
//             'Are you sure you want to delete your account? This action cannot be undone. All your data will be permanently removed.'),
//         actions: [
//           TextButton(
//             onPressed: () => Get.back(),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () {
//               Get.back();
//               deleteAccount();
//             },
//             child: const Text(
//               'Delete',
//               style: TextStyle(color: Colors.red),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }