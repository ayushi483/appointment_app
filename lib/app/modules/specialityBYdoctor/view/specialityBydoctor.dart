import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../routes/app_routes.dart';
import 'package:clinic_management/app/modules/appointment/controllers/appointment_controllers.dart';

class SpecialityByDoctorView extends StatefulWidget {
  const SpecialityByDoctorView({super.key});

  @override
  State<SpecialityByDoctorView> createState() => _SpecialityByDoctorViewState();
}

class _SpecialityByDoctorViewState extends State<SpecialityByDoctorView> {
  // ✅ Use AppointmentController instead of DoctorController
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
      debugPrint('>>> ARGS RECEIVED: $args');

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

    // ✅ Call the working getDoctorsBySpeciality from AppointmentController
    final doctors =
    await _appointmentController.getDoctorsBySpeciality(_specialityId!);

    if (!mounted) return;

    setState(() {
      _loading = false;
      if (doctors.isNotEmpty) {
        _doctors = doctors;
      } else {
        _doctors = [];
        // Not a hard error — just empty results
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2563EB)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.grey)),
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
            const Icon(Icons.person_search,
                size: 64, color: Color(0xFFBFDBFE)),
            const SizedBox(height: 16),
            Text(
              'No doctors available\nfor $_specialityName',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 15),
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
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildDoctorCard(_doctors[index - 1]),
          );
        },
      ),
    );
  }

  Widget _buildDoctorCard(DoctorSearchModel doc) {
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageBytes != null
                    ? Image.memory(imageBytes,
                    width: 72, height: 72, fit: BoxFit.cover)
                    : Container(
                  width: 72,
                  height: 72,
                  color: const Color(0xFFE0F2FE),
                  child: const Icon(Icons.person,
                      size: 40, color: Color(0xFF2563EB)),
                ),
              ),
              const SizedBox(width: 12),
              // Doctor info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if ((doc.speciality ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          doc.speciality!,
                          style: const TextStyle(
                              color: Color(0xFF2563EB), fontSize: 13),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.payments_outlined,
                            size: 13, color: Colors.grey),
                        const SizedBox(width: 3),
                        Text(
                          '₹${doc.fees.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                        const Text(' • ',
                            style: TextStyle(color: Colors.grey)),
                        const Icon(Icons.calendar_today_outlined,
                            size: 13, color: Colors.grey),
                        const SizedBox(width: 3),
                        Text(
                          '${doc.totalAppointment} appts',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    if ((doc.phone ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.phone_outlined,
                                size: 13, color: Colors.grey),
                            const SizedBox(width: 3),
                            Text(
                              doc.phone!,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
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
              // Availability badge
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: availableColor.withOpacity(0.1),
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
              // Book Now button
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