import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_sign_in/google_sign_in.dart' as auth;
import '../../../core/theme/app_theme.dart';
import '../../../core/providers.dart';
import '../../../core/services/backendless_auth_service.dart';
import '../../meters/presentation/add_meter_provider.dart';


class ProfileDrawer extends ConsumerStatefulWidget {
  const ProfileDrawer({super.key});

  @override
  ConsumerState<ProfileDrawer> createState() => _ProfileDrawerState();
}

class _ProfileDrawerState extends ConsumerState<ProfileDrawer> {
  bool _isUploading = false;

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 512,
    );

    if (image != null) {
      if (!mounted) return;
      setState(() => _isUploading = true);

      try {
        final authService = BackendlessAuthService();
        final updatedUser = await authService.updateProfilePicture(image.path);
        
        if (updatedUser != null && mounted) {
          ref.read(userProvider.notifier).state = updatedUser;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.redAccent),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final user = ref.watch(userProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final name = user?.getProperty('name') as String? ?? '';
    final staffId = user?.getProperty('staffId') as String? ?? '';
    final region = user?.getProperty('region') as String? ?? '';
    final groupNo = user?.getProperty('groupNo') as String? ?? '';
    final profilePicUrl = user?.getProperty('user-pic') as String?;
    final initials = name.isNotEmpty ? name.split(' ').map((e) => e[0]).take(2).join().toUpperCase() : '?';

    // Google Profile Info
    final googleAuth = ref.watch(googleSignInAccountProvider);
    final googleAccount = googleAuth.valueOrNull;

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          // Modern Fancy Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 80, bottom: 32, left: 32, right: 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark 
                  ? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]
                  : [AppTheme.primary, const Color(0xFF1E40AF)],
              ),
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(80),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Pic with Edit Button
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        backgroundImage: profilePicUrl != null ? NetworkImage(profilePicUrl) : null,
                        child: profilePicUrl == null 
                          ? Text(
                              initials,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            )
                          : null,
                      ),
                    ),
                    if (_isUploading)
                      const Positioned.fill(
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    if (googleAccount?.photoUrl != null)
                      Positioned(
                        bottom: 0,
                        right: 32,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 14,
                            backgroundImage: NetworkImage(googleAccount!.photoUrl!),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _isUploading ? null : _pickAndUploadImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.secondary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 16,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                if (staffId.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'ID: $staffId',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                if (googleAccount != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cloud_done, color: Colors.white, size: 10),
                            const SizedBox(width: 4),
                            Text(
                              googleAccount.displayName ?? googleAccount.email,
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildInfoBadge(Icons.location_on, region),
                    const SizedBox(width: 8),
                    _buildInfoBadge(Icons.group, 'GRP $groupNo'),
                  ],
                ),
              ],
            ),
          ),

          // Navigation Section
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                  child: Text(
                    'PREFERENCES',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: AppTheme.textLight,
                    ),
                  ),
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.nightlight_round,
                  title: 'Night Vision',
                  subtitle: themeMode == ThemeMode.dark ? 'Enabled' : 'Disabled',
                  onTap: () {
                    ref.read(themeModeProvider.notifier).state = 
                      themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
                  },
                  trailing: Switch(
                    value: themeMode == ThemeMode.dark,
                    onChanged: (val) {
                      ref.read(themeModeProvider.notifier).state = val ? ThemeMode.dark : ThemeMode.light;
                    },
                    activeThumbColor: AppTheme.accent,
                  ),
                ),
                
                // Google Drive Integration
                Consumer(
                  builder: (context, ref, child) {
                    final googleAuth = ref.watch(googleSignInAccountProvider);
                    final driveService = ref.read(googleDriveServiceProvider);
                    
                    return googleAuth.when(
                      data: (auth.GoogleSignInAccount? account) => _buildDrawerItem(
                        context: context,
                        icon: Icons.cloud_done_rounded,
                        title: 'Google Drive',
                        subtitle: account != null ? 'Connected as ${account.email}' : 'Not Connected',
                        onTap: () async {
                          if (account == null) {
                            final success = await driveService.signIn();
                            if (!success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Google Sign-In failed')),
                              );
                            }
                          } else {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Disconnect Google Drive?'),
                                content: const Text('The app will no longer be able to upload files until you reconnect.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
                                  TextButton(
                                    style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                                    onPressed: () => Navigator.pop(ctx, true), 
                                    child: const Text('DISCONNECT'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await driveService.signOut();
                            }
                          }
                        },
                        trailing: Icon(
                          account != null ? Icons.check_circle : Icons.link_rounded,
                          color: account != null ? Colors.green : AppTheme.textLight,
                          size: 20,
                        ),
                      ),
                      loading: () => _buildDrawerItem(
                        context: context,
                        icon: Icons.cloud_queue_rounded,
                        title: 'Google Drive',
                        subtitle: 'Checking status...',
                        onTap: () {},
                        trailing: const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      error: (err, _) => _buildDrawerItem(
                        context: context,
                        icon: Icons.cloud_off_rounded,
                        title: 'Google Drive',
                        subtitle: 'Connection Error',
                        onTap: () {},
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.cached_rounded,
                  title: 'Clean Slate',
                  subtitle: 'Wipe all local records',
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Reset Everything?'),
                        content: const Text('All investigation records will be permanently removed from this device.'),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('KEEP DATA')),
                          TextButton(
                            style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
                            onPressed: () => Navigator.pop(ctx, true), 
                            child: const Text('WIPE CLEAN'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await ref.read(meterRepositoryProvider).clearAll();
                      await ref.read(investigatorRepositoryProvider).clearAll();
                      ref.read(addMeterProvider.notifier).reset();
                      ref.invalidate(metersProvider);
                      ref.invalidate(investigatorsProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('All local data cleared')),
                        );
                        Navigator.pop(context);
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.only(left: 16, bottom: 8),
                  child: Text(
                    'SYSTEM',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: AppTheme.textLight,
                    ),
                  ),
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.help_outline_rounded,
                  title: 'Tech Support',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Tech Support'),
                        content: const Text('For assistance, please contact the IT department or email support@rpecg.com'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CLOSE')),
                        ],
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.info_outline_rounded,
                  title: 'Application Info',
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'RPECG Investigation App',
                      applicationVersion: '1.0.2',
                      applicationIcon: const Icon(Icons.electric_bolt, color: AppTheme.primary),
                      children: [
                        const Text('Corporate utility management and meter investigation suite.'),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Log Out Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: _buildActionItem(
              context: context,
              icon: Icons.logout_rounded,
              title: 'Sign Out Account',
              color: AppTheme.accent,
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Sign Out?'),
                    content: const Text('You will be taken back to the login screen. You can sign back in quickly using biometrics.'),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
                      TextButton(
                        style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
                        onPressed: () => Navigator.pop(ctx, true), 
                        child: const Text('SIGN OUT'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  final authService = BackendlessAuthService();
                  
                  // Perform logout first (sets sessionActive to false in file)
                  try {
                    await authService.logout();
                  } catch (_) {
                    // Ignore logout errors (offline)
                  }

                  // Then clear local state
                  ref.read(userProvider.notifier).state = null;
                  
                  if (context.mounted) {
                    context.go('/login');
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: isDark ? Colors.white70 : AppTheme.primary),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold, 
          fontSize: 15,
          color: isDark ? Colors.white : AppTheme.textDark,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textLight))
          : null,
      trailing: trailing,
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 15,
                  color: isDark ? Colors.white : AppTheme.textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
