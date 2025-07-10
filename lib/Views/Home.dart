import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:book_event/Controllers/HomeController.dart';
import 'package:book_event/Models/Event.dart';
import 'package:book_event/Models/Booking.dart';
import 'package:intl/intl.dart';
import '../Models/Testimonial.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.put(HomeController());

    return Obx(() {
      // Show loading indicator while prefs are being initialized
      if (!controller.prefsInitialized.value) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      // Get theme mode from controller
      final bool isDarkMode = controller.isDarkMode.value;
      final Color primaryColor = isDarkMode ? const Color(0xFF0A84FF) : const Color(0xFF007AFF);
      final Color secondaryColor = isDarkMode ? const Color(0xFF30D158) : const Color(0xFF34C759);
      final Color backgroundColor = isDarkMode ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
      final Color cardColor = isDarkMode ? const Color(0xFF2C2C2E) : Colors.white;
      final Color textColor = isDarkMode ? Colors.white : const Color(0xFF1C1C1E);

      return Theme(
        data: ThemeData(
          brightness: isDarkMode ? Brightness.dark : Brightness.light,
          primaryColor: primaryColor,
          colorScheme: isDarkMode
              ? ColorScheme.dark(
            primary: primaryColor,
            secondary: secondaryColor,
            surface: cardColor,
          )
              : ColorScheme.light(
            primary: primaryColor,
            secondary: secondaryColor,
            surface: cardColor,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: cardColor,
            elevation: 0,
            titleTextStyle: TextStyle(
              color: textColor,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
            iconTheme: IconThemeData(color: primaryColor),
          ),
        ),
        child: Scaffold(
          backgroundColor: backgroundColor,
          drawer: _buildDrawer(context, controller, cardColor, textColor, primaryColor),
          appBar: AppBar(
            title: const Text('User Dashboard'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(
                  isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: primaryColor,
                ),
                onPressed: () {
                  controller.toggleTheme();

                },
              ),
            ],
          ),
          body: Obx(() {
            if (controller.currentTabIndex.value == 0 && controller.isLoading.value) {
              return Center(
                child: CircularProgressIndicator(
                  color: primaryColor,
                ),
              );
            }

            if (controller.currentTabIndex.value == 1 && controller.isBookingLoading.value) {
              return Center(
                child: CircularProgressIndicator(
                  color: primaryColor,
                ),
              );
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SegmentedButton<int>(
                    style: SegmentedButton.styleFrom(
                      backgroundColor: cardColor.withOpacity(0.1),
                      selectedBackgroundColor: primaryColor,
                      selectedForegroundColor: Colors.white,
                    ),
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Events')),
                      ButtonSegment(value: 1, label: Text('My Bookings')),
                      ButtonSegment(value: 2, label: Text('Testimonials')),
                    ],
                    selected: {controller.currentTabIndex.value},
                    onSelectionChanged: (newSelection) {
                      controller.currentTabIndex.value = newSelection.first;
                    },
                  ),
                ),
                Expanded(
                  child: IndexedStack(
                    index: controller.currentTabIndex.value.clamp(0, 2), // Ensure index is between 0-2
                    children: [
                      _buildEventsTab(context, controller, cardColor, textColor, primaryColor),
                      _buildBookingsTab(context, controller, cardColor, textColor, primaryColor),
                      _buildTestimonialsTab(context, controller, cardColor, textColor, primaryColor),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      );
    });
  }

  Widget _buildEventsTab(BuildContext context, HomeController controller, Color cardColor, Color textColor, Color primaryColor) {
    if (controller.events.isEmpty) {
      return RefreshIndicator(
        onRefresh: controller.getEvents,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event, size: 48, color: textColor.withOpacity(0.3)),
              const SizedBox(height: 16),
              Text(
                'No events available',
                style: TextStyle(
                  fontSize: 18,
                  color: textColor.withOpacity(0.6),
                ),
              ),
              TextButton(
                onPressed: controller.getEvents,
                child: Text(
                  'Refresh',
                  style: TextStyle(color: primaryColor),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: controller.getEvents,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: controller.events.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final event = controller.events[index];
          return _buildEventCard(context, event, controller, cardColor, textColor, primaryColor);
        },
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Event event, HomeController controller, Color cardColor, Color textColor, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (event.image.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                'http://172.20.10.3:8000/${event.image}',
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: cardColor.withOpacity(0.1),
                    child: Center(
                      child: Icon(Icons.broken_image, color: textColor.withOpacity(0.3)),
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  event.description,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow(Icons.location_on, event.location, textColor, primaryColor),
                const SizedBox(height: 8),
                _buildDetailRow(
                  Icons.calendar_today,
                  '${controller.formatDate(event.startDate.toString())} - ${controller.formatDate(event.endDate.toString())}',
                  textColor,
                  primaryColor,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Flexible(
                      child: _buildDetailChip('\$${event.price}', Icons.attach_money, primaryColor, textColor),
                    ),
                    const Spacer(),
                    Flexible(
                      child: _buildDetailChip('${event.availableSeats}/${event.totalSeats} seats',
                          Icons.event_seat, primaryColor, textColor),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (event.availableSeats > 0 && !controller.isEventExpired(event)) {
                        _showBookingConfirmation(context, event, controller, cardColor, textColor, primaryColor);
                      } else {
                        Get.snackbar(
                          'Error',
                          controller.isEventExpired(event)
                              ? 'This event has expired'
                              : 'No available seats for this event',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Book Now'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(String text, IconData icon, Color primaryColor, Color textColor) {
    return Container(
      constraints: BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: primaryColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsTab(BuildContext context, HomeController controller, Color cardColor, Color textColor, Color primaryColor) {
    if (controller.bookings.isEmpty) {
      return RefreshIndicator(
        onRefresh: controller.getBookings,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.book_online, size: 48, color: textColor.withOpacity(0.3)),
              const SizedBox(height: 16),
              Text(
                'No bookings yet',
                style: TextStyle(
                  fontSize: 18,
                  color: textColor.withOpacity(0.6),
                ),
              ),
              TextButton(
                onPressed: controller.getBookings,
                child: Text(
                  'Refresh',
                  style: TextStyle(color: primaryColor),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: controller.getBookings,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: controller.bookings.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final booking = controller.bookings[index];
          return _buildBookingCard(context, booking, cardColor, textColor, primaryColor);
        },
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, Booking booking, Color cardColor, Color textColor, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.eventTitle ?? 'Event',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    booking.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(booking.status),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (booking.location != null)
              _buildDetailRow(Icons.location_on, booking.location!, textColor, primaryColor),
            if (booking.startDate != null)
              _buildDetailRow(
                Icons.calendar_today,
                DateFormat('MMM d, y').format(booking.startDate!),
                textColor,
                primaryColor,
              ),
            if (booking.price != null)
              _buildDetailRow(Icons.attach_money, '\$${booking.price}', textColor, primaryColor),
            const SizedBox(height: 8),
            Text(
              'Booking ID: ${booking.id}',
              style: TextStyle(
                fontSize: 12,
                color: textColor.withOpacity(0.6),
              ),
            ),
            Text(
              'Booked on ${DateFormat('MMM d, y - h:mm a').format(booking.bookingDate)}',
              style: TextStyle(
                fontSize: 12,
                color: textColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.info_outline, color: primaryColor),
                  onPressed: () => _showBookingDetails(context, booking, cardColor, textColor, primaryColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingDetails(BuildContext context, Booking booking, Color cardColor, Color textColor, Color primaryColor) {
    final HomeController controller = Get.find<HomeController>();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Booking Details",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.print, color: primaryColor),
                      onPressed: () async {
                        final doc = pw.Document();

                        doc.addPage(
                          pw.Page(
                            build: (pw.Context context) {
                              return pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text('Booking Details', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                                  pw.SizedBox(height: 20),
                                  pw.Text(booking.eventTitle ?? 'Event', style: pw.TextStyle(fontSize: 18)),
                                  pw.Text('Status: ${booking.status.toUpperCase()}', style: pw.TextStyle(fontSize: 16)),
                                  pw.SizedBox(height: 20),
                                  pw.Text('Location: ${booking.location ?? 'N/A'}', style: pw.TextStyle(fontSize: 14)),
                                  pw.Text('Date: ${DateFormat('MMM d, y').format(booking.startDate!)}', style: pw.TextStyle(fontSize: 14)),
                                  pw.Text('Time: ${DateFormat('h:mm a').format(booking.startDate!)}', style: pw.TextStyle(fontSize: 14)),
                                  pw.SizedBox(height: 20),
                                  pw.Text('Booking ID: #${booking.id}', style: pw.TextStyle(fontSize: 14)),
                                  pw.Text('Booked on: ${DateFormat('MMM d, y h:mm a').format(booking.bookingDate)}', style: pw.TextStyle(fontSize: 14)),
                                  if (booking.price != null) pw.Text('Price: \$${booking.price}', style: pw.TextStyle(fontSize: 14)),
                                  pw.SizedBox(height: 20),
                                  pw.Text('User Information', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                                  pw.Text('Name: ${controller.userProfile['full_name'] ?? 'N/A'}', style: pw.TextStyle(fontSize: 14)),
                                  pw.Text('Email: ${controller.userProfile['email'] ?? 'N/A'}', style: pw.TextStyle(fontSize: 14)),
                                ],
                              );
                            },
                          ),
                        );

                        await Printing.layoutPdf(
                          onLayout: (PdfPageFormat format) async => doc.save(),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Event Details Section
                Text(
                  booking.eventTitle ?? 'Event',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    booking.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(booking.status),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                if (booking.location != null)
                  _buildDialogDetailRow("Location:", booking.location!, textColor),
                if (booking.startDate != null) ...[
                  _buildDialogDetailRow(
                    "Date:",
                    DateFormat('MMM d, y').format(booking.startDate!),
                    textColor,
                  ),
                  _buildDialogDetailRow(
                    "Time:",
                    DateFormat('h:mm a').format(booking.startDate!),
                    textColor,
                  ),
                ],

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Booking Information Section
                Text(
                  "Booking Information",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),

                _buildDialogDetailRow("Booking ID:", "#${booking.id}", textColor),
                _buildDialogDetailRow(
                  "Booking Date:",
                  DateFormat('MMM d, y h:mm a').format(booking.bookingDate),
                  textColor,
                ),
                if (booking.price != null)
                  _buildDialogDetailRow("Price:", "\$${booking.price}", textColor),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // User Information Section
                Text(
                  "Your Information",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),

                _buildDialogDetailRow("Name:", controller.userProfile['full_name'] ?? 'N/A', textColor),
                _buildDialogDetailRow("Email:", controller.userProfile['email'] ?? 'N/A', textColor),

                const SizedBox(height: 24),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      "Close",
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTestimonialsTab(BuildContext context, HomeController controller, Color cardColor, Color textColor, Color primaryColor) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () => _showTestimonialDialog(context, controller, cardColor, textColor, primaryColor),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Submit Feedback'),
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.testimonials.isEmpty) {
              return RefreshIndicator(
                onRefresh: controller.getTestimonials,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rate_review, size: 48, color: textColor.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'No testimonials yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: textColor.withOpacity(0.6),
                        ),
                      ),
                      TextButton(
                        onPressed: controller.getTestimonials,
                        child: Text(
                          'Refresh',
                          style: TextStyle(color: primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              color: primaryColor,
              onRefresh: controller.getTestimonials,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: controller.testimonials.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final testimonial = controller.testimonials[index];
                  return _buildTestimonialCard(testimonial, cardColor, textColor, primaryColor);
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTestimonialCard(Testimonial testimonial, Color cardColor, Color textColor, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: primaryColor.withOpacity(0.2),
                  child: Text(
                    testimonial.userName[0].toUpperCase(),
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  testimonial.userName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: testimonial.approved
                        ? Colors.green.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    testimonial.approved ? 'Approved' : 'Pending',
                    style: TextStyle(
                      color: testimonial.approved ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              testimonial.content,
              style: TextStyle(
                fontSize: 14,
                color: textColor.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                DateFormat('MMM d, y').format(testimonial.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: textColor.withOpacity(0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, HomeController controller, Color cardColor, Color textColor, Color primaryColor) {
    return Drawer(
      backgroundColor: cardColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'User Panel',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 8),
                Text(
                  'Manage your bookings',
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          // Update Profile item
          ListTile(
            leading: Icon(
              Icons.person,
              color: textColor.withOpacity(0.8),
            ),
            title: Text(
              'Update Profile',
              style: TextStyle(
                color: textColor,
              ),
            ),
            onTap: () {
              Navigator.pop(context); // Close drawer first
              _showUpdateProfileDialog(context, controller, cardColor, textColor, primaryColor);
            },
          ),
          _buildDrawerItem(
            context,
            Icons.event,
            'Events',
            0,
            controller.currentTabIndex.value == 0,
            textColor,
            primaryColor,
                () {
              controller.currentTabIndex.value = 0;
              Navigator.pop(context);
            },
          ),
          _buildDrawerItem(
            context,
            Icons.book_online,
            'My Bookings',
            1,
            controller.currentTabIndex.value == 1,
            textColor,
            primaryColor,
                () {
              controller.currentTabIndex.value = 1;
              Navigator.pop(context);
            },
          ),
          _buildDrawerItem(
            context,
            Icons.rate_review,
            'Testimonials',
            2,
            controller.currentTabIndex.value == 2,
            textColor,
            primaryColor,
                () {
              controller.currentTabIndex.value = 2;
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            onTap: controller.logout,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
      BuildContext context,
      IconData icon,
      String title,
      int tabIndex,
      bool isSelected,
      Color textColor,
      Color primaryColor,
      VoidCallback onTap,
      ) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? primaryColor : textColor.withOpacity(0.8),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? primaryColor : textColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onTap: onTap,
    );
  }

  Widget _buildDetailRow(IconData icon, String text, Color textColor, Color primaryColor) {
    return Row(
      children: [
        Icon(icon, size: 18, color: primaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: textColor.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }

  void _showBookingConfirmation(
      BuildContext context,
      Event event,
      HomeController controller,
      Color cardColor,
      Color textColor,
      Color primaryColor,
      ) {
    final cardNumberController = TextEditingController();
    final expiryController = TextEditingController();
    final cvvController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Confirm Booking",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),

                // Event Details
                _buildDialogDetailRow("Event:", event.title, textColor),
                _buildDialogDetailRow("Location:", event.location, textColor),
                _buildDialogDetailRow(
                  "Date:",
                  DateFormat('MMM d, y').format(event.startDate),
                  textColor,
                ),
                _buildDialogDetailRow(
                  "Time:",
                  DateFormat('h:mm a').format(event.startDate),
                  textColor,
                ),
                _buildDialogDetailRow("Price:", "\$${event.price}", textColor),
                _buildDialogDetailRow(
                  "Available Seats:",
                  event.availableSeats.toString(),
                  textColor,
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Payment Details Section
                Text(
                  "Payment Details",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),

                // Card Number Field
                Text(
                  "Card Number",
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: cardNumberController,
                  decoration: InputDecoration(
                    hintText: "1234 5678 9012 3456",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: textColor.withOpacity(0.2)),
                    ),
                    filled: true,
                    fillColor: cardColor.withOpacity(0.8),
                  ),
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: textColor),
                ),
                const SizedBox(height: 16),

                // Expiry and CVV Row
                Row(
                  children: [
                    // Expiry Date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Expiry",
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: expiryController,
                            decoration: InputDecoration(
                              hintText: "MM/YY",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: textColor.withOpacity(0.2)),
                              ),
                              filled: true,
                              fillColor: cardColor.withOpacity(0.8),
                            ),
                            keyboardType: TextInputType.datetime,
                            style: TextStyle(color: textColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // CVV
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "CVV",
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: cvvController,
                            decoration: InputDecoration(
                              hintText: "123",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: textColor.withOpacity(0.2)),
                              ),
                              filled: true,
                              fillColor: cardColor.withOpacity(0.8),
                            ),
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            style: TextStyle(color: textColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          // Validate payment fields
                          if (cardNumberController.text.isEmpty ||
                              expiryController.text.isEmpty ||
                              cvvController.text.isEmpty) {
                            Get.snackbar(
                              'Error',
                              'Please fill all payment details',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                            return;
                          }

                          // Validate card number format (simple validation)
                          if (cardNumberController.text.replaceAll(' ', '').length != 16) {
                            Get.snackbar(
                              'Error',
                              'Please enter a valid 16-digit card number',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                            return;
                          }

                          // Validate expiry date format (simple validation)
                          if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(expiryController.text)) {
                            Get.snackbar(
                              'Error',
                              'Please enter expiry date in MM/YY format',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                            return;
                          }

                          // Validate CVV (simple validation)
                          if (cvvController.text.length < 3) {
                            Get.snackbar(
                              'Error',
                              'Please enter a valid CVV',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                            return;
                          }

                          try {
                            // Show loading indicator
                            Get.dialog(
                              Center(
                                child: CircularProgressIndicator(
                                  color: primaryColor,
                                ),
                              ),
                              barrierDismissible: false,
                            );

                            // Process booking
                            await controller.bookEvent(int.parse(event.id));

                            // Close loading and booking dialog
                            Navigator.pop(context); // Close loading
                            Navigator.pop(context); // Close booking dialog

                            // Show success message
                            Get.snackbar(
                              'Success',
                              'Your booking has been confirmed!',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.green,
                              colorText: Colors.white,
                            );
                          } catch (e) {
                            Navigator.pop(context); // Close loading if error occurs
                            Get.snackbar(
                              'Error',
                              'Failed to book event: ${e.toString()}',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          "Confirm Payment",
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogDetailRow(String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: textColor.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTestimonialDialog(
      BuildContext context,
      HomeController controller,
      Color cardColor,
      Color textColor,
      Color primaryColor,
      ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7, // Limit height
          ),
          child: SingleChildScrollView( // Make it scrollable
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Important for scrollable content
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Share Your Experience",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller.testimonialController,
                    style: TextStyle(color: textColor),
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: "Tell us about your experience...",
                      hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: textColor.withOpacity(0.2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: textColor.withOpacity(0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor),
                      ),
                      filled: true,
                      fillColor: cardColor.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            controller.submitTestimonial();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            "Submit",
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showUpdateProfileDialog(
      BuildContext context,
      HomeController controller,
      Color cardColor,
      Color textColor,
      Color primaryColor,
      ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: controller.profileFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Update Profile",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Full Name Field
                  Text(
                    "Full Name",
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: controller.fullNameController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: "Enter your full name",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: textColor.withOpacity(0.2)),
                      ),
                      filled: true,
                      fillColor: cardColor.withOpacity(0.8),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email Field
                  Text(
                    "Email",
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: controller.emailController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: "Enter your email",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: textColor.withOpacity(0.2)),
                      ),
                      filled: true,
                      fillColor: cardColor.withOpacity(0.8),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Phone Field
                  Text(
                    "Phone",
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: controller.phoneController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: "Enter your phone number",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: textColor.withOpacity(0.2)),
                      ),
                      filled: true,
                      fillColor: cardColor.withOpacity(0.8),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Obx(() => ElevatedButton(
                          onPressed: controller.isProfileLoading.value
                              ? null
                              : () => controller.updateProfile(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: controller.isProfileLoading.value
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : const Text(
                            "Update",
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        )),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }



  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}