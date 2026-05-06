import 'package:flutter/foundation.dart';

/// A referral sent from a Patient's Triage to a Professional.
class Referral {
  final String id;
  final String patientName;
  final int patientAge;
  final String symptomSummary;
  final int severityScore; // 0-10
  final String suggestedSpecialist;
  final String suggestedAction;
  final DateTime timestamp;
  bool accepted;
  bool viewed;

  Referral({
    required this.id,
    required this.patientName,
    required this.patientAge,
    required this.symptomSummary,
    required this.severityScore,
    required this.suggestedSpecialist,
    required this.suggestedAction,
    DateTime? timestamp,
    this.accepted = false,
    this.viewed = false,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Singleton service that bridges Patient Triage → Professional Portal.
class ReferralService {
  ReferralService._();
  static final ReferralService instance = ReferralService._();

  /// All incoming referrals (list is the canonical source).
  final ValueNotifier<List<Referral>> referrals =
      ValueNotifier<List<Referral>>([]);

  /// Pending (unaccepted) referrals.
  List<Referral> get pending =>
      referrals.value.where((r) => !r.accepted).toList();

  /// Accepted referrals.
  List<Referral> get accepted =>
      referrals.value.where((r) => r.accepted).toList();

  /// Add a new referral from the Patient portal.
  void addReferral(Referral referral) {
    referrals.value = [...referrals.value, referral];
  }

  /// Professional accepts a referral → moves to Active Appointments.
  void acceptReferral(int index) {
    final list = [...referrals.value];
    if (index >= list.length) return;
    list[index] = Referral(
      id: list[index].id,
      patientName: list[index].patientName,
      patientAge: list[index].patientAge,
      symptomSummary: list[index].symptomSummary,
      severityScore: list[index].severityScore,
      suggestedSpecialist: list[index].suggestedSpecialist,
      suggestedAction: list[index].suggestedAction,
      timestamp: list[index].timestamp,
      accepted: true,
      viewed: true,
    );
    referrals.value = list;
  }

  /// Mark a referral as viewed (dismisses the "new" pulse).
  void markViewed(int index) {
    final list = [...referrals.value];
    if (index >= list.length) return;
    list[index] = Referral(
      id: list[index].id,
      patientName: list[index].patientName,
      patientAge: list[index].patientAge,
      symptomSummary: list[index].symptomSummary,
      severityScore: list[index].severityScore,
      suggestedSpecialist: list[index].suggestedSpecialist,
      suggestedAction: list[index].suggestedAction,
      timestamp: list[index].timestamp,
      accepted: list[index].accepted,
      viewed: true,
    );
    referrals.value = list;
  }

  /// Number of unviewed referrals (for pulse badge).
  int get unviewedCount =>
      referrals.value.where((r) => !r.viewed).length;

  /// Whether there are new unviewed referrals.
  bool get hasNewReferrals => unviewedCount > 0;
}