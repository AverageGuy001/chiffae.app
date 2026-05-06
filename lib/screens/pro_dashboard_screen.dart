import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants.dart';
import '../services/pharmacy_data_service.dart';
import '../services/referral_service.dart';
import 'login_screen.dart';

class ProDashboardScreen extends StatefulWidget {
  const ProDashboardScreen({super.key});

  @override
  State<ProDashboardScreen> createState() => _ProDashboardScreenState();
}

class _ProDashboardScreenState extends State<ProDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ProfessionalProfile?>(
      valueListenable: PharmacyDataService.instance.currentProfessional,
      builder: (context, profile, child) {
        if (profile == null) {
          return const Scaffold(body: Center(child: Text('Aucun profil trouvé.')));
        }
        return _buildScaffold(profile);
      },
    );
  }

  Widget _buildScaffold(ProfessionalProfile profile) {
    final service = PharmacyDataService.instance;
    final Color roleColor = service.roleColor;
    final bool isOpen = profile.isAvailable247;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.logout_rounded),
          tooltip: 'Déconnexion',
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
        ),
        title: Text(
          profile.profession,
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOpen ? roleColor.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: isOpen ? Border.all(color: roleColor, width: 1) : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isOpen)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.greenAccent.withValues(alpha: 0.6),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    if (isOpen) const SizedBox(width: 6),
                    Text(
                      isOpen ? 'LIVE' : profile.profession.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        color: isOpen ? roleColor : AppColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: isOpen
            ? BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    roleColor.withValues(alpha: 0.06),
                    AppColors.background,
                    AppColors.background,
                  ],
                ),
              )
            : null,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IdentityCard(profile: profile, roleColor: roleColor, isOpen: isOpen),
              const SizedBox(height: 16),
              _StatsRow(roleColor: roleColor, service: service, profile: profile),
              const SizedBox(height: 18),
              _GardeToggle(roleColor: roleColor, isOpen: isOpen, onToggle: service.toggleProfessionalAvailability),
              const SizedBox(height: 20),

              // ═══ INCOMING CONSULTATIONS (Smart Referral Bridge) ═════
              _IncomingReferrals(roleColor: roleColor),
              const SizedBox(height: 20),

              _ProfessionContent(profile: profile, roleColor: roleColor, service: service),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 1. IDENTITY CARD
// ═══════════════════════════════════════════════════════════════════════════

class _IdentityCard extends StatelessWidget {
  final ProfessionalProfile profile;
  final Color roleColor;
  final bool isOpen;

  const _IdentityCard({required this.profile, required this.roleColor, required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isOpen ? roleColor.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.9),
              width: isOpen ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isOpen ? roleColor : roleColor.withValues(alpha: 0.3),
                        width: isOpen ? 2.5 : 1.5,
                      ),
                    ),
                    child: Icon(Icons.person_rounded, size: 38, color: roleColor),
                  ),
                  if (isOpen)
                    Positioned(
                      right: 0, top: 0,
                      child: Container(
                        width: 18, height: 18,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.6), blurRadius: 8, spreadRadius: 2)],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.fullName,
                        style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.onBackground)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.medical_services_rounded, size: 13, color: roleColor),
                        const SizedBox(width: 4),
                        Text(profile.profession,
                            style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.muted)),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('Exp: ${profile.yearsOfExperience} ans',
                              style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w700, color: roleColor)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 12, color: AppColors.muted),
                        const SizedBox(width: 4),
                        Text(profile.location,
                            style: GoogleFonts.montserrat(fontSize: 11, color: AppColors.muted)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 2. STATS ROW
// ═══════════════════════════════════════════════════════════════════════════

class _StatsRow extends StatelessWidget {
  final Color roleColor;
  final PharmacyDataService service;
  final ProfessionalProfile profile;

  const _StatsRow({required this.roleColor, required this.service, required this.profile});

  @override
  Widget build(BuildContext context) {
    final ValueNotifier<int> monthlyPatients;
    switch (profile.roleCategory) {
      case 'generalist':
        monthlyPatients = service.generalist.monthlyPatients;
        break;
      case 'specialist':
        monthlyPatients = service.specialist.monthlyPatients;
        break;
      default:
        monthlyPatients = service.pharmacist.monthlyPatients;
    }
    return Row(
      children: [
        Expanded(child: _GlassStatCard(icon: Icons.people_rounded, label: 'Patients / Mois', valueListenable: monthlyPatients, roleColor: roleColor, suffix: '')),
        const SizedBox(width: 10),
        Expanded(child: _GlassStatCard(icon: Icons.star_rounded, label: 'Note Moyenne', roleColor: roleColor, isRating: true, valueListenableDouble: service.averageRating)),
        const SizedBox(width: 10),
        Expanded(child: _GlassStatCard(icon: Icons.trending_up_rounded, label: 'Découverte %', valueListenable: service.profileDiscoveryRate, roleColor: roleColor, suffix: '%')),
      ],
    );
  }
}

class _GlassStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color roleColor;
  final String suffix;
  final bool isRating;
  final ValueNotifier<int>? valueListenable;
  final ValueNotifier<double>? valueListenableDouble;
  const _GlassStatCard({required this.icon, required this.label, required this.roleColor, this.suffix = '', this.isRating = false, this.valueListenable, this.valueListenableDouble});

  @override
  Widget build(BuildContext context) {
    final listenable = isRating ? valueListenableDouble! : valueListenable!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
          ),
          child: AnimatedBuilder(
            animation: listenable,
            builder: (context, _) {
              String valueText;
              if (isRating) { valueText = (valueListenableDouble!.value).toStringAsFixed(1); }
              else { valueText = '${valueListenable!.value}$suffix'; }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 22, color: roleColor),
                  const SizedBox(height: 6),
                  Text(valueText, style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.onBackground)),
                  const SizedBox(height: 2),
                  Text(label, style: GoogleFonts.montserrat(fontSize: 9, color: AppColors.muted), textAlign: TextAlign.center),
                  if (isRating) Row(mainAxisSize: MainAxisSize.min, children: List.generate(5, (i) => Icon(Icons.star_rounded, size: 12, color: roleColor))),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 3. GARDE TOGGLE
// ═══════════════════════════════════════════════════════════════════════════

class _GardeToggle extends StatelessWidget {
  final Color roleColor;
  final bool isOpen;
  final VoidCallback onToggle;
  const _GardeToggle({required this.roleColor, required this.isOpen, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isOpen ? roleColor.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isOpen ? roleColor.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.9), width: isOpen ? 2 : 1),
            boxShadow: isOpen ? [BoxShadow(color: roleColor.withValues(alpha: 0.25), blurRadius: 20, spreadRadius: 3)] : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(isOpen ? Icons.nightlight_round : Icons.nightlight_outlined, size: 22, color: isOpen ? roleColor : AppColors.onBackground),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Disponibilité 24/7 (Garde)',
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 15, color: isOpen ? roleColor : AppColors.onBackground))),
                  Switch(
                    value: isOpen,
                    activeTrackColor: roleColor.withValues(alpha: 0.4),
                    activeThumbColor: roleColor,
                    onChanged: (_) => onToggle(),
                  ),
                ],
              ),
              if (isOpen)
                Row(
                  children: [
                    Icon(Icons.circle, size: 10, color: Colors.greenAccent.shade400),
                    const SizedBox(width: 6),
                    Expanded(child: Text('Visible comme "Ouvert (24/7)" pour les patients.',
                        style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w500, color: roleColor))),
                  ],
                )
              else
                Text('Activez pour apparaître comme professionnel de garde.',
                    style: GoogleFonts.montserrat(fontSize: 11, color: AppColors.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 4. INCOMING REFERRALS (Smart Referral Bridge)
// ═══════════════════════════════════════════════════════════════════════════

class _IncomingReferrals extends StatefulWidget {
  final Color roleColor;
  const _IncomingReferrals({required this.roleColor});

  @override
  State<_IncomingReferrals> createState() => _IncomingReferralsState();
}

class _IncomingReferralsState extends State<_IncomingReferrals>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    // Start pulse if there are unviewed referrals
    if (ReferralService.instance.hasNewReferrals) {
      _pulseController.repeat(reverse: true);
    }
    ReferralService.instance.referrals.addListener(_onReferralChange);
  }

  void _onReferralChange() {
    if (ReferralService.instance.hasNewReferrals) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    ReferralService.instance.referrals.removeListener(_onReferralChange);
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final referrals = ReferralService.instance.referrals.value;
    final rc = widget.roleColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Pulse icon for new referrals
            if (ReferralService.instance.hasNewReferrals)
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, child) => Transform.scale(
                  scale: _pulseAnim.value,
                  child: Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 10),
            Text(
              'Consultations Entrantes',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.onBackground),
            ),
            if (ReferralService.instance.unviewedCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${ReferralService.instance.unviewedCount} nouveau(x)',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        if (referrals.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
            ),
            child: Center(
              child: Text(
                'Aucune consultation entrante.\nLes résultats de triage des patients apparaîtront ici.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.muted),
              ),
            ),
          )
        else
          Column(
            children: referrals.asMap().entries.map((entry) {
              final idx = entry.key;
              final ref = entry.value;
              final Color sevColor = ref.severityScore > 6 ? Colors.red : ref.severityScore > 3 ? Colors.orange : rc;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: !ref.viewed
                      ? Border.all(color: rc.withValues(alpha: 0.4), width: 1.5)
                      : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Severity dot
                          Container(
                            width: 12, height: 12,
                            decoration: BoxDecoration(
                              color: sevColor,
                              shape: BoxShape.circle,
                              boxShadow: !ref.viewed
                                  ? [BoxShadow(color: sevColor.withValues(alpha: 0.4), blurRadius: 4)]
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ref.patientName,
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppColors.onBackground,
                                  ),
                                ),
                                Text(
                                  'Âge: ${ref.patientAge} • Sévérité: ${ref.severityScore}/10 • ${ref.suggestedSpecialist}',
                                  style: GoogleFonts.montserrat(fontSize: 10, color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                          if (!ref.viewed)
                            Container(
                              width: 10, height: 10,
                              decoration: BoxDecoration(
                                color: rc,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.assignment_rounded, size: 14, color: AppColors.muted),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                ref.symptomSummary,
                                style: GoogleFonts.montserrat(fontSize: 11, color: AppColors.onBackground),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (!ref.accepted)
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: rc,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () {
                                    ReferralService.instance.acceptReferral(idx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Référence acceptée – ${ref.patientName} ajouté aux rendez-vous actifs.'),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.check_rounded, size: 16),
                                  label: Text('Accepter', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 11)),
                                ),
                              ),
                            ),
                          if (!ref.accepted) const SizedBox(width: 8),
                          Expanded(
                            child: SizedBox(
                              height: 36,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: rc,
                                  side: BorderSide(color: rc.withValues(alpha: 0.4)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () {
                                  // Mark as viewed / dismiss
                                  if (!ref.viewed) ReferralService.instance.markViewed(idx);
                                },
                                icon: Icon(Icons.visibility_rounded, size: 16),
                                label: Text(
                                  ref.viewed ? 'Vue' : 'Marquer vue',
                                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 11),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (ref.accepted) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: rc.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_rounded, size: 14, color: rc),
                              const SizedBox(width: 6),
                              Text(
                                'Accepté – Ajouté aux rendez-vous actifs',
                                style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w600, color: rc),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 5. PROFESSION-CONTENT DISPATCHER
//    Each profession gets its OWN dedicated dashboard section.
// ═══════════════════════════════════════════════════════════════════════════

class _ProfessionContent extends StatelessWidget {
  final ProfessionalProfile profile;
  final Color roleColor;
  final PharmacyDataService service;
  const _ProfessionContent({required this.profile, required this.roleColor, required this.service});

  @override
  Widget build(BuildContext context) {
    final prof = profile.profession.toLowerCase();

    // Dispatch by exact profession name
    if (prof.contains('pharmac')) {
      return _PharmacistDashboard(roleColor: roleColor, service: service);
    } else if (prof.contains('generalist') || prof.contains('généraliste')) {
      return _GeneralistDashboard(roleColor: roleColor, service: service);
    } else if (prof.contains('dent')) {
      return _DentistDashboard(roleColor: roleColor, service: service);
    } else if (prof.contains('pediat')) {
      return _PediatricianDashboard(roleColor: roleColor, service: service);
    } else if (prof.contains('cardio')) {
      return _CardiologistDashboard(roleColor: roleColor, service: service);
    }
    // Fallback to specialist
    return _DentistDashboard(roleColor: roleColor, service: service);
  }
}

// ─── Shared Section Header ───────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color roleColor;
  const _SectionHeader({required this.icon, required this.title, required this.roleColor});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 18, color: roleColor),
      const SizedBox(width: 8),
      Text(title, style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.onBackground)),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PHARMACIST DASHBOARD
// ═══════════════════════════════════════════════════════════════════════════

class _PharmacistDashboard extends StatelessWidget {
  final Color roleColor;
  final PharmacyDataService service;
  const _PharmacistDashboard({required this.roleColor, required this.service});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(icon: Icons.inventory_2_rounded, title: 'Gestion du Stock Médicaments', roleColor: roleColor),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
          child: Text('Gérez vos médicaments : appuyez pour changer le statut, éditez le prix.',
              style: GoogleFonts.montserrat(fontSize: 10, color: AppColors.muted, fontStyle: FontStyle.italic)),
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder<List<MedicineItem>>(
          valueListenable: service.pharmacist.stockInventory,
          builder: (context, inventory, child) => Column(
            children: inventory.asMap().entries.map((entry) => _MedicineTile(
              index: entry.key, item: entry.value, roleColor: roleColor,
              onToggleStock: () => service.toggleMedicineInStock(entry.key),
              onPriceChanged: (price) => service.setMedicinePrice(entry.key, price),
            )).toList(),
          ),
        ),
        const SizedBox(height: 24),
        _SectionHeader(icon: Icons.warning_amber_rounded, title: 'Demandes Urgentes de Garde', roleColor: roleColor),
        const SizedBox(height: 10),
        ValueListenableBuilder<List<AnalysisRequest>>(
          valueListenable: service.pharmacist.urgentRequests,
          builder: (context, requests, child) {
            if (requests.isEmpty) {
              return Padding(padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('Aucune demande urgente.', style: GoogleFonts.montserrat(color: AppColors.muted)));
            }
            return Column(
              children: requests.asMap().entries.map((entry) {
                final idx = entry.key;
                final req = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    leading: Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 22),
                    title: Text('${req.patientName} – ${req.requestType}',
                        style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: Text(req.id, style: GoogleFonts.montserrat(fontSize: 10, color: AppColors.muted)),
                    trailing: req.status == 'pending'
                        ? TextButton(
                            onPressed: () => service.resolveUrgentRequest(idx),
                            child: Text('Traiter', style: GoogleFonts.montserrat(color: roleColor, fontWeight: FontWeight.w600, fontSize: 12)))
                        : Icon(Icons.check_circle_rounded, color: roleColor, size: 22),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 24),
        _SectionHeader(icon: Icons.local_shipping_rounded, title: 'Contacter les Fournisseurs', roleColor: roleColor),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Grossistes partenaires:', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              _SupplierButton(label: 'Sothema (Casablanca) – Tél: 0522xx', roleColor: roleColor),
              const SizedBox(height: 6),
              _SupplierButton(label: 'Cooper Pharma (Rabat) – Tél: 0537xx', roleColor: roleColor),
              const SizedBox(height: 6),
              _SupplierButton(label: 'Afriquia Pharmacie – Tél: 0529xx', roleColor: roleColor),
            ],
          ),
        ),
      ],
    );
  }
}

class _MedicineTile extends StatelessWidget {
  final int index;
  final MedicineItem item;
  final Color roleColor;
  final VoidCallback onToggleStock;
  final ValueChanged<double> onPriceChanged;
  const _MedicineTile({required this.index, required this.item, required this.roleColor, required this.onToggleStock, required this.onPriceChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            GestureDetector(
              onTap: onToggleStock,
              child: Icon(item.inStock ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 20, color: item.inStock ? roleColor : AppColors.muted),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(item.name,
                style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600,
                    color: item.inStock ? AppColors.onBackground : AppColors.muted,
                    decoration: item.inStock ? null : TextDecoration.lineThrough))),
            SizedBox(
              width: 64,
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.zero,
                  hintText: '${item.price.toStringAsFixed(0)} DH',
                  border: InputBorder.none,
                ),
                style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w700, color: roleColor),
                textAlign: TextAlign.right,
                onSubmitted: (v) { final p = double.tryParse(v.trim()); if (p != null) onPriceChanged(p); },
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: item.inStock ? roleColor.withValues(alpha: 0.12) : Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(item.inStock ? 'En stock' : 'Rupture',
                  style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w600,
                      color: item.inStock ? roleColor : Colors.orange)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupplierButton extends StatelessWidget {
  final String label;
  final Color roleColor;
  const _SupplierButton({required this.label, required this.roleColor});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: roleColor, side: BorderSide(color: roleColor.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Demande envoyée à $label'))),
        icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
        label: Text(label, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GENERALIST DASHBOARD
// ═══════════════════════════════════════════════════════════════════════════

class _GeneralistDashboard extends StatefulWidget {
  final Color roleColor;
  final PharmacyDataService service;
  const _GeneralistDashboard({required this.roleColor, required this.service});
  @override
  State<_GeneralistDashboard> createState() => _GeneralistDashboardState();
}

class _GeneralistDashboardState extends State<_GeneralistDashboard> {
  final _notesController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _notesController.text = widget.service.generalist.consultationNotes.value;
    widget.service.generalist.consultationNotes.addListener(_syncNotes);
  }
  void _syncNotes() {
    if (_notesController.text != widget.service.generalist.consultationNotes.value) {
      _notesController.text = widget.service.generalist.consultationNotes.value;
    }
  }
  @override
  void dispose() {
    widget.service.generalist.consultationNotes.removeListener(_syncNotes);
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final rc = widget.roleColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(icon: Icons.local_hospital_rounded, title: 'Cabinet Médical Général', roleColor: rc),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: rc.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
          child: Text('Références AI, notes de consultation et gestion du temps d\'attente.',
              style: GoogleFonts.montserrat(fontSize: 10, color: AppColors.muted, fontStyle: FontStyle.italic)),
        ),
        const SizedBox(height: 14),

        // Références Triage
        _SectionHeader(icon: Icons.inbox_rounded, title: 'Boîte de Réception – Références AI', roleColor: rc),
        const SizedBox(height: 8),
        ValueListenableBuilder<List<TriageReferral>>(
          valueListenable: service.generalist.triageReferrals,
          builder: (context, referrals, child) {
            if (referrals.isEmpty) {
              return Padding(padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('Aucune référence.', style: GoogleFonts.montserrat(color: AppColors.muted)));
            }
            return Column(
              children: referrals.asMap().entries.map((entry) {
                final idx = entry.key;
                final ref = entry.value;
                final Color sevColor = ref.severity > 6 ? Colors.red : ref.severity > 3 ? Colors.orange : rc;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(radius: 16, backgroundColor: rc.withValues(alpha: 0.15),
                                child: Icon(Icons.person_rounded, size: 16, color: rc)),
                            const SizedBox(width: 8),
                            Text(ref.patientName, style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 14)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: sevColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.warning_rounded, size: 10, color: sevColor),
                                  const SizedBox(width: 4),
                                  Text('${ref.severity}/10', style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w700, color: sevColor)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(ref.symptomSummary, style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.muted)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.smart_toy_rounded, size: 12, color: AppColors.muted),
                            const SizedBox(width: 4),
                            Text('Recommandé par AI Triage', style: GoogleFonts.montserrat(fontSize: 9, color: AppColors.muted)),
                            const Spacer(),
                            TextButton(
                              onPressed: () => service.resolveReferral(idx),
                              child: Text('Traiter', style: GoogleFonts.montserrat(color: rc, fontWeight: FontWeight.w600, fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 20),

        // Notes de consultation
        _SectionHeader(icon: Icons.edit_note_rounded, title: 'Notes de Consultation', roleColor: rc),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                TextField(
                  controller: _notesController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Écrivez vos notes de consultation ici...\nEx: Patient présente une fièvre légère...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: rc, foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () {
                          service.saveConsultationNotes(_notesController.text);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notes sauvegardées.')));
                        },
                        icon: const Icon(Icons.save_rounded, size: 16),
                        label: Text('Sauvegarder', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: rc, side: BorderSide(color: rc.withValues(alpha: 0.4)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('PDF Ordonnance exporté (simulation).'))),
                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                        label: Text('Exporter PDF', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Gestion du temps d'attente
        _SectionHeader(icon: Icons.timer_rounded, title: "Temps d'Attente Estimé", roleColor: rc),
        const SizedBox(height: 10),
        ValueListenableBuilder<int>(
          valueListenable: service.generalist.waitTimeMinutes,
          builder: (context, minutes, child) {
            return Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('$minutes min', style: GoogleFonts.montserrat(fontSize: 32, fontWeight: FontWeight.w800, color: rc)),
                        const SizedBox(width: 10),
                        Text('actuel', style: GoogleFonts.montserrat(fontSize: 14, color: AppColors.muted)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Slider(
                      value: minutes.toDouble(), min: 0, max: 240, divisions: 48,
                      activeColor: rc, inactiveColor: rc.withValues(alpha: 0.2),
                      label: '$minutes min',
                      onChanged: (v) => service.setWaitTime(v.round()),
                    ),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('0 min', style: GoogleFonts.montserrat(fontSize: 10, color: AppColors.muted)),
                      Text('4 heures', style: GoogleFonts.montserrat(fontSize: 10, color: AppColors.muted)),
                    ]),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DENTIST DASHBOARD
// ═══════════════════════════════════════════════════════════════════════════

class _DentistDashboard extends StatelessWidget {
  final Color roleColor;
  final PharmacyDataService service;
  const _DentistDashboard({required this.roleColor, required this.service});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(icon: Icons.smart_toy_rounded, title: 'Cabinet Dentaire', roleColor: roleColor),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
          child: Text('Gérez vos rendez-vous, services et dossiers patients.',
              style: GoogleFonts.montserrat(fontSize: 10, color: AppColors.muted, fontStyle: FontStyle.italic)),
        ),
        const SizedBox(height: 14),

        // Agenda du jour
        _SectionHeader(icon: Icons.calendar_month_rounded, title: 'Agenda du Jour', roleColor: roleColor),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Icon(Icons.today_rounded, size: 14, color: roleColor),
              const SizedBox(width: 6),
              Text('Aujourd\'hui, ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                  style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w600, color: roleColor)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ValueListenableBuilder<List<Appointment>>(
          valueListenable: service.specialist.appointments,
          builder: (context, appointments, child) => Column(
            children: appointments.map((apt) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          children: [
                            Text(apt.time.split(':')[0], style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w800, color: roleColor)),
                            Text('h${apt.time.split(':')[1]}', style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w600, color: roleColor)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(apt.patientName, style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 14)),
                            Text(apt.procedure, style: GoogleFonts.montserrat(fontSize: 11, color: AppColors.muted)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: apt.status == 'confirmed' ? roleColor.withValues(alpha: 0.12) : Colors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          apt.status == 'confirmed' ? 'Confirmé' : 'En attente',
                          style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w700,
                              color: apt.status == 'confirmed' ? roleColor : Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // Services dentaires
        _SectionHeader(icon: Icons.build_circle_rounded, title: 'Prestations & Tarifs', roleColor: roleColor),
        const SizedBox(height: 10),
        ValueListenableBuilder<List<ProcedureService>>(
          valueListenable: service.specialist.procedureServices,
          builder: (context, procedures, child) => Column(
            children: procedures.asMap().entries.map((entry) {
              final idx = entry.key;
              final proc = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => service.toggleProcedureService(idx),
                        child: Icon(proc.isActive ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            size: 20, color: proc.isActive ? roleColor : AppColors.muted),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(proc.name,
                            style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600,
                                color: proc.isActive ? AppColors.onBackground : AppColors.muted,
                                decoration: proc.isActive ? null : TextDecoration.lineThrough)),
                      ),
                      SizedBox(
                        width: 72,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          enabled: proc.isActive,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.zero,
                            hintText: '${proc.price.toStringAsFixed(0)} DH',
                            border: InputBorder.none,
                          ),
                          style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w700, color: roleColor),
                          textAlign: TextAlign.right,
                          onSubmitted: (v) { final p = double.tryParse(v.trim()); if (p != null) service.setProcedurePrice(idx, p); },
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text('DH', style: GoogleFonts.montserrat(fontSize: 10, color: AppColors.muted)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // Dossiers patients
        _SectionHeader(icon: Icons.folder_rounded, title: 'Dossiers Patients Dentaires', roleColor: roleColor),
        const SizedBox(height: 10),
        ValueListenableBuilder<List<PatientRecord>>(
          valueListenable: service.specialist.patientRecords,
          builder: (context, records, child) => Column(
            children: records.map((rec) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.person_rounded, size: 22, color: roleColor),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(rec.name, style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 13)),
                            Text('Dernière visite: ${rec.lastVisit}', style: GoogleFonts.montserrat(fontSize: 10, color: AppColors.muted)),
                            const SizedBox(height: 4),
                            Text(rec.notes, style: GoogleFonts.montserrat(fontSize: 10, color: AppColors.onBackground, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PEDIATRICIAN DASHBOARD
// ═══════════════════════════════════════════════════════════════════════════

class _PediatricianDashboard extends StatelessWidget {
  final Color roleColor;
  final PharmacyDataService service;
  const _PediatricianDashboard({required this.roleColor, required this.service});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(icon: Icons.child_care_rounded, title: 'Cabinet Pédiatrique', roleColor: roleColor),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
          child: Text('Consultations enfants, vaccins et suivi de croissance.',
              style: GoogleFonts.montserrat(fontSize: 10, color: AppColors.muted, fontStyle: FontStyle.italic)),
        ),
        const SizedBox(height: 14),

        // Rendez-vous pédiatriques
        _SectionHeader(icon: Icons.calendar_month_rounded, title: 'Consultations du Jour', roleColor: roleColor),
        const SizedBox(height: 10),
        _pediatricAppointmentCard('09:00', 'Amine (3 ans)', 'Fièvre + toux', roleColor),
        _pediatricAppointmentCard('10:30', 'Sofia (18 mois)', 'Vaccin ROR', roleColor),
        _pediatricAppointmentCard('14:00', 'Youssef (5 ans)', 'Douleur oreille', roleColor),
        _pediatricAppointmentCard('15:30', 'Nour (8 ans)', 'Asthme – contrôle', roleColor),
        const SizedBox(height: 20),

        // Calendrier vaccinal
        _SectionHeader(icon: Icons.vaccines_rounded, title: 'Calendrier Vaccinal', roleColor: roleColor),
        const SizedBox(height: 10),
        _vaccineCard('ROR', '18 mois', 'Sofia – prévue cette semaine', roleColor),
        _vaccineCard('DTCP', '6 ans', 'Youssef – dans 2 semaines', roleColor),
        _vaccineCard('HPV', '12 ans', 'Nour – dans 1 mois', roleColor),
        const SizedBox(height: 20),

        // Courbes de croissance
        _SectionHeader(icon: Icons.monitor_heart_rounded, title: 'Suivi de Croissance', roleColor: roleColor),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _growthMetric('Poids moyen', '3 mois', '5.8 kg (50e percentile)', roleColor),
                const Divider(height: 16),
                _growthMetric('Taille moyenne', '3 mois', '60 cm (50e percentile)', roleColor),
                const Divider(height: 16),
                _growthMetric('Périmètre crânien', '3 mois', '40 cm (45e percentile)', roleColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _pediatricAppointmentCard(String time, String patient, String reason, Color rc) {
    final parts = time.split(':');
    final hour = parts.isNotEmpty ? parts[0] : '09';
    final minute = parts.length > 1 ? parts[1] : '00';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 50,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(color: rc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: [
                  Text(hour, style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w800, color: rc)),
                  Text('h$minute', style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w600, color: rc)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(patient, style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(reason, style: GoogleFonts.montserrat(fontSize: 11, color: AppColors.muted)),
                ],
              ),
            ),
            Icon(Icons.child_care_rounded, size: 18, color: rc.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _vaccineCard(String vaccine, String age, String note, Color rc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: rc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.vaccines_rounded, size: 22, color: rc),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(vaccine, style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: rc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(age, style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w700, color: rc)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(note, style: GoogleFonts.montserrat(fontSize: 10, color: AppColors.muted)),
                ],
              ),
            ),
            Icon(Icons.check_circle_rounded, size: 20, color: rc),
          ],
        ),
      ),
    );
  }

  Widget _growthMetric(String label, String age, String value, Color rc) {
    return Row(
      children: [
        Icon(Icons.monitor_heart_rounded, size: 14, color: rc),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$label ($age)', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 13)),
              Text(value, style: GoogleFonts.montserrat(fontSize: 11, color: AppColors.muted)),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CARDIOLOGIST DASHBOARD
// ═══════════════════════════════════════════════════════════════════════════

class _CardiologistDashboard extends StatelessWidget {
  final Color roleColor;
  final PharmacyDataService service;
  const _CardiologistDashboard({required this.roleColor, required this.service});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(icon: Icons.favorite_rounded, title: 'Cabinet de Cardiologie', roleColor: roleColor),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
          child: Text('Consultations cardiaques, ECG et suivi des patients à risque.',
              style: GoogleFonts.montserrat(fontSize: 10, color: AppColors.muted, fontStyle: FontStyle.italic)),
        ),
        const SizedBox(height: 14),

        // Rendez-vous
        _SectionHeader(icon: Icons.calendar_month_rounded, title: 'Consultations du Jour', roleColor: roleColor),
        const SizedBox(height: 10),
        _cardioAppointmentCard('08:30', 'Ahmed Bennani', 'ECG de contrôle – HTA', roleColor),
        _cardioAppointmentCard('10:00', 'Fatima Zrira', 'Palpitations – Holter', roleColor),
        _cardioAppointmentCard('11:30', 'Omar Tazi', 'Bilan cardiaque annuel', roleColor),
        _cardioAppointmentCard('14:30', 'Khadija Rafik', 'Douleur thoracique – test effort', roleColor),
        const SizedBox(height: 20),

        // Signes vitaux récents
        _SectionHeader(icon: Icons.monitor_heart_rounded, title: 'Signes Vitaux (Patients)', roleColor: roleColor),
        const SizedBox(height: 10),
        _vitalSignCard('Ahmed Bennani', '14/9 mmHg', '72 bpm', '98%', roleColor),
        _vitalSignCard('Fatima Zrira', '13/8 mmHg', '88 bpm', '97%', roleColor),
        _vitalSignCard('Omar Tazi', '16/10 mmHg', '68 bpm', '96%', roleColor),
        const SizedBox(height: 20),

        // Médicaments cardiaques
        _SectionHeader(icon: Icons.medication_rounded, title: 'Prescriptions Fréquentes', roleColor: roleColor),
        const SizedBox(height: 10),
        _prescriptionCard('Amlodipine', '5 mg – 1x/jour', 'HTA', roleColor),
        _prescriptionCard('Bisoprolol', '2.5 mg – 1x/jour', 'Insuff. cardiaque', roleColor),
        _prescriptionCard('Ramipril', '5 mg – 1x/jour', 'Protection rénale', roleColor),
        _prescriptionCard('Aspirine 100', '100 mg – 1x/jour', 'Antiagrégant', roleColor),
      ],
    );
  }

  Widget _cardioAppointmentCard(String time, String patient, String reason, Color rc) {
    final parts = time.split(':');
    final hour = parts.isNotEmpty ? parts[0] : '08';
    final minute = parts.length > 1 ? parts[1] : '00';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 50,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(color: rc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: [
                  Text(hour,
                      style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w800, color: rc)),
                  Text('h$minute',
                      style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w600, color: rc)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(patient, style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(reason, style: GoogleFonts.montserrat(fontSize: 11, color: AppColors.muted)),
                ],
              ),
            ),
            Icon(Icons.favorite_rounded, size: 18, color: Colors.red.shade300),
          ],
        ),
      ),
    );
  }

  Widget _vitalSignCard(String name, String bp, String hr, String spo2, Color rc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(radius: 18, backgroundColor: rc.withValues(alpha: 0.12),
                child: Icon(Icons.person_rounded, size: 18, color: rc)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _vitalBadge('TA: $bp', rc),
                      const SizedBox(width: 6),
                      _vitalBadge('FC: $hr', rc),
                      const SizedBox(width: 6),
                      _vitalBadge('SpO2: $spo2', rc),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vitalBadge(String label, Color rc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: rc.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w600, color: rc)),
    );
  }

  Widget _prescriptionCard(String med, String dose, String indication, Color rc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: rc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.medication_rounded, size: 18, color: rc),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(med, style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 14)),
                  Row(
                    children: [
                      Text(dose, style: GoogleFonts.montserrat(fontSize: 10, color: AppColors.muted)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(indication, style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w600, color: Colors.orange.shade700)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.content_copy_rounded, size: 16, color: rc.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}