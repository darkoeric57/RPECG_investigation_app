import 'package:flutter/material.dart';
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
    _checkBiometrics();
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
            context.go('/');
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
        Navigator.pop(context); // Remove loading
        
        // Prompt for biometrics if available and not enabled yet
        final hasBiometrics = await _biometricService.isBiometricAvailable();
        if (hasBiometrics) {
           final biometricEnabled = await authService.isBiometricEnabled();
           if (!biometricEnabled && mounted) {
              await _showBiometricPrompt(authService);
           }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile synchronized for offline use.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
        
        ref.read(userProvider.notifier).state = user;
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Remove loading
        String message = e.toString();
        if (e is BackendlessException) {
          if (e.code == '3064') {
            message = 'This account is already logged in on another device or session. Please logout there first or check your Backendless settings.';
          } else {
            message = e.message;
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double height = constraints.maxHeight;
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: height,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // Header with Blue Curve (Maximizing Yellow Visibility)
                    Stack(
                      children: [
                        Container(
                          height: height * 0.28, // Increased for more yellow visibility
                          width: double.infinity,
                          color: AppTheme.secondary,
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: height * 0.16, // Kept small as previously requested
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(60),
                                topRight: Radius.circular(60),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Logo (Compact)
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Container(
                                    width: height * 0.05,
                                    height: height * 0.05,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.electric_bolt,
                                        size: height * 0.025,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: height * 0.005),
                                Text(
                                  'Utility Manager',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: height * 0.02,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const Text(
                                  'CORPORATE SUITE',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 7,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Login Form
                    FadeTransition(
                      opacity: _formFade,
                      child: SlideTransition(
                        position: _formSlide,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Transform.translate(
                        offset: const Offset(0, -15),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Welcome Back',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                const Text(
                                  'Please sign in to your staff account',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textLight,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                 CustomTextField(
                                   label: 'Email Address',
                                   hint: 'Enter your email',
                                   prefixIcon: Icons.email_outlined,
                                   controller: _emailController,
                                   keyboardType: TextInputType.emailAddress,
                                   textCapitalization: TextCapitalization.none,
                                   validator: (value) => value == null || value.isEmpty ? 'Email is required' : null,
                                 ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'PASSWORD',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textLight,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {},
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'Forgot?',
                                        style: TextStyle(
                                          color: AppTheme.primary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                 CustomTextField(
                                   label: '', // Label already shown above
                                   hint: '••••••••',
                                   prefixIcon: Icons.lock_outline,
                                   controller: _passwordController,
                                   obscureText: _obscurePassword,
                                   textCapitalization: TextCapitalization.none,
                                   suffixIcon: _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                   onSuffixTap: () => setState(() => _obscurePassword = !_obscurePassword),
                                   validator: (value) => value == null || value.isEmpty ? 'Password is required' : null,
                                 ),
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _rememberMe,
                                      activeColor: AppTheme.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      onChanged: (val) => setState(() => _rememberMe = val!),
                                    ),
                                    const Text(
                                      'Keep me signed in',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                CustomButton(
                                  text: 'Sign In to Dashboard',
                                  icon: Icons.arrow_forward,
                                  type: ButtonType.accent,
                                  onPressed: _handleLogin,
                                ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(flex: 2), // Encourage pushing down

                    // Biometric Section
                    FadeTransition(
                      opacity: _bioFade,
                      child: SlideTransition(
                        position: _bioSlide,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                        children: [
                          const Row(
                            children: [
                              Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'FAST LOGIN',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textLight,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_isBiometricAvailable)
                            Column(
                              children: [
                                InkWell(
                                  onTap: _handleBiometricLogin,
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: AppTheme.borderLight),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.fingerprint,
                                      size: 32,
                                      color: AppTheme.primary, // Changed to primary to show it's active
                                      semanticLabel: 'Biometric Login',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Touch ID / Face ID',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textLight,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            )
                          else
                            const Text(
                              'Biometrics not available on this device',
                              style: TextStyle(
                                fontSize: 8,
                                color: AppTheme.textLight,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 1),

                    // Footer
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account?",
                              style: TextStyle(color: AppTheme.textLight, fontSize: 12),
                            ),
                            TextButton(
                              onPressed: () {
                                if (context.mounted) {
                                  context.push('/signup');
                                }
                              },
                              child: const Text(
                                'Sign up now',
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
