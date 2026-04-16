import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../routes/app_routes.dart';
import '../../../core/session.dart';
import 'package:clinic_management/app/modules/appointment/controllers/appointment_controllers.dart';

class AppointmentView extends StatefulWidget {
  final String patientName;
  const AppointmentView({super.key, required this.patientName});

  @override
  State<AppointmentView> createState() => _AppointmentViewState();
}

class _AppointmentViewState extends State<AppointmentView> {
  int _selectedIndex = 0;
  late final AppointmentController _controller;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showSearchResults = false;

  // Always read from AppSession so name never falls back to 'User'
  String get _displayName =>
      AppSession.patientName?.isNotEmpty == true
          ? AppSession.patientName!
          : widget.patientName;

  @override
  void initState() {
    super.initState();
    _controller = AppointmentController();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    if (query.length >= 1) {
      _controller.searchDoctors(query);
      setState(() => _showSearchResults = true);
    } else if (query.isEmpty) {
      _controller.clearSearch();
      setState(() => _showSearchResults = false);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _controller.clearSearch();
    setState(() => _showSearchResults = false);
    _searchFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Top blue header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2563EB),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(28),
                          bottomRight: Radius.circular(28),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _displayName,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold),
                              ),
                              const Icon(Icons.notifications_outlined,
                                  color: Colors.white, size: 26),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1F2937)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              keyboardType: TextInputType.text,
                              style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : Colors.black87),
                              decoration: InputDecoration(
                                hintText:
                                'Search doctors, specialty or code e.g. APP0011',
                                hintStyle: TextStyle(
                                    color: isDark
                                        ? Colors.grey[500]
                                        : Colors.grey),
                                prefixIcon: Icon(Icons.search,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey),
                                suffixIcon:
                                _searchController.text.isNotEmpty
                                    ? IconButton(
                                  icon: Icon(Icons.clear,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey),
                                  onPressed: _clearSearch,
                                )
                                    : null,
                                border: InputBorder.none,
                                contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tip: Type APP0011 to search by appointment code',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    if (_showSearchResults &&
                        _controller.searchQuery.isNotEmpty)
                      _buildSearchResults(isDark)
                    else
                      _buildNormalContent(isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor:
        isDark ? const Color(0xFF1F2937) : Colors.white,
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor:
        isDark ? Colors.grey[500] : Colors.grey,
        onTap: (i) {
          setState(() => _selectedIndex = i);
          if (i == 1) Navigator.pushNamed(context, AppRoutes.booking);
          if (i == 2) Navigator.pushNamed(context, AppRoutes.profile);
          if (i == 3) {
            Navigator.pushNamed(context, AppRoutes.settings,
                arguments: {
                  'name': AppSession.patientName ?? _displayName,
                  'email': AppSession.patientEmail ?? '',
                });
          }
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'Book'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings'),
        ],
      ),
    );
  }

  // ── Normal content ──────────────────────────────────────────────────────────

  Widget _buildNormalContent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Transform.translate(
          offset: const Offset(0, -20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 20, horizontal: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2937) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black
                          .withOpacity(isDark ? 0.3 : 0.07),
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickAction(isDark, '📅', 'Book',
                          () => Navigator.pushNamed(
                          context, AppRoutes.booking)),
                  _buildQuickAction(isDark, '🩺', 'Doctors',
                          () => Navigator.pushNamed(
                          context, AppRoutes.doctors)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Upcoming Appointment',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87)),
              GestureDetector(
                onTap: () => Navigator.pushNamed(
                    context, AppRoutes.viewAppointments),
                child: const Text('View All',
                    style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildUpcomingAppointmentCard(isDark),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Specialties',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87)),
        ),
        const SizedBox(height: 12),
        SizedBox(height: 100, child: _buildSpecialitiesList(isDark)),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── Search results ──────────────────────────────────────────────────────────

  Widget _buildSearchResults(bool isDark) {
    if (_controller.isSearching) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
            child:
            CircularProgressIndicator(color: Color(0xFF2563EB))),
      );
    }

    if (_controller.searchError != null && !_controller.hasResults) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.search_off, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(_controller.searchError!,
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 14),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _controller
                    .searchDoctors(_searchController.text),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final hasDoctors = _controller.doctorResults.isNotEmpty;
    final hasAppointments = _controller.appointmentResults.isNotEmpty;

    if (!hasDoctors && !hasAppointments) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.search_off,
                  size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('No results found',
                  style:
                  TextStyle(color: Colors.grey, fontSize: 16)),
              const Text(
                  'Try a different name, specialty or appointment code',
                  style:
                  TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                hasDoctors
                    ? 'Doctors (${_controller.doctorResults.length})'
                    : 'Appointments (${_controller.appointmentResults.length})',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87),
              ),
              TextButton(
                  onPressed: _clearSearch,
                  child: const Text('Clear')),
            ],
          ),
        ),
        if (hasAppointments)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _controller.appointmentResults.length,
            itemBuilder: (context, index) =>
                _buildAppointmentResultCard(
                    isDark, _controller.appointmentResults[index]),
          ),
        if (hasDoctors)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _controller.doctorResults.length,
            itemBuilder: (context, index) => _buildDoctorCard(
                isDark, _controller.doctorResults[index]),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── Appointment result card ─────────────────────────────────────────────────

  Widget _buildAppointmentResultCard(bool isDark, AppointmentModel appt) {
    Color statusColor;
    IconData statusIcon;
    switch (appt.status) {
      case 'confirmed':
        statusColor = const Color(0xFF16A34A);
        statusIcon = Icons.check_circle_outline;
        break;
      case 'done':
        statusColor = const Color(0xFF2563EB);
        statusIcon = Icons.task_alt;
        break;
      case 'cancel':
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = const Color(0xFFD97706);
        statusIcon = Icons.schedule;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color:
              Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 8)
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E3A5F)
                        : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.confirmation_number_outlined,
                          size: 13, color: Color(0xFF2563EB)),
                      const SizedBox(width: 4),
                      Text(appt.appointmentCode,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 13, color: statusColor),
                      const SizedBox(width: 4),
                      Text(appt.status.toUpperCase(),
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E3A5F)
                          : const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.person,
                      size: 26, color: Color(0xFF2563EB)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appt.doctorName,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDark
                                  ? Colors.white
                                  : Colors.black87)),
                      Text(
                          appt.doctorSpeciality ??
                              'General Practice',
                          style: TextStyle(
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey.shade600,
                              fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF374151)
                      : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(appt.formattedDate,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.grey)),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time_outlined,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(appt.formattedTime,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.grey)),
                ],
              ),
            ),
            if (appt.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(appt.notes,
                  style: TextStyle(
                      color: isDark
                          ? Colors.grey[400]
                          : Colors.grey.shade600,
                      fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ],
        ),
      ),
    );
  }

  // ── Doctor card ─────────────────────────────────────────────────────────────

  Widget _buildDoctorCard(bool isDark, DoctorSearchModel doctor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color:
              Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 8)
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.booking,
                  arguments: {
                    'doctor_id': doctor.id,
                    'doctor_name': doctor.name,
                    'doctor_speciality': doctor.speciality,
                    'doctor_fees': doctor.fees,
                  }),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E3A5F)
                          : const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(12)),
                  child: _buildDoctorImage(doctor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doctor.name,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark
                                  ? Colors.white
                                  : Colors.black87)),
                      const SizedBox(height: 4),
                      Text(doctor.speciality ?? 'General Practice',
                          style: TextStyle(
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey.shade600,
                              fontSize: 13)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.currency_rupee,
                              size: 14,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey),
                          Text(
                              ' ${doctor.fees.toStringAsFixed(0)} consultation fee',
                              style: TextStyle(
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey.shade600,
                                  fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text('Book',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorImage(DoctorSearchModel doctor) {
    if (doctor.imageBase64 != null &&
        doctor.imageBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(doctor.imageBase64!);
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(bytes,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.person,
                  size: 32, color: Color(0xFF2563EB))),
        );
      } catch (_) {}
    }
    return const Icon(Icons.person,
        size: 32, color: Color(0xFF2563EB));
  }

  // ── Upcoming appointment card ───────────────────────────────────────────────

  Widget _buildUpcomingAppointmentCard(bool isDark) {
    if (_controller.loadingAppointment) {
      return _cardShell(
          isDark: isDark,
          child: const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF2563EB), strokeWidth: 2)));
    }

    if (_controller.upcomingAppointment == null) {
      return _cardShell(
          isDark: isDark,
          child: Center(
              child: Text('No upcoming appointments',
                  style: TextStyle(
                      color: isDark
                          ? Colors.grey[400]
                          : Colors.grey,
                      fontSize: 14))));
    }

    final appt = _controller.upcomingAppointment!;

    return _cardShell(
      isDark: isDark,
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 60,
                  height: 60,
                  color: isDark
                      ? const Color(0xFF1E3A5F)
                      : const Color(0xFFE0F2FE),
                  child: const Icon(Icons.person,
                      size: 36, color: Color(0xFF2563EB)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appt.doctorName,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark
                                ? Colors.white
                                : Colors.black87),
                        overflow: TextOverflow.ellipsis),
                    Text(
                        appt.doctorSpeciality ??
                            'General Practice',
                        style: TextStyle(
                            color: isDark
                                ? Colors.grey[400]
                                : Colors.grey,
                            fontSize: 13)),
                    const SizedBox(height: 4),
                    if (appt.appointmentCode.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E3A5F)
                              : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                                Icons.confirmation_number_outlined,
                                size: 11,
                                color: Color(0xFF2563EB)),
                            const SizedBox(width: 3),
                            Text(appt.appointmentCode,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF2563EB),
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 12, color: Colors.grey),
                        const SizedBox(width: 3),
                        Text(appt.formattedDate,
                            style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey)),
                        const SizedBox(width: 8),
                        const Icon(Icons.access_time_outlined,
                            size: 12, color: Colors.grey),
                        const SizedBox(width: 3),
                        Text(appt.formattedTime,
                            style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.pushNamed(
                context, AppRoutes.viewAppointments),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E3A5F)
                    : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('View Details',
                    style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardShell({required Widget child, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black
                  .withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 8)
        ],
      ),
      child: child,
    );
  }

  Widget _buildSpecialitiesList(bool isDark) {
    if (_controller.loadingSpecialities) {
      return const Center(
          child: CircularProgressIndicator(
              color: Color(0xFF2563EB), strokeWidth: 2));
    }
    if (_controller.specialityError != null) {
      return Center(
        child: GestureDetector(
          onTap: _controller.fetchSpecialities,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.refresh, color: Color(0xFF2563EB), size: 22),
              SizedBox(height: 4),
              Text('Tap to retry',
                  style: TextStyle(
                      color: Color(0xFF2563EB), fontSize: 12)),
            ],
          ),
        ),
      );
    }
    if (_controller.specialities.isEmpty) {
      return Center(
          child: Text('No specialities available',
              style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey,
                  fontSize: 13)));
    }
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _controller.specialities.length,
      itemBuilder: (context, index) {
        final speciality = _controller.specialities[index];
        return GestureDetector(
          onTap: () => Navigator.pushNamed(
              context, AppRoutes.specialityDoctors,
              arguments: {
                'speciality_id': speciality.id,
                'speciality_name': speciality.name,
              }),
          child: _SpecialityItem(
              speciality: speciality, isDark: isDark),
        );
      },
    );
  }

  Widget _buildQuickAction(
      bool isDark, String emoji, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E3A5F)
                  : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
                child: Text(emoji,
                    style: const TextStyle(fontSize: 28))),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.black87)),
        ],
      ),
    );
  }
}

// ── Speciality item ───────────────────────────────────────────────────────────

class _SpecialityItem extends StatelessWidget {
  final SpecialityModel speciality;
  final bool isDark;
  const _SpecialityItem(
      {required this.speciality, required this.isDark});

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (speciality.imageBase64 != null &&
        speciality.imageBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(speciality.imageBase64!);
        imageWidget = ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(bytes,
              width: 42,
              height: 42,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                  Icons.medical_services_outlined,
                  size: 28,
                  color: Color(0xFF2563EB))),
        );
      } catch (_) {
        imageWidget = const Icon(Icons.medical_services_outlined,
            size: 28, color: Color(0xFF2563EB));
      }
    } else {
      imageWidget = const Icon(Icons.medical_services_outlined,
          size: 28, color: Color(0xFF2563EB));
    }

    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 84,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark
                ? const Color(0xFF374151)
                : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          imageWidget,
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              speciality.name,
              style: TextStyle(
                  fontSize: 11,
                  color:
                  isDark ? Colors.white70 : Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}