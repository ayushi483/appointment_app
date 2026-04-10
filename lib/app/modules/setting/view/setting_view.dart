import 'package:flutter/material.dart';
import '../../../routes/app_routes.dart';
import '../../../core/theme_notifier.dart';
import '../../../core/session.dart'; // ← added

class SettingsView extends StatefulWidget {
  final String name;
  final String email;

  const SettingsView({
    super.key,
    required this.name,
    required this.email,
  });

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  // Always read from AppSession so name never shows 'User'
  String get _displayName =>
      AppSession.patientName?.isNotEmpty == true
          ? AppSession.patientName!
          : widget.name;

  String get _displayEmail =>
      AppSession.patientEmail?.isNotEmpty == true
          ? AppSession.patientEmail!
          : widget.email;

  @override
  void initState() {
    super.initState();
    _darkModeEnabled = themeNotifier.isDark;
  }

  String get _initials {
    final parts = _displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              AppSession.clear(); // ← clear session on logout
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                    (route) => false,
              );
            },
            child: const Text(
              'Log Out',
              style: TextStyle(
                  color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
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
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            _buildCard(
              isDark: isDark,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                leading: CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFF2563EB),
                  child: Text(
                    _initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                title: Text(
                  _displayName, // ← uses AppSession
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  _displayEmail, // ← uses AppSession
                  style: TextStyle(
                    color:
                    isDark ? Colors.grey[400] : Colors.grey,
                    fontSize: 13,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color:
                  isDark ? Colors.grey[400] : Colors.grey,
                ),
                onTap: () => Navigator.pop(context),
              ),
            ),

            const SizedBox(height: 24),

            // PREFERENCES
            _sectionLabel('PREFERENCES'),
            const SizedBox(height: 8),
            _buildCard(
              isDark: isDark,
              child: Column(
                children: [
                  _buildToggleTile(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    value: _notificationsEnabled,
                    isDark: isDark,
                    onChanged: (val) =>
                        setState(() => _notificationsEnabled = val),
                  ),
                  _divider(isDark),
                  _buildToggleTile(
                    icon: Icons.dark_mode_outlined,
                    label: 'Dark Mode',
                    value: _darkModeEnabled,
                    isDark: isDark,
                    onChanged: (val) {
                      setState(() => _darkModeEnabled = val);
                      themeNotifier.toggleDark(val);
                    },
                  ),
                  _divider(isDark),
                  _buildNavTile(
                    icon: Icons.language_outlined,
                    label: 'Language',
                    isDark: isDark,
                    trailing: Text(
                      'English',
                      style: TextStyle(
                        color: isDark
                            ? Colors.grey[400]
                            : Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // SECURITY
            _sectionLabel('SECURITY'),
            const SizedBox(height: 8),
            _buildCard(
              isDark: isDark,
              child: Column(
                children: [
                  _buildNavTile(
                    icon: Icons.lock_outline,
                    label: 'Change Password',
                    isDark: isDark,
                    onTap: () {},
                  ),
                  _divider(isDark),
                  _buildNavTile(
                    icon: Icons.shield_outlined,
                    label: 'Privacy Settings',
                    isDark: isDark,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // SUPPORT
            _sectionLabel('SUPPORT'),
            const SizedBox(height: 8),
            _buildCard(
              isDark: isDark,
              child: Column(
                children: [
                  _buildNavTile(
                    icon: Icons.help_outline,
                    label: 'Help Center',
                    isDark: isDark,
                    onTap: () {},
                  ),
                  _divider(isDark),
                  _buildNavTile(
                    icon: Icons.description_outlined,
                    label: 'Terms & Conditions',
                    isDark: isDark,
                    onTap: () {},
                  ),
                  _divider(isDark),
                  _buildNavTile(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    isDark: isDark,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Log Out Button
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _showLogoutDialog,
                style: TextButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color(0xFF3B1F1F)
                      : const Color(0xFFFFF1F1),
                  padding:
                  const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Log Out',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Footer
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Made with ',
                    style: TextStyle(
                      color: isDark
                          ? Colors.grey[500]
                          : Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                  const Icon(Icons.favorite,
                      color: Colors.red, size: 14),
                  Text(
                    ' for better healthcare',
                    style: TextStyle(
                      color: isDark
                          ? Colors.grey[500]
                          : Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child, required bool isDark}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _divider(bool isDark) => Divider(
    height: 1,
    indent: 56,
    endIndent: 0,
    color: isDark
        ? const Color(0xFF374151)
        : const Color(0xFFF3F4F6),
  );

  Widget _buildToggleTile({
    required IconData icon,
    required String label,
    required bool value,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF374151)
              : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color:
          isDark ? Colors.grey[300] : Colors.black54,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF2563EB),
      ),
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required String label,
    required bool isDark,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF374151)
              : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color:
          isDark ? Colors.grey[300] : Colors.black54,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      trailing: trailing ??
          Icon(
            Icons.chevron_right,
            color: isDark ? Colors.grey[400] : Colors.grey,
          ),
      onTap: onTap,
    );
  }
}