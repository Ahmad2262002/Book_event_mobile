import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:book_event/Controllers/AdminHomeController.dart';
import 'package:book_event/Models/Event.dart';
import 'package:book_event/Models/Booking.dart';
import 'package:book_event/Models/User.dart';
import 'package:book_event/Models/Testimonial.dart';
import 'package:path/path.dart';

class AdminHome extends StatelessWidget {
  final AdminHomeController controller = Get.put(AdminHomeController());
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _seatsController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String? _imagePath;

  // iOS-inspired colors
  final Color _primaryColor = const Color(0xFF007AFF);
  final Color _secondaryColor = const Color(0xFF34C759);
  final Color _backgroundColor = const Color(0xFFF2F2F7);
  final Color _cardColor = Colors.white;
  final Color _textColor = const Color(0xFF1C1C1E);

  AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDarkMode = controller.isDarkMode.value;
      final primaryColor = isDarkMode ? Colors.blueAccent : _primaryColor;
      final backgroundColor = isDarkMode ? Colors.grey[900]! : _backgroundColor;
      final cardColor = isDarkMode ? Colors.grey[800]!.withOpacity(0.8) : _cardColor;
      final textColor = isDarkMode ? Colors.white : _textColor;

      return Theme(
        data: ThemeData(
          brightness: isDarkMode ? Brightness.dark : Brightness.light,
          primaryColor: primaryColor,
          colorScheme: isDarkMode
              ? ColorScheme.dark(
            primary: primaryColor,
            secondary: Colors.green,
            surface: cardColor,
          )
              : ColorScheme.light(
            primary: primaryColor,
            secondary: _secondaryColor,
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
          tabBarTheme: TabBarThemeData(
            labelColor: primaryColor,
            unselectedLabelColor: Colors.grey,
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(width: 2, color: primaryColor),
            ),
          ),
        ),
        child: Scaffold(
          backgroundColor: backgroundColor,
          drawer: _buildDrawer(context, isDarkMode, cardColor, textColor, primaryColor),
          appBar: AppBar(
            title: const Text('Admin Dashboard'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(
                  isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: primaryColor,
                ),
                onPressed: controller.toggleDarkMode,
              ),
              IconButton(
                icon: Icon(Icons.logout, color: primaryColor),
                onPressed: controller.logout,
              ),
            ],
          ),
          body: Column(
            children: [
              _buildStatsSection(cardColor, textColor, primaryColor),
              Expanded(
                child: Obx(() {
                  switch (controller.selectedTab.value) {
                    case 0:
                      return _buildEventsTab(cardColor, textColor, primaryColor);
                    case 1:
                      return _buildBookingsTab(cardColor, textColor, primaryColor);
                    case 2:
                      return _buildUsersTab(cardColor, textColor, primaryColor);
                    case 3:
                      return _buildTestimonialsTab(cardColor, textColor, primaryColor);
                    default:
                      return _buildEventsTab(cardColor, textColor, primaryColor);
                  }
                }),
              ),
            ],
          ),
          floatingActionButton: controller.selectedTab.value == 0
              ? FloatingActionButton(
            backgroundColor: primaryColor,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onPressed: () => _showAddEventDialog(context, isDarkMode, cardColor, textColor, primaryColor),
            child: const Icon(Icons.add, color: Colors.white),
          )
              : null,
        ),
      );
    });
  }

  Widget _buildDrawer(BuildContext context, bool isDarkMode, Color cardColor, Color textColor, Color primaryColor) {
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
                  'Admin Panel',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your application',
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            context,
            Icons.event,
            'Events',
            0,
            isDarkMode,
            textColor,
            primaryColor,
          ),
          _buildDrawerItem(
            context,
            Icons.book_online,
            'Bookings',
            1,
            isDarkMode,
            textColor,
            primaryColor,
          ),
          _buildDrawerItem(
            context,
            Icons.people,
            'Users',
            2,
            isDarkMode,
            textColor,
            primaryColor,
          ),
          _buildDrawerItem(
            context,
            Icons.rate_review,
            'Testimonials',
            3,
            isDarkMode,
            textColor,
            primaryColor,
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
      bool isDarkMode,
      Color textColor,
      Color primaryColor,
      ) {
    return Obx(() {
      final isSelected = controller.selectedTab.value == tabIndex;
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
        onTap: () {
          controller.selectedTab.value = tabIndex;
          Navigator.pop(context);
        },
      );
    });
  }

  Widget _buildStatsSection(Color cardColor, Color textColor, Color primaryColor) {
    return Obx(() {
      final stats = controller.stats.value;
      return Container(
        margin: const EdgeInsets.all(16),
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
            children: [
              Text(
                'Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    Icons.event,
                    'Events',
                    '${stats.totalEvents}',
                    primaryColor,
                    textColor,
                  ),
                  _buildStatItem(
                    Icons.people,
                    'Users',
                    '${stats.totalUsers}',
                    _secondaryColor,
                    textColor,
                  ),
                  _buildStatItem(
                    Icons.book_online,
                    'Bookings',
                    '${stats.totalBookings}',
                    Colors.orange,
                    textColor,
                  ),
                  _buildStatItem(
                    Icons.attach_money,
                    'Revenue',
                    '\$${stats.totalRevenue.toStringAsFixed(2)}',
                    Colors.purple,
                    textColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildStatItem(
      IconData icon,
      String label,
      String value,
      Color color,
      Color textColor,
      ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: textColor.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildEventsTab(Color cardColor, Color textColor, Color primaryColor) {
    return Obx(() {
      if (controller.isLoading.value && controller.events.isEmpty) {
        return Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        );
      }

      if (controller.events.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event, size: 48, color: textColor.withOpacity(0.3)),
              const SizedBox(height: 16),
              Text(
                'No events found',
                style: TextStyle(
                  fontSize: 18,
                  color: textColor.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: controller.fetchEvents,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: primaryColor.withOpacity(0.1),
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(color: primaryColor),
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        color: primaryColor,
        onRefresh: controller.fetchEvents,
        child: ListView.builder(
          key: Key('events_list_${controller.events.length}'),
          padding: const EdgeInsets.all(16),
          itemCount: controller.events.length,
          itemBuilder: (context, index) {
            final event = controller.events[index];
            return _buildEventCard(event, cardColor, textColor, primaryColor);
          },
        ),
      );
    });
  }

  Widget _buildEventCard(Event event, Color cardColor, Color textColor, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              child: _buildEventImage(event),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        final context = Get.context!; // Get the BuildContext from GetX
                        _showUpdateEventDialog(
                          context, // Use the proper BuildContext
                          event,
                          controller.isDarkMode.value,
                          cardColor,
                          textColor,
                          primaryColor,
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteConfirmation(event.id),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  event.description ?? 'No description',
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                _buildEventDetailRow(
                  Icons.location_on,
                  event.location,
                  textColor,
                  primaryColor,
                ),
                const SizedBox(height: 8),
                _buildEventDetailRow(
                  Icons.calendar_today,
                  '${_formatDateTime(event.startDate, includeTime: true)} - ${_formatDateTime(event.endDate, includeTime: true)}',
                  textColor,
                  primaryColor,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildEventDetailChip(
                      '\$${event.price.toStringAsFixed(2)}',
                      Icons.attach_money,
                      primaryColor,
                      textColor,
                    ),
                    const Spacer(),
                    _buildEventDetailChip(
                      '${event.availableSeats}/${event.totalSeats} seats',
                      Icons.event_seat,
                      primaryColor,
                      textColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsTab(Color cardColor, Color textColor, Color primaryColor) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Obx(() => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip('Pending', 'pending', primaryColor, textColor),
              _buildFilterChip('Confirmed', 'confirmed', primaryColor, textColor),
              _buildFilterChip('Cancelled', 'cancelled', primaryColor, textColor),
              _buildFilterChip('All', 'all', primaryColor, textColor),
            ],
          )),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value && controller.bookings.isEmpty) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              );
            }

            final filteredBookings = controller.filteredBookings;
            if (filteredBookings.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.book_online, size: 48, color: textColor.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    Text(
                      'No bookings found',
                      style: TextStyle(
                        fontSize: 18,
                        color: textColor.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: controller.fetchBookings,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: primaryColor.withOpacity(0.1),
                      ),
                      child: Text(
                        'Retry',
                        style: TextStyle(color: primaryColor),
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              color: primaryColor,
              onRefresh: controller.fetchBookings,
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: filteredBookings.length,
                itemBuilder: (context, index) {
                  final booking = filteredBookings[index];
                  return _buildBookingCard(booking, cardColor, textColor, primaryColor);
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildUsersTab(Color cardColor, Color textColor, Color primaryColor) {
    return Obx(() {
      if (controller.isLoading.value && controller.users.isEmpty) {
        return Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        );
      }

      if (controller.users.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people, size: 48, color: textColor.withOpacity(0.3)),
              const SizedBox(height: 16),
              Text(
                'No users found',
                style: TextStyle(
                  fontSize: 18,
                  color: textColor.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: controller.fetchUsers,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: primaryColor.withOpacity(0.1),
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(color: primaryColor),
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        color: primaryColor,
        onRefresh: controller.fetchUsers,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.users.length,
          itemBuilder: (context, index) {
            final user = controller.users[index];
            return _buildUserCard(user, cardColor, textColor, primaryColor);
          },
        ),
      );
    });
  }

  Widget _buildTestimonialsTab(Color cardColor, Color textColor, Color primaryColor) {
    return Obx(() {
      if (controller.isLoading.value && controller.testimonials.isEmpty) {
        return Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        );
      }

      if (controller.testimonials.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.rate_review, size: 48, color: textColor.withOpacity(0.3)),
              const SizedBox(height: 16),
              Text(
                'No testimonials found',
                style: TextStyle(
                  fontSize: 18,
                  color: textColor.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: controller.fetchTestimonials,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: primaryColor.withOpacity(0.1),
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(color: primaryColor),
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        color: primaryColor,
        onRefresh: controller.fetchTestimonials,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.testimonials.length,
          itemBuilder: (context, index) {
            final testimonial = controller.testimonials[index];
            return _buildTestimonialCard(testimonial, cardColor, textColor, primaryColor);
          },
        ),
      );
    });
  }

  Widget _buildUserCard(User user, Color cardColor, Color textColor, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                    user.fullName[0].toUpperCase(),
                    style: TextStyle(color: primaryColor),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.info_outline, color: primaryColor),
                  onPressed: () => _showUserDetails(user, cardColor, textColor, primaryColor),
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showUpdateUserDialog(user, cardColor, textColor, primaryColor),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteUserConfirmation(user.id),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildUserDetailChip(
                  user.phone,
                  Icons.phone,
                  primaryColor,
                  textColor,
                ),
                const SizedBox(width: 8),
                _buildUserDetailChip(
                  user.role,
                  Icons.person,
                  primaryColor,
                  textColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestimonialCard(Testimonial testimonial, Color cardColor, Color textColor, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                    style: TextStyle(color: primaryColor),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    testimonial.userName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                if (!testimonial.approved)
                  IconButton(
                    icon: Icon(Icons.check, color: Colors.green),
                    onPressed: () => controller.approveTestimonial(testimonial.id),
                  ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteTestimonialConfirmation(testimonial.id),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              testimonial.content,
              style: TextStyle(
                fontSize: 14,
                color: textColor.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: testimonial.approved ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    testimonial.approved ? 'Approved' : 'Pending',
                    style: TextStyle(
                      color: testimonial.approved ? Colors.green : Colors.orange,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(testimonial.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Booking booking, Color cardColor, Color textColor, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            // User information section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: primaryColor.withOpacity(0.2),
                    child: Text(
                      booking.userName?[0].toUpperCase() ?? 'U',
                      style: TextStyle(color: primaryColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.userName ?? 'No name',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      Text(
                        booking.userEmail ?? 'No email',
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Event information
            Text(
              'Event: ${booking.eventTitle ?? 'N/A'}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status).withOpacity(0.1),
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
                const Spacer(),
                Text(
                  _formatDate(booking.bookingDate),
                  style: TextStyle(
                    color: textColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            if (booking.location != null)
              _buildEventDetailRow(
                Icons.location_on,
                booking.location!,
                textColor,
                primaryColor,
              ),
            if (booking.startDate != null)
              _buildEventDetailRow(
                Icons.calendar_today,
                _formatDateTime(booking.startDate!, includeTime: true),
                textColor,
                primaryColor,
              ),
            if (booking.price != null)
              _buildEventDetailRow(
                Icons.attach_money,
                '\$${booking.price!.toStringAsFixed(2)}',
                textColor,
                primaryColor,
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showBookingDetails(booking, cardColor, textColor, primaryColor),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: primaryColor),
                    ),
                    child: Text(
                      'View Details',
                      style: TextStyle(color: primaryColor),
                    ),
                  ),
                ),
                if (booking.status == 'pending') ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => controller.updateBookingStatus(booking.id, 'confirmed'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _secondaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventImage(Event event) {
    final imageUrl = 'http://172.20.10.3:8000/${event.image}';
    debugPrint('Loading event image from: $imageUrl');

    return Image.network(
      imageUrl,
      height: 150,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(
          height: 150,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Image load error: $error');
        return Container(
          height: 150,
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, size: 50),
        );
      },
    );
  }

  Widget _buildEventDetailRow(IconData icon, String text, Color textColor, Color primaryColor) {
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

  Widget _buildEventDetailChip(String text, IconData icon, Color primaryColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: primaryColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserDetailChip(String text, IconData icon, Color primaryColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: primaryColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, Color primaryColor, Color textColor) {
    return ChoiceChip(
      label: Text(label),
      selected: controller.selectedBookingFilter.value == value,
      onSelected: (_) => controller.selectedBookingFilter.value = value,
      selectedColor: primaryColor,
      labelStyle: TextStyle(
        color: controller.selectedBookingFilter.value == value
            ? Colors.white
            : textColor,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return _secondaryColor;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Future<void> _showAddEventDialog(BuildContext context, bool isDarkMode, Color cardColor, Color textColor, Color primaryColor) async {
    _titleController.clear();
    _descriptionController.clear();
    _locationController.clear();
    _priceController.clear();
    _seatsController.clear();
    _startDate = null;
    _endDate = null;
    _startTime = null;
    _endTime = null;
    _startTimeController.clear();
    _endTimeController.clear();
    _imagePath = null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: textColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'Add New Event',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildFormField(
                      controller: _titleController,
                      label: 'Title',
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      textColor: textColor,
                    ),
                    const SizedBox(height: 16),
                    _buildFormField(
                      controller: _descriptionController,
                      label: 'Description',
                      maxLines: 3,
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      textColor: textColor,
                    ),
                    const SizedBox(height: 16),
                    _buildFormField(
                      controller: _locationController,
                      label: 'Location',
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      textColor: textColor,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateButton(
                            'Start Date',
                            _startDate,
                                () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) {
                                _startDate = date;
                                _startTime = null;
                                _startTimeController.clear();
                              }
                            },
                            textColor: textColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTimeButton(
                            'Start Time',
                            _startTime,
                                () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (time != null) {
                                _startTime = time;
                                _startTimeController.text = _formatTime(time);
                              }
                            },
                            controller: _startTimeController,
                            textColor: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateButton(
                            'End Date',
                            _endDate,
                                () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _startDate ?? DateTime.now(),
                                firstDate: _startDate ?? DateTime.now(),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) {
                                _endDate = date;
                                _endTime = null;
                                _endTimeController.clear();
                              }
                            },
                            textColor: textColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTimeButton(
                            'End Time',
                            _endTime,
                                () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: _startTime ?? TimeOfDay.now(),
                              );
                              if (time != null) {
                                _endTime = time;
                                _endTimeController.text = _formatTime(time);
                              }
                            },
                            controller: _endTimeController,
                            textColor: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            controller: _priceController,
                            label: 'Price',
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Required';
                              final price = double.tryParse(value);
                              if (price == null) return 'Invalid number';
                              if (price < 0) return 'Must be positive';
                              return null;
                            },
                            textColor: textColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFormField(
                            controller: _seatsController,
                            label: 'Total Seats',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Required';
                              final seats = int.tryParse(value);
                              if (seats == null) return 'Invalid number';
                              if (seats <= 0) return 'Must be at least 1';
                              return null;
                            },
                            textColor: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          final image = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                            maxWidth: 1024,
                            maxHeight: 1024,
                            imageQuality: 85,
                          );
                          if (image != null) {
                            _imagePath = image.path;
                          }
                        } catch (e) {
                          Get.snackbar(
                            'Error',
                            'Failed to select image: ${e.toString()}',
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor.withOpacity(0.1),
                        foregroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Upload Image'),
                    ),
                    if (_imagePath != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Image selected',
                        style: TextStyle(
                          color: _secondaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: primaryColor),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState?.validate() ?? false) {
                                // Validate dates and times
                                if (_startDate == null || _endDate == null ||
                                    _startTime == null || _endTime == null) {
                                  Get.snackbar(
                                    'Error',
                                    'Please select both date and time',
                                    backgroundColor: Colors.red,
                                    colorText: Colors.white,
                                  );
                                  return;
                                }

                                // Combine date and time
                                final startDateTime = DateTime(
                                  _startDate!.year,
                                  _startDate!.month,
                                  _startDate!.day,
                                  _startTime!.hour,
                                  _startTime!.minute,
                                );

                                final endDateTime = DateTime(
                                  _endDate!.year,
                                  _endDate!.month,
                                  _endDate!.day,
                                  _endTime!.hour,
                                  _endTime!.minute,
                                );

                                if (endDateTime.isBefore(startDateTime)) {
                                  Get.snackbar(
                                    'Error',
                                    'End date/time must be after start date/time',
                                    backgroundColor: Colors.red,
                                    colorText: Colors.white,
                                  );
                                  return;
                                }

                                if (_imagePath == null) {
                                  Get.snackbar(
                                    'Error',
                                    'Please select an image',
                                    backgroundColor: Colors.red,
                                    colorText: Colors.white,
                                  );
                                  return;
                                }

                                final success = await controller.createEvent(
                                  title: _titleController.text,
                                  description: _descriptionController.text,
                                  location: _locationController.text,
                                  startDate: startDateTime,
                                  endDate: endDateTime,
                                  price: double.tryParse(_priceController.text) ?? 0,
                                  totalSeats: int.tryParse(_seatsController.text) ?? 0,
                                  imagePath: _imagePath!,
                                );

                                if (success) {
                                  Navigator.pop(context);
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Save'),
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
      },
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    int? maxLines,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    required Color textColor,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textColor.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textColor),
        ),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: textColor),
    );
  }

  Widget _buildDateButton(String label, DateTime? date, VoidCallback onPressed, {required Color textColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textColor.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: BorderSide(color: textColor.withOpacity(0.3)),
            backgroundColor: Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date == null ? 'Select $label' : _formatDate(date),
                style: TextStyle(
                  color: date == null
                      ? textColor.withOpacity(0.5)
                      : textColor,
                ),
              ),
              Icon(Icons.calendar_today, size: 18, color: textColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeButton(
      String label,
      TimeOfDay? time,
      VoidCallback onPressed, {
        required TextEditingController controller,
        required Color textColor,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textColor.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: BorderSide(color: textColor.withOpacity(0.3)),
            backgroundColor: Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: false,
                  decoration: InputDecoration(
                    hintText: time == null ? 'Select $label' : '',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: TextStyle(
                    color: time == null
                        ? textColor.withOpacity(0.5)
                        : textColor,
                  ),
                ),
              ),
              Icon(Icons.access_time, size: 18, color: textColor),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(String eventId) {
    Get.defaultDialog(
      title: 'Delete Event',
      middleText: 'Are you sure you want to delete this event?',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      cancelTextColor: Colors.black,
      onConfirm: () async {
        Get.back();
        final success = await controller.deleteEvent(eventId);
        if (!success) {
          Get.snackbar('Error', 'Cannot delete event with active bookings');
        }
      },
    );
  }

  void _showDeleteUserConfirmation(int userId) {
    Get.defaultDialog(
      title: 'Delete User',
      middleText: 'Are you sure you want to delete this user?',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      cancelTextColor: Colors.black,
      onConfirm: () async {
        Get.back();
        final success = await controller.deleteUser(userId);
        if (!success) {
          Get.snackbar('Error', 'Cannot delete user with active bookings');
        }
      },
    );
  }

  void _showUserDetails(User user, Color cardColor, Color textColor, Color primaryColor) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'User Details',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Name:', user.fullName, textColor),
              _buildDetailRow('Email:', user.email, textColor),
              _buildDetailRow('Phone:', user.phone, textColor),
              _buildDetailRow('Role:', user.role, textColor),
              if (user.createdAt != null)
                _buildDetailRow('Joined:', _formatDate(user.createdAt!), textColor),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteTestimonialConfirmation(int testimonialId) {
    Get.defaultDialog(
      title: 'Delete Testimonial',
      middleText: 'Are you sure you want to delete this testimonial?',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      cancelTextColor: Colors.black,
      onConfirm: () {
        controller.deleteTestimonial(testimonialId);
        Get.back();
      },
    );
  }

  void _showBookingDetails(Booking booking, Color cardColor, Color textColor, Color primaryColor) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Booking Details',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Event:', booking.eventTitle ?? 'N/A', textColor),
              _buildDetailRow('Status:', booking.status.toUpperCase(), textColor),
              _buildDetailRow('Booking Date:', _formatDateTime(booking.bookingDate), textColor),
              if (booking.startDate != null)
                _buildDetailRow('Event Date:', _formatDateTime(booking.startDate!, includeTime: true), textColor),
              if (booking.location != null)
                _buildDetailRow('Location:', booking.location!, textColor),
              if (booking.price != null)
                _buildDetailRow('Price:', '\$${booking.price!.toStringAsFixed(2)}', textColor),
              const SizedBox(height: 24),
              if (booking.qrCode.isNotEmpty)
                Column(
                  children: [
                    Text(
                      'QR Code',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.network(
                        'http://172.20.10.3:8000/${booking.qrCode}',
                        height: 200,
                        width: 200,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.error, size: 50, color: Colors.red);
                        },
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUpdateUserDialog(User user, Color cardColor, Color textColor, Color primaryColor) {
    final _updateNameController = TextEditingController(text: user.fullName);
    final _updateEmailController = TextEditingController(text: user.email);
    final _updatePhoneController = TextEditingController(text: user.phone);
    final _updateRoleController = TextEditingController(text: user.role);

    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Update User',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 24),
              _buildFormField(
                controller: _updateNameController,
                label: 'Full Name',
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                textColor: textColor,
              ),
              const SizedBox(height: 16),
              _buildFormField(
                controller: _updateEmailController,
                label: 'Email',
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                textColor: textColor,
              ),
              const SizedBox(height: 16),
              _buildFormField(
                controller: _updatePhoneController,
                label: 'Phone',
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                textColor: textColor,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: user.role,
                decoration: InputDecoration(
                  labelText: 'Role',
                  labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: textColor.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: textColor.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: textColor),
                  ),
                ),
                items: ['user', 'admin']
                    .map((role) => DropdownMenuItem<String>(
                  value: role,
                  child: Text(
                    role.toUpperCase(),
                    style: TextStyle(color: textColor),
                  ),
                ))
                    .toList(),
                onChanged: (value) {
                  _updateRoleController.text = value ?? 'user';
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: primaryColor),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final updatedUser = User(
                          id: user.id,
                          fullName: _updateNameController.text,
                          email: _updateEmailController.text,
                          phone: _updatePhoneController.text,
                          role: _updateRoleController.text,
                        );

                        final success = await controller.updateUser(updatedUser);
                        if (success) {
                          Get.back();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Update'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color textColor) {
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

  void _showUpdateEventDialog(
      BuildContext context,
      Event event,
      bool isDarkMode,
      Color cardColor,
      Color textColor,
      Color primaryColor,
      ) {
    _titleController.text = event.title;
    _descriptionController.text = event.description;
    _locationController.text = event.location;
    _priceController.text = event.price.toString();
    _seatsController.text = event.totalSeats.toString();
    _startDate = event.startDate;
    _endDate = event.endDate;
    _startTime = TimeOfDay.fromDateTime(event.startDate);
    _endTime = TimeOfDay.fromDateTime(event.endDate);
    _startTimeController.text = _formatTime(_startTime!);
    _endTimeController.text = _formatTime(_endTime!);
    _imagePath = event.image.isNotEmpty ? 'http://172.20.10.3:8000/uploads/${event.image}' : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: textColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'Update Event',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildFormField(
                      controller: _titleController,
                      label: 'Title',
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      textColor: textColor,
                    ),
                    const SizedBox(height: 16),
                    _buildFormField(
                      controller: _descriptionController,
                      label: 'Description',
                      maxLines: 3,
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      textColor: textColor,
                    ),
                    const SizedBox(height: 16),
                    _buildFormField(
                      controller: _locationController,
                      label: 'Location',
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      textColor: textColor,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateButton(
                            'Start Date',
                            _startDate,
                                () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _startDate ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) {
                                _startDate = date;
                              }
                            },
                            textColor: textColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTimeButton(
                            'Start Time',
                            _startTime,
                                () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: _startTime ?? TimeOfDay.now(),
                              );
                              if (time != null) {
                                _startTime = time;
                                _startTimeController.text = _formatTime(time);
                              }
                            },
                            controller: _startTimeController,
                            textColor: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateButton(
                            'End Date',
                            _endDate,
                                () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _endDate ?? DateTime.now(),
                                firstDate: _startDate ?? DateTime.now(),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) {
                                _endDate = date;
                              }
                            },
                            textColor: textColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTimeButton(
                            'End Time',
                            _endTime,
                                () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: _endTime ?? TimeOfDay.now(),
                              );
                              if (time != null) {
                                _endTime = time;
                                _endTimeController.text = _formatTime(time);
                              }
                            },
                            controller: _endTimeController,
                            textColor: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            controller: _priceController,
                            label: 'Price',
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Required';
                              final price = double.tryParse(value);
                              if (price == null) return 'Invalid number';
                              if (price < 0) return 'Must be positive';
                              return null;
                            },
                            textColor: textColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFormField(
                            controller: _seatsController,
                            label: 'Total Seats',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Required';
                              final seats = int.tryParse(value);
                              if (seats == null) return 'Invalid number';
                              if (seats <= 0) return 'Must be at least 1';
                              return null;
                            },
                            textColor: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          final image = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                            maxWidth: 1024,
                            maxHeight: 1024,
                            imageQuality: 85,
                          );
                          if (image != null) {
                            _imagePath = image.path;
                          }
                        } catch (e) {
                          Get.snackbar(
                            'Error',
                            'Failed to select image: ${e.toString()}',
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor.withOpacity(0.1),
                        foregroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Change Image'),
                    ),
                    if (_imagePath != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'New image selected',
                        style: TextStyle(
                          color: _secondaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ] else if (event.image.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Current image will be kept',
                        style: TextStyle(
                          color: textColor.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: primaryColor),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState?.validate() ?? false) {
                                // Validate dates and times
                                if (_startDate == null || _endDate == null ||
                                    _startTime == null || _endTime == null) {
                                  Get.snackbar(
                                    'Error',
                                    'Please select both date and time',
                                    backgroundColor: Colors.red,
                                    colorText: Colors.white,
                                  );
                                  return;
                                }

                                // Combine date and time
                                final startDateTime = DateTime(
                                  _startDate!.year,
                                  _startDate!.month,
                                  _startDate!.day,
                                  _startTime!.hour,
                                  _startTime!.minute,
                                );

                                final endDateTime = DateTime(
                                  _endDate!.year,
                                  _endDate!.month,
                                  _endDate!.day,
                                  _endTime!.hour,
                                  _endTime!.minute,
                                );

                                if (endDateTime.isBefore(startDateTime)) {
                                  Get.snackbar(
                                    'Error',
                                    'End date/time must be after start date/time',
                                    backgroundColor: Colors.red,
                                    colorText: Colors.white,
                                  );
                                  return;
                                }

                                final success = await controller.updateEvent(
                                  eventId: event.id,
                                  title: _titleController.text,
                                  description: _descriptionController.text,
                                  location: _locationController.text,
                                  startDate: startDateTime,
                                  endDate: endDateTime,
                                  price: double.tryParse(_priceController.text) ?? 0,
                                  totalSeats: int.tryParse(_seatsController.text) ?? 0,
                                  imagePath: _imagePath,
                                );

                                if (success) {
                                  Navigator.pop(context);
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Update'),
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
      },
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _formatDateTime(DateTime date, {bool includeTime = false}) {
    if (includeTime) {
      return DateFormat('yyyy-MM-dd hh:mm a').format(date);
    }
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}