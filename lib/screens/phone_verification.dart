import 'dart:async';
import 'package:flutter/material.dart';
import 'otp_verification.dart';

class PhoneVerificationPage extends StatefulWidget {
  final String language;

  const PhoneVerificationPage({
    super.key,
    required this.language,
  });

  @override
  State<PhoneVerificationPage> createState() =>
      _PhoneVerificationPageState();
}

class _PhoneVerificationPageState
    extends State<PhoneVerificationPage> {
  final TextEditingController phoneController =
      TextEditingController();

  Timer? timer;
  int secondsLeft = 0;

  final Map<String, Map<String, String>> texts = {
    'English': {
      'title': 'Verify your phone',
      'welcome': 'Let’s secure your account',
      'description':
          'Enter your phone number. We will send you a 6-digit verification code.',
      'phone': 'Phone number',
      'hint': 'Example: +216 20 123 456',
      'send': 'Send verification code',
      'resend': 'Resend code',
      'change': 'Change phone number',
      'notReceived': 'Didn’t receive the code?',
      'wait': 'You can resend the code in',
      'seconds': 'seconds',
      'empty': 'Please enter your phone number.',
      'short': 'Please enter a valid phone number.',
      'sent': 'Verification code sent ✓',
      'privacy':
          'Your phone number is private and securely protected.',
    },
    'Français': {
      'title': 'Vérifier votre téléphone',
      'welcome': 'Sécurisons votre compte',
      'description':
          'Entrez votre numéro de téléphone. Nous vous enverrons un code de vérification à 6 chiffres.',
      'phone': 'Numéro de téléphone',
      'hint': 'Exemple : +216 20 123 456',
      'send': 'Envoyer le code de vérification',
      'resend': 'Renvoyer le code',
      'change': 'Modifier le numéro',
      'notReceived': 'Vous n’avez pas reçu le code ?',
      'wait': 'Vous pouvez renvoyer le code dans',
      'seconds': 'secondes',
      'empty': 'Veuillez entrer votre numéro.',
      'short': 'Veuillez entrer un numéro valide.',
      'sent': 'Code de vérification envoyé ✓',
      'privacy':
          'Votre numéro est privé et protégé de manière sécurisée.',
    },
    'العربية': {
      'title': 'تأكيد رقم الهاتف',
      'welcome': 'لنؤمّن حسابك',
      'description':
          'أدخل رقم هاتفك. سنرسل لك رمز تحقق مكوّنًا من 6 أرقام.',
      'phone': 'رقم الهاتف',
      'hint': 'مثال: +216 20 123 456',
      'send': 'إرسال رمز التحقق',
      'resend': 'إعادة إرسال الرمز',
      'change': 'تغيير رقم الهاتف',
      'notReceived': 'لم يصلك الرمز؟',
      'wait': 'يمكنك إعادة إرسال الرمز بعد',
      'seconds': 'ثانية',
      'empty': 'يرجى إدخال رقم الهاتف.',
      'short': 'يرجى إدخال رقم هاتف صالح.',
      'sent': 'تم إرسال رمز التحقق ✓',
      'privacy':
          'رقم هاتفك خاص ومحمي بشكل آمن.',
    },
    'تونسي': {
      'title': 'ثبّت نومرو التليفون',
      'welcome': 'خلّينا نأمّنو حسابك',
      'description':
          'دخل نومرو تليفونك. باش نبعثولك كود تثبّت فيه 6 أرقام.',
      'phone': 'نومرو التليفون',
      'hint': 'مثال: +216 20 123 456',
      'send': 'ابعثلي كود التثبّت',
      'resend': 'عاود ابعث الكود',
      'change': 'بدّل نومرو التليفون',
      'notReceived': 'ما وصلكش الكود؟',
      'wait': 'تنجم تعاود تبعث الكود بعد',
      'seconds': 'ثانية',
      'empty': 'دخل نومرو التليفون.',
      'short': 'دخل نومرو صحيح.',
      'sent': 'الكود تبعث ✓',
      'privacy':
          'نومروك يبقى خاص ومأمّن.',
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

                // Phone icon
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFF167D8D),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(
                    Icons.phone_android,
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

                const SizedBox(height: 10),

                Text(
                  t['welcome']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF167D8D),
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

                // Phone input card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        t['phone']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: t['hint'],
                          prefixIcon:
                              const Icon(Icons.phone_outlined),
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
                ),

                const SizedBox(height: 18),

                // Privacy
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
                        t['privacy']!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Send button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: sendCode,
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
                      t['send']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Didn't receive
                Text(
                  t['notReceived']!,
                  style: const TextStyle(
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 8),

                if (secondsLeft > 0)
                  Text(
                    '${t['wait']} $secondsLeft ${t['seconds']}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black45,
                      fontSize: 13,
                    ),
                  )
                else
                  TextButton(
                    onPressed: resendCode,
                    child: Text(
                      t['resend']!,
                      style: const TextStyle(
                        color: Color(0xFF167D8D),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                const SizedBox(height: 5),

                // Change number
                TextButton.icon(
                  onPressed: changeNumber,
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 18,
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

  void sendCode() {
    final phone = phoneController.text.trim();
    final t = texts[widget.language]!;

    if (phone.isEmpty) {
      showMessage(t['empty']!);
      return;
    }

    if (phone.length < 8) {
      showMessage(t['short']!);
      return;
    }

    startTimer();

    showMessage(t['sent']!);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationPage(
            language: widget.language,
            phoneNumber: phone,
          ),
        ),
      );
    });
  }

  void resendCode() {
    if (secondsLeft > 0) return;

    startTimer();

    final t = texts[widget.language]!;

    showMessage(t['sent']!);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationPage(
            language: widget.language,
            phoneNumber:
                phoneController.text.trim(),
          ),
        ),
      );
    });
  }

  void changeNumber() {
    phoneController.clear();

    if (timer != null) {
      timer!.cancel();
    }

    setState(() {
      secondsLeft = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          texts[widget.language]!['change']!,
        ),
      ),
    );
  }

  void startTimer() {
    timer?.cancel();

    setState(() {
      secondsLeft = 30;
    });

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (secondsLeft <= 1) {
          timer.cancel();

          if (mounted) {
            setState(() {
              secondsLeft = 0;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              secondsLeft--;
            });
          }
        }
      },
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    phoneController.dispose();
    super.dispose();
  }
}
