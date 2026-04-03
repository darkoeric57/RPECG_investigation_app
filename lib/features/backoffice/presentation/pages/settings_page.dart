import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers.dart';

final _notificationsEmailProvider = StateProvider<bool>((ref) => true);
final _notificationsSmsProvider = StateProvider<bool>((ref) => false);
final _notificationsPushProvider = StateProvider<bool>((ref) => true);
final _twoFaEnabledProvider = StateProvider<bool>((ref) => false);
final _darkModeProvider = StateProvider<bool>((ref) => false);

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final name = (user?.getProperty('name') as String?) ?? 'Admin User';
    final email = user?.email ?? 'admin@fieldops.com';
    final initials = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join()
        .toUpperCase();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppTheme.primary,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Manage your account, preferences and security',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
          ),
          const SizedBox(height: 40),

          // Two-column layout
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildProfileCard(context, initials, name, email),
                    const SizedBox(height: 24),
                    _buildNotificationsCard(ref),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Right column
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _buildSecurityCard(context, ref),
                    const SizedBox(height: 24),
                    _buildPreferencesCard(ref),
                    const SizedBox(height: 24),
                    _buildAboutCard(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, String initials, String name, String email) {
    return _buildSectionCard(
      title: 'Profile',
      icon: Icons.person_outline_rounded,
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: Color(0xFF166534),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Divider(color: Color(0xFFF1F5F9)),
        const SizedBox(height: 16),
        _buildInfoRow(Icons.badge_outlined, 'Display Name', name),
        const SizedBox(height: 12),
        _buildInfoRow(Icons.email_outlined, 'Email Address', email),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile editor coming soon.')),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsCard(WidgetRef ref) {
    final email = ref.watch(_notificationsEmailProvider);
    final sms = ref.watch(_notificationsSmsProvider);
    final push = ref.watch(_notificationsPushProvider);

    return _buildSectionCard(
      title: 'Notifications',
      icon: Icons.notifications_none_rounded,
      children: [
        _buildToggleRow(
          'Email Alerts',
          'Receive critical alerts via email',
          email,
          (v) => ref.read(_notificationsEmailProvider.notifier).state = v,
        ),
        const SizedBox(height: 16),
        _buildToggleRow(
          'SMS Alerts',
          'Receive urgent alerts via text message',
          sms,
          (v) => ref.read(_notificationsSmsProvider.notifier).state = v,
        ),
        const SizedBox(height: 16),
        _buildToggleRow(
          'Push Notifications',
          'Real-time browser push notifications',
          push,
          (v) => ref.read(_notificationsPushProvider.notifier).state = v,
        ),
      ],
    );
  }

  Widget _buildToggleRow(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1E293B))),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.primary,
        ),
      ],
    );
  }

  Widget _buildSecurityCard(BuildContext context, WidgetRef ref) {
    final twoFaEnabled = ref.watch(_twoFaEnabledProvider);

    return _buildSectionCard(
      title: 'Security',
      icon: Icons.security_rounded,
      children: [
        _buildToggleRow(
          'Two-Factor Authentication',
          'Add an extra layer of login security',
          twoFaEnabled,
          (v) => ref.read(_twoFaEnabledProvider.notifier).state = v,
        ),
        const SizedBox(height: 24),
        const Divider(color: Color(0xFFF1F5F9)),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password change email sent.')),
                  );
                },
                icon: const Icon(Icons.lock_outline_rounded, size: 18),
                label: const Text('Change Password'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: BorderSide(color: AppTheme.primary.withOpacity(0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Session history feature coming soon.')),
                  );
                },
                icon: const Icon(Icons.history_rounded, size: 18),
                label: const Text('Session History'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreferencesCard(WidgetRef ref) {
    final darkMode = ref.watch(_darkModeProvider);

    return _buildSectionCard(
      title: 'Preferences',
      icon: Icons.tune_rounded,
      children: [
        _buildToggleRow(
          'Dark Mode',
          'Switch to a darker interface theme',
          darkMode,
          (v) => ref.read(_darkModeProvider.notifier).state = v,
        ),
        const SizedBox(height: 20),
        const Divider(color: Color(0xFFF1F5F9)),
        const SizedBox(height: 16),
        const Text('LANGUAGE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Row(
            children: [
              Icon(Icons.language_rounded, size: 18, color: Color(0xFF64748B)),
              SizedBox(width: 12),
              Text('English (US)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Spacer(),
              Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutCard() {
    return _buildSectionCard(
      title: 'About',
      icon: Icons.info_outline_rounded,
      children: [
        _buildAboutRow('Application', 'Field Ops Backoffice'),
        const SizedBox(height: 12),
        _buildAboutRow('Version', '2.4.1 (Build 394)'),
        const SizedBox(height: 12),
        _buildAboutRow('Platform', 'Flutter Web'),
        const SizedBox(height: 12),
        _buildAboutRow('Data Provider', 'Backendless Platform'),
        const SizedBox(height: 20),
        const Divider(color: Color(0xFFF1F5F9)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                '© 2024 RPE-CG Systems. All rights reserved.',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAboutRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1E293B))),
      ],
    );
  }
}
