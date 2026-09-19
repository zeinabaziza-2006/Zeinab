import 'dart:convert';

import 'package:flutter/material.dart';

import '../data/ai_engine.dart';
import '../data/khatwa_store.dart';

class SavedAiReportPage extends StatelessWidget {
  final String language;

  const SavedAiReportPage({
    super.key,
    required this.language,
  });

  bool get rtl =>
      language == 'العربية' ||
      language == 'تونسي';

  String text(
    String en,
    String fr,
    String ar,
    String tn,
  ) {
    switch (language) {
      case 'Français':
        return fr;
      case 'العربية':
        return ar;
      case 'تونسي':
        return tn;
      default:
        return en;
    }
  }

  String entryTitle(Map<String, dynamic> entry) {
    switch (entry['type']) {
      case 'temperature':
        return text(
          'Temperature',
          'Température',
          'الحرارة',
          'الحرارة',
        );

      case 'glycemia':
        return text(
          'Blood glucose',
          'Glycémie',
          'سكر الدم',
          'السكر',
        );

      case 'foot_photo':
        return text(
          'Foot photo',
          'Photo du pied',
          'صورة القدم',
          'تصويرة الساق',
        );

      case 'activity':
        return text(
          'Activity',
          'Activité',
          'النشاط',
          'النشاط',
        );

      case 'food':
        return text(
          'Food',
          'Alimentation',
          'الغذاء',
          'الماكلة',
        );

      case 'sensory':
        return text(
          'Foot sensation',
          'Sensibilité du pied',
          'إحساس القدم',
          'إحساس الساق',
        );

      case 'wellbeing':
        return text(
          'Wellbeing',
          'Bien-être',
          'الحالة النفسية',
          'الحالة النفسية',
        );

      case 'appointment_request':
        return text(
          'Appointment',
          'Rendez-vous',
          'موعد',
          'موعد',
        );

      default:
        return entry['type']?.toString() ?? 'Entry';
    }
  }

  String entryDescription(Map<String, dynamic> entry) {
    final type = entry['type'];

    switch (type) {
      case 'temperature':
        return '${entry['value'] ?? '--'} °C';

      case 'glycemia':
        return '${entry['value'] ?? '--'} ${entry['unit'] ?? 'mg/dL'}';

      case 'activity':
        return entry['value']?.toString() ?? '';

      case 'food':
        return entry['meal']?.toString() ??
            entry['description']?.toString() ??
            '';

      case 'sensory':
        final sensations = entry['sensations'];

        if (sensations is Map) {
          final reduced = sensations.entries
              .where((item) => item.value == false)
              .map((item) => item.key.toString())
              .toList();

          if (reduced.isEmpty) {
            return text(
              'All tested areas were reported as felt.',
              'Toutes les zones testées ont été ressenties.',
              'تم الإحساس بكل المناطق المختبرة.',
              'حسّيت بكل المناطق اللي اختبرتهم.',
            );
          }

          return text(
            'Reduced sensation: ${reduced.join(', ')}',
            'Sensibilité réduite : ${reduced.join(', ')}',
            'نقص في الإحساس: ${reduced.join(', ')}',
            'نقص في الإحساس: ${reduced.join(', ')}',
          );
        }

        return '';

      case 'wellbeing':
        final emotions = entry['emotions'];

        if (emotions is List) {
          return emotions.map((e) => e.toString()).join(', ');
        }

        return entry['note']?.toString() ?? '';

      case 'appointment_request':
        return '${entry['doctor'] ?? ''} • ${entry['date'] ?? ''}';

      case 'foot_photo':
        return text(
          'Saved image',
          'Image enregistrée',
          'صورة محفوظة',
          'تصويرة محفوظة',
        );

      default:
        return entry['note']?.toString() ??
            entry['description']?.toString() ??
            '';
    }
  }

  Widget buildPhoto(Map<String, dynamic> entry) {
    final base64Image =
        entry['base64']?.toString() ?? '';

    if (base64Image.isEmpty) {
      return const SizedBox.shrink();
    }

    try {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.memory(
          base64Decode(base64Image),
          height: 190,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = KhatwaStore.instance;

    return Directionality(
      textDirection: rtl
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            text(
              'AI Report',
              'Rapport IA',
              'تقرير الذكاء الاصطناعي',
              'تقرير الذكاء الاصطناعي',
            ),
          ),
        ),
        body: AnimatedBuilder(
          animation: store,
          builder: (context, _) {
            final findings =
                KhatwaAiEngine.analyze(store);

            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🤖 ${text(
                            'Khatwa monitoring report',
                            'Rapport de suivi Khatwa',
                            'تقرير متابعة Khatwa',
                            'تقرير متابعة Khatwa',
                          )}',
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${text(
                            'Patient',
                            'Patient',
                            'المريض',
                            'المريض',
                          )}: ${store.patientName.isEmpty ? '-' : store.patientName}',
                        ),
                        if (store.patientId.isNotEmpty)
                          Text(
                            '${text(
                              'Patient ID',
                              'Identifiant patient',
                              'معرف المريض',
                              'ID المريض',
                            )}: ${store.patientId}',
                          ),
                        if (store.diabetesType.isNotEmpty)
                          Text(
                            '${text(
                              'Diabetes type',
                              'Type de diabète',
                              'نوع السكري',
                              'نوع السكري',
                            )}: ${store.diabetesType}',
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Text(
                          findings.level ==
                                  AlertLevel.red
                              ? '🔴'
                              : findings.level ==
                                      AlertLevel.yellow
                                  ? '🟡'
                                  : '✅',
                          style: const TextStyle(
                            fontSize: 34,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            findings.level ==
                                    AlertLevel.red
                                ? text(
                                    'Red flag',
                                    'Alerte rouge',
                                    'تنبيه أحمر',
                                    'تنبيه أحمر',
                                  )
                                : findings.level ==
                                        AlertLevel.yellow
                                    ? text(
                                        'Needs attention',
                                        'À surveiller',
                                        'يحتاج متابعة',
                                        'يلزم متابعة',
                                      )
                                    : text(
                                        'No alerts today',
                                        'Aucune alerte aujourd’hui',
                                        'لا توجد تنبيهات اليوم',
                                        'ما فما حتى تنبيه اليوم',
                                      ),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  text(
                    'Saved information',
                    'Informations enregistrées',
                    'المعلومات المحفوظة',
                    'المعلومات المحفوظة',
                  ),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                if (store.entries.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        text(
                          'Nothing has been recorded yet.',
                          'Aucune donnée enregistrée.',
                          'لم يتم تسجيل أي بيانات بعد.',
                          'ما تسجل حتى شيء توة.',
                        ),
                      ),
                    ),
                  ),

                ...store.entries.reversed.map(
                  (entry) {
                    final isPhoto =
                        entry['type'] == 'foot_photo';

                    return Card(
                      margin: const EdgeInsets.only(
                        bottom: 12,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  isPhoto ? '📸' : '•',
                                  style: const TextStyle(
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    entryTitle(entry),
                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 7),
                            Text(
                              entryDescription(entry),
                            ),
                            if (isPhoto) ...[
                              const SizedBox(height: 10),
                              buildPhoto(entry),
                            ],
                            if (entry['date'] != null) ...[
                              const SizedBox(height: 7),
                              Text(
                                entry['date']
                                    .toString(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}