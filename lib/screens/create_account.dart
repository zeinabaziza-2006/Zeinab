import 'dart:math';
import 'package:flutter/material.dart';
import 'patient_dashboard.dart';

class CreateAccountPage extends StatefulWidget {
  final String language;

  const CreateAccountPage({
    super.key,
    required this.language,
  });

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool showPassword = false;
  bool showConfirm = false;

  late String patientId;

  final Map<String, Map<String, String>> texts = {
    'English': {
      'title': 'Secure your account',
      'subtitle': 'Create your password',
      'description':
          'Choose a strong password that you will use to access your Khatwa account.',
      'password': 'Password',
      'passwordHint': 'Create a password',
      'confirm': 'Confirm password',
      'confirmHint': 'Enter your password again',
      'requirements': 'Password should contain at least 8 characters.',
      'continue': 'Create my account',
      'empty': 'Please fill in both password fields.',
      'short': 'Password must contain at least 8 characters.',
      'different': 'The passwords do not match.',
      'created': 'Account created successfully ✓',
      'yourId': 'Your Patient ID',
      'saveId':
          'Keep this ID safe. You can use it to communicate with your doctor.',
      'idCopied': 'Patient ID copied ✓',
      'goDashboard': 'Go to my dashboard',
    },
    'Français': {
      'title': 'Sécurisez votre compte',
      'subtitle': 'Créez votre mot de passe',
      'description':
          'Choisissez un mot de passe sécurisé pour accéder à votre compte Khatwa.',
      'password': 'Mot de passe',
      'passwordHint': 'Créez un mot de passe',
      'confirm': 'Confirmer le mot de passe',
      'confirmHint': 'Entrez votre mot de passe à nouveau',
      'requirements':
          'Le mot de passe doit contenir au moins 8 caractères.',
      'continue': 'Créer mon compte',
      'empty': 'Veuillez remplir les deux champs.',
      'short':
          'Le mot de passe doit contenir au moins 8 caractères.',
      'different': 'Les mots de passe ne correspondent pas.',
      'created': 'Compte créé avec succès ✓',
      'yourId': 'Votre identifiant patient',
      'saveId':
          'Gardez cet identifiant. Il pourra être utilisé pour communiquer avec votre médecin.',
      'idCopied': 'Identifiant copié ✓',
      'goDashboard': 'Accéder à mon tableau de bord',
    },
    'العربية': {
      'title': 'حماية حسابك',
      'subtitle': 'أنشئ كلمة المرور',
      'description':
          'اختر كلمة مرور قوية لاستخدامها للوصول إلى حسابك في خطوة.',
      'password': 'كلمة المرور',
      'passwordHint': 'أنشئ كلمة مرور',
      'confirm': 'تأكيد كلمة المرور',
      'confirmHint': 'أدخل كلمة المرور مرة أخرى',
      'requirements':
          'يجب أن تحتوي كلمة المرور على 8 أحرف على الأقل.',
      'continue': 'إنشاء حسابي',
      'empty': 'يرجى ملء حقلي كلمة المرور.',
      'short': 'يجب أن تحتوي كلمة المرور على 8 أحرف على الأقل.',
      'different': 'كلمتا المرور غير متطابقتين.',
      'created': 'تم إنشاء الحساب بنجاح ✓',
      'yourId': 'معرّف المريض الخاص بك',
      'saveId':
          'احتفظ بهذا المعرّف. يمكنك استعماله للتواصل مع طبيبك.',
      'idCopied': 'تم نسخ معرّف المريض ✓',
      'goDashboard': 'الذهاب إلى لوحة التحكم',
    },
    'تونسي': {
      'title': 'أمّن حسابك',
      'subtitle': 'اعمل كلمة السر',
      'description':
          'إختار كلمة سر قوية باش تستعملها للدخول لحسابك في خطوة.',
      'password': 'كلمة السر',
      'passwordHint': 'اعمل كلمة سر',
      'confirm': 'عاود كلمة السر',
      'confirmHint': 'عاود دخل كلمة السر',
      'requirements':
          'كلمة السر يلزمها تكون فيها 8 حروف على الأقل.',
      'continue': 'اعمل حسابي',
      'empty': 'عمّر الخانتين متاع كلمة السر.',
      'short': 'كلمة السر يلزمها تكون فيها 8 حروف على الأقل.',
      'different': 'كلمات السر موش كيف كيف.',
      'created': 'الحساب تعمل بنجاح ✓',
      'yourId': 'معرّف المريض متاعك',
      'saveId':
          'حافظ على المعرّف هذا. تنجم تستعملو باش تتواصل مع طبيبك.',
      'idCopied': 'المعرّف تنسخ ✓',
      'goDashboard': 'امشي للوحة التحكم',
    },
  };

  @override
  void initState() {
    super.initState();
    patientId = generatePatientId();
  }

  String generatePatientId() {
    final random = Random();
    final number = 100000 + random.nextInt(900000);
    return 'KHT-$number';
  }

  void createAccount() {
    final t = texts[widget.language]!;

    if (passwordController.text.isEmpty ||
        confirmController.text.isEmpty) {
      showMessage(t['empty']!);
      return;
    }

    if (passwordController.text.length < 8) {
      showMessage(t['short']!);
      return;
    }

    if (passwordController.text != confirmController.text) {
      showMessage(t['different']!);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            t['created']!,
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF167D8D),
                  size: 70,
                ),

                const SizedBox(height: 20),

                Text(
                  t['yourId']!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F5F5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        patientId,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF167D8D),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          showMessage(t['idCopied']!);
                        },
                        icon: const Icon(
                          Icons.copy_outlined,
                          color: Color(0xFF167D8D),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                Text(
                  t['saveId']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PatientDashboardPage(
                        language: widget.language,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF167D8D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  t['goDashboard']!,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget passwordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool visible,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            obscureText: !visible,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: onPressed,
                icon: Icon(
                  visible
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF7FAFA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
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

  Widget progressCircle(bool active) {
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

  Widget progressLine() {
    return Expanded(
      child: Container(
        height: 3,
        color: Colors.grey.shade300,
      ),
    );
  }

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
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    progressCircle(true),
                    progressLine(),
                    progressCircle(true),
                    progressLine(),
                    progressCircle(true),
                  ],
                ),

                const SizedBox(height: 30),

                Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFF167D8D),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      color: Colors.white,
                      size: 45,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                Center(
                  child: Text(
                    t['title']!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF123B43),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Center(
                  child: Text(
                    t['subtitle']!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF167D8D),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  t['description']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 30),

                passwordField(
                  label: t['password']!,
                  hint: t['passwordHint']!,
                  controller: passwordController,
                  visible: showPassword,
                  onPressed: () {
                    setState(() {
                      showPassword = !showPassword;
                    });
                  },
                ),

                const SizedBox(height: 16),

                passwordField(
                  label: t['confirm']!,
                  hint: t['confirmHint']!,
                  controller: confirmController,
                  visible: showConfirm,
                  onPressed: () {
                    setState(() {
                      showConfirm = !showConfirm;
                    });
                  },
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF167D8D),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t['requirements']!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      createAccount();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF167D8D),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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

  @override
  void dispose() {
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }
}