import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared_widgets/custom_button.dart';
import '../../../shared_widgets/custom_text_field.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Column(
          children: [
            Text('Create Account'),
            Text(
              'Personal & Security Details',
              style: TextStyle(fontSize: 10, color: AppTheme.textLight),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Join Us',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Fill in your details to get started with your new account.',
              style: TextStyle(fontSize: 14, color: AppTheme.textLight),
            ),
            const SizedBox(height: 24),

            // Identity Section
            _buildSectionHeader(Icons.person, 'Identity'),
            const SizedBox(height: 16),
            _buildCard([
              const CustomTextField(label: 'Full Name', hint: 'e.g. John Doe'),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(
                    child: CustomTextField(label: 'Staff ID', hint: 'ID-0000'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdownField('Region', ['Lagos, NG', 'Abuja, NG']),
                  ),
                ],
              ),
            ]),
            const SizedBox(height: 24),

            // Contact Section
            _buildSectionHeader(Icons.contact_mail, 'Contact Information'),
            const SizedBox(height: 16),
            _buildCard([
              const CustomTextField(label: 'Email Address', hint: 'john@example.com', keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 20),
              const CustomTextField(label: 'Phone Number', hint: '+234 ...', keyboardType: TextInputType.phone),
            ]),
            const SizedBox(height: 24),

            // Security Section
            _buildSectionHeader(Icons.security, 'Security'),
            const SizedBox(height: 16),
            _buildCard([
              const CustomTextField(label: 'Password', hint: '••••••••', obscureText: true, suffixIcon: Icons.visibility_off_outlined),
              const SizedBox(height: 20),
              const CustomTextField(label: 'Confirm Password', hint: '••••••••', obscureText: true, suffixIcon: Icons.visibility_off_outlined),
            ]),
            
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () => context.pop(),
                child: const Text.rich(
                  TextSpan(
                    text: 'Already have an account? ',
                    style: TextStyle(color: AppTheme.textLight),
                    children: [
                      TextSpan(
                        text: 'Sign in',
                        style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 100), // Space for sticky bottom bar
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          border: const Border(top: BorderSide(color: AppTheme.borderLight)),
        ),
        child: Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'CANCEL',
                type: ButtonType.outlined,
                onPressed: () => context.pop(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: CustomButton(
                text: 'SIGN UP',
                icon: Icons.arrow_forward,
                type: ButtonType.accent,
                onPressed: () => context.go('/'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
      ],
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppTheme.borderLight.withOpacity(0.5)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDropdownField(String label, List<String> items) {
     return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppTheme.textLight,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: items.first,
              icon: const Icon(Icons.expand_more),
              items: items.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                );
              }).toList(),
              onChanged: (_) {},
            ),
          ),
        ),
      ],
    );
  }
}
