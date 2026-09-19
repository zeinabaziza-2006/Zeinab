import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/khatwa_store.dart';
import '../data/ai_engine.dart';

class BasePage extends StatelessWidget {
  final String title;
  final Widget child;

  const BasePage({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: child,
        ),
      ),
    );
  }
}

/* ============================================================
   TEMPERATURE
============================================================ */

class TemperaturePage extends StatefulWidget {
  final String language;

  const TemperaturePage({super.key, required this.language});

  @override
  State<TemperaturePage> createState() => _TemperaturePageState();
}

class _TemperaturePageState extends State<TemperaturePage> {
  final store = KhatwaStore.instance;
  final controller = TextEditingController();

  String text(String en, String fr, String ar, String tn) {
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

  Future<void> save() async {
    final value = double.tryParse(controller.text.replaceAll(',', '.'));

    if (value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            text(
              'Enter a valid temperature.',
              'Entrez une température valide.',
              'أدخل درجة حرارة صحيحة.',
              'دخل درجة حرارة صحيحة.',
            ),
          ),
        ),
      );
      return;
    }

    await store.addEntry({
      'type': 'temperature',
      'temperature': value,
      'temperatureNote': '',
      'date': DateTime.now().toIso8601String(),
    });

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: text(
        'Temperature',
        'Température',
        'درجة الحرارة',
        'الحرارة',
      ),
      child: Column(
        children: [
          const Icon(Icons.thermostat, size: 70),
          const SizedBox(height: 20),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: text(
                'Temperature °C',
                'Température °C',
                'درجة الحرارة °C',
                'الحرارة °C',
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: save,
              child: Text(
                text('Save', 'Enregistrer', 'حفظ', 'سجّل'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ============================================================
   ACTIVITY
============================================================ */

class ActivityPage extends StatefulWidget {
  final String language;

  const ActivityPage({super.key, required this.language});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  final store = KhatwaStore.instance;
  final description = TextEditingController();
  final duration = TextEditingController();
  final distance = TextEditingController();

  String text(String en, String fr, String ar, String tn) {
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

  Future<void> save() async {
    await store.addEntry({
      'type': 'activity',
      'activity': description.text,
      'duration': duration.text,
      'distance': distance.text,
      'date': DateTime.now().toIso8601String(),
    });

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: text('Activity', 'Activité', 'النشاط', 'النشاط'),
      child: Column(
        children: [
          TextField(
            controller: description,
            decoration: InputDecoration(
              labelText: text(
                'Activity',
                'Activité',
                'النشاط',
                'شنوة عملت؟',
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: duration,
            decoration: InputDecoration(
              labelText: text(
                'Duration',
                'Durée',
                'المدة',
                'قداش من وقت؟',
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: distance,
            decoration: InputDecoration(
              labelText: text(
                'Distance',
                'Distance',
                'المسافة',
                'المسافة',
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: save,
            child: Text(
              text('Save', 'Enregistrer', 'حفظ', 'سجّل'),
            ),
          ),
        ],
      ),
    );
  }
}

/* ============================================================
   FOOD
============================================================ */

class FoodPage extends StatefulWidget {
  final String language;

  const FoodPage({super.key, required this.language});

  @override
  State<FoodPage> createState() => _FoodPageState();
}

class _FoodPageState extends State<FoodPage> {
  final store = KhatwaStore.instance;
  final controller = TextEditingController();

  String text(String en, String fr, String ar, String tn) {
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

  Future<void> save() async {
    await store.addEntry({
      'type': 'food',
      'food': controller.text,
      'date': DateTime.now().toIso8601String(),
    });

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: text('Food', 'Alimentation', 'الغذاء', 'الماكلة'),
      child: Column(
        children: [
          TextField(
            controller: controller,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: text(
                'What did you eat?',
                'Qu’avez-vous mangé ?',
                'ماذا أكلت؟',
                'شنوة كلّيت؟',
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: save,
            child: Text(
              text('Save', 'Enregistrer', 'حفظ', 'سجّل'),
            ),
          ),
        ],
      ),
    );
  }
}

/* ============================================================
   SENSORY TEST
============================================================ */

class SensoryPage extends StatefulWidget {
  final String language;

  const SensoryPage({super.key, required this.language});

  @override
  State<SensoryPage> createState() => _SensoryPageState();
}

class _SensoryPageState extends State<SensoryPage> {
  final store = KhatwaStore.instance;

  final Map<String, bool> sensations = {
    'left_big_toe': true,
    'left_second_toe': true,
    'left_middle_toe': true,
    'left_fourth_toe': true,
    'left_little_toe': true,
    'right_big_toe': true,
    'right_second_toe': true,
    'right_middle_toe': true,
    'right_fourth_toe': true,
    'right_little_toe': true,
    'left_sole': true,
    'right_sole': true,
    'left_heel': true,
    'right_heel': true,
  };

  String text(String en, String fr, String ar, String tn) {
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

  String locationName(String key) {
    final names = {
      'left_big_toe': [
        'Left big toe',
        'Gros orteil gauche',
        'إبهام القدم اليسرى',
        'صبع الرجل الكبير اليسار',
      ],
      'left_second_toe': [
        'Left second toe',
        'Deuxième orteil gauche',
        'الإصبع الثاني للقدم اليسرى',
        'الصبع الثاني متاع الرجل اليسار',
      ],
      'left_middle_toe': [
        'Left middle toe',
        'Orteil central gauche',
        'الإصبع الأوسط للقدم اليسرى',
        'الصبع الوسطاني متاع الرجل اليسار',
      ],
      'left_fourth_toe': [
        'Left fourth toe',
        'Quatrième orteil gauche',
        'الإصبع الرابع للقدم اليسرى',
        'الصبع الرابع متاع الرجل اليسار',
      ],
      'left_little_toe': [
        'Left little toe',
        'Petit orteil gauche',
        'الخنصر للقدم اليسرى',
        'الصبع الصغير متاع الرجل اليسار',
      ],
      'right_big_toe': [
        'Right big toe',
        'Gros orteil droit',
        'إبهام القدم اليمنى',
        'صبع الرجل الكبير اليمين',
      ],
      'right_second_toe': [
        'Right second toe',
        'Deuxième orteil droit',
        'الإصبع الثاني للقدم اليمنى',
        'الصبع الثاني متاع الرجل اليمين',
      ],
      'right_middle_toe': [
        'Right middle toe',
        'Orteil central droit',
        'الإصبع الأوسط للقدم اليمنى',
        'الصبع الوسطاني متاع الرجل اليمين',
      ],
      'right_fourth_toe': [
        'Right fourth toe',
        'Quatrième orteil droit',
        'الإصبع الرابع للقدم اليمنى',
        'الصبع الرابع متاع الرجل اليمين',
      ],
      'right_little_toe': [
        'Right little toe',
        'Petit orteil droit',
        'الخنصر للقدم اليمنى',
        'الصبع الصغير متاع الرجل اليمين',
      ],
      'left_sole': [
        'Left sole',
        'Plante du pied gauche',
        'باطن القدم اليسرى',
        'باطن الرجل اليسار',
      ],
      'right_sole': [
        'Right sole',
        'Plante du pied droit',
        'باطن القدم اليمنى',
        'باطن الرجل اليمين',
      ],
      'left_heel': [
        'Left heel',
        'Talon gauche',
        'كعب القدم اليسرى',
        'كعب الرجل اليسار',
      ],
      'right_heel': [
        'Right heel',
        'Talon droit',
        'كعب القدم اليمنى',
        'كعب الرجل اليمين',
      ],
    };

    final value = names[key]!;
    return text(value[0], value[1], value[2], value[3]);
  }

  Future<void> save() async {
    final reduced = sensations.values.any((value) => !value);

    await store.addEntry({
      'type': 'sensory',
      'sensations': Map<String, bool>.from(sensations),
      'reducedSensation': reduced,
      'date': DateTime.now().toIso8601String(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          reduced
              ? text(
                  'Reduced sensation recorded. This is not a diagnosis.',
                  'Diminution de sensibilité enregistrée. Ce test ne constitue pas un diagnostic.',
                  'تم تسجيل نقص الإحساس. هذا الاختبار لا يمثل تشخيصاً.',
                  'تسجل نقص في الإحساس. الاختبار هذا موش تشخيص.',
                )
              : text(
                  'Sensory check saved.',
                  'Test de sensibilité enregistré.',
                  'تم حفظ اختبار الإحساس.',
                  'اختبار الإحساس تسجل.',
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: text(
        'Sensory Check',
        'Test de sensibilité',
        'اختبار الإحساس',
        'اختبار الإحساس',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text(
              'For each area, indicate whether you can feel normally.',
              'Pour chaque zone, indiquez si vous ressentez normalement.',
              'لكل منطقة، حدد إذا كنت تشعر بها بشكل طبيعي.',
              'لكل بلاصة، اختار إذا تحس بيها عادي.',
            ),
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          ...sensations.keys.map(
            (key) => Card(
              child: SwitchListTile(
                title: Text(locationName(key)),
                subtitle: Text(
                  sensations[key]!
                      ? text(
                          'Normal sensation',
                          'Sensibilité normale',
                          'إحساس طبيعي',
                          'الإحساس عادي',
                        )
                      : text(
                          'Reduced / absent sensation',
                          'Sensibilité réduite / absente',
                          'إحساس ضعيف / غائب',
                          'الإحساس ناقص / غايب',
                        ),
                ),
                value: sensations[key]!,
                onChanged: (value) {
                  setState(() {
                    sensations[key] = value;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: save,
              child: Text(
                text(
                  'Save sensory check',
                  'Enregistrer',
                  'حفظ الاختبار',
                  'سجّل الاختبار',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ============================================================
   AI REPORT
============================================================ */

class AiReportPage extends StatelessWidget {
  final String language;

  const AiReportPage({super.key, required this.language});

  String text(String en, String fr, String ar, String tn) {
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

  String levelPatient(AlertLevel level) {
    if (level == AlertLevel.red) {
      return text(
        'Red flag',
        'Alerte rouge',
        'علامة حمراء',
        'علامة حمراء',
      );
    }

    if (level == AlertLevel.yellow) {
      return text(
        'Yellow flag',
        'Alerte jaune',
        'علامة صفراء',
        'علامة صفراء',
      );
    }

    return text(
      'No alerts today',
      'Aucune alerte aujourd’hui',
      'لا توجد تنبيهات اليوم',
      'ما فما حتى تنبيه اليوم',
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = KhatwaStore.instance;
    final finding = KhatwaAiEngine.analyze(store);

    return BasePage(
      title: text(
        'AI Report',
        'Rapport IA',
        'تقرير الذكاء الاصطناعي',
        'تقرير الذكاء الاصطناعي',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    '🤖',
                    style: TextStyle(fontSize: 50),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    levelPatient(finding.level),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            text(
              'What we found',
              'Ce que nous avons trouvé',
              'شنوة لقينا',
              'شنوة لقينا',
            ),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ...finding.reasons.map(
            (reason) => Card(
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(reason),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                finding.explanation,
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            text(
              'This is a screening aid and not a medical diagnosis.',
              'Cet outil est une aide au dépistage et ne constitue pas un diagnostic médical.',
              'هذا النظام للمساعدة في التقييم الأولي وليس تشخيصاً طبياً.',
              'النظام هذا يعاون في التقييم الأولي وموش تشخيص طبي.',
            ),
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/* ============================================================
   APPOINTMENTS
============================================================ */

class AppointmentsPage extends StatefulWidget {
  final String language;

  const AppointmentsPage({
    super.key,
    required this.language,
  });

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  final store = KhatwaStore.instance;

  final doctors = [
    {
      'name': 'Dr. Ahmed Ben Ali',
      'specialty': 'Diabetology',
    },
    {
      'name': 'Dr. Mariem Trabelsi',
      'specialty': 'Endocrinology',
    },
    {
      'name': 'Dr. Sami Gharbi',
      'specialty': 'Diabetic Foot',
    },
  ];

  String? selectedDoctor;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  String text(String en, String fr, String ar, String tn) {
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

  Future<void> chooseDate() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: text(
        'Choose appointment date',
        'Choisir la date du rendez-vous',
        'اختر تاريخ الموعد',
        'اختار نهار الموعد',
      ),
      cancelText: text('Cancel', 'Annuler', 'إلغاء', 'إلغاء'),
      confirmText: text('Select', 'Choisir', 'اختيار', 'اختار'),
    );

    if (date != null) {
      setState(() {
        selectedDate = date;
      });
    }
  }

  Future<void> chooseTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: text(
        'Choose appointment time',
        'Choisir l’heure du rendez-vous',
        'اختر وقت الموعد',
        'اختار وقت الموعد',
      ),
      cancelText: text('Cancel', 'Annuler', 'إلغاء', 'إلغاء'),
      confirmText: text('Select', 'Choisir', 'اختيار', 'اختار'),
    );

    if (time != null) {
      setState(() {
        selectedTime = time;
      });
    }
  }

  Future<void> requestAppointment() async {
    if (selectedDoctor == null ||
        selectedDate == null ||
        selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            text(
              'Please select a doctor, date and time.',
              'Veuillez sélectionner un médecin, une date et une heure.',
              'يرجى اختيار الطبيب والتاريخ والوقت.',
              'اختار الطبيب والنهار والوقت.',
            ),
          ),
        ),
      );
      return;
    }

    await store.addEntry({
      'type': 'appointment_request',
      'doctor': selectedDoctor,
      'date': selectedDate!.toIso8601String(),
      'time': selectedTime!.format(context),
      'status': 'pending',
      'dateCreated': DateTime.now().toIso8601String(),
    });

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          text(
            'Appointment requested',
            'Rendez-vous demandé',
            'تم طلب الموعد',
            'طلب الموعد تسجل',
          ),
        ),
        content: Text(
          text(
            'Your appointment request has been saved. The doctor must confirm it.',
            'Votre demande a été enregistrée. Le médecin doit la confirmer.',
            'تم حفظ طلب الموعد. يجب على الطبيب تأكيده.',
            'طلب الموعد تسجل، والطبيب يلزمو يأكدو.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(
              text('Done', 'Terminé', 'تم', 'تم'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: text(
        'Appointments',
        'Rendez-vous',
        'المواعيد',
        'المواعيد',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text(
              'Book an appointment',
              'Prendre un rendez-vous',
              'حجز موعد',
              'خذ موعد',
            ),
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          DropdownButtonFormField<String>(
            initialValue: selectedDoctor,
            decoration: InputDecoration(
              labelText: text(
                'Doctor',
                'Médecin',
                'الطبيب',
                'الطبيب',
              ),
              border: const OutlineInputBorder(),
            ),
            items: doctors.map((doctor) {
              return DropdownMenuItem<String>(
                value: doctor['name'],
                child: Text(
                  '${doctor['name']} — ${doctor['specialty']}',
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedDoctor = value;
              });
            },
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: chooseDate,
              icon: const Icon(Icons.calendar_month),
              label: Text(
                selectedDate == null
                    ? text(
                        'Choose date',
                        'Choisir une date',
                        'اختر التاريخ',
                        'اختار النهار',
                      )
                    : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
              ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: chooseTime,
              icon: const Icon(Icons.access_time),
              label: Text(
                selectedTime == null
                    ? text(
                        'Choose time',
                        'Choisir une heure',
                        'اختر الوقت',
                        'اختار الوقت',
                      )
                    : selectedTime!.format(context),
              ),
            ),
          ),

          const SizedBox(height: 25),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: requestAppointment,
              icon: const Icon(Icons.event_available),
              label: Text(
                text(
                  'Request appointment',
                  'Demander le rendez-vous',
                  'طلب الموعد',
                  'اطلب الموعد',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ============================================================
   EXERCISES
============================================================ */

class ExercisesPage extends StatelessWidget {
  final String language;

  const ExercisesPage({super.key, required this.language});

  String text(String en, String fr, String ar, String tn) {
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

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: text(
        'Exercises',
        'Exercices',
        'التمارين',
        'التمارين',
      ),
      child: Column(
        children: [
          const Text('🏃', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 20),
          Text(
            text(
              'Recommended exercises',
              'Exercices recommandés',
              'تمارين مقترحة',
              'تمارين مقترحة',
            ),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ...[
            text(
              'Gentle walking',
              'Marche douce',
              'المشي الخفيف',
              'المشي الخفيف',
            ),
            text(
              'Ankle movement',
              'Mobilité de la cheville',
              'تحريك الكاحل',
              'تحريك الكاحل',
            ),
            text(
              'Toe movement',
              'Mobilité des orteils',
              'تحريك أصابع القدم',
              'تحريك صوابع الرجل',
            ),
          ].map(
            (e) => Card(
              child: ListTile(
                leading: const Icon(Icons.directions_walk),
                title: Text(e),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ============================================================
   VIDEOS
============================================================ */

class VideosPage extends StatelessWidget {
  final String language;

  const VideosPage({super.key, required this.language});

  String text(String en, String fr, String ar, String tn) {
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

  Future<void> openVideo() async {
    final uri = Uri.parse(
      'https://www.youtube.com/results?search_query=diabetic+foot+care',
    );

    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: text('Videos', 'Vidéos', 'الفيديوهات', 'الفيديوهات'),
      child: ElevatedButton.icon(
        onPressed: openVideo,
        icon: const Icon(Icons.play_circle),
        label: Text(
          text(
            'Watch educational videos',
            'Regarder des vidéos éducatives',
            'مشاهدة فيديوهات توعوية',
            'تفرج على فيديوهات توعوية',
          ),
        ),
      ),
    );
  }
}

/* ============================================================
   TIPS
============================================================ */

class TipsPage extends StatelessWidget {
  final String language;

  const TipsPage({super.key, required this.language});

  String text(String en, String fr, String ar, String tn) {
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

  @override
  Widget build(BuildContext context) {
    final tips = [
      text(
        'Check your feet every day.',
        'Examinez vos pieds chaque jour.',
        'افحص قدميك يومياً.',
        'تفقد ساقيك كل يوم.',
      ),
      text(
        'Keep your feet clean and dry.',
        'Gardez vos pieds propres et secs.',
        'حافظ على نظافة وجفاف قدميك.',
        'خلي ساقيك نضاف وناشفين.',
      ),
      text(
        'Avoid walking barefoot.',
        'Évitez de marcher pieds nus.',
        'تجنب المشي حافي القدمين.',
        'ما تمشيش حافي.',
      ),
    ];

    return BasePage(
      title: text('Tips', 'Conseils', 'نصائح', 'نصائح'),
      child: Column(
        children: tips
            .map(
              (tip) => Card(
                child: ListTile(
                  leading: const Icon(Icons.lightbulb_outline),
                  title: Text(tip),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}