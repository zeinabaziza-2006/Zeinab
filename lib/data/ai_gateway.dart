import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'rule_engine.dart';
import 'triage.dart';

/// Gemini multimodal triage layer.
///
/// The key is never hardcoded. It is read, in order, from:
///   1. --dart-define=GEMINI_API_KEY=...  (build time)
///   2. the key the user pastes in Settings (stored on the device only)
///
/// If no key is available, or the call fails, the app falls back to the
/// deterministic rule engine and says so in the report.
class ApiConfig {
  static const String _compileTimeKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  static const String _prefsKey = 'khatwa_gemini_key';

  static String _runtimeKey = '';

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _runtimeKey = prefs.getString(_prefsKey) ?? '';
  }

  static Future<void> setKey(String key) async {
    _runtimeKey = key.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _runtimeKey);
  }

  static String get key {
    if (_runtimeKey.isNotEmpty) return _runtimeKey;
    return _compileTimeKey;
  }

  static bool get hasKey => key.isNotEmpty;

  static String get source {
    if (_runtimeKey.isNotEmpty) return 'device';
    if (_compileTimeKey.isNotEmpty) return 'build';
    return 'none';
  }
}

class CaseImage {
  final String label; // human readable position
  final String base64; // raw base64, no data: prefix
  final String mimeType;

  const CaseImage({
    required this.label,
    required this.base64,
    this.mimeType = 'image/jpeg',
  });
}

class AiGateway {
  /// Models are tried in order, so the demo survives a model being retired.
  static const List<String> _models = [
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-1.5-flash',
  ];

  static const String _endpointBase =
      'https://generativelanguage.googleapis.com/v1beta/models';

  static String _languageName(String lang) {
    switch (lang) {
      case 'العربية':
        return 'Modern Standard Arabic';
      case 'تونسي':
        return 'Tunisian Arabic (derja), written in Arabic script, simple everyday words';
      case 'Français':
        return 'French';
      default:
        return 'English';
    }
  }

  static String buildPrompt({
    required Map<String, dynamic> answers,
    required Map<String, dynamic> profile,
    required List<String> imageLabels,
    required String lang,
  }) {
    final buffer = StringBuffer();

    buffer.writeln(
        'You are a clinical triage assistant for a diabetic foot self-monitoring service used in Tunisian primary care.');
    buffer.writeln(
        'You support DETECTION and TRIAGE only. You never give a diagnosis, never name a disease as confirmed, and never replace the clinician who reviews every case.');
    buffer.writeln();
    buffer.writeln('TASK');
    buffer.writeln(
        'Look at the attached foot photographs and read the self-check answers. Report what is visible, decide a triage level, and write advice.');
    buffer.writeln();
    buffer.writeln('WHAT TO LOOK FOR (early signs, this is the point of the service)');
    buffer.writeln(
        '- redness or localised erythema, callus or hyperkeratosis, fissures or cracked heel, skin colour change, blister, maceration between toes, nail problems, deformity, dry skin, and any open wound or ulcer.');
    buffer.writeln();
    buffer.writeln('TRIAGE RULES');
    buffer.writeln(
        '- red: an open wound or ulcer, spreading redness, suspected infection (pus, bad smell, fever with foot pain), black or very dark tissue, or a wound that the person cannot feel.');
    buffer.writeln(
        '- amber: callus, fissure, blister, new localised redness, colour change, maceration, nail problem, or reported numbness or pain without an open wound.');
    buffer.writeln('- green: nothing of the above is visible or reported.');
    buffer.writeln(
        'If the photographs are too dark, blurred or incomplete to judge, say so in photoQuality and lower confidence. Never conclude that a foot is healthy on a photo you cannot read.');
    buffer.writeln();
    buffer.writeln('SAFETY');
    buffer.writeln(
        '- Never write that the foot is fine or normal. The safe phrasing is that no warning sign was detected in these photos, that the check should continue daily, and when to consult.');
    buffer.writeln('- A clinician validates every case. Say that in the advice when the level is amber or red.');
    buffer.writeln();
    buffer.writeln('PHOTOS PROVIDED, IN ORDER');
    for (var i = 0; i < imageLabels.length; i++) {
      buffer.writeln('${i + 1}. ${imageLabels[i]}');
    }
    buffer.writeln();
    buffer.writeln('PATIENT CONTEXT');
    buffer.writeln(const JsonEncoder().convert(profile));
    buffer.writeln();
    buffer.writeln('SELF-CHECK ANSWERS');
    buffer.writeln(const JsonEncoder().convert(answers));
    buffer.writeln();
    buffer.writeln('OUTPUT');
    buffer.writeln(
        'Return ONLY a JSON object, no markdown fence, no commentary, exactly this shape:');
    buffer.writeln('''{
  "level": "green|amber|red",
  "photoQuality": "good|fair|poor",
  "confidence": 0.0,
  "findings": [
    {"label": "short name of the sign",
     "detail": "one sentence, where it is and what it looks like",
     "severity": "info|watch|urgent",
     "source": "image|questionnaire"}
  ],
  "advice": ["short actionable sentence", "..."],
  "patientSummary": "2 or 3 short sentences addressed to the patient",
  "clinicianSummary": "3 or 4 lines for the reviewing clinician: visible signs, reported symptoms, suggested priority and suggested orientation (SSB or regional hospital)"
}''');
    buffer.writeln();
    buffer.writeln(
        'Write "findings[].label", "findings[].detail", "advice" and "patientSummary" in ${_languageName(lang)}.');
    buffer.writeln('Write "clinicianSummary" in French, the working language of Tunisian clinicians.');
    buffer.writeln('confidence is your own confidence between 0 and 1.');

    return buffer.toString();
  }

  /// Runs the LLM layer, merges it with the deterministic rule engine and
  /// returns a single triage result. Never throws.
  static Future<TriageResult> analyse({
    required List<CaseImage> images,
    required Map<String, dynamic> answers,
    required Map<String, dynamic> profile,
    required String lang,
  }) async {
    final rules = RuleEngine.evaluate(answers: answers, profile: profile, lang: lang);

    if (!ApiConfig.hasKey || images.isEmpty) {
      return rules;
    }

    try {
      final raw = await _callGemini(
        prompt: buildPrompt(
          answers: answers,
          profile: profile,
          imageLabels: images.map((image) => image.label).toList(),
          lang: lang,
        ),
        images: images,
      );

      if (raw == null) return rules;

      final parsed = _parseJson(raw);
      if (parsed == null) return rules;

      final ai = TriageResult.fromJson({
        ...parsed,
        'source': 'gemini+rules',
      });

      return _merge(ai, rules);
    } catch (_) {
      return rules;
    }
  }

  /// The rule engine can only raise the level, never lower what the model saw.
  static TriageResult _merge(TriageResult ai, TriageResult rules) {
    final level =
        levelRank(rules.level) > levelRank(ai.level) ? rules.level : ai.level;

    final findings = <TriageFinding>[...ai.findings];
    for (final finding in rules.findings) {
      final duplicate = findings.any(
        (existing) => existing.label.toLowerCase() == finding.label.toLowerCase(),
      );
      if (!duplicate) findings.add(finding);
    }

    final advice = <String>[...ai.advice];
    for (final item in rules.advice) {
      if (!advice.contains(item)) advice.add(item);
    }

    return TriageResult(
      level: level,
      findings: findings,
      advice: advice,
      patientSummary:
          ai.patientSummary.isNotEmpty ? ai.patientSummary : rules.patientSummary,
      clinicianSummary: ai.clinicianSummary.isNotEmpty
          ? ai.clinicianSummary
          : rules.clinicianSummary,
      confidence: ai.confidence,
      photoQuality: ai.photoQuality,
      source: 'gemini+rules',
      engineNote: levelRank(rules.level) > levelRank(ai.level)
          ? 'Niveau relevé par les règles cliniques'
          : null,
    );
  }

  static Future<String?> _callGemini({
    required String prompt,
    required List<CaseImage> images,
  }) async {
    final parts = <Map<String, dynamic>>[
      {'text': prompt},
    ];

    for (final image in images) {
      parts.add({
        'inline_data': {
          'mime_type': image.mimeType,
          'data': image.base64,
        }
      });
    }

    final body = jsonEncode({
      'contents': [
        {'role': 'user', 'parts': parts}
      ],
      'generationConfig': {
        'temperature': 0.2,
        'maxOutputTokens': 1400,
        'responseMimeType': 'application/json',
      },
      'safetySettings': const <Map<String, String>>[],
    });

    for (final model in _models) {
      try {
        final response = await http
            .post(
              Uri.parse('$_endpointBase/$model:generateContent?key=${ApiConfig.key}'),
              headers: const {'Content-Type': 'application/json'},
              body: body,
            )
            .timeout(const Duration(seconds: 45));

        if (response.statusCode == 404 || response.statusCode == 400) {
          // Model not available for this key: try the next one.
          continue;
        }
        if (response.statusCode != 200) {
          return null;
        }

        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is! Map) return null;

        final candidates = decoded['candidates'];
        if (candidates is! List || candidates.isEmpty) return null;

        final content = candidates.first['content'];
        if (content is! Map) return null;

        final responseParts = content['parts'];
        if (responseParts is! List || responseParts.isEmpty) return null;

        final buffer = StringBuffer();
        for (final part in responseParts) {
          if (part is Map && part['text'] != null) buffer.write(part['text']);
        }
        final text = buffer.toString();
        return text.isEmpty ? null : text;
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  /// Tolerates a stray markdown fence or leading prose around the JSON.
  static Map<String, dynamic>? _parseJson(String raw) {
    var text = raw.trim();

    if (text.startsWith('```')) {
      text = text.replaceFirst(RegExp(r'^```[a-zA-Z]*'), '').trim();
      if (text.endsWith('```')) {
        text = text.substring(0, text.length - 3).trim();
      }
    }

    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    text = text.substring(start, end + 1);

    try {
      final decoded = jsonDecode(text);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
  }

  /// Small call used by the Settings screen to prove the key works.
  static Future<bool> testKey() async {
    if (!ApiConfig.hasKey) return false;
    try {
      final response = await http
          .post(
            Uri.parse(
                '$_endpointBase/${_models.first}:generateContent?key=${ApiConfig.key}'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'role': 'user',
                  'parts': [
                    {'text': 'Reply with the single word: ok'}
                  ]
                }
              ]
            }),
          )
          .timeout(const Duration(seconds: 20));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Free-text assistant used by the chat screen. Returns null on failure.
  static Future<String?> chat({
    required List<Map<String, String>> history,
    required Map<String, dynamic> profile,
    required String lang,
    required bool isDoctor,
  }) async {
    if (!ApiConfig.hasKey) return null;

    final system = StringBuffer();
    system.writeln(
        'You are the Khatwa assistant, part of a diabetic foot self-monitoring service in Tunisia.');
    system.writeln(isDoctor
        ? 'You are talking to a health professional. Be concise, clinical, and reference the patient record given below.'
        : 'You are talking to a patient or their family carer. Use short, warm, simple sentences.');
    system.writeln(
        'You never diagnose and never replace a clinician. For anything urgent (open wound, spreading redness, fever, black tissue) tell the person to contact their SSB or regional hospital now.');
    system.writeln('Answer in ${_languageName(lang)}.');
    system.writeln('Patient record: ${const JsonEncoder().convert(profile)}');

    final contents = <Map<String, dynamic>>[
      {
        'role': 'user',
        'parts': [
          {'text': system.toString()}
        ]
      },
      {
        'role': 'model',
        'parts': [
          {'text': 'Understood.'}
        ]
      },
    ];

    for (final message in history) {
      contents.add({
        'role': message['role'] == 'user' ? 'user' : 'model',
        'parts': [
          {'text': message['text'] ?? ''}
        ]
      });
    }

    for (final model in _models) {
      try {
        final response = await http
            .post(
              Uri.parse('$_endpointBase/$model:generateContent?key=${ApiConfig.key}'),
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode({
                'contents': contents,
                'generationConfig': {'temperature': 0.4, 'maxOutputTokens': 700},
              }),
            )
            .timeout(const Duration(seconds: 40));

        if (response.statusCode != 200) continue;

        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final candidates = decoded is Map ? decoded['candidates'] : null;
        if (candidates is! List || candidates.isEmpty) continue;
        final parts = candidates.first['content']?['parts'];
        if (parts is! List || parts.isEmpty) continue;

        final buffer = StringBuffer();
        for (final part in parts) {
          if (part is Map && part['text'] != null) buffer.write(part['text']);
        }
        final text = buffer.toString().trim();
        if (text.isNotEmpty) return text;
      } catch (_) {
        continue;
      }
    }
    return null;
  }
}
