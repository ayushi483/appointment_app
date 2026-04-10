import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/session.dart';
import '../../../routes/app_routes.dart';
import 'package:clinic_management/app/modules/booking/controllers/booking_controllers.dart';

class BookingView extends StatefulWidget {
  const BookingView({super.key});

  @override
  State<BookingView> createState() => _BookingViewState();
}

class _BookingViewState extends State<BookingView> {
  final _controller = BookingController();
  final _notesController = TextEditingController();

  int _currentStep = 1;
  bool _isLoadingDoctors = true;
  bool _isBooking = false;
  bool _isCheckingAvailability = false;
  String? _doctorsError;

  List<Map<String, dynamic>> _doctors = [];
  Map<String, dynamic>? _selectedDoctor;
  DateTime? _selectedDate;
  String? _selectedTime;

  final List<String> _timeSlots = [
    '09:00 AM', '09:30 AM', '10:00 AM',
    '10:30 AM', '11:00 AM', '11:30 AM',
    '12:00 PM', '12:30 PM', '1:00 PM',
    '1:30 PM',  '02:00 PM', '02:30 PM',
    '03:00 PM', '03:30 PM', '04:00 PM',
    '04:30 PM', '05:00 PM', '06:00 PM',
    '06:30 PM', '07:00 PM', '07:30 PM',
  ];

  @override
  void initState() {
    super.initState();
    _loadDoctors();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments
      as Map<String, dynamic>?;
      if (args != null && args['doctor_id'] != null) {
        setState(() {
          _selectedDoctor = {
            'id': args['doctor_id'],
            'name': args['doctor_name'] ?? '',
          };
          _currentStep = 2;
        });
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _isLoadingDoctors = true;
      _doctorsError = null;
    });
    final result = await _controller.fetchDoctors();
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() {
        _doctors = result['doctors'] as List<Map<String, dynamic>>;
        _isLoadingDoctors = false;
      });
    } else {
      setState(() {
        _doctorsError = result['message'];
        _isLoadingDoctors = false;
      });
    }
  }

  String _timeSlotTo24h(String slot) {
    final parts = slot.split(' ');
    final timeParts = parts[0].split(':');
    int hour = int.parse(timeParts[0]);
    final minute = timeParts[1];
    final period = parts[1];
    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return '${hour.toString().padLeft(2, '0')}:$minute:00';
  }

  String _buildAppointmentDatetime() {
    final dateStr =
        '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
    final timeStr = _timeSlotTo24h(_selectedTime!);
    return '$dateStr $timeStr';
  }

  Future<void> _checkAndProceed() async {
    if (_selectedDoctor == null ||
        _selectedDate == null ||
        _selectedTime == null) return;

    setState(() => _isCheckingAvailability = true);

    final result = await _controller.checkAvailability(
      doctorId: _selectedDoctor!['id'] as int,
      appointmentDatetime: _buildAppointmentDatetime(),
    );

    if (!mounted) return;
    setState(() => _isCheckingAvailability = false);

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>;
      final bool available = data['available'] == true;
      if (available) {
        setState(() => _currentStep = 3);
      } else {
        final schedule = data['doctor_schedule'] as List<dynamic>? ?? [];
        _showUnavailableDialog(
          message: data['message'] ?? 'Slot not available',
          schedule: schedule,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Could not check availability'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUnavailableDialog(
      {required String message, required List<dynamic> schedule}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.event_busy, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Slot Unavailable',
                style:
                TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(message,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 13)),
                    ),
                  ],
                ),
              ),
              if (schedule.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Doctor\'s Available Schedule:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),
                ...schedule.map((slot) {
                  final s = slot as Map<String, dynamic>;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                      border:
                      Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule,
                            color: Color(0xFF2563EB), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _capitalizeDay(s['day'] ?? ''),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Color(0xFF1E40AF)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${s['start_time']} – ${s['end_time']}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Choose Another Slot',
                style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String _capitalizeDay(String day) {
    if (day.isEmpty) return day;
    return day[0].toUpperCase() + day.substring(1).toLowerCase();
  }

  Future<void> _confirmBooking() async {
    if (_selectedDoctor == null ||
        _selectedDate == null ||
        _selectedTime == null) return;

    if (AppSession.patientId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expired. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isBooking = true);

    final result = await _controller.bookAppointment(
      doctorId: _selectedDoctor!['id'] as int,
      patientId: AppSession.patientId,
      appointmentDatetime: _buildAppointmentDatetime(),
      notes: _notesController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isBooking = false);

    if (result['success'] == true) {
      final d = result['data'] as Map<String, dynamic>;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => _BookingConfirmedView(
            doctor:
            d['doctor_name'] ?? _selectedDoctor!['name'],
            date: _formatDate(_selectedDate!),
            time: _selectedTime!,
            appointmentCode: d['appointment_code'] ?? '',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Booking failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor:
        isDark ? const Color(0xFF1F2937) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? Colors.white : Colors.black),
          onPressed: () {
            if (_currentStep > 1) {
              setState(() => _currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          'Book Appointment',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        backgroundColor:
        isDark ? const Color(0xFF1F2937) : Colors.white,
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor:
        isDark ? Colors.grey[500] : Colors.grey,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month), label: 'Book'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, AppRoutes.home);
              break;
            case 2:
              Navigator.pushReplacementNamed(context, AppRoutes.profile);
              break;
            case 3:
              Navigator.pushNamed(context, AppRoutes.settings);
              break;
          }
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildStepIndicator(isDark),
            const SizedBox(height: 24),
            Expanded(
              child: _currentStep == 1
                  ? _buildStep1(isDark)
                  : _currentStep == 2
                  ? _buildStep2(isDark)
                  : _buildStep3(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(bool isDark) {
    return Row(
      children: [
        _stepCircle(1),
        _stepLine(_currentStep > 1),
        _stepCircle(2),
        _stepLine(_currentStep > 2),
        _stepCircle(3),
      ],
    );
  }

  Widget _stepCircle(int step) {
    final isActive = _currentStep >= step;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF2563EB)
            : const Color(0xFFD1D5DB),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text('$step',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _stepLine(bool active) {
    return Expanded(
      child: Container(
        height: 3,
        color: active
            ? const Color(0xFF2563EB)
            : const Color(0xFFD1D5DB),
      ),
    );
  }

  Widget _buildStep1(bool isDark) {
    if (_isLoadingDoctors) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF2563EB)));
    }

    if (_doctorsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_doctorsError!,
                style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadDoctors,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB)),
              child: const Text('Retry',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Select Doctor',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              border: Border.all(
                color: _selectedDoctor != null
                    ? const Color(0xFF2563EB)
                    : (isDark
                    ? const Color(0xFF4B5563)
                    : const Color(0xFFE5E7EB)),
                width: _selectedDoctor != null ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Map<String, dynamic>>(
                isExpanded: true,
                dropdownColor:
                isDark ? const Color(0xFF1F2937) : Colors.white,
                hint: Text('Choose a doctor',
                    style: TextStyle(
                        color: isDark
                            ? Colors.grey[400]
                            : Colors.grey)),
                value: _selectedDoctor,
                icon: Icon(Icons.keyboard_arrow_down,
                    color:
                    isDark ? Colors.grey[400] : Colors.grey),
                items: _doctors.map((doc) {
                  Uint8List? imageBytes;
                  try {
                    final imgStr = doc['image_1024'] as String? ?? '';
                    if (imgStr.isNotEmpty)
                      imageBytes = base64Decode(imgStr);
                  } catch (_) {}

                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: doc,
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: imageBytes != null
                              ? Image.memory(imageBytes,
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover)
                              : Container(
                            width: 36,
                            height: 36,
                            color: isDark
                                ? const Color(0xFF1E3A5F)
                                : const Color(0xFFE0F2FE),
                            child: const Icon(Icons.person,
                                size: 20,
                                color: Color(0xFF2563EB)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(doc['name'] ?? '',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87),
                                  overflow: TextOverflow.ellipsis),
                              if ((doc['speciality'] ?? '')
                                  .toString()
                                  .isNotEmpty)
                                Text(doc['speciality'],
                                    style: TextStyle(
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey,
                                        fontSize: 12),
                                    overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedDoctor = v),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedDoctor != null
                  ? () => setState(() => _currentStep = 2)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                disabledBackgroundColor: const Color(0xFFD1D5DB),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Continue',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(bool isDark) {
    final canContinue = _selectedDate != null &&
        _selectedTime != null &&
        !_isCheckingAvailability;

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Date & Time',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 20),
            Text('Date',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate:
                  DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate:
                  DateTime.now().add(const Duration(days: 60)),
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                          primary: Color(0xFF2563EB)),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null)
                  setState(() => _selectedDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF374151)
                      : Colors.white,
                  border: Border.all(
                    color: _selectedDate != null
                        ? const Color(0xFF2563EB)
                        : (isDark
                        ? const Color(0xFF4B5563)
                        : const Color(0xFFD1D5DB)),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDate != null
                          ? '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}'
                          : 'dd/mm/yyyy',
                      style: TextStyle(
                          color: _selectedDate != null
                              ? (isDark ? Colors.white : Colors.black)
                              : Colors.grey),
                    ),
                    Icon(Icons.calendar_today_outlined,
                        color: isDark ? Colors.grey[400] : Colors.grey,
                        size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Time',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: _timeSlots.length,
              itemBuilder: (context, index) {
                final slot = _timeSlots[index];
                final isSelected = slot == _selectedTime;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTime = slot),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : (isDark
                          ? const Color(0xFF374151)
                          : Colors.white),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF2563EB)
                            : (isDark
                            ? const Color(0xFF4B5563)
                            : const Color(0xFFD1D5DB)),
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        slot,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                              ? Colors.grey[300]
                              : Colors.black87),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isCheckingAvailability
                        ? null
                        : () => setState(() => _currentStep = 1),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: isDark
                              ? const Color(0xFF4B5563)
                              : const Color(0xFFD1D5DB)),
                      padding:
                      const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Back',
                        style: TextStyle(
                            color: isDark
                                ? Colors.grey[300]
                                : Colors.black87)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: canContinue ? _checkAndProceed : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      disabledBackgroundColor:
                      const Color(0xFFD1D5DB),
                      padding:
                      const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isCheckingAvailability
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                        : const Text('Continue',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3(bool isDark) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Details',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 6),
            Text(
              'Confirm your details and describe your reason for visit',
              style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey,
                  fontSize: 13),
            ),
            const SizedBox(height: 20),
            _readOnlyField(isDark, 'Full Name', Icons.person_outline,
                AppSession.patientName ?? 'Unknown'),
            const SizedBox(height: 16),
            _readOnlyField(isDark, 'Phone', Icons.phone_outlined,
                AppSession.patientPhone ?? 'Unknown'),
            const SizedBox(height: 16),
            Text('Reason (optional)',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 4,
              style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: 'Brief description of your symptoms...',
                hintStyle: TextStyle(
                    color: isDark ? Colors.grey[500] : Colors.grey),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF374151)
                    : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF4B5563)
                          : const Color(0xFFD1D5DB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF4B5563)
                          : const Color(0xFFD1D5DB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  const BorderSide(color: Color(0xFF2563EB)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isBooking
                        ? null
                        : () => setState(() => _currentStep = 2),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: isDark
                              ? const Color(0xFF4B5563)
                              : const Color(0xFFD1D5DB)),
                      padding:
                      const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Back',
                        style: TextStyle(
                            color: isDark
                                ? Colors.grey[300]
                                : Colors.black87)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isBooking ? null : _confirmBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      disabledBackgroundColor:
                      const Color(0xFFD1D5DB),
                      padding:
                      const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isBooking
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                        : const Text('Confirm Booking',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _readOnlyField(
      bool isDark, String label, IconData icon, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 8),
        Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF374151)
                : const Color(0xFFF9FAFB),
            border: Border.all(
                color: isDark
                    ? const Color(0xFF4B5563)
                    : const Color(0xFFD1D5DB)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: isDark ? Colors.grey[400] : Colors.grey,
                  size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(value,
                    style: TextStyle(
                        fontSize: 15,
                        color:
                        isDark ? Colors.white : Colors.black87)),
              ),
              Icon(Icons.lock_outline,
                  color: isDark
                      ? const Color(0xFF4B5563)
                      : const Color(0xFFD1D5DB),
                  size: 16),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Booking Confirmed Screen ──────────────────────────────────────────────────
class _BookingConfirmedView extends StatelessWidget {
  final String doctor;
  final String date;
  final String time;
  final String appointmentCode;

  const _BookingConfirmedView({
    required this.doctor,
    required this.date,
    required this.time,
    required this.appointmentCode,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor:
        isDark ? const Color(0xFF1F2937) : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Booking Confirmed',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black
                      .withOpacity(isDark ? 0.2 : 0.05),
                  blurRadius: 10),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline,
                    color: Color(0xFF16A34A), size: 44),
              ),
              const SizedBox(height: 16),
              Text('Booking Confirmed!',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 6),
              Text(
                'Your appointment has been booked successfully',
                style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF374151)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    if (appointmentCode.isNotEmpty) ...[
                      _infoRow(isDark, 'Code:', appointmentCode),
                      const SizedBox(height: 8),
                    ],
                    _infoRow(isDark, 'Doctor:', doctor),
                    const SizedBox(height: 8),
                    _infoRow(isDark, 'Date:', date),
                    const SizedBox(height: 8),
                    _infoRow(isDark, 'Time:', time),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.viewAppointments,
                        (r) => false,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding:
                    const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('View Appointments',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.home,
                        (r) => false,
                  ),
                  style: OutlinedButton.styleFrom(
                    padding:
                    const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(
                        color: isDark
                            ? const Color(0xFF4B5563)
                            : const Color(0xFFD1D5DB)),
                  ),
                  child: Text('Back to Home',
                      style: TextStyle(
                          color: isDark
                              ? Colors.grey[300]
                              : Colors.black87,
                          fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(bool isDark, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey,
                fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87),
              textAlign: TextAlign.right),
        ),
      ],
    );
  }
}