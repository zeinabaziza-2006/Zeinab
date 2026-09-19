import 'package:flutter/material.dart';
import 'phone_verification.dart';

class PatientRegistrationPage extends StatefulWidget {
  final String language;

  const PatientRegistrationPage({
    super.key,
    required this.language,
  });

  @override
  State<PatientRegistrationPage> createState() =>
      _PatientRegistrationPageState();
}

class _PatientRegistrationPageState
    extends State<PatientRegistrationPage> {
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final weightController = TextEditingController();

  String? gender;

  final Map<String, Map<String, String>> texts = {
    'English': {
      'title': 'Create your account',
      'welcome': 'Welcome to Khatwa',
      'description':
          'Let’s start by getting to know you. This information will help us personalize your experience.',
      'name': 'Full name',
      'nameHint': 'Enter your full name',
      'age': 'Age',
      'ageHint': 'Enter your age',
      'weight': 'Weight (kg)',
      'weightHint': 'Enter your weight',
      'gender': 'Gender',
      'selectGender': 'Select your gender',
      'female': 'Female',
      'male': 'Male',
      'other': 'Prefer not to say',
      'private':
          'Your information is private and securely stored.',
      'continue': 'Continue',
      'error': 'Please complete all fields.',
      'saved': 'Information saved ✓',
    },
    'Français': {
      'title': 'Créer votre compte',
      'welcome': 'Bienvenue sur Khatwa',
      'description':
          'Commençons par faire connaissance. Ces informations nous aideront à personnaliser votre expérience.',
      'name': 'Nom complet',
      'nameHint': 'Entrez votre nom complet',
      'age': 'Âge',
      'ageHint': 'Entrez votre âge',
      'weight': 'Poids (kg)',
      'weightHint': 'Entrez votre poids',
      'gender': 'Sexe',
      'selectGender': 'Sélectionnez votre sexe',
      'female': 'Femme',
      'male': 'Homme',
      'other': 'Je préfère ne pas répondre',
      'private':
          'Vos informations sont privées et stockées en toute sécurité.',
      'continue': 'Continuer',
      'error': 'Veuillez remplir tous les champs.',
      'saved': 'Informations enregistrées ✓',
    },
    'العربية': {
      'title': 'إنشاء حسابك',
      'welcome': 'مرحبا بك في خطوة',
      'description':
          'لنبدأ بالتعرف عليك. ستساعدنا هذه المعلومات على تخصيص تجربتك.',
      'name': 'الاسم الكامل',
      'nameHint': 'أدخل اسمك الكامل',
      'age': 'العمر',
      'ageHint': 'أدخل عمرك',
      'weight': 'الوزن (كغ)',
      'weightHint': 'أدخل وزنك',
      'gender': 'الجنس',
      'selectGender': 'اختر جنسك',
      'female': 'أنثى',
      'male': 'ذكر',
      'other': 'أفضل عدم الإجابة',
      'private': 'معلوماتك خاصة ويتم تخزينها بأمان.',
      'continue': 'متابعة',
      'error': 'يرجى ملء جميع الخانات.',
      'saved': 'تم حفظ المعلومات ✓',
    },
    'تونسي': {
      'title': 'اعمل كونت جديد',
      'welcome': 'مرحبا بيك في خطوة',
      'description':
          'باش نبدأو نتعرفو عليك. المعلومات هاذي تعاونّا باش نعطيوك تجربة تناسبك.',
      'name': 'الإسم واللقب',
      'nameHint': 'دخل إسمك ولقبك',
      'age': 'العمر',
      'ageHint': 'دخل عمرك',
      'weight': 'الوزن (كغ)',
      'weightHint': 'دخل وزنك',
      'gender': 'الجنس',
      'selectGender': 'إختار جنسك',
      'female': 'مرا',
      'male': 'راجل',
      'other': 'نفضّل ما نجاوبش',
      'private': 'معلوماتك خاصة ومأمّنة.',
      'continue': 'نكمل',
      'error': 'عمّر الخانات الكل.',
      'saved': 'المعلومات تسجّلت ✓',
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
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _progressCircle(true),
                    _progressLine(),
                    _progressCircle(false),
                    _progressLine(),
                    _progressCircle(false),
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
                  t['welcome']!,
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

                _field(
                  label: t['name']!,
                  hint: t['nameHint']!,
                  controller: nameController,
                  icon: Icons.person_outline,
                ),

                const SizedBox(height: 16),

                _field(
                  label: t['age']!,
                  hint: t['ageHint']!,
                  controller: ageController,
                  icon: Icons.cake_outlined,
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 16),

                _field(
                  label: t['weight']!,
                  hint: t['weightHint']!,
                  controller: weightController,
                  icon: Icons.monitor_weight_outlined,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  t['gender']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 8),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: gender,
                    decoration: InputDecoration(
                      prefixIcon:
                          const Icon(Icons.people_outline),
                      hintText: t['selectGender'],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'female',
                        child: Text(t['female']!),
                      ),
                      DropdownMenuItem(
                        value: 'male',
                        child: Text(t['male']!),
                      ),
                      DropdownMenuItem(
                        value: 'other',
                        child: Text(t['other']!),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        gender = value;
                      });
                    },
                  ),
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
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameController.text.trim().isEmpty ||
                          ageController.text.trim().isEmpty ||
                          weightController.text.trim().isEmpty ||
                          gender == null) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          SnackBar(
                            content: Text(t['error']!),
                          ),
                        );
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PhoneVerificationPage(
                            language: widget.language,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF167D8D),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
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

  Widget _field({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ],
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
    nameController.dispose();
    ageController.dispose();
    weightController.dispose();
    super.dispose();
  }
}
