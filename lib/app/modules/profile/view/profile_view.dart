import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:clinic_management/app/modules/profile/controllers/profile_controllers.dart';
import '../../../core/session.dart';
import '../../../routes/app_routes.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late final ProfileController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = ProfileController();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final success = await _controller.updatePatient();
    if (!mounted) return;
    if (success) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Color(0xFF2563EB),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update profile. Please try again.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
        leading: const SizedBox.shrink(),
        title: Text(
          'Profile',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          if (!_controller.isLoading)
            _controller.isSaving
                ? const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF2563EB)),
              ),
            )
                : TextButton.icon(
              onPressed: () {
                if (_isEditing) {
                  _handleSave();
                } else {
                  setState(() => _isEditing = true);
                }
              },
              icon: Icon(
                _isEditing
                    ? Icons.check
                    : Icons.edit_outlined,
                size: 18,
                color: const Color(0xFF2563EB),
              ),
              label: Text(
                _isEditing ? 'Save' : 'Edit',
                style: const TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          if (_isEditing)
            TextButton(
              onPressed: () {
                setState(() => _isEditing = false);
                _controller.phoneController.text =
                    _controller.phone;
                _controller.dobController.text =
                _controller.dateOfBirth.isNotEmpty
                    ? _formatDob(_controller.dateOfBirth)
                    : '';
                _controller.addressController.text =
                    _controller.address;
                _controller.selectedGender = _controller.gender;
              },
              child: const Text(
                'Cancel',
                style:
                TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
        ],
      ),
      body: _controller.isLoading
          ? const Center(
          child: CircularProgressIndicator(
              color: Color(0xFF2563EB)))
          : _controller.errorMessage != null
          ? _buildError(isDark)
          : _buildBody(isDark),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatsFooter(isDark),
          _buildBottomNav(isDark),
        ],
      ),
    );
  }

  Widget _buildError(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline,
              color: Colors.redAccent, size: 48),
          const SizedBox(height: 12),
          Text(
            _controller.errorMessage!,
            style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _controller.fetchPatientInfo,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB)),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          _buildAvatar(isDark),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1F2937)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(isDark ? 0.2 : 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildReadOnlyField(
                        isDark: isDark,
                        label: 'Full Name',
                        value: _controller.name,
                        icon: Icons.person_outline),
                    const SizedBox(height: 16),
                    _buildReadOnlyField(
                        isDark: isDark,
                        label: 'Email Address',
                        value: _controller.email,
                        icon: Icons.mail_outline),
                    const SizedBox(height: 16),
                    _buildField(
                        isDark: isDark,
                        label: 'Phone Number',
                        icon: Icons.phone_outlined,
                        controller: _controller.phoneController,
                        editable: _isEditing,
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: 16),
                    _buildGenderField(isDark),
                    const SizedBox(height: 16),
                    if (_controller.patientCode.isNotEmpty)
                      _buildPatientCodeInline(isDark),
                    if (_controller.patientCode.isNotEmpty)
                      const SizedBox(height: 16),
                    _buildField(
                        isDark: isDark,
                        label: 'Date of Birth',
                        icon: Icons.calendar_month_outlined,
                        controller: _controller.dobController,
                        editable: _isEditing,
                        hint: 'DD/MM/YYYY',
                        keyboardType: TextInputType.datetime),
                    const SizedBox(height: 16),
                    _buildField(
                        isDark: isDark,
                        label: 'Address',
                        icon: Icons.location_on_outlined,
                        controller: _controller.addressController,
                        editable: _isEditing),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatsFooter(bool isDark) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatCard(
            isDark: isDark,
            value: _controller.statsLoading
                ? '...'
                : '${_controller.totalAppointments}',
            label: 'Total',
            color: const Color(0xFF2563EB),
            bgColor: isDark
                ? const Color(0xFF1E3A5F)
                : const Color(0xFFEFF6FF),
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            isDark: isDark,
            value: _controller.statsLoading
                ? '...'
                : '${_controller.completedAppointments}',
            label: 'Completed',
            color: const Color(0xFF16A34A),
            bgColor: isDark
                ? const Color(0xFF064E3B)
                : const Color(0xFFF0FDF4),
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            isDark: isDark,
            value: _controller.statsLoading
                ? '...'
                : '${_controller.upcomingAppointments}',
            label: 'Upcoming',
            color: const Color(0xFF9333EA),
            bgColor: isDark
                ? const Color(0xFF3B0764)
                : const Color(0xFFFAF5FF),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCodeInline(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Patient Code',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[400] : Colors.black54,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E3A5F)
                : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isDark
                    ? const Color(0xFF1D4ED8)
                    : const Color(0xFFBFDBFE)),
          ),
          child: Row(
            children: [
              const Icon(Icons.badge_outlined,
                  color: Color(0xFF2563EB), size: 18),
              const SizedBox(width: 10),
              Text(
                _controller.patientCode,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D4ED8),
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(bool isDark) {
    Widget avatar;
    if (_controller.imageBase64 != null &&
        _controller.imageBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(_controller.imageBase64!);
        avatar = CircleAvatar(
            radius: 52, backgroundImage: MemoryImage(bytes));
      } catch (_) {
        avatar = _defaultAvatar();
      }
    } else {
      avatar = _defaultAvatar();
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            avatar,
            if (_isEditing)
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Image upload coming soon'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt,
                      color: Colors.white, size: 16),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _controller.name,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _controller.email,
          style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey),
        ),
      ],
    );
  }

  Widget _defaultAvatar() {
    return CircleAvatar(
      radius: 52,
      backgroundColor: const Color(0xFF2563EB),
      child: Text(
        _controller.avatarInitial,
        style: const TextStyle(
            fontSize: 40,
            color: Colors.white,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatCard({
    required bool isDark,
    required String value,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? Colors.grey[400]
                        : Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required bool isDark,
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color:
                isDark ? Colors.grey[400] : Colors.black54)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF374151)
                : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 18,
                  color: isDark ? Colors.grey[400] : Colors.grey),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value.isNotEmpty ? value : '—',
                  style: TextStyle(
                      fontSize: 15,
                      color: isDark
                          ? Colors.grey[300]
                          : Colors.black54),
                ),
              ),
              Icon(Icons.lock_outline,
                  size: 14,
                  color: isDark ? Colors.grey[600] : Colors.grey),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required bool isDark,
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required bool editable,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color:
                isDark ? Colors.grey[400] : Colors.black54)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: editable
                ? (isDark ? const Color(0xFF374151) : Colors.white)
                : (isDark
                ? const Color(0xFF374151)
                : const Color(0xFFF3F4F6)),
            borderRadius: BorderRadius.circular(12),
            border: editable
                ? Border.all(
                color: const Color(0xFF2563EB), width: 1.5)
                : null,
          ),
          child: TextField(
            controller: controller,
            enabled: editable,
            keyboardType: keyboardType,
            style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              prefixIcon: Icon(icon,
                  size: 18,
                  color: editable
                      ? const Color(0xFF2563EB)
                      : (isDark ? Colors.grey[400] : Colors.grey)),
              hintText: hint,
              hintStyle: TextStyle(
                  color: isDark ? Colors.grey[500] : Colors.grey,
                  fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 14, horizontal: 4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderField(bool isDark) {
    const options = ['male', 'female', 'other'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gender',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color:
                isDark ? Colors.grey[400] : Colors.black54)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: _isEditing
                ? (isDark ? const Color(0xFF374151) : Colors.white)
                : (isDark
                ? const Color(0xFF374151)
                : const Color(0xFFF3F4F6)),
            borderRadius: BorderRadius.circular(12),
            border: _isEditing
                ? Border.all(
                color: const Color(0xFF2563EB), width: 1.5)
                : null,
          ),
          child: Row(
            children: [
              Icon(Icons.person_outline,
                  size: 18,
                  color: _isEditing
                      ? const Color(0xFF2563EB)
                      : (isDark ? Colors.grey[400] : Colors.grey)),
              const SizedBox(width: 10),
              Expanded(
                child: _isEditing
                    ? DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _controller.selectedGender.isNotEmpty
                        ? _controller.selectedGender
                        : null,
                    hint: Text('Select gender',
                        style: TextStyle(
                            color: isDark
                                ? Colors.grey[400]
                                : Colors.grey)),
                    isExpanded: true,
                    dropdownColor: isDark
                        ? const Color(0xFF1F2937)
                        : Colors.white,
                    style: TextStyle(
                        color: isDark
                            ? Colors.white
                            : Colors.black87),
                    items: options
                        .map((g) => DropdownMenuItem(
                      value: g,
                      child: Text(
                          g[0].toUpperCase() +
                              g.substring(1),
                          style: const TextStyle(
                              fontSize: 15)),
                    ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _controller
                            .selectedGender = val);
                      }
                    },
                  ),
                )
                    : Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 14),
                  child: Text(
                    _controller.gender.isNotEmpty
                        ? _controller.gender[0]
                        .toUpperCase() +
                        _controller.gender.substring(1)
                        : '—',
                    style: TextStyle(
                        fontSize: 15,
                        color: isDark
                            ? Colors.grey[300]
                            : Colors.black54),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return BottomNavigationBar(
      currentIndex: 2,
      backgroundColor:
      isDark ? const Color(0xFF1F2937) : Colors.white,
      selectedItemColor: const Color(0xFF2563EB),
      unselectedItemColor:
      isDark ? Colors.grey[500] : Colors.grey,
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, AppRoutes.home);
            break;
          case 1:
            Navigator.pushReplacementNamed(
                context, AppRoutes.booking);
            break;
          case 2:
            break;
          case 3:
            Navigator.pushNamed(context, AppRoutes.settings);
            break;
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
    );
  }

  String _formatDob(String raw) {
    try {
      final parts = raw.split('-');
      if (parts.length == 3)
        return '${parts[2]}/${parts[1]}/${parts[0]}';
    } catch (_) {}
    return raw;
  }
}