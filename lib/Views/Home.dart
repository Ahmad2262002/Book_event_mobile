// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:book_event/Controllers/HomeController.dart';
//
// class Home extends StatelessWidget {
//   const Home({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final HomeController controller = Get.put(HomeController());
//
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Theme.of(context).colorScheme.primary,
//         title: Center(
//           child: Text(
//             "Bokking app",
//             style: GoogleFonts.poppins(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: Theme.of(context).colorScheme.onPrimary,
//             ),
//           ),
//         ),
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: Icon(Get.isDarkMode ? Icons.light_mode : Icons.dark_mode,
//                 color: Theme.of(context).colorScheme.onPrimary),
//             onPressed: controller.toggleTheme,
//           ),
//         ],
//       ),
//       body: Obx(() {
//         if (controller.isLoading.value) {
//           return Center(
//             child: CircularProgressIndicator(
//               color: Theme.of(context).colorScheme.primary,
//             ),
//           );
//         }
//
//         if (controller.events.isEmpty) {
//           return Center(
//             child: Text(
//               'No events available',
//               style: GoogleFonts.poppins(
//                 fontSize: 18,
//                 color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
//               ),
//             ),
//           );
//         }
//
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const SizedBox(height: 16),
//             Expanded(
//               child: RefreshIndicator(
//                 onRefresh: () async {
//                   await controller.getEvents();
//                 },
//                 child: ListView.separated(
//                   padding: const EdgeInsets.all(16),
//                   itemCount: controller.events.length,
//                   separatorBuilder: (context, index) => const SizedBox(height: 16),
//                   itemBuilder: (context, index) {
//                     final event = controller.events[index];
//                     return _buildEventCard(context, event, controller);
//                   },
//                 ),
//               ),
//             ),
//           ],
//         );
//       }),
//       drawer: _buildDrawer(context, controller),
//     );
//   }
//
//   Widget _buildEventCard(BuildContext context, dynamic event, HomeController controller) {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             if (event['image'] != null)
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(12),
//                 child: Image.network(
//                   'http://172.20.10.3:8000/${event['image']}',
//                   width: double.infinity,
//                   height: 180,
//                   fit: BoxFit.cover,
//                   errorBuilder: (context, error, stackTrace) {
//                     return Container(
//                       height: 180,
//                       color: Colors.grey[200],
//                       child: const Center(
//                         child: Icon(Icons.broken_image, color: Colors.grey),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             const SizedBox(height: 12),
//             Text(
//               event['title'] ?? 'Event',
//               style: GoogleFonts.poppins(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Theme.of(context).colorScheme.onSurface,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               event['description'] ?? 'No description',
//               style: GoogleFonts.poppins(
//                 fontSize: 14,
//                 color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
//               ),
//             ),
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 Icon(Icons.location_on, size: 16,
//                     color: Theme.of(context).colorScheme.primary),
//                 const SizedBox(width: 4),
//                 Text(
//                   event['location'] ?? 'Location not specified',
//                   style: GoogleFonts.poppins(fontSize: 14),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 Icon(Icons.calendar_today, size: 16,
//                     color: Theme.of(context).colorScheme.primary),
//                 const SizedBox(width: 4),
//                 Text(
//                   '${event['start_date']} - ${event['end_date']}',
//                   style: GoogleFonts.poppins(fontSize: 14),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 Icon(Icons.attach_money, size: 16,
//                     color: Theme.of(context).colorScheme.primary),
//                 const SizedBox(width: 4),
//                 Text(
//                   '${event['price']} USD',
//                   style: GoogleFonts.poppins(fontSize: 14),
//                 ),
//                 const Spacer(),
//                 Icon(Icons.event_seat, size: 16,
//                     color: Theme.of(context).colorScheme.primary),
//                 const SizedBox(width: 4),
//                 Text(
//                   '${event['available_seats']}/${event['total_seats']} seats',
//                   style: GoogleFonts.poppins(fontSize: 14),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () {
//                   if (event['available_seats'] > 0) {
//                     controller.bookEvent(event['id']);
//                   } else {
//                     Get.snackbar(
//                       'Error',
//                       'No available seats for this event',
//                       snackPosition: SnackPosition.BOTTOM,
//                     );
//                   }
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Theme.of(context).colorScheme.primary,
//                   foregroundColor: Theme.of(context).colorScheme.onPrimary,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   padding: const EdgeInsets.symmetric(vertical: 12),
//                 ),
//                 child: const Text('Book Now'),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDrawer(BuildContext context, HomeController controller) {
//     return Drawer(
//       child: Column(
//         children: [
//           Obx(() => UserAccountsDrawerHeader(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   Theme.of(context).colorScheme.primary,
//                   Theme.of(context).colorScheme.secondary,
//                 ],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//             ),
//             accountName: Text(
//               controller.staff['username'] ?? 'Username',
//               style: GoogleFonts.poppins(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Theme.of(context).colorScheme.onPrimary,
//               ),
//             ),
//             accountEmail: Text(
//               controller.staff['email'] ?? 'user@email.com',
//               style: GoogleFonts.poppins(
//                 fontSize: 14,
//                 color: Theme.of(context)
//                     .colorScheme
//                     .onPrimary
//                     .withOpacity(0.8),
//               ),
//             ),
//             currentAccountPicture: CircleAvatar(
//               backgroundColor: Theme.of(context).colorScheme.secondary,
//               backgroundImage: controller.profilePicturePath != null
//                   ? NetworkImage(
//                 'http://172.20.10.3:8000/storage/${controller.profilePicturePath}',
//                 headers: {
//                   'Authorization':
//                   'Bearer ${controller.prefs.getString('token')}'
//                 },
//               )
//                   : null,
//               child: controller.profilePicturePath == null
//                   ? Text(
//                 controller.staff['username']
//                     ?.substring(0, 1)
//                     .toUpperCase() ??
//                     'U',
//                 style: GoogleFonts.poppins(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: Theme.of(context).colorScheme.onSecondary,
//                 ),
//               )
//                   : null,
//             ),
//           )),
//
//           ListTile(
//             leading: Icon(
//               Get.isDarkMode ? Icons.light_mode : Icons.dark_mode,
//               color: Theme.of(context).colorScheme.onSurface,
//             ),
//             title: const Text("Dark Mode", style: TextStyle(fontSize: 16)),
//             trailing: Switch(
//               value: Get.isDarkMode,
//               onChanged: (value) => controller.toggleTheme(),
//               activeColor: Theme.of(context).colorScheme.primary,
//             ),
//           ),
//
//           const Spacer(),
//           const Divider(),
//
//           ListTile(
//             leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
//             title: Text(
//               "Logout",
//               style: TextStyle(
//                 fontSize: 16,
//                 color: Theme.of(context).colorScheme.error,
//               ),
//             ),
//             onTap: controller.logout,
//           ),
//         ],
//       ),
//     );
//   }
// }