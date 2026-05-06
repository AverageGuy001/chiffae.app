import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants.dart';
import '../services/pharmacy_data_service.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onStartTriage;

  const DashboardScreen({super.key, required this.onStartTriage});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _nearestPharmacy = 'Chargement...';
  int _gardeCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNearestPharmacy();
    _gardeCount = PharmacyDataService.instance.gardePharmacies.length;
    // Listen for changes from the professional portal
    PharmacyDataService.instance.pharmacies.addListener(_onPharmacyUpdate);
  }

  @override
  void dispose() {
    PharmacyDataService.instance.pharmacies.removeListener(_onPharmacyUpdate);
    super.dispose();
  }

  void _onPharmacyUpdate() {
    setState(() {
      _gardeCount = PharmacyDataService.instance.gardePharmacies.length;
    });
    _loadNearestPharmacy();
  }

  Future<void> _loadNearestPharmacy() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        setState(() => _nearestPharmacy = 'Activez la localisation.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() => _nearestPharmacy = 'Permission GPS refusée.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final pharmacies = PharmacyDataService.instance.pharmacies.value;
      if (pharmacies.isEmpty) {
        setState(() => _nearestPharmacy = 'Aucune pharmacie trouvée.');
        return;
      }
      double best = double.infinity;
      String bestName = 'Pharmacie';
      for (final p in pharmacies) {
        final km = Geolocator.distanceBetween(
              pos.latitude,
              pos.longitude,
              p.lat,
              p.lng,
            ) /
            1000;
        if (km < best) {
          best = km;
          bestName = p.name;
        }
      }
      setState(() => _nearestPharmacy = '$bestName (${best.toStringAsFixed(1)} km)');
    } catch (_) {
      setState(() => _nearestPharmacy = 'Localisation indisponible.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Dashboard',
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.onBackground,
          ),
        ),
        const SizedBox(height: 14),
        // Nearest pharmacy card
        _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_pharmacy_rounded,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Pharmacie la plus proche',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _nearestPharmacy,
                style: GoogleFonts.montserrat(color: AppColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Garde pharmacies card
        _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.nightlight_round,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Pharmacies de Garde (24/7)',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '$_gardeCount pharmacie(s) en service de garde actuellement.',
                style: GoogleFonts.montserrat(color: AppColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Professional "Open Now" indicator
        ValueListenableBuilder<ProfessionalProfile?>(
          valueListenable: PharmacyDataService.instance.currentProfessional,
          builder: (context, pro, child) {
            if (pro == null || !pro.isAvailable247) return const SizedBox.shrink();
            final Color roleColor = PharmacyDataService.instance.roleColor;
            return _GlassCard(
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.greenAccent.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${pro.fullName} – Ouvert (24/7)',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: roleColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.medical_services_rounded,
                                size: 11, color: AppColors.muted),
                            const SizedBox(width: 4),
                            Text(
                              '${pro.profession} • ${pro.location}',
                              style: GoogleFonts.montserrat(
                                color: AppColors.muted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.check_circle_rounded,
                      size: 22, color: roleColor),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: widget.onStartTriage,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Start Triage'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Urgent Call: composez les urgences locales.')),
            );
          },
          icon: const Icon(Icons.call_rounded, color: AppColors.primary),
          label: const Text('Urgent Call', style: TextStyle(color: AppColors.primary)),
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
          ),
          child: child,
        ),
      ),
    );
  }
}