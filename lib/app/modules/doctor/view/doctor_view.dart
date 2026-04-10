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
  List<Map<String, dynamic>> _specialityDoctors = [];
  List<Map<String, dynamic>> _specialities = [];

  bool _isLoading = true;
  String? _error;
  int? _selectedSpecialityId;
  String _selectedSpecialityName = 'All';
  String _searchQuery = '';

  int? _initialSpecialityId;
  String? _initialSpecialityName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_allDoctors.isEmpty) {
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
      });

      if (_initialSpecialityId != null) {
        _applySpecialityFilter(_initialSpecialityId!, _initialSpecialityName ?? 'All');
        _initialSpecialityId = null;
        _initialSpecialityName = null;
      } else {
        setState(() {
          _specialityDoctors = doctors;
          _filteredDoctors = doctors;
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _error = docResult['message'];
        _isLoading = false;
      });
    }
  }

  // FIX: All filtering is done locally from _allDoctors.
  // No API call to /get_doctors_by_speciality (returns 404 due to
  // missing res.speciality model on the server).
  void _applySpecialityFilter(int? specialityId, String name) {
    if (_selectedSpecialityId == specialityId) return;

    final base = specialityId == null
        ? _allDoctors
        : _allDoctors
        .where((d) => d['speciality_id'] == specialityId)
        .toList();

    setState(() {
      _selectedSpecialityId = specialityId;
      _selectedSpecialityName = name;
      _specialityDoctors = base;
      _filteredDoctors = _applySearch(base);
      _isLoading = false;
      _error = null;
    });
  }

  List<Map<String, dynamic>> _applySearch(List<Map<String, dynamic>> doctors) {
    if (_searchQuery.isEmpty) return List.from(doctors);
    final q = _searchQuery.toLowerCase();
    return doctors
        .where((d) =>
    (d['name'] as String? ?? '').toLowerCase().contains(q) ||
        (d['speciality'] as String? ?? '').toLowerCase().contains(q))
        .toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      // Always search on top of speciality-filtered base, not on already-searched list
      _filteredDoctors = _applySearch(_specialityDoctors);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor:
            isDark ? const Color(0xFF1F2937) : Colors.white,
            elevation: 0,
            title: Text(
              'Doctors',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black),
            ),
            iconTheme:
            IconThemeData(color: isDark ? Colors.white : Colors.black),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh,
                    color: isDark ? Colors.white : Colors.black),
                onPressed: _loadAll,
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(108),
              child: Container(
                color: isDark ? const Color(0xFF1F2937) : Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Search doctors...',
                          hintStyle: TextStyle(
                              color: isDark
                                  ? Colors.grey[500]
                                  : Colors.grey),
                          prefixIcon: Icon(Icons.search,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                            icon: Icon(Icons.clear,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                              : null,
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF374151)
                              : const Color(0xFFF3F4F6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                          const EdgeInsets.symmetric(vertical: 0),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 44,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            _specialtyChip(isDark, null, 'All'),
                            ..._specialities.map((s) => _specialtyChip(
                                isDark,
                                s['id'] as int,
                                s['name'] as String)),
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
        body: _buildBody(isDark),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey),
              ),
            ),
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
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                '${_filteredDoctors.length} doctor${_filteredDoctors.length == 1 ? '' : 's'} found',
                style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey,
                    fontSize: 13),
              ),
            );
          }
          if (_filteredDoctors.isEmpty && index == 1) {
            return SizedBox(
              height: 300,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_search,
                        size: 48,
                        color: isDark
                            ? Colors.grey[600]
                            : Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'No doctors found',
                      style: TextStyle(
                          color:
                          isDark ? Colors.grey[400] : Colors.grey,
                          fontSize: 15),
                    ),
                  ],
                ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child:
            _buildDoctorCard(isDark, _filteredDoctors[index - 1]),
          );
        },
      ),
    );
  }

  Widget _specialtyChip(bool isDark, int? id, String name) {
    // FIX: Only compare id — name comparison caused chip highlight issues
    final isSelected = _selectedSpecialityId == id;
    return GestureDetector(
      onTap: () => _applySpecialityFilter(id, name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB)
              : (isDark ? const Color(0xFF374151) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : (isDark
                ? const Color(0xFF4B5563)
                : const Color(0xFFE5E7EB)),
          ),
        ),
        child: Text(
          name,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.grey[300] : Colors.black87),
            fontWeight:
            isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorCard(bool isDark, Map<String, dynamic> doc) {
    final isAvailable = doc['available'] == true;
    final availableColor =
    isAvailable ? const Color(0xFF16A34A) : const Color(0xFFD97706);
    final availableText =
    isAvailable ? 'Available Today' : 'Not Available';

    Uint8List? imageBytes;
    try {
      final imgStr = (doc['image_1024'] as String?)?.isNotEmpty == true
          ? doc['image_1024'] as String
          : (doc['image'] as String? ?? '');
      if (imgStr.isNotEmpty) imageBytes = base64Decode(imgStr);
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 6)
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
                    Text(doc['name'] ?? '',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark
                                ? Colors.white
                                : Colors.black87)),
                    if ((doc['speciality'] ?? '').toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(doc['speciality'],
                            style: const TextStyle(
                                color: Color(0xFF2563EB),
                                fontSize: 13)),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 13,
                            color: isDark
                                ? Colors.grey[400]
                                : Colors.grey),
                        const SizedBox(width: 4),
                        Text('${doc['total_appointment'] ?? 0} appts',
                            style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey)),
                        Text(' • ',
                            style: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey)),
                        Icon(Icons.payments_outlined,
                            size: 13,
                            color: isDark
                                ? Colors.grey[400]
                                : Colors.grey),
                        const SizedBox(width: 2),
                        Text('₹${doc['fees'] ?? 0}',
                            style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey)),
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
                  color: availableColor.withOpacity(0.15),
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