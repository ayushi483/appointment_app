import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../routes/app_routes.dart';
import 'package:clinic_management/app/modules/doctor/controllers/doctor_controllers.dart';

class DoctorView extends StatefulWidget {
  const DoctorView({super.key});

  @override
  State<DoctorView> createState() => _DoctorViewState();
}

class _DoctorViewState extends State<DoctorView> {
  final _controller = DoctorController();
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _allDoctors = [];
  List<Map<String, dynamic>> _filteredDoctors = [];
  List<Map<String, dynamic>> _specialities = [];

  bool _isLoading = true;
  String? _error;
  int? _selectedSpecialityId;
  String _selectedSpecialityName = 'All';
  String _searchQuery = '';

  // ── NEW: read optional speciality args passed from AppointmentView ────────
  int? _initialSpecialityId;
  String? _initialSpecialityName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only read args once on first mount
    if (_initialSpecialityId == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        _initialSpecialityId = args['speciality_id'] as int?;
        _initialSpecialityName = args['speciality_name'] as String?;
      }
      _loadAll();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final results = await Future.wait([
      _controller.fetchSpecialities(),
      _controller.fetchDoctors(),
    ]);

    if (!mounted) return;

    final specResult = results[0];
    final docResult = results[1];

    if (docResult['success'] == true) {
      final doctors = docResult['doctors'] as List<Map<String, dynamic>>;
      final specs = specResult['success'] == true
          ? specResult['specialities'] as List<Map<String, dynamic>>
          : <Map<String, dynamic>>[];

      setState(() {
        _allDoctors = doctors;
        _specialities = specs;
        _isLoading = false;
      });

      // ── If we arrived from a speciality card, auto-select it ─────────────
      if (_initialSpecialityId != null) {
        await _onSpecialityTap(
          _initialSpecialityId!,
          _initialSpecialityName ?? 'All',
        );
        // Clear so a manual refresh doesn't re-trigger
        _initialSpecialityId = null;
        _initialSpecialityName = null;
      } else {
        setState(() => _filteredDoctors = doctors);
      }
    } else {
      setState(() {
        _error = docResult['message'];
        _isLoading = false;
      });
    }
  }

  Future<void> _onSpecialityTap(int? specialityId, String name) async {
    setState(() {
      _selectedSpecialityId = specialityId;
      _selectedSpecialityName = name;
      _isLoading = true;
    });

    if (specialityId == null) {
      setState(() {
        _filteredDoctors = _applySearch(_allDoctors);
        _isLoading = false;
      });
    } else {
      final result = await _controller.fetchDoctorsBySpeciality(specialityId);
      if (!mounted) return;
      setState(() {
        _filteredDoctors = result['success'] == true
            ? _applySearch(result['doctors'] as List<Map<String, dynamic>>)
            : [];
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _applySearch(
      List<Map<String, dynamic>> doctors) {
    if (_searchQuery.isEmpty) return doctors;
    return doctors
        .where((d) =>
    (d['name'] as String? ?? '')
        .toLowerCase()
        .contains(_searchQuery.toLowerCase()) ||
        (d['speciality'] as String? ?? '')
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filteredDoctors = _applySearch(
        _selectedSpecialityId == null ? _allDoctors : _filteredDoctors,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // ── Sliver App Bar ──────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Doctors',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black),
            ),
            iconTheme: const IconThemeData(color: Colors.black),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.black),
                onPressed: _loadAll,
              ),
            ],
            // ── Search bar + speciality chips ────────────────────────
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(108),
              child: Container(
                color: Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search doctors...',
                          hintStyle: const TextStyle(color: Colors.grey),
                          prefixIcon:
                          const Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFFF3F4F6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                          const EdgeInsets.symmetric(vertical: 0),
                        ),
                      ),
                    ),
                    // Speciality chips
                    SizedBox(
                      height: 44,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            _specialtyChip(null, 'All'),
                            ..._specialities.map((s) => _specialtyChip(
                                s['id'] as int, s['name'] as String)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF2563EB)));
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
            ElevatedButton(
              onPressed: _loadAll,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB)),
              child: const Text('Retry',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF2563EB),
      onRefresh: _loadAll,
      child: ListView.builder(
        key: const PageStorageKey('doctors'),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount:
        _filteredDoctors.isEmpty ? 2 : _filteredDoctors.length + 1,
        itemBuilder: (context, index) {
          // Count row
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                '${_filteredDoctors.length} doctors found',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            );
          }
          // Empty state
          if (_filteredDoctors.isEmpty && index == 1) {
            return const SizedBox(
              height: 300,
              child: Center(
                child: Text('No doctors found',
                    style: TextStyle(color: Colors.grey, fontSize: 15)),
              ),
            );
          }
          // Doctor card
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildDoctorCard(_filteredDoctors[index - 1]),
          );
        },
      ),
    );
  }

  Widget _specialtyChip(int? id, String name) {
    final isSelected =
        _selectedSpecialityId == id && _selectedSpecialityName == name;
    return GestureDetector(
      onTap: () => _onSpecialityTap(id, name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          name,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight:
            isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doc) {
    final isAvailable = doc['available'] == true;
    final availableColor =
    isAvailable ? const Color(0xFF16A34A) : const Color(0xFFD97706);
    final availableText =
    isAvailable ? 'Available Today' : 'Not Available';

    Uint8List? imageBytes;
    try {
      final imgStr =
          doc['image_1024'] as String? ?? doc['image'] as String? ?? '';
      if (imgStr.isNotEmpty) imageBytes = base64Decode(imgStr);
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 6)
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
                  color: const Color(0xFFE0F2FE),
                  child: const Icon(Icons.person,
                      size: 40, color: Color(0xFF2563EB)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc['name'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    if ((doc['speciality'] ?? '').toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(doc['speciality'],
                            style: const TextStyle(
                                color: Color(0xFF2563EB), fontSize: 13)),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 13, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('${doc['total_appointment'] ?? 0} appts',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                        const Text(' • ',
                            style: TextStyle(color: Colors.grey)),
                        const Icon(Icons.payments_outlined,
                            size: 13, color: Colors.grey),
                        const SizedBox(width: 2),
                        Text('₹${doc['fees'] ?? 0}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
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
                  color: availableColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(availableText,
                    style: TextStyle(
                        color: availableColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.booking,
                  arguments: {
                    'doctor_id': doc['id'],
                    'doctor_name': doc['name'],
                  },
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                ),
                child: const Text('Book Now',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}