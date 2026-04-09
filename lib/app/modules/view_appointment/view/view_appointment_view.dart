import 'package:flutter/material.dart';
import '../../../routes/app_routes.dart';
import '../../../core/session.dart';
import 'package:clinic_management/app/modules/view_appointment/controllers/view_appointment_controllers.dart';

class ViewAppointmentView extends StatefulWidget {
  const ViewAppointmentView({super.key});

  @override
  State<ViewAppointmentView> createState() => _ViewAppointmentViewState();
}

class _ViewAppointmentViewState extends State<ViewAppointmentView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _controller = ViewAppointmentController();

  List<Map<String, dynamic>> _upcoming = [];
  List<Map<String, dynamic>> _completed = [];
  List<Map<String, dynamic>> _cancelled = [];
  List<Map<String, dynamic>> _noShow = [];

  bool _isLoadingUpcoming = true;
  bool _isLoadingCompleted = true;
  bool _isLoadingCancelled = true;
  bool _isLoadingNoShow = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadAll();
  }

  void _loadAll() {
    _loadUpcoming();
    _loadCompleted();
    _loadCancelled();
    _loadNoShow();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUpcoming() async {
    setState(() => _isLoadingUpcoming = true);
    final result = await _controller.fetchAppointments('confirmed');
    if (!mounted) return;
    setState(() {
      _upcoming = result['success'] == true
          ? List<Map<String, dynamic>>.from(result['appointments'])
          : [];
      _isLoadingUpcoming = false;
    });
  }

  Future<void> _loadCompleted() async {
    setState(() => _isLoadingCompleted = true);
    final result = await _controller.fetchAppointments('done');
    if (!mounted) return;
    setState(() {
      _completed = result['success'] == true
          ? List<Map<String, dynamic>>.from(result['appointments'])
          : [];
      _isLoadingCompleted = false;
    });
  }

  Future<void> _loadCancelled() async {
    setState(() => _isLoadingCancelled = true);
    final result = await _controller.fetchAppointments('cancel');
    if (!mounted) return;
    setState(() {
      _cancelled = result['success'] == true
          ? List<Map<String, dynamic>>.from(result['appointments'])
          : [];
      _isLoadingCancelled = false;
    });
  }

  Future<void> _loadNoShow() async {
    setState(() => _isLoadingNoShow = true);
    final result = await _controller.fetchNoShowAppointments();
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() {
        _noShow = List<Map<String, dynamic>>.from(result['appointments']);
        _isLoadingNoShow = false;
      });
    } else {
      final fallback = await _controller.fetchAppointments('no_show');
      if (!mounted) return;
      setState(() {
        _noShow = fallback['success'] == true
            ? List<Map<String, dynamic>>.from(fallback['appointments'])
            : [];
        _isLoadingNoShow = false;
      });
    }
  }

  Future<void> _confirmCancel(Map<String, dynamic> appt) async {
    final id = appt['appointment_id'] as int?;
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Appointment'),
        content: const Text(
            'Are you sure you want to cancel this appointment? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep It')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await _controller.cancelAppointment(id);
    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Appointment cancelled successfully'),
        backgroundColor: Colors.green,
      ));
      _loadUpcoming();
      _loadCancelled();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Failed to cancel'),
        backgroundColor: Colors.red,
      ));
    }
  }

  String _formatDatetime(String? dt) {
    if (dt == null || dt.isEmpty) return '';
    try {
      final parsed = DateTime.parse(dt);
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
      return '${days[parsed.weekday - 1]}, ${months[parsed.month - 1]} ${parsed.day}';
    } catch (_) {
      return dt;
    }
  }

  String _formatTime(String? dt) {
    if (dt == null || dt.isEmpty) return '';
    try {
      final parsed = DateTime.parse(dt).toLocal();
      final hour = parsed.hour;
      final minute = parsed.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour % 12 == 0 ? 12 : hour % 12;
      return '$displayHour:$minute $period';
    } catch (_) {
      return '';
    }
  }

  String _tabLabel(String base, bool loading, int count) =>
      loading ? base : '$base ($count)';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Book'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
        onTap: (i) {
          if (i == 0) {
            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false,
                arguments: {'name': AppSession.patientName ?? 'User'});
          }
          if (i == 1) Navigator.pushNamed(context, AppRoutes.booking);
        },
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: Colors.white,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('My Appointments',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18)),
                if (AppSession.patientName != null)
                  Text(AppSession.patientName!,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey, fontWeight: FontWeight.normal)),
              ],
            ),
            iconTheme: const IconThemeData(color: Colors.black),
            actions: [
              IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.black),
                  onPressed: _loadAll),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF2563EB),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF2563EB),
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: _tabLabel('Upcoming', _isLoadingUpcoming, _upcoming.length)),
                Tab(text: _tabLabel('Completed', _isLoadingCompleted, _completed.length)),
                Tab(text: _tabLabel('Cancelled', _isLoadingCancelled, _cancelled.length)),
                Tab(text: _tabLabel('No Show', _isLoadingNoShow, _noShow.length)),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildScrollableList(_upcoming,
                isLoading: _isLoadingUpcoming, tabType: _TabType.upcoming),
            _buildScrollableList(_completed,
                isLoading: _isLoadingCompleted, tabType: _TabType.completed),
            _buildScrollableList(_cancelled,
                isLoading: _isLoadingCancelled, tabType: _TabType.cancelled),
            _buildScrollableList(_noShow,
                isLoading: _isLoadingNoShow, tabType: _TabType.noShow),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollableList(List<Map<String, dynamic>> appointments,
      {bool isLoading = false, required _TabType tabType}) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)));
    }

    if (appointments.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: 400,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                tabType == _TabType.noShow
                    ? Icons.person_off_outlined
                    : tabType == _TabType.cancelled
                    ? Icons.cancel_outlined
                    : Icons.calendar_today_outlined,
                size: 60,
                color: Colors.grey,
              ),
              const SizedBox(height: 12),
              Text(_emptyMessage(tabType),
                  style: const TextStyle(color: Colors.grey, fontSize: 16)),
              if (tabType == _TabType.upcoming) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.booking),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                  child: const Text('Book Appointment',
                      style: TextStyle(color: Colors.white)),
                ),
              ]
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      key: PageStorageKey(tabType.name),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: appointments.length,
      itemBuilder: (context, index) =>
          _buildAppointmentCard(appointments[index], tabType: tabType),
    );
  }

  String _emptyMessage(_TabType t) {
    switch (t) {
      case _TabType.upcoming:   return 'No upcoming appointments';
      case _TabType.completed:  return 'No completed appointments';
      case _TabType.cancelled:  return 'No cancelled appointments';
      case _TabType.noShow:     return 'No no-show appointments';
    }
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appt,
      {required _TabType tabType}) {
    final dateStr = _formatDatetime(appt['appointment_datetime']);
    final timeStr = _formatTime(appt['appointment_datetime']);
    final status = appt['status'] ?? '';
    final code = appt['appointment_code'] ?? '';

    Color statusColor;
    switch (status) {
      case 'confirmed':
      case 'draft':
        statusColor = const Color(0xFF16A34A);
        break;
      case 'done':
        statusColor = const Color(0xFF2563EB);
        break;
      case 'cancel':
      case 'cancelled':
        statusColor = Colors.red;
        break;
      case 'no_show':
        statusColor = const Color(0xFFF59E0B);
        break;
      default:
        statusColor = Colors.orange;
    }

    String statusLabel = status.toUpperCase();
    if (status == 'no_show') statusLabel = 'NO SHOW';
    if (status == 'cancel' || status == 'cancelled') statusLabel = 'CANCELLED';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Doctor row ───────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.person, size: 32, color: Color(0xFF2563EB)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appt['doctor_name'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    if ((appt['doctor_speciality'] ?? '').isNotEmpty)
                      Text(appt['doctor_speciality'],
                          style: const TextStyle(
                              color: Color(0xFF2563EB), fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(statusLabel,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Info rows ─────────────────────────────────────────────────
          _infoRow(Icons.calendar_today_outlined, dateStr),
          const SizedBox(height: 4),
          _infoRow(Icons.access_time_outlined, timeStr),

          // ── Appointment Code pill badge ────────────────────────────────
          if (code.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.confirmation_number_outlined,
                      size: 13, color: Color(0xFF2563EB)),
                  const SizedBox(width: 4),
                  Text(
                    code,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],

          // ── No-show notice ────────────────────────────────────────────
          if (tabType == _TabType.noShow) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF59E0B), width: 1),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFF59E0B), size: 16),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'You missed this appointment. Please contact the clinic to reschedule.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Cancelled notice ──────────────────────────────────────────
          if (tabType == _TabType.cancelled) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200, width: 1),
              ),
              child: Row(
                children: const [
                  Icon(Icons.cancel_outlined, color: Colors.red, size: 16),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text('This appointment has been cancelled.',
                        style: TextStyle(fontSize: 12, color: Colors.red)),
                  ),
                ],
              ),
            ),
          ],

          // ── Notes ─────────────────────────────────────────────────────
          if ((appt['notes'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Notes',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(appt['notes'],
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 13)),
                ],
              ),
            ),
          ],

          // ── Action buttons — upcoming only ────────────────────────────
          if (tabType == _TabType.upcoming) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Reschedule',
                        style: TextStyle(color: Colors.black87, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _confirmCancel(appt),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.red, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],

          // ── Re-book — cancelled & no-show ─────────────────────────────
          if (tabType == _TabType.cancelled || tabType == _TabType.noShow) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_circle_outline,
                    size: 16, color: Colors.white),
                label: const Text('Book Again',
                    style: TextStyle(color: Colors.white, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pushNamed(context, AppRoutes.booking),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }
}

enum _TabType { upcoming, completed, cancelled, noShow }