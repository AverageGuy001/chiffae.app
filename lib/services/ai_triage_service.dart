import 'dart:convert';
import 'package:flutter/services.dart';

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

/// One specialist profile loaded from health_data.json.
class SpecialistProfile {
  final String id;
  final String label;
  final String specialty;
  final String icon;
  final List<String> scopeOfPractice;
  final List<String> keywords;
  final List<String> childTriggers;

  const SpecialistProfile({
    required this.id,
    required this.label,
    required this.specialty,
    required this.icon,
    required this.scopeOfPractice,
    required this.keywords,
    required this.childTriggers,
  });

  factory SpecialistProfile.fromJson(Map<String, dynamic> json) {
    final scope = List<String>.from(
      (json['scope_of_practice'] ?? json['scope'] ?? []) as List,
    );
    final keywords = List<String>.from(json['keywords'] as List? ?? []);
    final id = (json['id'] ?? '').toString();
    final childTriggers = List<String>.from(json['child_triggers'] as List? ?? []);
    if (childTriggers.isEmpty && id == 'pediatrician') {
      childTriggers.addAll(const [
        'child',
        'children',
        'infant',
        'baby',
        'toddler',
        'kid',
        'newborn',
        'enfant',
        'bébé',
        'nourrisson',
        'mon fils',
        'ma fille',
        'mon enfant',
      ]);
    }

    return SpecialistProfile(
      id: id,
      label: (json['label'] ?? json['title'] ?? id).toString(),
      specialty: (json['specialty'] ?? json['title'] ?? id).toString(),
      icon: (json['icon'] ?? 'medical').toString(),
      scopeOfPractice: scope,
      keywords: keywords.isNotEmpty ? keywords : _keywordsFromScope(scope),
      childTriggers: childTriggers,
    );
  }

  static List<String> _keywordsFromScope(List<String> scope) {
    final words = <String>{};
    for (final item in scope) {
      final tokens = item
          .toLowerCase()
          .replaceAll(RegExp(r"[^\w\s']"), ' ')
          .split(RegExp(r'\s+'))
          .where((t) => t.isNotEmpty && t.length > 2);
      words.addAll(tokens);
      words.add(item.toLowerCase());
    }
    return words.toList();
  }
}

/// Result returned for a single specialist after symptom analysis.
class TriageMatch {
  /// The matched specialist profile.
  final SpecialistProfile specialist;

  /// Match confidence in the range [0, 100].
  final int confidence;

  /// The scope items that were triggered by the symptom input.
  final List<String> matchedScopes;

  /// Whether the Pédiatre priority rule was applied.
  final bool pediatricPriorityApplied;

  const TriageMatch({
    required this.specialist,
    required this.confidence,
    required this.matchedScopes,
    this.pediatricPriorityApplied = false,
  });
}

/// Full result of a triage analysis session.
class TriageResult {
  /// All specialists ranked by confidence (highest first).
  final List<TriageMatch> rankedMatches;

  /// The top recommendation (may be null if no match ≥ threshold).
  final TriageMatch? topMatch;

  /// Whether the input was ambiguous (multiple specialists with similar scores).
  final bool isAmbiguous;

  /// Human-readable explanation of the recommendation.
  final String explanation;

  const TriageResult({
    required this.rankedMatches,
    required this.topMatch,
    required this.isAmbiguous,
    required this.explanation,
  });
}

// ---------------------------------------------------------------------------
// Triage service
// ---------------------------------------------------------------------------

/// Pure Dart symptom-to-specialist matching engine.
///
/// Scoring algorithm:
///   1. Tokenise the user's symptom input (lower-case, split on spaces / punctuation).
///   2. Score each specialist on two dimensions:
///        a. **Scope match** – does any scope_of_practice item overlap with the input?
///           Each full scope-item match adds +35 pts.
///        b. **Keyword match** – how many individual keywords are present?
///           Each keyword hit adds +10 pts (capped so total ≤ 100).
///   3. **Pédiatre priority rule**: if the input contains any child_triggers AND
///      another specialist (e.g. Dentiste) is ranked #1 with an ambiguous
///      symptom (fever, swelling, rash), the Pédiatre is boosted to first place
///      and the flag `pediatricPriorityApplied` is set.
///   4. Cap the final confidence at 100.
class AiTriageService {
  AiTriageService._();

  // Singleton
  static final AiTriageService instance = AiTriageService._();

  // Data
  List<SpecialistProfile> _profiles = [];
  bool _loaded = false;

  // Ambiguous symptoms that can belong to multiple specialties
  static const _ambiguousSymptoms = <String>{
    'fever', 'swelling', 'rash', 'pain', 'infection', 'inflammation',
    'fièvre', 'gonflement', 'éruption', 'douleur',
  };

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  /// Must be called once before [analyse] — typically in [main] or a splash screen.
  Future<void> load() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString('assets/data/health_data.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final list = (decoded['profiles'] ?? decoded['specialists']) as List<dynamic>;
    _profiles = list
        .map((e) => SpecialistProfile.fromJson(e as Map<String, dynamic>))
        .toList();
    _loaded = true;
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Analyse [symptomInput] and return a [TriageResult] with ranked matches.
  ///
  /// Throws a [StateError] if [load] has not been awaited first.
  TriageResult analyse(String symptomInput) {
    if (!_loaded) {
      throw StateError(
        'AiTriageService.load() must be awaited before calling analyse().',
      );
    }

    final tokens = _tokenise(symptomInput);
    final inputLower = symptomInput.toLowerCase();
    final hasChildContext = _hasChildContext(tokens, _profiles);

    // Score every specialist
    final matches = <TriageMatch>[];
    for (final profile in _profiles) {
      final (score, matched) = _scoreProfile(profile, tokens, inputLower);
      matches.add(TriageMatch(
        specialist: profile,
        confidence: score,
        matchedScopes: matched,
      ));
    }

    // Sort descending
    matches.sort((a, b) => b.confidence.compareTo(a.confidence));

    // Apply Pédiatre priority rule
    final ranked = _applyPediatricPriority(matches, hasChildContext, tokens);

    // Determine ambiguity: top-2 within 15 pts of each other
    final isAmbiguous = ranked.length >= 2 &&
        ranked[0].confidence > 0 &&
        (ranked[0].confidence - ranked[1].confidence) <= 15;

    final top = ranked.isNotEmpty && ranked[0].confidence > 0
        ? ranked[0]
        : null;

    return TriageResult(
      rankedMatches: ranked,
      topMatch: top,
      isAmbiguous: isAmbiguous,
      explanation: _buildExplanation(top, isAmbiguous, hasChildContext),
    );
  }

  // ---------------------------------------------------------------------------
  // Scoring helpers
  // ---------------------------------------------------------------------------

  /// Returns (finalScore, matchedScopeItems).
  (int, List<String>) _scoreProfile(
    SpecialistProfile profile,
    List<String> tokens,
    String inputLower,
  ) {
    int score = 0;
    final matched = <String>[];

    // --- Scope-of-practice matching (+35 per full scope item hit) ---
    for (final scope in profile.scopeOfPractice) {
      final scopeLower = scope.toLowerCase();
      if (inputLower.contains(scopeLower)) {
        score += 35;
        matched.add(scope);
      } else {
        // Partial: all words of the scope item present in tokens
        final scopeWords = _tokenise(scope);
        if (scopeWords.isNotEmpty &&
            scopeWords.every((w) => tokens.contains(w))) {
          score += 25;
          matched.add(scope);
        }
      }
    }

    // --- Keyword matching (+10 per keyword, capped contribution at 60) ---
    int keywordScore = 0;
    for (final kw in profile.keywords) {
      final kwLower = kw.toLowerCase();
      if (inputLower.contains(kwLower) || tokens.contains(kwLower)) {
        keywordScore += 10;
      }
    }
    score += keywordScore.clamp(0, 60);

    return (score.clamp(0, 100), matched);
  }

  // ---------------------------------------------------------------------------
  // Pédiatre priority rule
  // ---------------------------------------------------------------------------

  List<TriageMatch> _applyPediatricPriority(
    List<TriageMatch> sorted,
    bool hasChildContext,
    List<String> tokens,
  ) {
    if (!hasChildContext) return sorted;

    // Check if the input contains any ambiguous symptom
    final inputIsAmbiguous =
        tokens.any((t) => _ambiguousSymptoms.contains(t));
    if (!inputIsAmbiguous) return sorted;

    // Find Pédiatre entry
    final pediatreIdx = sorted.indexWhere(
      (m) => m.specialist.id == 'pediatre' || m.specialist.id == 'pediatrician',
    );
    if (pediatreIdx <= 0) return sorted; // already first or not found

    final pediatreMatch = sorted[pediatreIdx];

    // Only apply rule if top specialist is NOT already Pédiatre and Pédiatre
    // has at least some confidence
    if (pediatreMatch.confidence == 0) return sorted;

    final boosted = TriageMatch(
      specialist: pediatreMatch.specialist,
      // Boost confidence to just above current leader, capped at 100
      confidence: (sorted[0].confidence + 5).clamp(0, 100),
      matchedScopes: pediatreMatch.matchedScopes,
      pediatricPriorityApplied: true,
    );

    final result = List<TriageMatch>.from(sorted);
    result.removeAt(pediatreIdx);
    result.insert(0, boosted);
    return result;
  }

  // ---------------------------------------------------------------------------
  // Child-context detection
  // ---------------------------------------------------------------------------

  bool _hasChildContext(List<String> tokens, List<SpecialistProfile> profiles) {
    final pediatre = profiles.firstWhere(
      (p) => p.id == 'pediatre' || p.id == 'pediatrician',
      orElse: () => const SpecialistProfile(
        id: '', label: '', specialty: '', icon: '',
        scopeOfPractice: [], keywords: [], childTriggers: [],
      ),
    );
    return pediatre.childTriggers.any(
      (trigger) => tokens.contains(trigger.toLowerCase()),
    );
  }

  // ---------------------------------------------------------------------------
  // Tokeniser
  // ---------------------------------------------------------------------------

  List<String> _tokenise(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r"[^\w\s']"), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Explanation builder
  // ---------------------------------------------------------------------------

  String _buildExplanation(
    TriageMatch? top,
    bool isAmbiguous,
    bool hasChildContext,
  ) {
    if (top == null) {
      return 'No specialist match found for the entered symptoms. '
          'Please consult a general practitioner.';
    }

    final buffer = StringBuffer();
    buffer.write(
      'Recommended specialist: ${top.specialist.label} '
      '(${top.confidence}% match).',
    );

    if (top.matchedScopes.isNotEmpty) {
      buffer.write(
        ' Matched scope: ${top.matchedScopes.join(", ")}.',
      );
    }

    if (top.pediatricPriorityApplied) {
      buffer.write(
        ' Child context detected — Pédiatre prioritised over other specialists.',
      );
    }

    if (isAmbiguous) {
      buffer.write(
        ' Note: symptoms are ambiguous and may overlap with another specialty.',
      );
    }

    return buffer.toString();
  }
}
