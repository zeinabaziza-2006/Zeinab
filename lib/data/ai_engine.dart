import 'khatwa_store.dart';

enum AlertLevel {
  none,
  yellow,
  red,
}

class AiFinding {
  final AlertLevel level;
  final List<String> reasons;
  final String report;

  const AiFinding({
    required this.level,
    required this.reasons,
    required this.report,
  });

  String get explanation {
    return report;
  }
}

class KhatwaAiEngine {
  static AiFinding analyze(KhatwaStore store) {
    final reasons = <String>[];
    AlertLevel level = AlertLevel.none;

    void red(String reason) {
      reasons.add(reason);
      level = AlertLevel.red;
    }

    void yellow(String reason) {
      reasons.add(reason);

      if (level != AlertLevel.red) {
        level = AlertLevel.yellow;
      }
    }

    // ============================================================
    // TEMPERATURE
    // ============================================================

    double? temperature;
    DateTime? latestTemperatureDate;

    for (final entry in store.entries) {
      if (entry is! Map) continue;

      final type =
          '${entry['type'] ?? entry['field'] ?? ''}'.toLowerCase();

      final possibleValues = <dynamic>[
        entry['temperature'],
        entry['temp'],
        entry['body_temperature'],
        entry['bodyTemperature'],
      ];

      final nestedValue = entry['value'];

      if (nestedValue is Map) {
        possibleValues.add(nestedValue['temperature']);
        possibleValues.add(nestedValue['temp']);
        possibleValues.add(nestedValue['body_temperature']);
        possibleValues.add(nestedValue['bodyTemperature']);
        possibleValues.add(nestedValue['value']);
      } else {
        possibleValues.add(nestedValue);
      }

      double? foundTemperature;

      for (final value in possibleValues) {
        if (value == null) continue;

        final parsed = double.tryParse(
          value.toString().replaceAll(',', '.').trim(),
        );

        if (parsed != null) {
          foundTemperature = parsed;
          break;
        }
      }

      if (foundTemperature == null) continue;

      final looksLikeTemperature =
          type.contains('temperature') ||
          type.contains('temp') ||
          entry.containsKey('temperature') ||
          entry.containsKey('temp') ||
          entry.containsKey('body_temperature') ||
          entry.containsKey('bodyTemperature');

      if (!looksLikeTemperature) continue;

      DateTime? entryDate;

      final rawDate =
          entry['date'] ?? entry['time'] ?? entry['createdAt'];

      if (rawDate != null) {
        entryDate = DateTime.tryParse(rawDate.toString());
      }

      if (temperature == null ||
          (entryDate != null &&
              (latestTemperatureDate == null ||
                  entryDate.isAfter(latestTemperatureDate!)))) {
        temperature = foundTemperature;
        latestTemperatureDate = entryDate;
      }
    }

    if (temperature != null) {
      if (temperature! >= 39 || temperature! < 35) {
        red(
          'Temperature: ${temperature!.toStringAsFixed(1)} °C. '
          'This value needs prompt professional review.',
        );
      } else if (temperature! >= 38 || temperature! < 36) {
        yellow(
          'Temperature: ${temperature!.toStringAsFixed(1)} °C. '
          'This value is outside the usual range and should be monitored.',
        );
      }
    }

    // ============================================================
    // GLYCEMIA
    // ============================================================

    double? glucose;
    String? glucoseUnit;

    for (final entry in store.entries) {
      if (entry is! Map) continue;

      final type =
          '${entry['type'] ?? entry['field'] ?? ''}'.toLowerCase();

      final looksLikeGlucose =
          type.contains('glucose') ||
          type.contains('glycemia') ||
          type.contains('glycémie') ||
          type.contains('glycemie') ||
          type.contains('sugar');

      if (!looksLikeGlucose) continue;

      dynamic value =
          entry['glucose'] ??
          entry['value'] ??
          entry['reading'];

      if (value is Map) {
        value =
            value['glucose'] ??
            value['value'] ??
            value['reading'];
      }

      final parsed = double.tryParse(
        '${value ?? ''}'.replaceAll(',', '.').trim(),
      );

      if (parsed != null) {
        glucose = parsed;
        glucoseUnit =
            '${entry['unit'] ?? entry['glucoseUnit'] ?? 'mg/dL'}';
      }
    }

    if (glucose != null) {
      final unit = (glucoseUnit ?? 'mg/dL').toLowerCase();

      if (unit.contains('mmol')) {
        if (glucose! < 3.0 || glucose! >= 13.9) {
          red(
            'A glucose value was recorded in a very low or very high range.',
          );
        } else if (glucose! < 3.9 || glucose! > 10) {
          yellow(
            'A glucose value was recorded outside the selected usual monitoring range.',
          );
        }
      } else {
        if (glucose! < 54 || glucose! >= 250) {
          red(
            'A glucose value was recorded in a very low or very high range.',
          );
        } else if (glucose! < 70 || glucose! > 180) {
          yellow(
            'A glucose value was recorded outside the selected usual monitoring range.',
          );
        }
      }
    }

    // ============================================================
    // SENSORY
    // ============================================================

    for (final entry in store.entries) {
      if (entry is! Map) continue;

      final type =
          '${entry['type'] ?? ''}'.toLowerCase();

      if (!type.contains('sens')) continue;

      dynamic sensory = entry['sensations'];
      sensory ??= entry['value'];

      if (sensory is Map) {
        final noFeeling = sensory.values.any(
          (value) => value == false,
        );

        if (noFeeling) {
          yellow(
            'The sensory self-check contains a location where feeling was not reported.',
          );
        }
      }
    }

    // ============================================================
    // WELLBEING
    // ============================================================

    for (final entry in store.entries) {
      if (entry is! Map) continue;

      final type =
          '${entry['type'] ?? ''}'.toLowerCase();

      if (!type.contains('wellbeing') &&
          !type.contains('mood')) {
        continue;
      }

      final values = <String>[
        '${entry['note'] ?? ''}',
        '${entry['mood'] ?? ''}',
        '${entry['emotions'] ?? ''}',
        '${entry['emotionKeys'] ?? ''}',
      ].join(' ').toLowerCase();

      if (values.contains('pain') ||
          values.contains('douleur') ||
          values.contains('ألم') ||
          values.contains('وجيعة') ||
          values.contains('very anxious') ||
          values.contains('anxious')) {
        yellow(
          'The wellbeing check indicates pain or significant distress.',
        );
      }
    }

    // ============================================================
    // FINAL RESULT
    // ============================================================

    late final String report;

    if (level == AlertLevel.red) {
      report =
          'RED FLAG\n'
          '${reasons.join('\n')}\n\n'
          'A healthcare professional should review the information promptly.';
    } else if (level == AlertLevel.yellow) {
      report =
          'YELLOW FLAG\n'
          '${reasons.join('\n')}\n\n'
          'Continue monitoring and discuss the findings with a healthcare professional.';
    } else {
      report =
          'No alerts today\n'
          'Keep updating the app every day, continue your exercises and keep taking care of your feet.';
    }

    return AiFinding(
      level: level,
      reasons: reasons,
      report: report,
    );
  }

  static String generateReport(KhatwaStore store) {
    return analyze(store).report;
  }
}