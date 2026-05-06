import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants.dart';
import '../services/pharmacy_data_service.dart';
import 'pro_dashboard_screen.dart';

class ProSetupScreen extends StatefulWidget {
  const ProSetupScreen({super.key});

  @override
  State<ProSetupScreen> createState() => _ProSetupScreenState();
}

class _ProSetupScreenState extends State<ProSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _experienceController = TextEditingController();
  final _locationController = TextEditingController(text: 'Kenitra, Maroc');

  String _selectedProfession = 'Pharmacist';
  final _professions = [
    'Pharmacist',
    'Generalist',
    'Dentist',
    'Pediatrician',
    'Cardiologist',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _experienceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final years = int.tryParse(_experienceController.text.trim()) ?? 0;
    final profile = ProfessionalProfile(
      fullName: _nameController.text.trim(),
      profession: _selectedProfession,
      yearsOfExperience: years,
      location: _locationController.text.trim(),
    );

    PharmacyDataService.instance.setupProfessional(profile);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ProDashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Configuration',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              // ─── Profile Picture Placeholder ──────────────────────
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.person_rounded,
                  size: 48,
                  color: AppColors.primary.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Photo de profil',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 28),

              // ─── Full Name ───────────────────────────────────────
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nom complet',
                  hintText: 'Ex: Dr. Ahmed Alami',
                  prefixIcon: const Icon(Icons.badge_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 18),

              // ─── Profession Dropdown ─────────────────────────────
              DropdownButtonFormField<String>(
                initialValue: _selectedProfession,
                decoration: InputDecoration(
                  labelText: 'Profession',
                  prefixIcon: const Icon(Icons.medical_services_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                items: _professions
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedProfession = v);
                },
              ),
              const SizedBox(height: 18),

              // ─── Years of Experience ─────────────────────────────
              TextFormField(
                controller: _experienceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Années d'expérience",
                  hintText: 'Ex: 8',
                  prefixIcon: const Icon(Icons.timeline_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requis';
                  final n = int.tryParse(v.trim());
                  if (n == null || n < 0) return 'Nombre valide requis';
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // ─── Location ────────────────────────────────────────
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Localisation',
                  hintText: 'Ex: Kenitra, Maroc',
                  prefixIcon: const Icon(Icons.location_on_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 32),

              // ─── Submit Button ───────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _submit,
                  child: Text(
                    'Enter Dashboard',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}