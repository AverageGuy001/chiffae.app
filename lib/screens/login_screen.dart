import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants.dart';
import 'app_shell_screen.dart';
import 'pro_setup_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo / Icon
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    size: 42,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                // Welcome text
                Text(
                  'Marhaban',
                  style: GoogleFonts.montserrat(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onBackground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bienvenue sur Chifaae',
                  style: GoogleFonts.montserrat(
                    color: AppColors.muted,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Choisissez votre profil',
                  style: GoogleFonts.montserrat(
                    color: AppColors.onBackground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 32),

                // ─── Patient Card ──────────────────────────────────────
                _RoleCard(
                  icon: Icons.person_rounded,
                  title: 'Je suis un Patient',
                  subtitle: 'Accédez au triage médical, chatbot\net pharmacie la plus proche',
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const AppShellScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // ─── Professional Card ──────────────────────────────────
                _RoleCard(
                  icon: Icons.medical_services_rounded,
                  title: 'Je suis un Professionnel',
                  subtitle: 'Pharmacien ou médecin : gérez votre\nstock, disponibilité et demandes',
                  color: AppColors.accent,
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const ProSetupScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),
                Text(
                  'Chifaae v1.0 – Moroccan Healthcare MVP',
                  style: GoogleFonts.montserrat(
                    color: AppColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A large Material 3 card for role selection.
class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon circle
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onBackground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: AppColors.muted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}