import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/ai_engine.dart';
import '../data/khatwa_store.dart';
import 'ai_chatbot.dart';

class DoctorNetworkPage extends StatefulWidget {
  final String language;

  const DoctorNetworkPage({
    super.key,
    required this.language,
  });

  @override
  State<DoctorNetworkPage> createState() =>
      _DoctorNetworkPageState();
}

class _DoctorNetworkPageState
    extends State<DoctorNetworkPage> {
  String search = '';

  final List<Map<String, String>> doctors = const [
    {
      'name': 'Dr. Ahmed Ben Ali',
      'specialty': 'Diabetology',
      'city': 'Tunis',
    },
    {
      'name': 'Dr. Mariem Trabelsi',
      'specialty': 'Endocrinology',
      'city': 'Tunis',
    },
    {
      'name': 'Dr. Sami Gharbi',
      'specialty': 'Diabetic Foot',
      'city': 'Sousse',
    },
  ];

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

  @override
  Widget build(BuildContext context) {
    final filtered = doctors.where((doctor) {
      final q = search.trim().toLowerCase();

      if (q.isEmpty) return true;

      return doctor['name']!
              .toLowerCase()
              .contains(q) ||
          doctor['specialty']!
              .toLowerCase()
              .contains(q) ||
          doctor['city']!
              .toLowerCase()
              .contains(q);
    }).toList();

    return Directionality(
      textDirection:
          rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            text(
              'Find a Doctor',
              'Trouver un médecin',
              'العثور على طبيب',
              'لقى طبيب',
            ),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(15),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    search = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: text(
                    'Search by name, specialty or city',
                    'Rechercher par nom, spécialité ou ville',
                    'ابحث بالاسم أو الاختصاص أو المدينة',
                    'قلّب بالاسم ولا الاختصاص ولا المدينة',
                  ),
                  prefixIcon:
                      const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final doctor = filtered[index];

                  return Card(
                    margin: const EdgeInsets.only(
                      bottom: 10,
                    ),
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.all(14),
                      leading: const CircleAvatar(
                        child: Icon(
                          Icons.medical_services,
                        ),
                      ),
                      title: Text(
                        doctor['name']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${doctor['specialty']}\n📍 ${doctor['city']}',
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                DoctorConsentPage(
                              language:
                                  widget.language,
                              doctorName:
                                  doctor['name']!,
                              specialty:
                                  doctor['specialty']!,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DoctorConsentPage extends StatefulWidget {
  final String language;
  final String doctorName;
  final String specialty;

  const DoctorConsentPage({
    super.key,
    required this.language,
    required this.doctorName,
    required this.specialty,
  });

  @override
  State<DoctorConsentPage> createState() =>
      _DoctorConsentPageState();
}

class _DoctorConsentPageState
    extends State<DoctorConsentPage> {
  bool anonymous = true;
  bool shareDossier = false;
  bool consentGiven = false;

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

  Future<void> sendRequest() async {
    if (!consentGiven) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            text(
              'Please give consent first.',
              'Veuillez donner votre consentement.',
              'يرجى إعطاء الموافقة.',
              'يلزمك توافق قبل.',
            ),
          ),
        ),
      );
      return;
    }

    await KhatwaStore.instance.requestDoctor(
      doctorName: widget.doctorName,
      specialty: widget.specialty,
      consent: consentGiven,
      anonymous: anonymous,
      shareDossier: shareDossier,
    );

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          text(
            'Request sent',
            'Demande envoyée',
            'تم إرسال الطلب',
            'الطلب تبعث',
          ),
        ),
        content: Text(
          text(
            'Your request was saved.',
            'Votre demande a été enregistrée.',
            'تم حفظ طلبك.',
            'طلبك تسجل.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(
              text(
                'Done',
                'Terminé',
                'تم',
                'تم',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rtl =
        widget.language == 'العربية' ||
            widget.language == 'تونسي';

    return Directionality(
      textDirection:
          rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            text(
              'Doctor request',
              'Demande au médecin',
              'طلب الطبيب',
              'طلب للطبيب',
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 40,
                child: Icon(
                  Icons.medical_services,
                  size: 38,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.doctorName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(widget.specialty),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    text(
                      'Your information is shared only according to your consent.',
                      'Vos informations sont partagées uniquement selon votre consentement.',
                      'تتم مشاركة معلوماتك فقط حسب موافقتك.',
                      'معلوماتك تتشارك كان حسب موافقتك.',
                    ),
                  ),
                ),
              ),
              CheckboxListTile(
                value: anonymous,
                onChanged: (value) {
                  setState(() {
                    anonymous = value ?? true;
                  });
                },
                title: Text(
                  text(
                    'Send anonymously',
                    'Envoyer anonymement',
                    'إرسال بشكل مجهول',
                    'ابعث من غير اسم',
                  ),
                ),
              ),
              CheckboxListTile(
                value: shareDossier,
                onChanged: (value) {
                  setState(() {
                    shareDossier = value ?? false;
                  });
                },
                title: Text(
                  text(
                    'Allow access to my health dossier',
                    'Autoriser l’accès à mon dossier',
                    'السماح بالوصول إلى ملفي الصحي',
                    'نوافق على الوصول لملفي الصحي',
                  ),
                ),
              ),
              CheckboxListTile(
                value: consentGiven,
                onChanged: (value) {
                  setState(() {
                    consentGiven = value ?? false;
                  });
                },
                title: Text(
                  text(
                    'I understand and give consent',
                    'Je comprends et je donne mon consentement',
                    'أفهم وأعطي موافقتي',
                    'فهمت ونوافق',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: sendRequest,
                  icon: const Icon(Icons.send),
                  label: Text(
                    text(
                      'Send request',
                      'Envoyer la demande',
                      'إرسال الطلب',
                      'ابعث الطلب',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DoctorLoginPage extends StatefulWidget {
  final String language;

  const DoctorLoginPage({
    super.key,
    required this.language,
  });

  @override
  State<DoctorLoginPage> createState() =>
      _DoctorLoginPageState();
}

class _DoctorLoginPageState
    extends State<DoctorLoginPage> {
  final idController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscure = true;

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

  Future<void> login() async {
    final prefs =
        await SharedPreferences.getInstance();

    final savedId = prefs.getString('doctor_id');
    final savedPassword =
        prefs.getString('doctor_password');

    final savedName =
        prefs.getString('doctor_name') ?? 'Doctor';

    final savedSpecialty =
        prefs.getString('doctor_specialty') ?? '';

    if (savedId == null ||
        savedPassword == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            text(
              'Create a doctor account first.',
              'Créez d’abord un compte médecin.',
              'أنشئ حساب الطبيب أولاً.',
              'اعمل compte طبيب الأول.',
            ),
          ),
        ),
      );
      return;
    }

    if (idController.text.trim() == savedId &&
        passwordController.text == savedPassword) {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DoctorDashboardPage(
            language: widget.language,
            doctorName: savedName,
            doctorId: savedId,
            specialty: savedSpecialty,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            text(
              'Incorrect Doctor ID or password.',
              'Identifiant ou mot de passe incorrect.',
              'معرف الطبيب أو كلمة السر غير صحيحة.',
              'Doctor ID ولا كلمة السر غالطة.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rtl =
        widget.language == 'العربية' ||
            widget.language == 'تونسي';

    return Directionality(
      textDirection:
          rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            text(
              'Doctor Login',
              'Connexion médecin',
              'تسجيل دخول الطبيب',
              'دخول الطبيب',
            ),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 500,
              ),
              child: Column(
                children: [
                  const Text(
                    '👨‍⚕️',
                    style: TextStyle(fontSize: 60),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: idController,
                    decoration: InputDecoration(
                      labelText: text(
                        'Khatwa Doctor ID',
                        'Identifiant médecin Khatwa',
                        'معرف طبيب Khatwa',
                        'Doctor ID متاع Khatwa',
                      ),
                      prefixIcon:
                          const Icon(Icons.badge),
                      border:
                          const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: passwordController,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: text(
                        'Password',
                        'Mot de passe',
                        'كلمة السر',
                        'كلمة السر',
                      ),
                      prefixIcon:
                          const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            obscure = !obscure;
                          });
                        },
                        icon: Icon(
                          obscure
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                      border:
                          const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: login,
                      child: Text(
                        text(
                          'Login',
                          'Se connecter',
                          'تسجيل الدخول',
                          'ادخل',
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              DoctorCreateAccountPage(
                            language:
                                widget.language,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      text(
                        'Create a doctor account',
                        'Créer un compte médecin',
                        'إنشاء حساب طبيب',
                        'اعمل compte طبيب',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DoctorCreateAccountPage extends StatefulWidget {
  final String language;

  const DoctorCreateAccountPage({
    super.key,
    required this.language,
  });

  @override
  State<DoctorCreateAccountPage> createState() =>
      _DoctorCreateAccountPageState();
}

class _DoctorCreateAccountPageState
    extends State<DoctorCreateAccountPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final specialtyController =
      TextEditingController();
  final cityController = TextEditingController();
  final organizationIdController =
      TextEditingController();
  final passwordController =
      TextEditingController();
  final confirmPasswordController =
      TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirm = true;

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

  String generateDoctorId() {
    final random = Random();
    final number =
        100000 + random.nextInt(900000);

    return 'KHT-DR-$number';
  }

  Future<void> createAccount() async {
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        specialtyController.text.trim().isEmpty ||
        cityController.text.trim().isEmpty ||
        organizationIdController.text
            .trim()
            .isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            text(
              'Please complete all fields.',
              'Veuillez remplir tous les champs.',
              'يرجى ملء جميع الخانات.',
              'كمّل الخانات الكل.',
            ),
          ),
        ),
      );
      return;
    }

    if (passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            text(
              'Password must contain at least 6 characters.',
              'Le mot de passe doit contenir au moins 6 caractères.',
              'كلمة السر يجب أن تحتوي على 6 أحرف على الأقل.',
              'كلمة السر يلزم فيها 6 حروف على الأقل.',
            ),
          ),
        ),
      );
      return;
    }

    if (passwordController.text !=
        confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            text(
              'Passwords do not match.',
              'Les mots de passe ne correspondent pas.',
              'كلمتا السر غير متطابقتين.',
              'كلمات السر موش كيف كيف.',
            ),
          ),
        ),
      );
      return;
    }

    final doctorId = generateDoctorId();

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      'doctor_id',
      doctorId,
    );

    await prefs.setString(
      'doctor_name',
      nameController.text.trim(),
    );

    await prefs.setString(
      'doctor_email',
      emailController.text.trim(),
    );

    await prefs.setString(
      'doctor_specialty',
      specialtyController.text.trim(),
    );

    await prefs.setString(
      'doctor_city',
      cityController.text.trim(),
    );

    await prefs.setString(
      'doctor_organization_id',
      organizationIdController.text.trim(),
    );

    await prefs.setString(
      'doctor_password',
      passwordController.text,
    );

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          text(
            'Account created!',
            'Compte créé !',
            'تم إنشاء الحساب!',
            'الـ compte تسجل!',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text(
                'Your Khatwa Doctor ID is:',
                'Votre identifiant médecin Khatwa est :',
                'معرف طبيب Khatwa الخاص بك هو:',
                'Doctor ID متاعك هو:',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: SelectableText(
                doctorId,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              text(
                'Continue',
                'Continuer',
                'متابعة',
                'كمل',
              ),
            ),
          ),
        ],
      ),
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DoctorDashboardPage(
          language: widget.language,
          doctorName:
              nameController.text.trim(),
          doctorId: doctorId,
          specialty:
              specialtyController.text.trim(),
        ),
      ),
    );
  }

  Widget field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscure = false,
    VoidCallback? toggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: toggle == null
            ? null
            : IconButton(
                onPressed: toggle,
                icon: Icon(
                  obscure
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
              ),
        border: const OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rtl =
        widget.language == 'العربية' ||
            widget.language == 'تونسي';

    return Directionality(
      textDirection:
          rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            text(
              'Doctor Registration',
              'Inscription médecin',
              'تسجيل الطبيب',
              'تسجيل الطبيب',
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 650,
              ),
              child: Column(
                children: [
                  const Text(
                    '👨‍⚕️',
                    style:
                        TextStyle(fontSize: 55),
                  ),
                  const SizedBox(height: 10),

                  field(
                    nameController,
                    text(
                      'Full name',
                      'Nom complet',
                      'الاسم الكامل',
                      'الاسم الكامل',
                    ),
                    Icons.person,
                  ),

                  const SizedBox(height: 12),

                  field(
                    emailController,
                    'Email',
                    Icons.email,
                  ),

                  const SizedBox(height: 12),

                  field(
                    specialtyController,
                    text(
                      'Specialty',
                      'Spécialité',
                      'الاختصاص',
                      'الاختصاص',
                    ),
                    Icons.medical_services,
                  ),

                  const SizedBox(height: 12),

                  field(
                    cityController,
                    text(
                      'City',
                      'Ville',
                      'المدينة',
                      'المدينة',
                    ),
                    Icons.location_city,
                  ),

                  const SizedBox(height: 12),

                  field(
                    organizationIdController,
                    text(
                      'Professional organization / registration ID',
                      'Identifiant professionnel / numéro d’inscription',
                      'المعرف المهني / رقم التسجيل',
                      'الـ ID المهني / رقم التسجيل',
                    ),
                    Icons.verified_user,
                  ),

                  const SizedBox(height: 12),

                  field(
                    passwordController,
                    text(
                      'Create password',
                      'Créer un mot de passe',
                      'إنشاء كلمة السر',
                      'اعمل كلمة سر',
                    ),
                    Icons.lock,
                    obscure: obscurePassword,
                    toggle: () {
                      setState(() {
                        obscurePassword =
                            !obscurePassword;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  field(
                    confirmPasswordController,
                    text(
                      'Confirm password',
                      'Confirmer le mot de passe',
                      'تأكيد كلمة السر',
                      'عاود كلمة السر',
                    ),
                    Icons.lock_outline,
                    obscure: obscureConfirm,
                    toggle: () {
                      setState(() {
                        obscureConfirm =
                            !obscureConfirm;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child:
                        FilledButton.icon(
                      onPressed: createAccount,
                      icon: const Icon(
                        Icons.person_add,
                      ),
                      label: Text(
                        text(
                          'Create account',
                          'Créer le compte',
                          'إنشاء الحساب',
                          'اعمل الحساب',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DoctorDashboardPage
    extends StatelessWidget {
  final String language;
  final String doctorName;
  final String doctorId;
  final String specialty;

  const DoctorDashboardPage({
    super.key,
    required this.language,
    required this.doctorName,
    required this.doctorId,
    required this.specialty,
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

  Widget dashboardCard(
    BuildContext context, {
    required String emoji,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Text(
                emoji,
                style: const TextStyle(
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow:
                    TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void openAI(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiChatbotPage(
          language: language,
          role: 'doctor',
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
        backgroundColor:
            const Color(0xFFF4F9FB),
        appBar: AppBar(
          title: Text(
            text(
              'Doctor Dashboard',
              'Tableau de bord médecin',
              'لوحة الطبيب',
              'لوحة الطبيب',
            ),
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final columns =
                constraints.maxWidth >= 1100
                    ? 4
                    : constraints.maxWidth >= 700
                        ? 3
                        : 2;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(15),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 28,
                            child: Text(
                              '👨‍⚕️',
                              style:
                                  TextStyle(
                                fontSize: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  doctorName,
                                  style:
                                      const TextStyle(
                                    fontSize: 18,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                                Text(specialty),
                                const SizedBox(
                                    height: 3),
                                Text(
                                  doctorId,
                                  style: TextStyle(
                                    color: Colors
                                        .teal
                                        .shade700,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  GridView.count(
                    crossAxisCount: columns,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio:
                        constraints.maxWidth <
                                600
                            ? 1.28
                            : 1.42,
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    children: [
                      dashboardCard(
                        context,
                        emoji: '👥',
                        title: text(
                          'Patients',
                          'Patients',
                          'المرضى',
                          'المرضى',
                        ),
                        subtitle: text(
                          'Random demo + real patient',
                          'Patients démo + patient réel',
                          'مرضى تجريبيون + مريض حقيقي',
                          'مرضى démo + المريض الحقيقي',
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DemoPatientsPage(
                                language: language,
                              ),
                            ),
                          );
                        },
                      ),

                      dashboardCard(
                        context,
                        emoji: '📩',
                        title: text(
                          'Requests',
                          'Demandes',
                          'الطلبات',
                          'الطلبات',
                        ),
                        subtitle: text(
                          'Accept / reject',
                          'Accepter / refuser',
                          'قبول / رفض',
                          'اقبل / ارفض',
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DemoRequestsPage(
                                language: language,
                              ),
                            ),
                          );
                        },
                      ),

                      dashboardCard(
                        context,
                        emoji: '📋',
                        title: text(
                          'Patient dossiers',
                          'Dossiers patients',
                          'ملفات المرضى',
                          'ملفات المرضى',
                        ),
                        subtitle: text(
                          'Saved data + photos',
                          'Données + photos',
                          'البيانات + الصور',
                          'البيانات + التصاور',
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DoctorDossiersPage(
                                language: language,
                              ),
                            ),
                          );
                        },
                      ),

                      dashboardCard(
                        context,
                        emoji: '💬',
                        title: text(
                          'Messages',
                          'Messages',
                          'الرسائل',
                          'الميساجات',
                        ),
                        subtitle: text(
                          'Patient conversations',
                          'Conversations patients',
                          'محادثات المرضى',
                          'محادثات المرضى',
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DemoMessagesPage(
                                language: language,
                              ),
                            ),
                          );
                        },
                      ),

                      dashboardCard(
                        context,
                        emoji: '📄',
                        title: text(
                          'Reports',
                          'Rapports',
                          'التقارير',
                          'التقارير',
                        ),
                        subtitle: text(
                          'Monitoring reports',
                          'Rapports de suivi',
                          'تقارير المتابعة',
                          'تقارير المتابعة',
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DemoReportsPage(
                                language: language,
                              ),
                            ),
                          );
                        },
                      ),

                      dashboardCard(
                        context,
                        emoji: '🤖',
                        title: text(
                          'Doctor AI',
                          'IA médecin',
                          'مساعد الطبيب',
                          'مساعد الطبيب',
                        ),
                        subtitle: text(
                          'Ask the assistant',
                          'Parler à l’assistant',
                          'اسأل المساعد',
                          'اسأل المساعد',
                        ),
                        onTap: () =>
                            openAI(context),
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

final List<Map<String, dynamic>>
_demoPatients = [
  {
    'id': 'PT-DEMO-001',
    'name': 'Sarra Ben Amor',
    'age': '54',
    'diabetes': 'Type 2',
    'city': 'Tunis',
    'status': 'Yellow flag',
    'avatar':
        'https://i.pravatar.cc/150?img=47',
  },
  {
    'id': 'PT-DEMO-002',
    'name': 'Youssef Khelifi',
    'age': '61',
    'diabetes': 'Type 2',
    'city': 'Sousse',
    'status': 'No alerts today',
    'avatar':
        'https://i.pravatar.cc/150?img=12',
  },
  {
    'id': 'PT-DEMO-003',
    'name': 'Amel Jaziri',
    'age': '48',
    'diabetes': 'Type 1',
    'city': 'Sfax',
    'status': 'Red flag',
    'avatar':
        'https://i.pravatar.cc/150?img=32',
  },
  {
    'id': 'PT-DEMO-004',
    'name': 'Omar Trabelsi',
    'age': '57',
    'diabetes': 'Type 2',
    'city': 'Monastir',
    'status': 'Yellow flag',
    'avatar':
        'https://i.pravatar.cc/150?img=13',
  },
];

class DemoPatientsPage extends StatelessWidget {
  final String language;

  const DemoPatientsPage({
    super.key,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final store = KhatwaStore.instance;

    final realPatient =
        store.patientName.isEmpty
            ? null
            : {
                'id': store.patientId.isEmpty
                    ? 'REAL-PATIENT'
                    : store.patientId,
                'name': store.patientName,
                'age': '--',
                'diabetes':
                    store.diabetesType.isEmpty
                        ? '--'
                        : store.diabetesType,
                'city': 'Patient account',
                'status': 'Saved data',
                'avatar':
                    'https://i.pravatar.cc/150?img=5',
              };

    final patients = [
      if (realPatient != null) realPatient,
      ..._demoPatients,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('👥 Patients'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: patients.length,
        itemBuilder: (context, index) {
          final patient = patients[index];

          return Card(
            margin:
                const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.all(12),
              leading: CircleAvatar(
                backgroundImage:
                    NetworkImage(
                  patient['avatar'] as String,
                ),
              ),
              title: Text(
                patient['name'] as String,
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '${patient['id']}\n'
                '${patient['diabetes']} • '
                '${patient['city']}',
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 15,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        DoctorPatientDetailPage(
                      patient: patient,
                      language: language,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class DoctorPatientDetailPage
    extends StatelessWidget {
  final Map<String, dynamic> patient;
  final String language;

  const DoctorPatientDetailPage({
    super.key,
    required this.patient,
    required this.language,
  });

  Widget info(
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      margin:
          const EdgeInsets.only(bottom: 9),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = KhatwaStore.instance;
    final isReal =
        (patient['id'] as String)
            .startsWith('REAL') ||
        (patient['id'] as String)
            .startsWith('PAT');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          patient['name'] as String,
        ),
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final photos = isReal
              ? store.photoEntries()
              : <Map<String, dynamic>>[];

          final entries = isReal
              ? store.entries
              : <Map<String, dynamic>>[];

          return ListView(
            padding: const EdgeInsets.all(15),
            children: [
              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(15),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundImage:
                            NetworkImage(
                          patient['avatar']
                              as String,
                        ),
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              patient['name']
                                  as String,
                              style:
                                  const TextStyle(
                                fontSize: 19,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                            Text(
                              patient['id']
                                  as String,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              info(
                'Age',
                patient['age'] as String,
                Icons.cake,
              ),

              info(
                'Diabetes',
                patient['diabetes'] as String,
                Icons.bloodtype,
              ),

              info(
                'City',
                patient['city'] as String,
                Icons.location_city,
              ),

              info(
                'Current status',
                patient['status'] as String,
                Icons.monitor_heart,
              ),

              if (isReal &&
                  entries.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text(
                  'Saved patient information',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                if (store.medications
                    .isNotEmpty)
                  info(
                    'Medications',
                    store.medications,
                    Icons.medication,
                  ),

                if (store.allergies
                    .isNotEmpty)
                  info(
                    'Allergies',
                    store.allergies,
                    Icons.warning_amber,
                  ),

                if (store.otherConditions
                    .isNotEmpty)
                  info(
                    'Other conditions',
                    store.otherConditions,
                    Icons.health_and_safety,
                  ),

                ...entries.reversed.map(
                  (entry) => Card(
                    child: ListTile(
                      leading: Text(
                        entry['type'] ==
                                'foot_photo'
                            ? '📸'
                            : '📋',
                        style:
                            const TextStyle(
                          fontSize: 25,
                        ),
                      ),
                      title: Text(
                        entry['type']
                                ?.toString() ??
                            'Entry',
                      ),
                      subtitle: Text(
                        entry['date']
                                ?.toString() ??
                            '',
                      ),
                    ),
                  ),
                ),
              ],

              if (photos.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text(
                  'Saved foot photos',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...photos.map(
                  (photo) {
                    final raw =
                        photo['base64']
                                ?.toString() ??
                            '';

                    if (raw.isEmpty) {
                      return const SizedBox();
                    }

                    try {
                      return Card(
                        clipBehavior:
                            Clip.antiAlias,
                        margin:
                            const EdgeInsets.only(
                          bottom: 12,
                        ),
                        child: Image.memory(
                          base64Decode(raw),
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      );
                    } catch (_) {
                      return const SizedBox();
                    }
                  },
                ),
              ],

              if (!isReal) ...[
                const SizedBox(height: 10),
                Card(
                  color: Colors.blue.shade50,
                  child: const Padding(
                    padding:
                        EdgeInsets.all(14),
                    child: Text(
                      'DEMO PATIENT — this data is only here so you can test the doctor interface.',
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class DemoRequestsPage
    extends StatefulWidget {
  final String language;

  const DemoRequestsPage({
    super.key,
    required this.language,
  });

  @override
  State<DemoRequestsPage> createState() =>
      _DemoRequestsPageState();
}

class _DemoRequestsPageState
    extends State<DemoRequestsPage> {
  final store = KhatwaStore.instance;

  final List<Map<String, dynamic>>
      demoRequests = [
    {
      'name': 'Sarra Ben Amor',
      'specialty': 'Diabetology',
      'status': 'pending',
    },
    {
      'name': 'Youssef Khelifi',
      'specialty': 'Diabetic Foot',
      'status': 'pending',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final realRequests =
        store.doctorRequests;

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('📩 Requests'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(14),
            children: [
              ...realRequests.asMap().entries.map(
                (item) {
                  final index = item.key;
                  final request = item.value;

                  return _requestCard(
                    context,
                    name:
                        request['patientName']
                                ?.toString()
                                .isNotEmpty ==
                            true
                        ? request['patientName']
                              .toString()
                        : 'Anonymous patient',
                    specialty:
                        request['specialty']
                                ?.toString() ??
                            '',
                    status:
                        request['status']
                                ?.toString() ??
                            'pending',
                    onAccept: () async {
                      await store
                          .updateDoctorRequestStatus(
                        index,
                        'accepted',
                      );
                    },
                    onReject: () async {
                      await store
                          .updateDoctorRequestStatus(
                        index,
                        'rejected',
                      );
                    },
                  );
                },
              ),
              ...demoRequests.map(
                (request) => _requestCard(
                  context,
                  name:
                      request['name'] as String,
                  specialty:
                      request['specialty']
                          as String,
                  status:
                      request['status'] as String,
                  onAccept: () {
                    setState(() {
                      request['status'] =
                          'accepted';
                    });
                  },
                  onReject: () {
                    setState(() {
                      request['status'] =
                          'rejected';
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _requestCard(
    BuildContext context, {
    required String name,
    required String specialty,
    required String status,
    required VoidCallback onAccept,
    required VoidCallback onReject,
  }) {
    return Card(
      margin:
          const EdgeInsets.only(bottom: 11),
      child: ListTile(
        leading: const CircleAvatar(
          child: Text('👤'),
        ),
        title: Text(name),
        subtitle:
            Text('$specialty\nStatus: $status'),
        trailing:
            status == 'pending'
                ? Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: onAccept,
                        icon: const Icon(
                          Icons.check,
                          color: Colors.green,
                        ),
                      ),
                      IconButton(
                        onPressed: onReject,
                        icon: const Icon(
                          Icons.close,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  )
                : const Icon(
                    Icons.check_circle,
                  ),
      ),
    );
  }
}

class DoctorDossiersPage
    extends StatelessWidget {
  final String language;

  const DoctorDossiersPage({
    super.key,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final store = KhatwaStore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '📋 Patient Dossiers',
        ),
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              if (store.patientName
                  .isNotEmpty)
                Card(
                  child: ListTile(
                    leading: const Text(
                      '👤',
                      style: TextStyle(
                        fontSize: 28,
                      ),
                    ),
                    title:
                        Text(store.patientName),
                    subtitle:
                        const Text(
                      'Real saved patient dossier',
                    ),
                    trailing:
                        const Icon(
                      Icons.arrow_forward_ios,
                      size: 15,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              DoctorPatientDetailPage(
                            language: language,
                            patient: {
                              'id': store
                                      .patientId
                                      .isEmpty
                                  ? 'REAL-PATIENT'
                                  : store.patientId,
                              'name':
                                  store.patientName,
                              'age': '--',
                              'diabetes':
                                  store.diabetesType,
                              'city':
                                  'Patient account',
                              'status':
                                  'Saved data',
                              'avatar':
                                  'https://i.pravatar.cc/150?img=5',
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ..._demoPatients.map(
                (patient) => ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        NetworkImage(
                      patient['avatar'] as String,
                    ),
                  ),
                  title: Text(
                    patient['name'] as String,
                  ),
                  subtitle: const Text(
                    'Demo dossier',
                  ),
                  trailing:
                      const Icon(
                    Icons.arrow_forward_ios,
                    size: 15,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            DoctorPatientDetailPage(
                          patient: patient,
                          language: language,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class DemoReportsPage
    extends StatelessWidget {
  final String language;

  const DemoReportsPage({
    super.key,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final store = KhatwaStore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('📄 Reports'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          if (store.entries.isNotEmpty)
            Card(
              child: ListTile(
                leading: const Text(
                  '📋',
                  style: TextStyle(
                    fontSize: 28,
                  ),
                ),
                title: Text(
                  store.patientName.isEmpty
                      ? 'Real patient report'
                      : '${store.patientName} report',
                ),
                subtitle: const Text(
                  'Generated from saved patient entries',
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 15,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          RealDoctorReportPage(
                        language: language,
                      ),
                    ),
                  );
                },
              ),
            ),
          _demoReport(
            context,
            'Sarra Ben Amor',
            'Yellow flag',
          ),
          _demoReport(
            context,
            'Amel Jaziri',
            'Red flag',
          ),
          _demoReport(
            context,
            'Youssef Khelifi',
            'No alerts today',
          ),
        ],
      ),
    );
  }

  Widget _demoReport(
    BuildContext context,
    String patient,
    String status,
  ) {
    return Card(
      margin:
          const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Text(
          '📄',
          style: TextStyle(fontSize: 27),
        ),
        title: Text('$patient report'),
        subtitle: Text(
          'Status: $status\nDEMO REPORT',
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 15,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  DemoReportDetailPage(
                patientName: patient,
                status: status,
              ),
            ),
          );
        },
      ),
    );
  }
}

class RealDoctorReportPage
    extends StatelessWidget {
  final String language;

  const RealDoctorReportPage({
    super.key,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final store = KhatwaStore.instance;

    final report =
        KhatwaAiEngine.generateReport(store);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '📋 Patient Monitoring Report',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(18),
              child: Text(
                report,
                style: const TextStyle(
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding:
                  EdgeInsets.all(15),
              child: Text(
                'Doctor view: the report is based on the information saved in the patient dossier. Photo entries are stored and can be reviewed separately.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DemoReportDetailPage
    extends StatelessWidget {
  final String patientName;
  final String status;

  const DemoReportDetailPage({
    super.key,
    required this.patientName,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '📄 Demo Patient Report',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Text(
                '👤',
                style: TextStyle(
                  fontSize: 28,
                ),
              ),
              title: Text(patientName),
              subtitle: const Text(
                'DEMO PATIENT',
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.monitor_heart,
              ),
              title:
                  const Text('Screening status'),
              subtitle: Text(status),
            ),
          ),
          const Card(
            child: Padding(
              padding:
                  EdgeInsets.all(18),
              child: Text(
                'This is demo content so you can see how the doctor report interface looks.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DemoMessagesPage
    extends StatelessWidget {
  final String language;

  const DemoMessagesPage({
    super.key,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final store = KhatwaStore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('💬 Messages'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          ..._demoPatients.map(
            (patient) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      NetworkImage(
                    patient['avatar']
                        as String,
                  ),
                ),
                title: Text(
                  patient['name'] as String,
                ),
                subtitle: const Text(
                  'I have a question about my foot.',
                ),
                trailing:
                    const Icon(
                  Icons.arrow_forward_ios,
                  size: 15,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          DemoConversationPage(
                        patientName:
                            patient['name']
                                as String,
                        language: language,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (store.patientName
              .isNotEmpty)
            Card(
              child: ListTile(
                leading:
                    const CircleAvatar(
                  child: Text('👤'),
                ),
                title:
                    Text(store.patientName),
                subtitle: const Text(
                  'Real saved patient conversation',
                ),
                trailing:
                    const Icon(
                  Icons.arrow_forward_ios,
                  size: 15,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          RealConversationPage(
                        language: language,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class DemoConversationPage
    extends StatefulWidget {
  final String patientName;
  final String language;

  const DemoConversationPage({
    super.key,
    required this.patientName,
    required this.language,
  });

  @override
  State<DemoConversationPage> createState() =>
      _DemoConversationPageState();
}

class _DemoConversationPageState
    extends State<DemoConversationPage> {
  final controller =
      TextEditingController();

  final List<String> messages = [
    'Hello doctor, I have a question about my foot.',
    'Of course. Tell me what you noticed.',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.patientName),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding:
                  const EdgeInsets.all(14),
              itemCount: messages.length,
              itemBuilder:
                  (context, index) {
                return Align(
                  alignment:
                      index.isEven
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                  child: Card(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(
                        12,
                      ),
                      child: Text(
                        messages[index],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller:
                          controller,
                      decoration:
                          const InputDecoration(
                        hintText:
                            'Write a message...',
                        border:
                            OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      final value =
                          controller.text
                              .trim();

                      if (value.isEmpty) {
                        return;
                      }

                      setState(() {
                        messages.add(value);
                        controller.clear();
                      });
                    },
                    icon: const Icon(
                      Icons.send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RealConversationPage
    extends StatefulWidget {
  final String language;

  const RealConversationPage({
    super.key,
    required this.language,
  });

  @override
  State<RealConversationPage> createState() =>
      _RealConversationPageState();
}

class _RealConversationPageState
    extends State<RealConversationPage> {
  final store = KhatwaStore.instance;
  final controller =
      TextEditingController();

  Future<void> send() async {
    final message =
        controller.text.trim();

    if (message.isEmpty) return;

    await store.saveChatMessage(
      'doctor',
      message,
    );

    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          store.patientName.isEmpty
              ? 'Patient chat'
              : store.patientName,
        ),
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding:
                      const EdgeInsets.all(12),
                  itemCount:
                      store.chatMessages.length,
                  itemBuilder:
                      (context, index) {
                    final message =
                        store.chatMessages[
                            index];

                    final isDoctor =
                        message['sender'] ==
                            'doctor';

                    return Align(
                      alignment: isDoctor
                          ? Alignment
                              .centerRight
                          : Alignment
                              .centerLeft,
                      child: Card(
                        child: Padding(
                          padding:
                              const EdgeInsets.all(
                            11,
                          ),
                          child: Text(
                            message['message']
                                    ?.toString() ??
                                '',
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller:
                              controller,
                          decoration:
                              const InputDecoration(
                            hintText:
                                'Write a message...',
                            border:
                                OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: send,
                        icon: const Icon(
                          Icons.send,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}