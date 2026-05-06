import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants.dart';
import '../services/triage_history_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Profile',
          style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        _GlassProfileCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Taha Bouramdane', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Student ID: TBD', style: GoogleFonts.montserrat(color: AppColors.muted)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text('Historique des triages', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        ValueListenableBuilder<List<TriageHistoryItem>>(
          valueListenable: TriageHistoryService.instance.history,
          builder: (context, history, child) {
            if (history.isEmpty) {
              return Text('Aucun resultat pour le moment.', style: GoogleFonts.montserrat(color: AppColors.muted));
            }
            return Column(
              children: history
                  .map(
                    (h) => ListTile(
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      title: Text('${h.probability}% ${h.condition}', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                      subtitle: Text('${h.specialist} • ${h.location}', style: GoogleFonts.montserrat(fontSize: 12)),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _GlassProfileCard extends StatelessWidget {
  final Widget child;

  const _GlassProfileCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            border: Border.all(color: Colors.white),
            borderRadius: BorderRadius.circular(16),
          ),
          child: child,
        ),
      ),
    );
  }
}
