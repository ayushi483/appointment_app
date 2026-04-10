import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../routes/app_routes.dart';
import 'package:clinic_management/app/modules/appointment/controllers/appointment_controllers.dart';

class SpecialityByDoctorView extends StatefulWidget {
  const SpecialityByDoctorView({super.key});

  @override
  State<SpecialityByDoctorView> createState() =>
      _SpecialityByDoctorViewState();
}

class _SpecialityByDoctorViewState extends State<SpecialityByDoctorView> {
  final _appointmentController = AppointmentController();

  List<DoctorSearchModel> _doctors = [];
  bool _loading = true;
  String? _error;

  int? _specialityId;
  String _specialityName = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        setState(() {
          _specialityId = args['speciality_id'] as int?;
          _specialityName = args['speciality_name'] as String? ?? '';
        });
      }
      _load();
    });
  }

  @override
  void dispose() {
    _appointmentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    if (_specialityId == null) {
      setState(() {
        _loading = false;
        _error = 'No speciality selected.';
      });
      return;
    }

    final doctors = await _appointmentController
        .getDoctorsBySpeciality(_specialityId!);

    if (!mounted) return;

    setState(() {
      _loading = false;
      _doctors = doctors;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _specialityName.isNotEmpty ? _specialityName : 'Doctors',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_loading) {
      return const Center(
          child:
          CircularProgressIndicator(color: Color(0xFF2563EB)));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(_error!,
                style: TextStyle(
                    color:
                    isDark ? Colors.grey[400] : Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_doctors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search,
                size: 64,
                color: isDark
                    ? const Color(0xFF1E3A5F)
                    : const Color(0xFFBFDBFE)),
            const SizedBox(height: 16),
            Text(
              'No doctors available\nfor $_specialityName',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey,
                  fontSize: 15),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF2563EB),
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _doctors.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${_doctors.length} doctor${_doctors.length == 1 ? '' : 's'} found',
                style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey,
                    fontSize: 13),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildDoctorCard(isDark, _doctors[index - 1]),
          );
        },
      ),
    );
  }

  Widget _buildDoctorCard(bool isDark, DoctorSearchModel doc) {
    final isAvailable = doc.available;
    final availableColor =
    isAvailable ? const Color(0xFF16A34A) : const Color(0xFFD97706);

    Uint8List? imageBytes;
    try {
      final imgStr = doc.imageBase64 ?? '';
      if (imgStr.isNotEmpty) imageBytes = base64Decode(imgStr);
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color:
              Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 6),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageBytes != null
                    ? Image.memory(imageBytes,
                    width: 72, height: 72, fit: BoxFit.cover)
                    : Container(
                  width: 72,
                  height: 72,
                  color: isDark
                      ? const Color(0xFF1E3A5F)
                      : const Color(0xFFE0F2FE),
                  child: const Icon(Icons.person,
                      size: 40, color: Color(0xFF2563EB)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.name,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark
                              ? Colors.white
                              : Colors.black87),
                    ),
                    if ((doc.speciality ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          doc.speciality!,
                          style: const TextStyle(
                              color: Color(0xFF2563EB),
                              fontSize: 13),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.payments_outlined,
                            size: 13,
                            color: isDark
                                ? Colors.grey[400]
                                : Colors.grey),
                        const SizedBox(width: 3),
                        Text(
                          '₹${doc.fees.toStringAsFixed(0)}',
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey),
                        ),
                        Text(' • ',
                            style: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey)),
                        Icon(Icons.calendar_today_outlined,
                            size: 13,
                            color: isDark
                                ? Colors.grey[400]
                                : Colors.grey),
                        const SizedBox(width: 3),
                        Text(
                          '${doc.totalAppointment} appts',
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey),
                        ),
                      ],
                    ),
                    if ((doc.phone ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.phone_outlined,
                                size: 13,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey),
                            const SizedBox(width: 3),
                            Text(
                              doc.phone!,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: availableColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isAvailable ? 'Available Today' : 'Not Available',
                  style: TextStyle(
                      color: availableColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.booking,
                  arguments: {
                    'doctor_id': doc.id,
                    'doctor_name': doc.name,
                    'doctor_speciality': doc.speciality,
                    'doctor_fees': doc.fees,
                  },
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                ),
                child: const Text(
                  'Book Now',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}