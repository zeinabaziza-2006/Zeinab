import 'package:flutter/material.dart';

import '../data/khatwa_store.dart';

import 'ai_chatbot.dart';
import 'doctor_network.dart';
import 'foot_photo.dart';
import 'glycemia.dart';
import 'wellbeing.dart';
import 'feature_pages.dart';
import 'saved_ai_report.dart';

class PatientDashboardPage extends StatefulWidget {
  final String language;

  const PatientDashboardPage({
    super.key,
    required this.language,
  });

  @override
  State<PatientDashboardPage> createState() =>
      _PatientDashboardPageState();
}

class _PatientDashboardPageState
    extends State<PatientDashboardPage> {
  final store = KhatwaStore.instance;

  bool get rtl =>
      widget.language == 'العربية' ||
      widget.language == 'تونسي';

  String text(
    String en,
    String fr,
    String ar,
    String tn,
  ) {
    switch (widget.language) {
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

  Widget feature({
    required String emoji,
    required String title,
    required String subtitle,
    required Widget page,
  }) {
    return Card(
      elevation: 1.5,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => page,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 10,
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Text(
                emoji,
                style: const TextStyle(
                  fontSize: 29,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget alertCard() {
    bool red = false;
    bool yellow = false;

    for (final entry in store.entries) {
      if (entry['alert'] == 'red') {
        red = true;
      }

      if (entry['alert'] == 'yellow') {
        yellow = true;
      }
    }

    if (red) {
      return Card(
        color: Colors.red.shade50,
        child: const Padding(
          padding: EdgeInsets.all(15),
          child: Row(
            children: [
              Text(
                '🔴',
                style: TextStyle(fontSize: 30),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Red flag — please review your recent information.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (yellow) {
      return Card(
        color: Colors.orange.shade50,
        child: const Padding(
          padding: EdgeInsets.all(15),
          child: Row(
            children: [
              Text(
                '🟡',
                style: TextStyle(fontSize: 30),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Needs attention — keep monitoring your information.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            const Text(
              '✅',
              style: TextStyle(fontSize: 30),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text(
                  'No alerts today. Keep taking care of your feet.',
                  'Aucune alerte aujourd’hui. Continuez à prendre soin de vos pieds.',
                  'لا توجد تنبيهات اليوم. استمر في العناية بقدميك.',
                  'ما فما حتى تنبيه اليوم. واصل اعتني بساقيك.',
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F9FB),
        appBar: AppBar(
          title: const Text(
            '🦶 Khatwa',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: AnimatedBuilder(
          animation: store,
          builder: (context, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                14,
                14,
                14,
                24,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    text(
                      'Hello 👋',
                      'Bonjour 👋',
                      'مرحبا 👋',
                      'عسلامة 👋',
                    ),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    store.patientName.isEmpty
                        ? text(
                            'Take care of your feet every day.',
                            'Prenez soin de vos pieds chaque jour.',
                            'اعتنِ بقدميك كل يوم.',
                            'اعتني بساقيك كل نهار.',
                          )
                        : store.patientName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  alertCard(),

                  const SizedBox(height: 14),

                  Text(
                    text(
                      'Daily monitoring',
                      'Suivi quotidien',
                      'المتابعة اليومية',
                      'المتابعة اليومية',
                    ),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 9),

                  GridView.extent(
                    maxCrossAxisExtent: 185,
                    mainAxisExtent: 108,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    children: [
                      feature(
                        emoji: '🌡️',
                        title: text(
                          'Temperature',
                          'Température',
                          'الحرارة',
                          'الحرارة',
                        ),
                        subtitle: text(
                          'Foot temperature',
                          'Température du pied',
                          'حرارة القدم',
                          'حرارة الساق',
                        ),
                        page: TemperaturePage(
                          language: widget.language,
                        ),
                      ),

                      feature(
                        emoji: '🩸',
                        title: text(
                          'Glycemia',
                          'Glycémie',
                          'سكر الدم',
                          'السكر',
                        ),
                        subtitle: text(
                          'Record glucose',
                          'Enregistrer la glycémie',
                          'سجل السكر',
                          'سجل السكر',
                        ),
                        page: GlycemiaPage(
                          language: widget.language,
                        ),
                      ),

                      feature(
                        emoji: '📸',
                        title: text(
                          'Foot photo',
                          'Photo du pied',
                          'صورة القدم',
                          'تصويرة الساق',
                        ),
                        subtitle: text(
                          'Save foot photos',
                          'Enregistrer des photos',
                          'احفظ صور القدم',
                          'احفظ تصاور الساق',
                        ),
                        page: FootPhotoPage(
                          language: widget.language,
                        ),
                      ),

                      feature(
                        emoji: '🚶',
                        title: text(
                          'Activity',
                          'Activité',
                          'النشاط',
                          'النشاط',
                        ),
                        subtitle: text(
                          'Track activity',
                          'Suivre l’activité',
                          'تتبع النشاط',
                          'تابع النشاط',
                        ),
                        page: ActivityPage(
                          language: widget.language,
                        ),
                      ),

                      feature(
                        emoji: '🍽️',
                        title: text(
                          'Food',
                          'Alimentation',
                          'الغذاء',
                          'الماكلة',
                        ),
                        subtitle: text(
                          'Record meals',
                          'Enregistrer les repas',
                          'سجل الوجبات',
                          'سجل الماكلة',
                        ),
                        page: FoodPage(
                          language: widget.language,
                        ),
                      ),

                      feature(
                        emoji: '🦶',
                        title: text(
                          'Sensation',
                          'Sensibilité',
                          'الإحساس',
                          'الإحساس',
                        ),
                        subtitle: text(
                          'Check sensation',
                          'Tester la sensibilité',
                          'اختبر الإحساس',
                          'اختبر الإحساس',
                        ),
                        page: SensoryPage(
                          language: widget.language,
                        ),
                      ),

                      feature(
                        emoji: '😊',
                        title: text(
                          'Wellbeing',
                          'Bien-être',
                          'الحالة النفسية',
                          'الحالة النفسية',
                        ),
                        subtitle: text(
                          'How are you feeling?',
                          'Comment vous sentez-vous ?',
                          'كيف تشعر اليوم؟',
                          'كيفاش تحس اليوم؟',
                        ),
                        page: WellbeingPage(
                          language: widget.language,
                        ),
                      ),

                      feature(
                        emoji: '🤖',
                        title: 'Khatwa AI',
                        subtitle: text(
                          'Ask the AI assistant',
                          'Parler à l’assistant IA',
                          'تحدث مع المساعد',
                          'احكي مع المساعد',
                        ),
                        page: AiChatbotPage(
                          language: widget.language,
                          role: 'patient',
                        ),
                      ),

                      feature(
                        emoji: '📋',
                        title: text(
                          'AI Report',
                          'Rapport IA',
                          'تقرير الذكاء الاصطناعي',
                          'تقرير الذكاء الاصطناعي',
                        ),
                        subtitle: text(
                          'Everything you saved',
                          'Tout ce que vous avez enregistré',
                          'كل ما حفظته',
                          'كل شيء حفظتو',
                        ),
                        page: SavedAiReportPage(
                          language: widget.language,
                        ),
                      ),

                      feature(
                        emoji: '👨‍⚕️',
                        title: text(
                          'Find a doctor',
                          'Trouver un médecin',
                          'ابحث عن طبيب',
                          'لقى طبيب',
                        ),
                        subtitle: text(
                          'Connect with a doctor',
                          'Contacter un médecin',
                          'تواصل مع الطبيب',
                          'تواصل مع طبيب',
                        ),
                        page: DoctorNetworkPage(
                          language: widget.language,
                        ),
                      ),

                      feature(
                        emoji: '📅',
                        title: text(
                          'Appointments',
                          'Rendez-vous',
                          'المواعيد',
                          'المواعيد',
                        ),
                        subtitle: text(
                          'Manage appointments',
                          'Gérer les rendez-vous',
                          'إدارة المواعيد',
                          'إدارة المواعيد',
                        ),
                        page: AppointmentsPage(
                          language: widget.language,
                        ),
                      ),

                      feature(
                        emoji: '🏃',
                        title: text(
                          'Exercises',
                          'Exercices',
                          'التمارين',
                          'التمارين',
                        ),
                        subtitle: text(
                          'Foot exercises',
                          'Exercices du pied',
                          'تمارين القدم',
                          'تمارين الساق',
                        ),
                        page: ExercisesPage(
                          language: widget.language,
                        ),
                      ),

                      feature(
                        emoji: '🎥',
                        title: text(
                          'Videos',
                          'Vidéos',
                          'الفيديوهات',
                          'الفيديوهات',
                        ),
                        subtitle: text(
                          'Helpful videos',
                          'Vidéos utiles',
                          'فيديوهات مفيدة',
                          'فيديوهات مفيدة',
                        ),
                        page: VideosPage(
                          language: widget.language,
                        ),
                      ),

                      feature(
                        emoji: '💡',
                        title: text(
                          'Tips',
                          'Conseils',
                          'نصائح',
                          'نصائح',
                        ),
                        subtitle: text(
                          'Daily foot care',
                          'Soins quotidiens',
                          'العناية اليومية',
                          'العناية اليومية',
                        ),
                        page: TipsPage(
                          language: widget.language,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}