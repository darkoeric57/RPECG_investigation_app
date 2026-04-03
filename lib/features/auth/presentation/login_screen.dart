import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared_widgets/custom_button.dart';
import '../../../shared_widgets/custom_text_field.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/backendless_auth_service.dart';
import 'package:backendless_sdk/backendless_sdk.dart';

import '../../../core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..forward();

  late final Animation<double> _formFade = CurvedAnimation(
    parent: _animController,
    curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
  );
  late final Animation<Offset> _formSlide = Tween<Offset>(
    begin: const Offset(0, 0.15),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _animController,
    curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
  ));

  late final Animation<double> _bioFade = CurvedAnimation(
    parent: _animController,
    curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
  );
  late final Animation<Offset> _bioSlide = Tween<Offset>(
    begin: const Offset(0, 0.3),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _animController,
    curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
  ));

  bool _rememberMe = false;
  final _biometricService = BiometricService();
  bool _isBiometricAvailable = false;
  final TextEditingController _emailController = TextEditingController(); // Changed from Staff ID to email to match Backendless
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // local_auth has no web implementation — skip entirely on web
    if (!kIsWeb) _checkBiometrics();
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    final authService = BackendlessAuthService();
    try {
      final isValid = await authService.isValidLogin();
        if (isValid && mounted) {
          final user = await authService.getCurrentUser();
          if (user != null && mounted) {
            ref.read(userProvider.notifier).state = user;
            // Let the router redirect naturally
          }
        }
    } catch (_) {
      // Ignore errors during silent check
    }
  }

  Future<void> _checkBiometrics() async {
    final available = await _biometricService.isBiometricAvailable();
    debugPrint('BIOMETRIC_DEBUG: Available on device: $available');
    if (mounted) {
      setState(() {
        _isBiometricAvailable = available;
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleBiometricLogin() async {
    debugPrint('BIOMETRIC_DEBUG: Starting handleBiometricLogin...');
    final authService = BackendlessAuthService();
    
    // Check if we actually have credentials
    final hasCreds = await authService.hasOfflineCredentials();
    final biometricEnabled = await authService.isBiometricEnabled();
    debugPrint('BIOMETRIC_DEBUG: hasCreds: $hasCreds, biometricEnabled: $biometricEnabled');
    
    if (!hasCreds) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Please login with password once to enable biometric offline login.'))
         );
       }
       return;
    }

    final authenticated = await _biometricService.authenticate(
      reason: 'Please authenticate to log in to your staff account',
    );

    if (authenticated && mounted) {
      // Use offline credentials to login
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
      try {
        final user = await authService.loginWithBiometrics();
        if (user != null) {
          ref.read(userProvider.notifier).state = user;
          if (mounted) {
            Navigator.pop(context); // hide loading
            context.go('/');
          }
        } else {
           if (mounted) {
             Navigator.pop(context);
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Could not retrieve offline credentials.'))
             );
           }
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Offline login failed: ${e.toString()}'))
          );
        }
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometric authentication failed or cancelled'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _showBiometricPrompt(BackendlessAuthService authService) async {
    return showDialog(
       context: context,
       barrierDismissible: false,
       builder: (ctx) => AlertDialog(
          title: const Text('Enable Fast Login'),
          content: const Text('Would you like to use biometrics (Touch ID / Face ID) to login easily when offline?'),
          actions: [
            TextButton(
               onPressed: () {
                 authService.setBiometricEnabled(false);
                 Navigator.pop(ctx);
               },
               child: const Text('Not Now', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
               onPressed: () async {
                 // Try to authenticate once
                 final success = await _biometricService.authenticate(reason: 'Authenticate to enable fast login');
                 if (success) {
                   await authService.setBiometricEnabled(true);
                   if (mounted) Navigator.pop(ctx);
                 } else {
                   if (mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification failed.')));
                     Navigator.pop(ctx);
                   }
                 }
               },
               child: const Text('Enable', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
            ),
          ]
       )
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
    );

    try {
      final authService = BackendlessAuthService();
      final user = await authService.login(_emailController.text.trim(), _passwordController.text);
      
      if (mounted) {
        Navigator.pop(context); // Remove loading dialog

        // Brief delay to let the dialog close before triggering navigation
        await Future.delayed(Duration.zero);

        if (mounted) {
          // Update auth state — the router's refreshListenable will fire
          // synchronously and redirect to '/' via the GoRouter redirect.
          ref.read(userProvider.notifier).state = user;
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Remove loading
        String message = e.toString();
        if (e is BackendlessException) {
          if (e.code == '3064') {
            message = 'This account is already logged in on another device or session. Please logout there first or check your Backendless settings.';
          } else {
            message = e.message ?? 'Unknown error';
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: $message'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 900;
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: isWide ? _buildWideLayout() : _buildNarrowLayout(),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        // Left Column: Branding and Imagery
        Expanded(
          flex: 7,
          child: Container(
            color: AppTheme.primary,
            child: Stack(
              children: [
                // Background Image
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.4,
                    child: Image.network(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuAZAY_9uVLtOJKmMS2mNGJ7j_WpN-x5MbW9-zKR-bvNekWC3MKYwvXOkxT9raAKdWu8Bi7rQzc5w-x_xJvay2BZhf7lvfd8XIYtUBSG0aJPS5u0v9rjrHZLWryQpQ8cATBnK8plw_OVAa3_IOXNc-9w2uSV31PbiatXyD9PFAWo6fmMwwToLVO2h6Qo63P_RvRvBMG-NJzbcco8OVP8JcMwDtixR-joYBgXtJ4n2HbEUzNyTFJGt0PDJhyOO2T5PWMfshvbJKz_sHg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(color: AppTheme.primary),
                    ),
                  ),
                ),
                // Branding Overlay
                Padding(
                  padding: const EdgeInsets.all(64),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.dynamic_form, color: AppTheme.secondary, size: 40),
                              const SizedBox(width: 12),
                              Text(
                                'Sovereign Utility',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 48),
                          SizedBox(
                            width: 600,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text.rich(
                                  TextSpan(
                                    text: 'Precision in ',
                                    children: [
                                      TextSpan(
                                        text: 'Infrastructure',
                                        style: TextStyle(color: AppTheme.secondary),
                                      ),
                                      const TextSpan(text: ' Management.'),
                                    ],
                                  ),
                                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                    color: Colors.white,
                                    fontSize: 56,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'The definitive command center for field investigations, meter maintenance, and sovereign utility oversight. Designed for high-performance back-office operations.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 18,
                                    height: 1.6,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Stats Row
                      _buildStatsRow(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Right Column: Login Form
        Expanded(
          flex: 5,
          child: Container(
            color: AppTheme.surfaceContainerLowest,
            padding: const EdgeInsets.symmetric(horizontal: 100),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: _buildLoginForm(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStat('99.9%', 'Uptime Reliability'),
        const SizedBox(width: 32),
        _buildStat('2.4ms', 'Data Latency'),
        const SizedBox(width: 32),
        _buildStat('Encrypted', 'Military Grade'),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            color: AppTheme.primary,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.dynamic_form, color: AppTheme.secondary, size: 32),
                const SizedBox(height: 24),
                Text(
                  'Sovereign Utility',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: _buildLoginForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Staff Portal Access',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please enter your administrative credentials to continue.',
            style: TextStyle(color: Color(0xFF444651), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 40),
          
          _buildInputLabel('Email Address'),
          CustomTextField(
            label: '',
            showLabel: false,
            hint: 'work@sovereign-utility.com',
            prefixIcon: Icons.mail_outline,
            controller: _emailController,
            validator: (value) => value == null || !value.contains('@') ? 'Invalid email address' : null,
          ),
          const SizedBox(height: 32),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInputLabel('Password'),
              TextButton(
                onPressed: () {},
                child: const Text('Forgot Password?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          CustomTextField(
            label: '',
            showLabel: false,
            hint: '••••••••••••',
            prefixIcon: Icons.lock_outline,
            controller: _passwordController,
            obscureText: _obscurePassword,
            suffixIcon: _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            onSuffixTap: () => setState(() => _obscurePassword = !_obscurePassword),
            validator: (value) => value == null || value.isEmpty ? 'Password is required' : null,
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Checkbox(
                value: _rememberMe,
                onChanged: (v) => setState(() => _rememberMe = v!),
              ),
              const Text('Trust this workstation for 30 days', style: TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                shape: const StadiumBorder(),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Sign In', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info, color: AppTheme.secondary),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Access is restricted to authorized personnel only. Unauthorized access attempts are monitored and logged.',
                    style: TextStyle(fontSize: 11, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: TextButton(
              onPressed: () => context.push('/signup'),
              child: const Text('Don\'t have an account? Sign Up'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: Color(0xFF444651),
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.secondary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
