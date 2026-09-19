import 'package:flutter/material.dart';
import 'medical_information.dart';

class OtpVerificationPage extends StatefulWidget {
  final String language;
  final String phoneNumber;

  const OtpVerificationPage({
    super.key,
    required this.language,
    required this.phoneNumber,
  });

  @override
  State<OtpVerificationPage> createState() =>
      _OtpVerificationPageState();
}

class _OtpVerificationPageState
    extends State<OtpVerificationPage> {
  final TextEditingController codeController =
      TextEditingController();

  final Map<String, Map<String, String>> texts = {
    'English': {
      'title': 'Verify your number',
      'subtitle': 'Enter the 6-digit code sent to',
      'code': 'Verification code',
      'hint': 'Enter 6-digit code',
      'verify': 'Verify',
      'resend': 'Resend code',
      'change': 'Change phone number',
      'wrong': 'Incorrect code. Please try again.',
      'empty': 'Please enter the 6-digit code.',
      'success': 'Phone number verified ✓',
      'demo': 'For this prototype, use: 123456',
    },
    'Français': {
      'title': 'Vérifiez votre numéro',
      'subtitle': 'Entrez le code à 6 chiffres envoyé au',
      'code': 'Code de vérification',
      'hint': 'Entrez le code à 6 chiffres',
      'verify': 'Vérifier',
      'resend': 'Renvoyer le code',
      'change': 'Modifier le numéro',
      'wrong': 'Code incorrect. Veuillez réessayer.',
      'empty': 'Veuillez entrer le code à 6 chiffres.',
      'success': 'Numéro vérifié ✓',
      'demo': 'Pour ce prototype, utilisez : 123456',
    },
    'العربية': {
      'title': 'تأكيد رقم الهاتف',
      'subtitle': 'أدخل رمز التحقق المرسل إلى',
      'code': 'رمز التحقق',
      'hint': 'أدخل الرمز المكوّن من 6 أرقام',
      'verify': 'تأكيد',
      'resend': 'إعادة إرسال الرمز',
      'change': 'تغيير رقم الهاتف',
      'wrong': 'الرمز غير صحيح. حاول مرة أخرى.',
      'empty': 'يرجى إدخال رمز التحقق.',
      'success': 'تم تأكيد رقم الهاتف ✓',
      'demo': 'للتجربة، أدخل: 123456',
    },
    'تونسي': {
      'title': 'ثبّت نومروك',
      'subtitle': 'دخل الكود متاع 6 أرقام اللي تبعثلك على',
      'code': 'كود التثبّت',
      'hint': 'دخل الكود متاع 6 أرقام',
      'verify': 'ثبّت',
      'resend': 'عاود ابعث الكود',
      'change': 'بدّل نومرو التليفون',
      'wrong': 'الكود غالط. عاود جرّب.',
      'empty': 'دخل الكود متاع 6 أرقام.',
      'success': 'نومرو التليفون تثبّت ✓',
      'demo': 'للتجربة، دخل: 123456',
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
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),

                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFF167D8D),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(
                    Icons.sms_outlined,
                    color: Colors.white,
                    size: 45,
                  ),
                ),

                const SizedBox(height: 28),

                Text(
                  t['title']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF123B43),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  t['subtitle']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  widget.phoneNumber,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF167D8D),
                  ),
                ),

                const SizedBox(height: 35),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    t['code']!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: t['hint'],
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFF167D8D),
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                Text(
                  t['demo']!,
                  style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: verifyCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF167D8D),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      t['verify']!,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                TextButton(
                  onPressed: () {
                    codeController.clear();

                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      SnackBar(
                        content: Text(t['resend']!),
                      ),
                    );
                  },
                  child: Text(
                    t['resend']!,
                    style: const TextStyle(
                      color: Color(0xFF167D8D),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF167D8D),
                  ),
                  label: Text(
                    t['change']!,
                    style: const TextStyle(
                      color: Color(0xFF167D8D),
                      fontWeight: FontWeight.bold,
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

  void verifyCode() {
    final code = codeController.text.trim();
    final t = texts[widget.language]!;

    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t['empty']!),
        ),
      );
      return;
    }

    if (code == '123456') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t['success']!),
        ),
      );

      Future.delayed(
        const Duration(milliseconds: 500),
        () {
          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  MedicalInformationPage(
                language: widget.language,
              ),
            ),
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t['wrong']!),
        ),
      );
    }
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }
}
