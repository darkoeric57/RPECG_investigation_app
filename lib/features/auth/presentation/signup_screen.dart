import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared_widgets/custom_button.dart';
import '../../../shared_widgets/custom_text_field.dart';
import '../../../core/services/backendless_auth_service.dart';
import 'package:backendless_sdk/backendless_sdk.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedRegion = 'Head Office';
  String _accountType = 'Technical';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _staffIdController = TextEditingController();
  final TextEditingController _groupNoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final List<String> _regions = [
    'Head Office',
    'Accra East',
    'Accra West',
    'Tema',
    'Eastern',
    'Western',
    'Ho',
    'Ashanti East',
    'Ashanti West',
    'Ashanti South',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _staffIdController.dispose();
    _groupNoController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showRegionPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Select Region',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _regions.length,
                separatorBuilder: (context, index) => Divider(color: Colors.grey.shade100, height: 1),
                itemBuilder: (context, index) {
                  final region = _regions[index];
                  final isSelected = region == _selectedRegion;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: Text(
                      region,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? AppTheme.primary : AppTheme.textDark,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: AppTheme.primary)
                        : null,
                    onTap: () {
                      setState(() => _selectedRegion = region);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
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
        // Visual Column (Left)
        Expanded(
          child: Container(
            color: AppTheme.primary,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.4,
                    child: Image.network(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuCnEW7l9uEaphex3olCtGrPGkyu5NGL8J_us65nf1wmUT1MsxLaFnDI-w_g9eUwHvCwrACZNj-MGQuhC1pLmH8TwzqjvCBA2SHLf6jt3clXJOl9BeimTdheChQHTHLkcbdefpcKCJQWmIUJf3nI38FdR-XUgjr7LKk04i4KAJjZXLoNh9M97AtWo__FNONo-4T-P4BAf5vcPnjfi570tANwOo_9MRmmHMQMJ6J_5YtUvcJjImfAc7ql6sde5vQskPHmvGp3FZhh6Ro',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(color: AppTheme.primary),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(64),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Powering the Future of Utility Management.',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: Colors.white,
                          fontSize: 48,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Sovereign Utility provides back-office staff with precision tools for investigation, reporting, and real-time asset monitoring.',
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                      const SizedBox(height: 48),
                      Row(
                        children: [
                          _buildFeatureCard(Icons.analytics, 'Advanced Analytics', 'Real-time data processing.'),
                          const SizedBox(width: 24),
                          _buildFeatureCard(Icons.verified_user, 'Secure Access', 'Enterprise-grade security.'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Form Column (Right)
        Expanded(
          child: Container(
            color: AppTheme.surfaceContainerLowest,
            padding: const EdgeInsets.symmetric(horizontal: 80),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: _buildSignupForm(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: _buildSignupForm(),
    );
  }

  Widget _buildSignupForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.admin_panel_settings, color: AppTheme.secondary),
              ),
              const SizedBox(width: 12),
              Text(
                'Sovereign Utility',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Staff Registration',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text('Create your back-office investigator account.'),
        const SizedBox(height: 48),
        
        _buildInputLabel('Full Name'),
        CustomTextField(
          label: '',
          showLabel: false,
          hint: 'Enter your full name',
          prefixIcon: Icons.person_outline,
          controller: _nameController,
          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 24),
        
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputLabel('Staff ID'),
                  CustomTextField(
                    label: '',
                    showLabel: false,
                    hint: 'ID-0000',
                    controller: _staffIdController,
                    validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputLabel('Region'),
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRegion,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.textLight, size: 20),
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Inter',
                        ),
                        items: _regions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                        onChanged: (v) => setState(() => _selectedRegion = v!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        _buildInputLabel('Email Address'),
        CustomTextField(
          label: '',
          showLabel: false,
          hint: 'work@sovereign-utility.com',
          prefixIcon: Icons.mail_outline,
          controller: _emailController,
          validator: (value) => value == null || !value.contains('@') ? 'Invalid email' : null,
        ),
        const SizedBox(height: 24),
        
        _buildInputLabel('Password'),
        CustomTextField(
          label: '',
          showLabel: false,
          hint: '••••••••••••',
          prefixIcon: Icons.lock_outline,
          controller: _passwordController,
          obscureText: _obscurePassword,
          suffixIcon: _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          onSuffixTap: () => setState(() => _obscurePassword = !_obscurePassword),
          validator: (value) => value == null || value.length < 6 ? 'Too short' : null,
        ),
        const SizedBox(height: 48),
        
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: _handleSignup,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              shape: const StadiumBorder(),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Register', style: TextStyle(fontSize: 16)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        Center(
          child: TextButton(
            onPressed: () => context.pop(),
            child: const Text(
              'Already have an account? Sign In',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        ],
      ),
    );
  }

Widget _buildInputLabel(String label) {
  return Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 10),
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

  Widget _buildFeatureCard(IconData icon, String title, String desc) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.secondary),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
    );

    try {
      final authService = BackendlessAuthService();
      await authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        staffId: _staffIdController.text.trim(),
        region: _selectedRegion,
        accountType: _accountType,
        groupNo: _groupNoController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context); // Remove loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully! Please log in.')),
        );
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Remove loading
        String message = e.toString();
        if (e is BackendlessException) {
          message = e.message ?? 'Unknown error';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signup failed: $message'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }
}
