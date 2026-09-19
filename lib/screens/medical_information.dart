import 'package:flutter/material.dart';
import 'create_account.dart';

class MedicalInformationPage extends StatefulWidget {
  final String language;

  const MedicalInformationPage({
    super.key,
    required this.language,
  });

  @override
  State<MedicalInformationPage> createState() =>
      _MedicalInformationPageState();
}

class _MedicalInformationPageState
    extends State<MedicalInformationPage> {
  final medicationsController = TextEditingController();
  final allergiesController = TextEditingController();
  final diseasesController = TextEditingController();
  final yearsController = TextEditingController();
  final additionalController = TextEditingController();

  String? diabetesType;

  final Map<String, Map<String, String>> texts = {
    'English': {
      'title': 'Medical information',
      'subtitle': 'Tell us about your health',
      'description':
          'This information helps Khatwa personalize your monitoring.',
      'diabetes': 'Diabetes type',
      'select': 'Select diabetes type',
      'type1': 'Type 1',
      'type2': 'Type 2',
      'gestational': 'Gestational diabetes',
      'other': 'Other / Not sure',
      'years': 'Years since diagnosis',
      'yearsHint': 'Example: 5',
      'medications': 'Medications',
      'medicationsHint': 'List your medications',
      'allergies': 'Allergies',
      'allergiesHint':
          'Medicines, foods, or other allergies',
      'diseases': 'Other diseases or conditions',
      'diseasesHint':
          'Example: high blood pressure',
      'additional': 'Additional information',
      'additionalHint':
          'Anything else you want your healthcare team to know',
      'private':
          'Your medical information is private and securely protected.',
      'continue': 'Continue',
      'error': 'Please select your diabetes type.',
    },

    'Français': {
      'title': 'Informations médicales',
      'subtitle': 'Parlez-nous de votre santé',
      'description':
          'Ces informations nous aident à personnaliser votre suivi.',
      'diabetes': 'Type de diabète',
      'select': 'Sélectionnez le type de diabète',
      'type1': 'Type 1',
      'type2': 'Type 2',
      'gestational': 'Diabète gestationnel',
      'other': 'Autre / Je ne sais pas',
      'years': 'Années depuis le diagnostic',
      'yearsHint': 'Exemple : 5',
      'medications': 'Médicaments',
      'medicationsHint':
          'Indiquez vos médicaments',
      'allergies': 'Allergies',
      'allergiesHint':
          'Médicaments, aliments ou autres allergies',
      'diseases':
          'Autres maladies ou problèmes de santé',
      'diseasesHint':
          'Exemple : hypertension',
      'additional': 'Informations supplémentaires',
      'additionalHint':
          'Toute autre information importante',
      'private':
          'Vos informations médicales sont privées et protégées.',
      'continue': 'Continuer',
      'error':
          'Veuillez sélectionner votre type de diabète.',
    },

    'العربية': {
      'title': 'المعلومات الطبية',
      'subtitle': 'أخبرنا عن حالتك الصحية',
      'description':
          'تساعدنا هذه المعلومات على تخصيص المتابعة.',
      'diabetes': 'نوع السكري',
      'select': 'اختر نوع السكري',
      'type1': 'النوع الأول',
      'type2': 'النوع الثاني',
      'gestational': 'سكري الحمل',
      'other': 'آخر / لست متأكداً',
      'years': 'عدد سنوات الإصابة',
      'yearsHint': 'مثال: 5',
      'medications': 'الأدوية',
      'medicationsHint':
          'أدخل الأدوية التي تستعملها',
      'allergies': 'الحساسيات',
      'allergiesHint':
          'أدوية أو أطعمة أو أنواع حساسية أخرى',
      'diseases':
          'أمراض أو حالات صحية أخرى',
      'diseasesHint':
          'مثال: ارتفاع ضغط الدم',
      'additional': 'معلومات إضافية',
      'additionalHint':
          'أي معلومات أخرى تريد أن يعرفها فريقك الطبي',
      'private':
          'معلوماتك الطبية خاصة ومحمية بشكل آمن.',
      'continue': 'متابعة',
      'error':
          'يرجى اختيار نوع السكري.',
    },

    'تونسي': {
      'title': 'المعلومات الطبية',
      'subtitle': 'احكيلنا على صحتك',
      'description':
          'المعلومات هاذي تعاونّا باش نعملولك متابعة تناسبك.',
      'diabetes': 'نوع السكري',
      'select': 'إختار نوع السكري',
      'type1': 'النوع الأول',
      'type2': 'النوع الثاني',
      'gestational': 'سكري الحمل',
      'other': 'نوع آخر / ما نعرفش',
      'years':
          'قدّاش عندك سنين ملي عرفت بالسكري',
      'yearsHint': 'مثال: 5',
      'medications': 'الأدوية',
      'medicationsHint':
          'دخل أدوية السكري اللي تستعمل فيهم',
      'allergies': 'الحساسيات',
      'allergiesHint':
          'أدوية، ماكلة، ولا حاجات أخرى تعملك حساسية',
      'diseases':
          'أمراض ولا مشاكل صحية أخرى',
      'diseasesHint': 'مثال: ضغط الدم',
      'additional': 'معلومات أخرى',
      'additionalHint':
          'أي حاجة أخرى تحب الفريق الطبي يعرفها',
      'private':
          'معلوماتك الطبية خاصة ومأمّنة.',
      'continue': 'نكمل',
      'error': 'إختار نوع السكري.',
    },
  };

  @override
  Widget build(BuildContext context) {
    final t = texts[widget.language]!;

    final isRTL =
        widget.language == 'العربية' ||
        widget.language == 'تونسي';

    return Directionality(
      textDirection:
          isRTL ? TextDirection.rtl : TextDirection.ltr,

      child: Scaffold(
        backgroundColor: const Color(0xFFF2FAFA),

        appBar: AppBar(
          backgroundColor: const Color(0xFFF2FAFA),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),

        body: Scrollbar(
          thumbVisibility: true,

          child: SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),

            padding: const EdgeInsets.fromLTRB(
              24,
              10,
              24,
              60,
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                // PROGRESS
                Row(
                  children: [
                    _progressCircle(true),
                    _progressLine(),
                    _progressCircle(true),
                    _progressLine(),
                    _progressCircle(true),
                  ],
                ),

                const SizedBox(height: 30),

                Text(
                  t['title']!,
                  style: const TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF123B43),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  t['subtitle']!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF167D8D),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  t['description']!,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 25),

                // DIABETES TYPE
                _card(
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        t['diabetes']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      DropdownButtonFormField<String>(
                        value: diabetesType,

                        decoration: InputDecoration(
                          hintText: t['select'],
                          prefixIcon: const Icon(
                            Icons.bloodtype_outlined,
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(15),
                          ),
                        ),

                        items: [
                          DropdownMenuItem(
                            value: 'type1',
                            child: Text(t['type1']!),
                          ),
                          DropdownMenuItem(
                            value: 'type2',
                            child: Text(t['type2']!),
                          ),
                          DropdownMenuItem(
                            value: 'gestational',
                            child: Text(
                              t['gestational']!,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'other',
                            child: Text(t['other']!),
                          ),
                        ],

                        onChanged: (value) {
                          setState(() {
                            diabetesType = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                _field(
                  label: t['years']!,
                  hint: t['yearsHint']!,
                  controller: yearsController,
                  icon: Icons.calendar_month_outlined,
                  keyboardType:
                      TextInputType.number,
                ),

                const SizedBox(height: 16),

                _field(
                  label: t['medications']!,
                  hint: t['medicationsHint']!,
                  controller:
                      medicationsController,
                  icon: Icons.medication_outlined,
                  maxLines: 3,
                ),

                const SizedBox(height: 16),

                _field(
                  label: t['allergies']!,
                  hint: t['allergiesHint']!,
                  controller:
                      allergiesController,
                  icon:
                      Icons.warning_amber_outlined,
                  maxLines: 3,
                ),

                const SizedBox(height: 16),

                _field(
                  label: t['diseases']!,
                  hint: t['diseasesHint']!,
                  controller:
                      diseasesController,
                  icon:
                      Icons.local_hospital_outlined,
                  maxLines: 3,
                ),

                const SizedBox(height: 16),

                _field(
                  label: t['additional']!,
                  hint: t['additionalHint']!,
                  controller:
                      additionalController,
                  icon: Icons.notes_outlined,
                  maxLines: 4,
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      color: Color(0xFF167D8D),
                      size: 19,
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        t['private']!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // CONTINUE BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 56,

                  child: ElevatedButton(
                    onPressed: () {
                      if (diabetesType == null) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          SnackBar(
                            content:
                                Text(t['error']!),
                          ),
                        );

                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CreateAccountPage(
                            language:
                                widget.language,
                          ),
                        ),
                      );
                    },

                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF167D8D),
                      foregroundColor:
                          Colors.white,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                    ),

                    child: Text(
                      t['continue']!,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(Widget child) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: child,
    );
  }

  Widget _field({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType =
        TextInputType.text,
  }) {
    return _card(
      Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,

            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon),

              filled: true,
              fillColor:
                  const Color(0xFFF7FAFA),

              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(15),
              ),

              focusedBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(15),

                borderSide:
                    const BorderSide(
                  color: Color(0xFF167D8D),
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressCircle(bool active) {
    return Container(
      width: 28,
      height: 28,

      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? const Color(0xFF167D8D)
            : Colors.grey.shade300,
      ),

      child: active
          ? const Icon(
              Icons.check,
              color: Colors.white,
              size: 17,
            )
          : null,
    );
  }

  Widget _progressLine() {
    return Expanded(
      child: Container(
        height: 3,
        color: Colors.grey.shade300,
      ),
    );
  }

  @override
  void dispose() {
    medicationsController.dispose();
    allergiesController.dispose();
    diseasesController.dispose();
    yearsController.dispose();
    additionalController.dispose();
    super.dispose();
  }
}