import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'ai_triage_service.dart';

// ---------------------------------------------------------------------------
// Chifaae System Prompt
// ---------------------------------------------------------------------------
//
// This prompt is sent as the system instruction to every Gemini session.
// It defines the assistant's identity, language rules, triage logic, and
// pharmacy fallback behaviour.
// ---------------------------------------------------------------------------

const _kSystemPrompt = '''
You are Chifaae (شفاء), a warm, professional, and trustworthy Moroccan medical assistant built to help patients in Morocco navigate the healthcare system.
You are explicitly Chifaae, and you must always use the data from assets/data/health_data.json as the source of truth for all doctor and pharmacy recommendations.

## Identity
- Your name is Chifaae (شفاء = "healing" in Arabic).
- You communicate primarily in Moroccan Darija, French, or a natural mix of both — matching whatever language the user writes in.
- You are NOT a replacement for a real doctor. Always remind users to consult a licensed professional for serious conditions.

## Smart Translation (Voice Input Bridge)
The user may speak in Moroccan Darija, French, or a mix (Frarija) via voice input. Translate their spoken input into a clean, professional medical summary in French for the Doctor.
Example: if the user says "Darni rasi bzaf o fiya skhana", interpret this as "Céphalée intense et fièvre".
When you receive voice-transcribed text, first interpret it in the response by restating it as a proper French medical summary before proceeding with triage.

## Symptom Analysis & Triage
When a user describes symptoms, reason step-by-step and then:
1. Map the symptoms to the most appropriate specialist from the three profiles below.
2. State your recommended specialist clearly and explain WHY in 1–2 sentences.
3. Include a "Match Confidence" percentage (0–100%) for your recommendation.

### Specialist Profiles (internal knowledge):
**Dentiste (Dentistry)**
Scope: Toothache, Gum bleeding, Chipped tooth, Jaw swelling
Keywords: tooth, teeth, gum, jaw, mouth, molar, cavity, abscess, dent, gencive, mâchoire

**Cardiologue (Cardiology)**
Scope: Chest pain, Rapid heart rate, Dizziness, Palpitations
Keywords: chest, heart, cardiac, palpitation, tachycardia, dizziness, shortness of breath, coeur, poitrine, vertiges

**Pédiatre (Pediatrics)**
Scope: Child fever, Infant cough, Pediatric rash, General pediatric care
Keywords: child, infant, baby, toddler, newborn, enfant, bébé, nourrisson, vaccination

### Triage Rules:
- If symptoms areambiguous (e.g., "fever", "swelling"), and the user mentions a child (enfant, bébé, nourrisson, my kid, mon fils, ma fille), ALWAYS prioritise the Pédiatre.
- If no specialist matches well (confidence < 30%), recommend a Médecin Généraliste.

## Pharmacy Guidance
If your advice involves medication (e.g., paracetamol, ibuprofen, antibiotics), always add a line suggesting the user visit a nearby pharmacy. Use this list of trusted Moroccan pharmacies:
- **Pharmacie Centrale** – Available in most major cities (Casablanca, Rabat, Marrakech, Fès)
- **Pharmacie de Garde** – 24/7 emergency pharmacy, searchable at www.pharmaciesdegarde.ma
- **Pharmacie Atlas** – Casablanca city centre
- **Pharmacie Al Amal** – Rabat

## Response Format
Structure every response as follows:
1. **Greeting** (warm, brief — optional after first message)
2. **Symptom Summary** – restate the symptoms you understood (in French)
3. **Triage Recommendation** – specialist + confidence %
4. **Advice** – 2–4 actionable bullet points
5. **Pharmacy Note** (only if medication is discussed)
6. **Disclaimer** – one line reminder to see a real doctor for serious cases

Keep responses concise. Avoid medical jargon unless explaining in plain language immediately after.
''';

const _kDiagnosisPrompt = '''
You are Chifaae.
Based on these 10 triage answers, estimate the most likely issue as a probability (example: 80% Flu).
Suggest only one specialist from: Dentist, Cardiologist, Pediatrician.
Mention whether medicine is needed and whether urgent hospital visit is required.
Use assets/data/health_data.json structure (profiles, pharmacies, specialized_centers).
For severe situations (pain > 8 or chest pain), recommend Hôpital Al Idrissi (Provincial) or Clinique Tazi.
For long-term fever and blood-test need, recommend Laboratoire d'Analyses Mimosa.
Respond in French and/or Moroccan Darija.
Return STRICT JSON with this schema only:
{
  "probability": 0,
  "condition": "",
  "specialist": "",
  "needsMedicine": false,
  "medicines": [],
  "urgentHospital": false,
  "locationType": "pharmacy",
  "locationName": "",
  "message": ""
}
''';

// ---------------------------------------------------------------------------
// Message model
// ---------------------------------------------------------------------------

enum MessageRole { user, assistant }

class ChatMessage {
  final MessageRole role;
  final String text;
  final DateTime timestamp;
  final bool usedFastMode;

  const ChatMessage({
    required this.role,
    required this.text,
    required this.timestamp,
    this.usedFastMode = false,
  });
}

class GeminiReply {
  final String text;
  final bool usedFastMode;
  final bool hadApiError;

  const GeminiReply({
    required this.text,
    required this.usedFastMode,
    this.hadApiError = false,
  });
}

class DiagnosisResult {
  final int probability;
  final String condition;
  final String specialist;
  final bool needsMedicine;
  final List<String> medicines;
  final bool urgentHospital;
  final String locationType;
  final String locationName;
  final String message;
  final bool hadApiError;

  const DiagnosisResult({
    required this.probability,
    required this.condition,
    required this.specialist,
    required this.needsMedicine,
    required this.medicines,
    required this.urgentHospital,
    required this.locationType,
    required this.locationName,
    required this.message,
    this.hadApiError = false,
  });
}

// ---------------------------------------------------------------------------
// Gemini Service
// ---------------------------------------------------------------------------

class GeminiService {
  GeminiService._();
  static final GeminiService instance = GeminiService._();

  static const _kGroqEndpoint = 'https://api.groq.com/openai/v1/chat/completions';
  static const _kChatModels = <String>[
    'llama-3.3-70b-versatile',
    'llama-3.1-8b-instant',
  ];
  static const _kDiagnosisModels = <String>[
    'llama-3.3-70b-versatile',
    'llama-3.1-8b-instant',
  ];

  late final String _apiKey;
  bool _initialised = false;

  /// Init with Groq API key.
  void init(String apiKey) {
    if (_initialised) return;
    _apiKey = apiKey;
    _initialised = true;
  }

  /// Send [userMessage] and return the assistant's text response.
  /// Returns a Darija-language error message if the call fails.
  Future<GeminiReply> send(String userMessage) async {
    if (!_initialised) {
      return const GeminiReply(
        text: 'Smahli, l service mazal ma tconnectach. Jarreb mra khra.',
        usedFastMode: false,
        hadApiError: true,
      );
    }

    for (var i = 0; i < _kChatModels.length; i++) {
      final model = _kChatModels[i];
      final text = await _chatCompletion(
        model: model,
        systemPrompt: _kSystemPrompt,
        userPrompt: userMessage,
        temperature: 0.4,
        maxTokens: 800,
      );
      if (text != null && text.trim().isNotEmpty) {
        return GeminiReply(
          text: i == 0 ? text : '$text\n\n_Mode compatibilité activé._',
          usedFastMode: i > 0,
          hadApiError: false,
        );
      }
    }

    return GeminiReply(
      text: _buildOfflineFallback(userMessage),
      usedFastMode: false,
      hadApiError: true,
    );
  }

  String _buildOfflineFallback(String userMessage) {
    final q = userMessage.toLowerCase();
    if (q.contains('fièvre') || q.contains('fievre') || q.contains('fever')) {
      return 'Smahli, l\'API mazal ma khdamatch daba. Hna tawjih moufide:\n'
          '- Pour la fièvre légère: Paracétamol (si ma kaynach contre-indication).\n'
          '- Chrob lma bzzaf, rta7, w qiss l7rara kol 6-8 sa3at.\n'
          '- Ila l7rara b9at ktar men 48 sa3a, wela tl3at bzaaf, sir ltbib.\n'
          '- Ila kayn di9 f tnfass, alam sadr, wela tkhallot, sir l\'urgences daba.';
    }
    try {
      final triage = AiTriageService.instance.analyse(userMessage);
      final top = triage.topMatch;

      if (top == null) {
        return 'Smahli, daba lkhadma dyal l\'IA btiya chwiya. '
            'Mn lma3loumat li 3titi, afdal haja hiya tmchi 3nd '
            'Médecin Généraliste bach ydir lik t9yim mzyan.';
      }

      return 'Smahli, server dyal l\'IA m3emmer daba, walakin hadi tawjih sari3:\n'
          '- Spécialiste recommandé: ${top.specialist.label}\n'
          '- Match Confidence: ${top.confidence}%\n'
          '- Nasiha: ila kanet l7ala katswad, sir l\'urgences.\n'
          '- Pharmacie: qreb Pharmacie de Garde (www.pharmaciesdegarde.ma)\n'
          '- T3awed tconsulti m3a tbib mo5tas bach t2akd men tchkhiS.';
    } catch (e) {
      debugPrint('[GeminiService] Offline fallback error: $e');
      return 'Smahli, kayn da3t f lirtibat daba. '
          'Ila kayn alm qwi, di9 f tnaffos, wela 7rar 3alya, '
          'sir l\'urgences daba.';
    }
  }

  Future<DiagnosisResult> getDiagnosis(Map<String, dynamic> answers) async {
    if (!_initialised) {
      return const DiagnosisResult(
        probability: 0,
        condition: 'Indéterminé',
        specialist: 'Pediatrician',
        needsMedicine: false,
        medicines: [],
        urgentHospital: false,
        locationType: 'pharmacy',
        locationName: '',
        message: 'Service indisponible pour le moment.',
        hadApiError: true,
      );
    }

    try {
      for (final model in _kDiagnosisModels) {
        final text = await _chatCompletion(
          model: model,
          systemPrompt: _kDiagnosisPrompt,
          userPrompt: 'Triage answers JSON: $answers',
          temperature: 0.2,
          maxTokens: 600,
          jsonMode: true,
        );
        if (text == null || text.isEmpty) continue;
        final parsed = _parseDiagnosisJson(text);
        if (parsed != null) {
          return _applyCenterRules(parsed, answers);
        }
      }
    } catch (e) {
      debugPrint('[GeminiService] Diagnosis error: $e');
    }
    return _applyCenterRules(_fallbackDiagnosisFromAnswers(answers), answers);
  }

  Future<String?> _chatCompletion({
    required String model,
    required String systemPrompt,
    required String userPrompt,
    required double temperature,
    required int maxTokens,
    bool jsonMode = false,
  }) async {
    try {
      final body = <String, dynamic>{
        'model': model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': temperature,
        'max_tokens': maxTokens,
      };
      if (jsonMode) {
        body['response_format'] = {'type': 'json_object'};
      }

      final response = await http
          .post(
            Uri.parse(_kGroqEndpoint),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('[GeminiService/Groq] ${response.statusCode}: ${response.body}');
        return null;
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = (decoded['choices'] as List<dynamic>? ?? []);
      if (choices.isEmpty) return null;
      final message = choices.first['message'] as Map<String, dynamic>?;
      final content = (message?['content'] ?? '').toString();
      return content.trim().isEmpty ? null : content;
    } on TimeoutException catch (e) {
      debugPrint('[GeminiService/Groq] timeout on $model: $e');
      return null;
    } catch (e) {
      debugPrint('[GeminiService/Groq] error on $model: $e');
      return null;
    }
  }

  DiagnosisResult? _parseDiagnosisJson(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) return null;
    final jsonPart = raw.substring(start, end + 1);
    try {
      final map = jsonDecode(jsonPart) as Map<String, dynamic>;
      return DiagnosisResult(
        probability: (map['probability'] as num?)?.round() ?? 0,
        condition: (map['condition'] ?? 'Indéterminé').toString(),
        specialist: (map['specialist'] ?? 'Pediatrician').toString(),
        needsMedicine: map['needsMedicine'] == true,
        medicines: List<String>.from(map['medicines'] as List? ?? []),
        urgentHospital: map['urgentHospital'] == true,
        locationType: (map['locationType'] ?? 'pharmacy').toString().toLowerCase(),
        locationName: (map['locationName'] ?? '').toString(),
        message: (map['message'] ?? '').toString(),
        hadApiError: false,
      );
    } catch (_) {
      return null;
    }
  }

  DiagnosisResult _fallbackDiagnosisFromAnswers(Map<String, dynamic> answers) {
    final symptom = (answers['mainSymptom'] ?? '').toString().toLowerCase();
    final isChild = (answers['isChild'] ?? '').toString().toLowerCase() == 'yes';
    final pain = int.tryParse((answers['painLevel'] ?? '').toString()) ?? 0;
    final lostConsciousness =
        (answers['lossOfConsciousness'] ?? '').toString().toLowerCase() == 'yes';
    final nausea = symptom.contains('naus') || symptom.contains('vomis');
    final tenderness = symptom.contains('tendresse') || symptom.contains('localis');

    if (isChild) {
      return const DiagnosisResult(
        probability: 72,
        condition: 'Infection pédiatrique probable',
        specialist: 'Pediatrician',
        needsMedicine: true,
        medicines: ['Paracétamol', 'Sirop Toux'],
        urgentHospital: false,
        locationType: 'pharmacy',
        locationName: '',
        message: 'Probabilité modérée d\'infection. Consultez un pédiatre rapidement.',
        hadApiError: true,
      );
    }

    if (symptom.contains('dent') || symptom.contains('tooth')) {
      return const DiagnosisResult(
        probability: 80,
        condition: 'Infection dentaire possible',
        specialist: 'Dentist',
        needsMedicine: true,
        medicines: ['Amoxicilline', 'Paracétamol'],
        urgentHospital: false,
        locationType: 'pharmacy',
        locationName: '',
        message: 'Prenez rendez-vous chez le dentiste.',
        hadApiError: true,
      );
    }

    if (pain > 8 || lostConsciousness) {
      return const DiagnosisResult(
        probability: 84,
        condition: 'Condition sévère nécessitant une évaluation urgente',
        specialist: 'Généraliste',
        needsMedicine: false,
        medicines: [],
        urgentHospital: true,
        locationType: 'center',
        locationName: 'Hôpital Al Idrissi (Provincial)',
        message: 'Douleur sévère ou perte de conscience. Consultez urgemment.',
        hadApiError: true,
      );
    }

    if (nausea || tenderness) {
      return const DiagnosisResult(
        probability: 70,
        condition: 'Condition gastro-intestinale probable',
        specialist: 'Généraliste',
        needsMedicine: true,
        medicines: ['Paracétamol'],
        urgentHospital: false,
        locationType: 'pharmacy',
        locationName: '',
        message: 'Nausées ou sensibilité locale. Vérifiez avec un médecin.',
        hadApiError: true,
      );
    }

    return const DiagnosisResult(
      probability: 60,
      condition: 'Condition à confirmer',
      specialist: 'Généraliste',
      needsMedicine: false,
      medicines: [],
      urgentHospital: false,
      locationType: 'pharmacy',
      locationName: '',
      message: 'Consultez un professionnel pour confirmer le diagnostic.',
      hadApiError: true,
    );
  }

  DiagnosisResult _applyCenterRules(
    DiagnosisResult base,
    Map<String, dynamic> answers,
  ) {
    final severe = _isSevereCase(answers);
    final needsBloodTest = _needsBloodTest(answers);

    if (needsBloodTest) {
      return DiagnosisResult(
        probability: base.probability,
        condition: base.condition,
        specialist: base.specialist,
        needsMedicine: base.needsMedicine,
        medicines: base.medicines,
        urgentHospital: base.urgentHospital,
        locationType: 'center',
        locationName: "Laboratoire d'Analyses Mimosa",
        message: base.message,
        hadApiError: base.hadApiError,
      );
    }

    if (severe) {
      final chestPain = (answers['chestPain'] ?? '').toString().toLowerCase() == 'yes';
      return DiagnosisResult(
        probability: base.probability,
        condition: base.condition,
        specialist: base.specialist,
        needsMedicine: base.needsMedicine,
        medicines: base.medicines,
        urgentHospital: true,
        locationType: 'center',
        locationName: chestPain
            ? 'Hôpital Al Idrissi (Provincial)'
            : 'Clinique Tazi',
        message: base.message,
        hadApiError: base.hadApiError,
      );
    }

    return DiagnosisResult(
      probability: base.probability,
      condition: base.condition,
      specialist: base.specialist,
      needsMedicine: base.needsMedicine,
      medicines: base.medicines,
      urgentHospital: base.urgentHospital,
      locationType: 'pharmacy',
      locationName: base.locationName,
      message: base.message,
      hadApiError: base.hadApiError,
    );
  }

  bool _isSevereCase(Map<String, dynamic> answers) {
    final pain = int.tryParse((answers['painLevel'] ?? '').toString()) ?? 0;
    final chestPain = (answers['chestPain'] ?? '').toString().toLowerCase() == 'yes';
    return pain > 8 || chestPain;
  }

  bool _needsBloodTest(Map<String, dynamic> answers) {
    final fever = (answers['fever'] ?? '').toString().toLowerCase() == 'yes';
    if (!fever) return false;
    final duration = (answers['duration'] ?? '').toString().toLowerCase();
    return duration.contains('week') ||
        duration.contains('semaine') ||
        duration.contains('long') ||
        duration.contains('10') ||
        duration.contains('14');
  }

  bool get isInitialised => _initialised;
}
