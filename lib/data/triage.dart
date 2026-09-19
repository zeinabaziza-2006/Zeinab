/// Shared triage model: what the AI layer and the rule engine both produce.
enum TriageLevel { green, amber, red }

int levelRank(TriageLevel level) {
  switch (level) {
    case TriageLevel.green:
      return 0;
    case TriageLevel.amber:
      return 1;
    case TriageLevel.red:
      return 2;
  }
}

TriageLevel levelFromString(String value) {
  final v = value.toLowerCase().trim();
  if (v == 'red' || v == '2' || v == 'high') return TriageLevel.red;
  if (v == 'amber' || v == 'yellow' || v == '1' || v == 'medium') {
    return TriageLevel.amber;
  }
  return TriageLevel.green;
}

String levelToString(TriageLevel level) {
  switch (level) {
    case TriageLevel.green:
      return 'green';
    case TriageLevel.amber:
      return 'amber';
    case TriageLevel.red:
      return 'red';
  }
}

class TriageFinding {
  final String label;
  final String detail;
  final String severity; // 'info' | 'watch' | 'urgent'
  final String source; // 'image' | 'questionnaire' | 'rule'

  const TriageFinding({
    required this.label,
    required this.detail,
    this.severity = 'watch',
    this.source = 'rule',
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'detail': detail,
        'severity': severity,
        'source': source,
      };

  static TriageFinding fromJson(Map<String, dynamic> json) => TriageFinding(
        label: '${json['label'] ?? ''}',
        detail: '${json['detail'] ?? ''}',
        severity: '${json['severity'] ?? 'watch'}',
        source: '${json['source'] ?? 'rule'}',
      );
}

class TriageResult {
  final TriageLevel level;
  final List<TriageFinding> findings;
  final List<String> advice;
  final String patientSummary;
  final String clinicianSummary;
  final double confidence; // 0..1
  final String photoQuality; // 'good' | 'fair' | 'poor'
  final String source; // 'gemini+rules' | 'rules'
  final String? engineNote;

  const TriageResult({
    required this.level,
    required this.findings,
    required this.advice,
    required this.patientSummary,
    required this.clinicianSummary,
    required this.confidence,
    required this.photoQuality,
    required this.source,
    this.engineNote,
  });

  Map<String, dynamic> toJson() => {
        'level': levelToString(level),
        'findings': findings.map((f) => f.toJson()).toList(),
        'advice': advice,
        'patientSummary': patientSummary,
        'clinicianSummary': clinicianSummary,
        'confidence': confidence,
        'photoQuality': photoQuality,
        'source': source,
        'engineNote': engineNote,
      };

  static TriageResult fromJson(Map<String, dynamic> json) {
    final rawFindings = json['findings'];
    final findings = <TriageFinding>[];
    if (rawFindings is List) {
      for (final item in rawFindings) {
        if (item is Map) {
          findings.add(TriageFinding.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final rawAdvice = json['advice'];
    final advice = <String>[];
    if (rawAdvice is List) {
      for (final item in rawAdvice) {
        advice.add('$item');
      }
    }

    return TriageResult(
      level: levelFromString('${json['level'] ?? 'green'}'),
      findings: findings,
      advice: advice,
      patientSummary: '${json['patientSummary'] ?? ''}',
      clinicianSummary: '${json['clinicianSummary'] ?? ''}',
      confidence: double.tryParse('${json['confidence'] ?? 0.0}') ?? 0.0,
      photoQuality: '${json['photoQuality'] ?? 'fair'}',
      source: '${json['source'] ?? 'rules'}',
      engineNote: json['engineNote'] == null ? null : '${json['engineNote']}',
    );
  }
}
