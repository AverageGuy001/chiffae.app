import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// ---------------------------------------------------------------------------
// Shared Models
// ---------------------------------------------------------------------------

class MedicineItem {
  final String name;
  bool inStock;
  double price;

  MedicineItem({required this.name, this.inStock = true, this.price = 0.0});
}

class PharmacyInfo {
  final String name;
  final String district;
  final double lat;
  final double lng;
  List<MedicineItem> stock;
  bool isGarde;

  PharmacyInfo({
    required this.name,
    required this.district,
    required this.lat,
    required this.lng,
    List<MedicineItem>? stock,
    this.isGarde = false,
  }) : stock = stock ?? [];
}

class DoctorInfo {
  final String name;
  final String specialty;
  final String clinic;
  bool isAvailable;

  DoctorInfo({
    required this.name,
    required this.specialty,
    required this.clinic,
    this.isAvailable = true,
  });
}

class AnalysisRequest {
  final String id;
  final String patientName;
  final String requestType;
  String status; // pending, completed, cancelled
  final DateTime createdAt;

  AnalysisRequest({
    required this.id,
    required this.patientName,
    required this.requestType,
    this.status = 'pending',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class TriageReferral {
  final String id;
  final String patientName;
  final String symptomSummary;
  final int severity; // 0-10
  final String specialistSuggested;
  final DateTime createdAt;

  TriageReferral({
    required this.id,
    required this.patientName,
    required this.symptomSummary,
    required this.severity,
    required this.specialistSuggested,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

// ---------------------------------------------------------------------------
// Professional Profile (shared)
// ---------------------------------------------------------------------------

class ProfessionalProfile {
  String fullName;
  String profession; // Pharmacist, Generalist, Dentist, etc.
  int yearsOfExperience;
  String location;
  String? profilePictureBase64;
  bool isAvailable247;

  ProfessionalProfile({
    required this.fullName,
    required this.profession,
    required this.yearsOfExperience,
    this.location = 'Kenitra, Maroc',
    this.profilePictureBase64,
    this.isAvailable247 = false,
  });

  /// Determines the role category for dashboard styling
  String get roleCategory {
    final p = profession.toLowerCase();
    if (p.contains('pharmac')) return 'pharmacist';
    if (p.contains('generalist') || p.contains('généraliste')) return 'generalist';
    return 'specialist'; // Dentist, Pediatrician, Cardiologist, etc.
  }
}

// ---------------------------------------------------------------------------
// Role-specific data holders (singletons stored in the service)
// ---------------------------------------------------------------------------

class PharmacistData {
  ValueNotifier<List<MedicineItem>> stockInventory;
  ValueNotifier<List<AnalysisRequest>> urgentRequests;
  ValueNotifier<int> monthlyPatients;

  PharmacistData()
      : stockInventory = ValueNotifier<List<MedicineItem>>([
          MedicineItem(name: 'Amoxicilline', inStock: true, price: 45.0),
          MedicineItem(name: 'Paracétamol', inStock: true, price: 12.0),
          MedicineItem(name: 'Doliprane', inStock: true, price: 15.0),
          MedicineItem(name: 'Aspirine', inStock: false, price: 18.0),
          MedicineItem(name: 'Spasfon', inStock: true, price: 22.0),
          MedicineItem(name: 'Vitamine C', inStock: true, price: 35.0),
          MedicineItem(name: 'Oméprazole', inStock: true, price: 28.0),
          MedicineItem(name: 'Ventoline', inStock: false, price: 55.0),
        ]),
        urgentRequests = ValueNotifier<List<AnalysisRequest>>([
          AnalysisRequest(
              id: 'URG-001',
              patientName: 'Fatima Zahra',
              requestType: 'Paracétamol – Garde',
              status: 'pending'),
          AnalysisRequest(
              id: 'URG-002',
              patientName: 'Youssef Benali',
              requestType: 'Amoxicilline – Garde',
              status: 'pending'),
        ]),
        monthlyPatients = ValueNotifier<int>(124);
}

class GeneralistData {
  ValueNotifier<List<TriageReferral>> triageReferrals;
  ValueNotifier<String> consultationNotes;
  ValueNotifier<int> waitTimeMinutes; // Estimated wait time
  ValueNotifier<int> monthlyPatients;

  GeneralistData()
      : triageReferrals = ValueNotifier<List<TriageReferral>>([
          TriageReferral(
              id: 'REF-001',
              patientName: 'Amine El Fassi',
              symptomSummary: 'Fièvre persistante + toux sèche depuis 5 jours',
              severity: 6,
              specialistSuggested: 'Généraliste'),
          TriageReferral(
              id: 'REF-002',
              patientName: 'Nadia Ouazzani',
              symptomSummary: 'Fatigue générale, maux de tête fréquents',
              severity: 4,
              specialistSuggested: 'Généraliste'),
          TriageReferral(
              id: 'REF-003',
              patientName: 'Karim Tazi',
              symptomSummary: 'Douleurs abdominales + nausées',
              severity: 7,
              specialistSuggested: 'Généraliste'),
        ]),
        consultationNotes = ValueNotifier<String>(''),
        waitTimeMinutes = ValueNotifier<int>(15),
        monthlyPatients = ValueNotifier<int>(89);
}

class SpecialistData {
  ValueNotifier<List<Appointment>> appointments;
  ValueNotifier<List<ProcedureService>> procedureServices;
  ValueNotifier<List<PatientRecord>> patientRecords;
  ValueNotifier<int> monthlyPatients;

  SpecialistData()
      : appointments = ValueNotifier<List<Appointment>>([
          Appointment(
              id: 'APT-001',
              patientName: 'Sara Benali',
              time: '09:00',
              procedure: 'Nettoyage dentaire',
              status: 'confirmed'),
          Appointment(
              id: 'APT-002',
              patientName: 'Mohamed Rafik',
              time: '10:30',
              procedure: 'Extraction',
              status: 'confirmed'),
          Appointment(
              id: 'APT-003',
              patientName: 'Leila Amrani',
              time: '14:00',
              procedure: 'Détartrage',
              status: 'pending'),
          Appointment(
              id: 'APT-004',
              patientName: 'Hassan Ouadih',
              time: '15:30',
              procedure: 'Consultation',
              status: 'confirmed'),
        ]),
        procedureServices = ValueNotifier<List<ProcedureService>>([
          ProcedureService(name: 'Nettoyage dentaire', price: 250.0, isActive: true),
          ProcedureService(name: 'Extraction', price: 400.0, isActive: true),
          ProcedureService(name: 'Détartrage', price: 200.0, isActive: true),
          ProcedureService(name: 'Blanchiment', price: 800.0, isActive: false),
          ProcedureService(name: 'Dévitalisation', price: 600.0, isActive: true),
          ProcedureService(name: 'Couronne dentaire', price: 1500.0, isActive: false),
        ]),
        patientRecords = ValueNotifier<List<PatientRecord>>([
          PatientRecord(
              id: 'PAT-001',
              name: 'Sara Benali',
              lastVisit: '2026-04-28',
              notes: 'Extraction molaire #24. Suivi dans 2 semaines.'),
          PatientRecord(
              id: 'PAT-002',
              name: 'Mohamed Rafik',
              lastVisit: '2026-05-01',
              notes: 'Détartrage complet. Bonne hygiène buccale.'),
          PatientRecord(
              id: 'PAT-003',
              name: 'Leila Amrani',
              lastVisit: '2026-04-15',
              notes: 'Carie #16 à surveiller. Sensibilité au chaud.'),
        ]),
        monthlyPatients = ValueNotifier<int>(56);
}

class Appointment {
  final String id;
  final String patientName;
  final String time;
  final String procedure;
  final String status;

  Appointment({
    required this.id,
    required this.patientName,
    required this.time,
    required this.procedure,
    this.status = 'confirmed',
  });
}

class ProcedureService {
  final String name;
  double price;
  bool isActive;

  ProcedureService({
    required this.name,
    required this.price,
    this.isActive = true,
  });
}

class PatientRecord {
  final String id;
  final String name;
  final String lastVisit;
  final String notes;

  PatientRecord({
    required this.id,
    required this.name,
    required this.lastVisit,
    required this.notes,
  });
}

// ---------------------------------------------------------------------------
// Singleton Service
// ---------------------------------------------------------------------------

class PharmacyDataService {
  PharmacyDataService._();
  static final PharmacyDataService instance = PharmacyDataService._();

  bool _loaded = false;

  // --- Shared data ---
  final ValueNotifier<List<PharmacyInfo>> pharmacies =
      ValueNotifier<List<PharmacyInfo>>([]);
  final ValueNotifier<List<DoctorInfo>> doctors =
      ValueNotifier<List<DoctorInfo>>([]);
  final ValueNotifier<List<AnalysisRequest>> analysisRequests =
      ValueNotifier<List<AnalysisRequest>>([]);
  final ValueNotifier<ProfessionalProfile?> currentProfessional =
      ValueNotifier<ProfessionalProfile?>(null);

  final ValueNotifier<double> averageRating = ValueNotifier<double>(4.8);
  final ValueNotifier<int> profileDiscoveryRate = ValueNotifier<int>(32);

  // --- Role-specific data ---
  PharmacistData pharmacist = PharmacistData();
  GeneralistData generalist = GeneralistData();
  SpecialistData specialist = SpecialistData();

  Future<void> load() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString('assets/data/health_data.json');
    final map = jsonDecode(raw) as Map<String, dynamic>;

    final pharmacyList = (map['pharmacies'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    pharmacies.value = pharmacyList.map((p) {
      final stockList = (p['stock'] as List<dynamic>? ?? [])
          .map((m) => MedicineItem(name: m.toString()))
          .toList();
      return PharmacyInfo(
        name: (p['name'] ?? '').toString(),
        district: (p['district'] ?? '').toString(),
        lat: (p['lat'] as num).toDouble(),
        lng: (p['lng'] as num).toDouble(),
        stock: stockList,
        isGarde: (p['isGarde'] as bool?) ?? false,
      );
    }).toList();

    final profiles = (map['profiles'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    doctors.value = profiles.map((p) {
      return DoctorInfo(
        name: (p['title'] ?? p['id'] ?? '').toString(),
        specialty: (p['title'] ?? '').toString(),
        clinic: 'Cabinet principal',
        isAvailable: true,
      );
    }).toList();

    _loaded = true;
  }

  // ---------------------------------------------------------------------------
  // Professional profile actions
  // ---------------------------------------------------------------------------

  void setupProfessional(ProfessionalProfile profile) {
    currentProfessional.value = profile;
    if (profile.roleCategory == 'pharmacist') {
      _syncGardeToPharmacies(profile.isAvailable247);
    }
  }

  void toggleProfessionalAvailability() {
    final current = currentProfessional.value;
    if (current == null) return;
    final updated = ProfessionalProfile(
      fullName: current.fullName,
      profession: current.profession,
      yearsOfExperience: current.yearsOfExperience,
      location: current.location,
      profilePictureBase64: current.profilePictureBase64,
      isAvailable247: !current.isAvailable247,
    );
    currentProfessional.value = updated;
    if (updated.roleCategory == 'pharmacist') {
      _syncGardeToPharmacies(updated.isAvailable247);
    }
  }

  void _syncGardeToPharmacies(bool isGarde) {
    final list = [...pharmacies.value];
    if (list.isNotEmpty) {
      list[0] = PharmacyInfo(
        name: list[0].name,
        district: list[0].district,
        lat: list[0].lat,
        lng: list[0].lng,
        stock: list[0].stock,
        isGarde: isGarde,
      );
      pharmacies.value = list;
    }
  }

  /// Get the accent color for the current professional's role
  Color get roleColor {
    final cat = currentProfessional.value?.roleCategory ?? 'pharmacist';
    switch (cat) {
      case 'generalist':
        return const Color(0xFF1A5F9E);
      case 'specialist':
        return const Color(0xFF0D7377);
      default:
        return const Color(0xFF046307);
    }
  }

  String get roleColorName {
    final cat = currentProfessional.value?.roleCategory ?? 'pharmacist';
    switch (cat) {
      case 'generalist':
        return 'generalistBlue';
      case 'specialist':
        return 'specialistTeal';
      default:
        return 'pharmacistGreen';
    }
  }

  // ---------------------------------------------------------------------------
  // Pharmacist-specific actions
  // ---------------------------------------------------------------------------

  void setMedicinePrice(int index, double price) {
    final list = [...pharmacist.stockInventory.value];
    if (index >= list.length) return;
    list[index] = MedicineItem(
      name: list[index].name,
      inStock: list[index].inStock,
      price: price,
    );
    pharmacist.stockInventory.value = list;
  }

  void toggleMedicineInStock(int index) {
    final list = [...pharmacist.stockInventory.value];
    if (index >= list.length) return;
    list[index] = MedicineItem(
      name: list[index].name,
      inStock: !list[index].inStock,
      price: list[index].price,
    );
    pharmacist.stockInventory.value = list;
    // Sync to global pharmacy list
    _syncMedicineToPharmacy(list[index].name, list[index].inStock);
  }

  void _syncMedicineToPharmacy(String medName, bool inStock) {
    final list = [...pharmacies.value];
    for (var i = 0; i < list.length; i++) {
      final p = list[i];
      final updatedStock = p.stock.map((m) {
        if (m.name == medName) {
          return MedicineItem(name: m.name, inStock: inStock, price: m.price);
        }
        return MedicineItem(name: m.name, inStock: m.inStock, price: m.price);
      }).toList();
      list[i] = PharmacyInfo(
        name: p.name,
        district: p.district,
        lat: p.lat,
        lng: p.lng,
        stock: updatedStock,
        isGarde: p.isGarde,
      );
    }
    pharmacies.value = list;
  }

  void resolveUrgentRequest(int index) {
    final list = [...pharmacist.urgentRequests.value];
    if (index >= list.length) return;
    list[index].status = 'completed';
    pharmacist.urgentRequests.value = list;
  }

  // ---------------------------------------------------------------------------
  // Generalist-specific actions
  // ---------------------------------------------------------------------------

  void saveConsultationNotes(String notes) {
    generalist.consultationNotes.value = notes;
  }

  void setWaitTime(int minutes) {
    generalist.waitTimeMinutes.value = minutes.clamp(0, 240);
  }

  void resolveReferral(int index) {
    final list = [...generalist.triageReferrals.value];
    if (index >= list.length) return;
    // Remove it from inbox
    list.removeAt(index);
    generalist.triageReferrals.value = list;
  }

  // ---------------------------------------------------------------------------
  // Specialist-specific actions
  // ---------------------------------------------------------------------------

  void toggleProcedureService(int index) {
    final list = [...specialist.procedureServices.value];
    if (index >= list.length) return;
    list[index] = ProcedureService(
      name: list[index].name,
      price: list[index].price,
      isActive: !list[index].isActive,
    );
    specialist.procedureServices.value = list;
  }

  void setProcedurePrice(int index, double price) {
    final list = [...specialist.procedureServices.value];
    if (index >= list.length) return;
    list[index] = ProcedureService(
      name: list[index].name,
      price: price,
      isActive: list[index].isActive,
    );
    specialist.procedureServices.value = list;
  }

  // ---------------------------------------------------------------------------
  // Query helpers
  // ---------------------------------------------------------------------------

  List<PharmacyInfo> pharmaciesWithStock(String medicineName) {
    return pharmacies.value.where((p) {
      return p.stock.any((m) =>
          m.inStock &&
          m.name.toLowerCase().contains(medicineName.toLowerCase()));
    }).toList();
  }

  List<PharmacyInfo> get gardePharmacies =>
      pharmacies.value.where((p) => p.isGarde).toList();

  bool get isProfessionalOpenNow =>
      currentProfessional.value?.isAvailable247 ?? false;
}