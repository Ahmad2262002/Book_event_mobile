import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:book_event/Controllers/AdminHomeController.dart';
import 'package:book_event/Models/Event.dart';
import 'package:book_event/Models/Booking.dart';

class AdminHome extends StatelessWidget {
  final AdminHomeController controller = Get.put(AdminHomeController());
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _seatsController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
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
    return DefaultTabController(
      length: 2,
      child: Theme(
        data: ThemeData(
          primaryColor: _primaryColor,
          colorScheme: ColorScheme.light(
            primary: _primaryColor,
            secondary: _secondaryColor,
            surface: _cardColor,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            titleTextStyle: TextStyle(
              color: _textColor,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
            iconTheme: IconThemeData(color: _primaryColor),
          ),
          tabBarTheme: TabBarThemeData(
            labelColor: _primaryColor,
            unselectedLabelColor: Colors.grey,
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(width: 2, color: _primaryColor),
            ),
          ),
        ),
        child: Scaffold(
          backgroundColor: _backgroundColor,
          appBar: AppBar(
            title: const Text('Admin Dashboard'),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.withOpacity(0.2),
                    ),
                  ),
                ),
                child: const TabBar(
                  tabs: [
                    Tab(icon: Icon(Icons.event, size: 24)),
                    Tab(icon: Icon(Icons.book_online, size: 24)),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.logout, color: _primaryColor),
                onPressed: controller.logout,
              ),
            ],
          ),
          body: TabBarView(
            children: [
              _buildEventsTab(),
              _buildBookingsTab(),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: _primaryColor,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onPressed: () => _showAddEventDialog(context),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildEventsTab() {
    return Obx(() {
      if (controller.isLoading.value && controller.events.isEmpty) {
        return Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
          ),
        );
      }

      if (controller.events.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No events found',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
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
                  backgroundColor: _primaryColor.withOpacity(0.1),
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(color: _primaryColor),
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        color: _primaryColor,
        onRefresh: controller.fetchEvents,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.events.length,
          itemBuilder: (context, index) {
            final event = controller.events[index];
            return _buildEventCard(event);
          },
        ),
      );
    });
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

  Widget _buildEventCard(Event event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: _cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
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
                Text(
                  event.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  event.description ?? 'No description',
                  style: TextStyle(
                    fontSize: 16,
                    color: _textColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                _buildEventDetailRow(
                  Icons.location_on,
                  event.location,
                ),
                const SizedBox(height: 8),
                _buildEventDetailRow(
                  Icons.calendar_today,
                  '${_formatDate(event.startDate)} - ${_formatDate(event.endDate)}',
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildEventDetailChip(
                      '\$${event.price.toStringAsFixed(2)}',
                      Icons.attach_money,
                    ),
                    const Spacer(),
                    _buildEventDetailChip(
                      '${event.availableSeats}/${event.totalSeats} seats',
                      Icons.event_seat,
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

  Widget _buildEventDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _primaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: _textColor.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventDetailChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _primaryColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: _textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Obx(() => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip('Pending', 'pending'),
              _buildFilterChip('Confirmed', 'confirmed'),
              _buildFilterChip('All', 'all'),
            ],
          )),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value && controller.bookings.isEmpty) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                ),
              );
            }

            final filteredBookings = controller.filteredBookings;
            if (filteredBookings.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.book_online, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No bookings found',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
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
                        backgroundColor: _primaryColor.withOpacity(0.1),
                      ),
                      child: Text(
                        'Retry',
                        style: TextStyle(color: _primaryColor),
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              color: _primaryColor,
              onRefresh: controller.fetchBookings,
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: filteredBookings.length,
                itemBuilder: (context, index) {
                  final booking = filteredBookings[index];
                  return _buildBookingCard(booking);
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: controller.selectedBookingFilter.value == value,
      onSelected: (_) => controller.selectedBookingFilter.value = value,
      selectedColor: _primaryColor,
      labelStyle: TextStyle(
        color: controller.selectedBookingFilter.value == value
            ? Colors.white
            : _textColor,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: _cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Event: ${booking.eventTitle ?? 'N/A'}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _textColor,
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
                    color: _textColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            if (booking.status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => controller.updateBookingStatus(booking.id, 'confirmed'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _secondaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Approve'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => controller.updateBookingStatus(booking.id, 'cancelled'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
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

  Future<void> _showAddEventDialog(BuildContext context) async {
    _titleController.clear();
    _descriptionController.clear();
    _locationController.clear();
    _priceController.clear();
    _seatsController.clear();
    _startDate = null;
    _endDate = null;
    _imagePath = null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: _cardColor,
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
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'Add New Event',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: _textColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildFormField(
                      controller: _titleController,
                      label: 'Title',
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildFormField(
                      controller: _descriptionController,
                      label: 'Description',
                      maxLines: 3,
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildFormField(
                      controller: _locationController,
                      label: 'Location',
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
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
                              if (date != null) _startDate = date;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
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
                              if (date != null) _endDate = date;
                            },
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
                            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFormField(
                            controller: _seatsController,
                            label: 'Total Seats',
                            keyboardType: TextInputType.number,
                            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final image = await ImagePicker().pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          _imagePath = image.path;
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor.withOpacity(0.1),
                        foregroundColor: _primaryColor,
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
                              side: BorderSide(color: _primaryColor),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState?.validate() ?? false) {
                                if (_startDate == null || _endDate == null) {
                                  Get.snackbar(
                                    'Error',
                                    'Please select dates',
                                    backgroundColor: Colors.red,
                                    colorText: Colors.white,
                                  );
                                  return;
                                }
                                if (_endDate!.isBefore(_startDate!)) {
                                  Get.snackbar(
                                    'Error',
                                    'End date must be after start date',
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
                                  startDate: _startDate!,
                                  endDate: _endDate!,
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
                              backgroundColor: _primaryColor,
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
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryColor),
        ),
        labelStyle: TextStyle(color: _textColor.withOpacity(0.6)),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: _textColor),
    );
  }

  Widget _buildDateButton(String label, DateTime? date, VoidCallback onPressed) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _textColor.withOpacity(0.6),
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
            side: BorderSide(color: Colors.grey[300]!),
            backgroundColor: Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date == null ? 'Select $label' : _formatDate(date),
                style: TextStyle(
                  color: date == null
                      ? _textColor.withOpacity(0.5)
                      : _textColor,
                ),
              ),
              Icon(Icons.calendar_today, size: 18, color: _primaryColor),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}