import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../services/gemini_service.dart';
import '../services/pharmacy_data_service.dart';
import '../services/referral_service.dart';
import '../services/triage_history_service.dart';
import '../services/voice_input_helper.dart';

class TriageScreen extends StatefulWidget {
  const TriageScreen({super.key});

  @override
  State<TriageScreen> createState() => _TriageScreenState();
}

class _TriageScreenState extends State<TriageScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  final List<_Question> _questions = const [
    _Question(
      keyName: 'age',
      label: '1) Quel est votre âge ?',
      hint: 'Exemple: 27',
      keyboardType: TextInputType.number,
    ),
    _Question(
      keyName: 'isChild',
      label: '2) Le patient est-il un enfant (moins de 15 ans) ?',
      options: ['Oui', 'Non'],
    ),
    _Question(
      keyName: 'mainSymptom',
      label: '3) Quel est le symptôme principal aujourd\'hui ?',
      hint: 'Exemple: fièvre, douleur dentaire, palpitations...',
    ),
    _Question(
      keyName: 'duration',
      label: '4) Depuis quand ce symptôme est-il présent ?',
      options: ['Moins de 24h', '1-3 jours', '4-7 jours', 'Plus d\'une semaine'],
    ),
    _Question(
      keyName: 'painLevel',
      label: '5) Intensité de la douleur (0 à 10)',
      options: ['0-2', '3-5', '6-8', '9-10'],
    ),
    _Question(
      keyName: 'fever',
      label: '6) Avez-vous de la fièvre ?',
      options: ['Oui', 'Non'],
    ),
    _Question(
      keyName: 'chestPain',
      label: '7) Ressentez-vous une douleur thoracique ?',
      options: ['Oui', 'Non'],
    ),
    _Question(
      keyName: 'breathingIssue',
      label: '8) Avez-vous une difficulté à respirer ?',
      options: ['Oui', 'Non'],
    ),
    _Question(
      keyName: 'allergies',
      label: '9) Avez-vous des allergies connues (médicaments/aliments) ?',
      hint: 'Indiquez "Aucune" si non.',
    ),
    _Question(
      keyName: 'currentMedication',
      label: '10) Prenez-vous actuellement des médicaments ?',
      hint: 'Indiquez le nom ou écrivez "Aucun".',
    ),
  ];

  late final List<TextEditingController> _controllers;
  late final AnimationController _resultAnimController;
  late final Animation<double> _resultFade;

  int _currentPage = 0;
  bool _loading = false;
  DiagnosisResult? _result;
  _NearestPlace? _nearestPlace;
  List<String> _recommendedMedicines = const [];
  double? _userLat;
  double? _userLng;

  // Track stored answers for referral
  Map<String, dynamic> _lastAnswers = {};

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _questions.length,
      (index) => TextEditingController(),
    );
    _resultAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _resultFade = CurvedAnimation(
      parent: _resultAnimController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _controllers) {
      c.dispose();
    }
    _resultAnimController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_currentPage >= _questions.length - 1) return;
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  Future<_NearestPlace?> _findNearestPlace(DiagnosisResult diagnosis) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    _userLat = position.latitude;
    _userLng = position.longitude;

    // Use shared PharmacyDataService (respects stock/Garde changes made by professionals)
    final allPharmacies = PharmacyDataService.instance.pharmacies.value;
    // Specialized centers are loaded from JSON as before for the centers list
    final raw = await rootBundle.loadString('assets/data/health_data.json');
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final centers = (map['specialized_centers'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    if (diagnosis.locationType == 'center') {
      // Use centers from JSON
      if (centers.isEmpty) return null;
      _NearestPlace? nearest;
      for (final item in centers) {
        final lat = (item['lat'] as num).toDouble();
        final lng = (item['lng'] as num).toDouble();
        final km = Geolocator.distanceBetween(
              position.latitude,
              position.longitude,
              lat,
              lng,
            ) /
            1000;
        final candidate = _NearestPlace(
          name: (item['name'] ?? 'Centre').toString(),
          distanceKm: km,
          kind: 'Centre',
          lat: lat,
          lng: lng,
        );
        final exactRequested = diagnosis.locationName.isNotEmpty &&
            (item['name'] ?? '').toString() == diagnosis.locationName;
        if (exactRequested) return candidate;
        if (nearest == null || candidate.distanceKm < nearest.distanceKm) {
          nearest = candidate;
        }
      }
      return nearest;
    } else {
      // Use pharmacies from shared service (live data)
      if (allPharmacies.isEmpty) return null;
      _NearestPlace? nearest;
      for (final p in allPharmacies) {
        final km = Geolocator.distanceBetween(
              position.latitude,
              position.longitude,
              p.lat,
              p.lng,
            ) /
            1000;
        final candidate = _NearestPlace(
          name: p.name,
          distanceKm: km,
          kind: 'Pharmacie',
          lat: p.lat,
          lng: p.lng,
        );
        if (nearest == null || candidate.distanceKm < nearest.distanceKm) {
          nearest = candidate;
        }
      }
      return nearest;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Triage', style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                'Question ${_currentPage + 1}/10',
                style: GoogleFonts.montserrat(color: AppColors.muted, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (_currentPage + 1) / _questions.length,
                color: AppColors.primary,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              ),
            ],
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (value) => setState(() => _currentPage = value),
            itemCount: _questions.length,
            itemBuilder: (context, index) {
              final q = _questions[index];
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      q.label,
                      style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 20),
                    if (q.options == null)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controllers[index],
                              keyboardType: q.keyboardType,
                              decoration: InputDecoration(
                                hintText: q.hint ?? 'Votre réponse',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          VoiceInputButton(
                            iconSize: 22,
                            onResult: (text) {
                              setState(() => _controllers[index].text = text);
                            },
                          ),
                        ],
                      )
                    else
                      Wrap(
                        spacing: 10,
                        children: q.options!.map((o) {
                          final selected = _controllers[index].text == o;
                          return ChoiceChip(
                            label: Text(o),
                            selected: selected,
                            selectedColor: AppColors.primary.withValues(alpha: 0.3),
                            onSelected: (_) => setState(() => _controllers[index].text = o),
                          );
                        }).toList(),
                      ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF046307),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _loading
                            ? null
                            : index == _questions.length - 1
                                ? _finish
                                : _next,
                        child: Text(index == _questions.length - 1 ? 'Terminer' : 'Suivant'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.only(bottom: 18),
            child: CircularProgressIndicator(),
          ),
        if (_result != null) _buildResultCard(),
      ],
    );
  }

  Widget _buildResultCard() {
    final result = _result!;
    final nearest = _nearestPlace;
    final distanceText = nearest == null
        ? 'distance inconnue'
        : '${nearest.distanceKm.toStringAsFixed(1)} km';
    final placeText = nearest?.name ?? (result.locationType == 'center'
        ? (result.locationName.isNotEmpty ? result.locationName : 'centre spécialisé proche')
        : 'pharmacie proche');
    final placeKind = nearest?.kind ?? (result.locationType == 'center' ? 'Centre' : 'Pharmacie');
    final locationMapLink = nearest == null
        ? null
        : 'https://www.google.com/maps/search/?api=1&query=${nearest.lat},${nearest.lng}';
    final directionsLink =
        (nearest != null && _userLat != null && _userLng != null)
            ? 'https://www.google.com/maps/dir/?api=1&origin=$_userLat,$_userLng&destination=${nearest.lat},${nearest.lng}&travelmode=driving'
            : null;

    return FadeTransition(
      opacity: _resultFade,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Diagnosis Card',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Probabilité de l\'issue: ${result.probability}% ${result.condition}',
                  style: GoogleFonts.montserrat(height: 1.5),
                ),
                const SizedBox(height: 6),
                Text(
                  'Profile recommandé: ${result.specialist}',
                  style: GoogleFonts.montserrat(
                    fontSize: 12.5,
                    color: AppColors.onBackground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Lieu recommandé: $placeKind - $placeText (distance entre vous et le lieu: $distanceText)',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
                if (locationMapLink != null) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        avatar: const Icon(
                          Icons.map_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        label: const Text('Maps'),
                        labelStyle: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                        side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.35),
                        ),
                        onPressed: () => _openUrl(locationMapLink),
                      ),
                      if (directionsLink != null)
                        ActionChip(
                          avatar: const Icon(
                            Icons.directions_car_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          label: Text(
                            'Itinéraire',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                          side: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.35),
                          ),
                          onPressed: () => _openUrl(directionsLink),
                        ),
                    ],
                  ),
                ],
                if (_recommendedMedicines.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Médicaments recommandés',
                    style: GoogleFonts.montserrat(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _recommendedMedicines.map((med) {
                      final encoded = Uri.encodeComponent(med);
                      final medLink =
                          'https://www.google.com/search?q=$encoded+medicament+maroc';
                      return ActionChip(
                        avatar: const Icon(
                          Icons.medication_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        label: Text(
                          med,
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                        side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.35),
                        ),
                        onPressed: () => _openUrl(medLink),
                      );
                    }).toList(),
                  ),
                ],
                if (result.message.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(result.message, style: GoogleFonts.montserrat(fontSize: 12)),
                ],
                if (result.hadApiError) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _finish,
                    child: const Text('3awd jarrab', style: TextStyle(color: AppColors.primary)),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => _showReferralBottomSheet(result),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      'Envoyer au Spécialiste',
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showReferralBottomSheet(DiagnosisResult result) {
    // Get the patient's age/name from the stored answers
    final patientAge = _lastAnswers['age']?.toString() ?? '?';
    final symptomText = _lastAnswers['mainSymptom']?.toString() ?? 'Non spécifié';
    final painLevel = _lastAnswers['painLevel']?.toString() ?? '?';
    final severity = int.tryParse(painLevel) ?? 5;

    // Build professional list based on AI suggestion
    final specialist = result.specialist.toLowerCase();
    final List<Map<String, String>> professionals;

    if (specialist.contains('dent')) {
      professionals = [
        {'name': 'Dr. Ahmed Alami', 'spec': 'Dentiste', 'dist': '1.2 km'},
        {'name': 'Dr. Fatima Zahra', 'spec': 'Dentiste', 'dist': '2.5 km'},
        {'name': 'Dr. Karim Tazi', 'spec': 'Dentiste', 'dist': '3.8 km'},
      ];
    } else if (specialist.contains('pedia') || specialist.contains('child')) {
      professionals = [
        {'name': 'Dr. Nadia Ouazzani', 'spec': 'Pédiatre', 'dist': '0.8 km'},
        {'name': 'Dr. Samir Rafik', 'spec': 'Pédiatre', 'dist': '2.0 km'},
      ];
    } else if (specialist.contains('cardio') || specialist.contains('heart')) {
      professionals = [
        {'name': 'Dr. Hassan Bennani', 'spec': 'Cardiologue', 'dist': '1.5 km'},
        {'name': 'Dr. Leila Amrani', 'spec': 'Cardiologue', 'dist': '3.2 km'},
      ];
    } else {
      professionals = [
        {'name': 'Dr. Amine El Fassi', 'spec': 'Généraliste', 'dist': '1.0 km'},
        {'name': 'Dr. Sara Benali', 'spec': 'Généraliste', 'dist': '2.8 km'},
        {'name': 'Dr. Youssef Ouadih', 'spec': 'Généraliste', 'dist': '4.1 km'},
      ];
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.muted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              'Envoyer au Spécialiste',
              style: GoogleFonts.montserrat(
                fontSize: 18, fontWeight: FontWeight.w800,
                color: AppColors.onBackground,
              ),
            ),
            const SizedBox(height: 16),
            // Triage summary card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Résumé du Triage',
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 8),
                  Text('Âge: $patientAge ans • Symptôme: $symptomText • Sévérité: $severity/10',
                      style: GoogleFonts.montserrat(fontSize: 11, color: AppColors.muted)),
                  Text('Spécialiste recommandé: ${result.specialist}',
                      style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Professional list header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('Professionnels disponibles',
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: professionals.length,
                itemBuilder: (ctx, i) {
                  final p = professionals[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                        child: Icon(Icons.medical_services_rounded, color: AppColors.primary, size: 22),
                      ),
                      title: Text(p['name']!,
                          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 14)),
                      subtitle: Text('${p['spec']} • ${p['dist']}',
                          style: GoogleFonts.montserrat(fontSize: 11, color: AppColors.muted)),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          // Create and send the referral
                          final referral = Referral(
                            id: 'REF-${DateTime.now().millisecondsSinceEpoch}',
                            patientName: 'Patient (Âge: $patientAge)',
                            patientAge: int.tryParse(patientAge) ?? 0,
                            symptomSummary: symptomText,
                            severityScore: severity,
                            suggestedSpecialist: result.specialist,
                            suggestedAction: 'Consulter ${p['spec']} – ${p['name']}',
                          );
                          ReferralService.instance.addReferral(referral);
                          Navigator.pop(ctx);
                          // Show success
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text('Dossier Partagé!', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                                ],
                              ),
                              backgroundColor: AppColors.primary,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Text('Envoyer',
                            style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 11)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _finish() async {
    setState(() {
      _loading = true;
      _result = null;
      _nearestPlace = null;
    });

    final answers = <String, dynamic>{};
    for (var i = 0; i < _questions.length; i++) {
      final value = _controllers[i].text.trim();
      if (value.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veuillez compléter la question ${i + 1}.')),
        );
        setState(() => _loading = false);
        return;
      }
      answers[_questions[i].keyName] = _normalizeAnswer(_questions[i].keyName, value);
    }
    _lastAnswers = Map.from(answers);
    answers['submittedAt'] = DateTime.now().toIso8601String();

    final diagnosis = await GeminiService.instance.getDiagnosis(answers);
    final nearest = await _findNearestPlace(diagnosis);
    final meds = await _resolveMedicines(diagnosis, nearest);

    if (!mounted) return;
    setState(() {
      _result = diagnosis;
      _nearestPlace = nearest;
      _recommendedMedicines = meds;
      _loading = false;
    });
    final locationForHistory =
        nearest?.name ?? diagnosis.locationName.ifEmpty('Lieu non disponible');
    TriageHistoryService.instance.add(
      TriageHistoryItem(
        createdAt: DateTime.now(),
        probability: diagnosis.probability,
        condition: diagnosis.condition,
        specialist: diagnosis.specialist,
        location: locationForHistory,
      ),
    );
    _resultAnimController.forward(from: 0);
  }

  dynamic _normalizeAnswer(String key, String value) {
    final lower = value.toLowerCase();
    if (key == 'isChild' || key == 'fever' || key == 'chestPain' || key == 'breathingIssue') {
      return lower == 'oui' ? 'yes' : 'no';
    }
    if (key == 'painLevel') {
      if (value == '9-10') return '9';
      if (value == '6-8') return '7';
      if (value == '3-5') return '4';
      if (value == '0-2') return '1';
    }
    if (key == 'duration') {
      if (value == 'Plus d\'une semaine') return 'more than one week';
      if (value == '4-7 jours') return '4 to 7 days';
      if (value == '1-3 jours') return '1 to 3 days';
      if (value == 'Moins de 24h') return 'less than 24h';
    }
    return value;
  }

  Future<List<String>> _resolveMedicines(
    DiagnosisResult diagnosis,
    _NearestPlace? nearest,
  ) async {
    if (diagnosis.medicines.isNotEmpty) {
      return diagnosis.medicines.take(3).toList();
    }
    if (!diagnosis.needsMedicine || nearest == null || nearest.kind != 'Pharmacie') {
      return const [];
    }
    try {
      final raw = await rootBundle.loadString('assets/data/health_data.json');
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final pharmacies =
          (map['pharmacies'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      final selected = pharmacies.firstWhere(
        (p) => (p['name'] ?? '').toString() == nearest.name,
        orElse: () => <String, dynamic>{},
      );
      return List<String>.from(selected['stock'] as List? ?? const []).take(3).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

class _Question {
  final String keyName;
  final String label;
  final List<String>? options;
  final String? hint;
  final TextInputType keyboardType;

  const _Question({
    required this.keyName,
    required this.label,
    this.options,
    this.hint,
    this.keyboardType = TextInputType.text,
  });
}

class _NearestPlace {
  final String name;
  final double distanceKm;
  final String kind;
  final double lat;
  final double lng;

  const _NearestPlace({
    required this.name,
    required this.distanceKm,
    required this.kind,
    required this.lat,
    required this.lng,
  });
}