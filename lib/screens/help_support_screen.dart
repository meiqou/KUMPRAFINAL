import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


import '../utils/constants.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

Future<void> _launchURL(BuildContext context, String url) async {
    // Replace with real links when ready
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening $url'), backgroundColor: AppColors.primaryDark),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Help & Support', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.support_agent, color: AppColors.primary, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Need Help?',
                              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              'Contact us anytime',
                              style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'We\'re here to help you with Kumpra!',
                    style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Quick Actions
          Text(
            'Quick Actions',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          
          _buildActionTile(
            Icons.contact_phone,
            'Contact Support',
            'Chat or call our team',
            () => _launchURL(context, 'https://wa.me/639123456789'), // WhatsApp
          ),
          _buildActionTile(
            Icons.email_outlined,
            'Email Us',
            'support@kumpra.ph',
            () => _launchURL(context, 'mailto:support@kumpra.ph'),
          ),
          _buildActionTile(
            Icons.question_answer_outlined,
            'FAQ',
            'Frequently asked questions',
            () => _launchURL(context, 'https://kumpra.ph/faq'),
          ),
          
          const SizedBox(height: 24),
          
          // Troubleshooting
          Text(
            'Troubleshooting',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          
          _buildActionTile(
            Icons.refresh_outlined,
            'Clear Cache',
            'Refresh app data',
            () {
              // Mock clear cache
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared!'), backgroundColor: AppColors.success),
              );
            },
          ),
          _buildActionTile(
            Icons.logout_outlined,
            'Logout',
            'Sign out of account',
            () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out!'), backgroundColor: AppColors.error),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Version Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        'Kumpra v1.0.0',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '© 2024 Kumpra. All rights reserved.',
                    style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
           color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary),
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
