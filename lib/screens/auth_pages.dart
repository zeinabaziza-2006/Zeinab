import 'package:flutter/material.dart';

import '../data/auth_store.dart';
import '../data/case_store.dart';
import '../data/khatwa_store.dart';
import '../ui/app_state.dart';
import '../ui/app_theme.dart';
import '../ui/foot_shapes.dart';
import '../ui/strings.dart';

/// Language + role. First screen of the app.
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = appLanguage.value;

    return Scaffold(
      backgroundColor: K.paper,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: PopupMenuButton<String>(
                      onSelected: (value) => appLanguage.value = value,
                      icon: const Icon(Icons.language_rounded, color: K.inkSoft),
                      itemBuilder: (context) => [
                        for (final language in S.languages)
                          PopupMenuItem<String>(value: language, child: Text(language)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const _Wordmark(),
                  const SizedBox(height: 14),
                  Text(
                    S.t(lang, 'app.tagline'),
                    textAlign: TextAlign.center,
                    style: K.body.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 34),
                  Text(S.t(lang, 'role.choose'),
                      textAlign: TextAlign.center, style: K.label),
                  const SizedBox(height: 14),
                  _RoleCard(
                    title: S.t(lang, 'role.patient'),
                    subtitle: S.t(lang, 'home.todaySub'),
                    icon: Icons.person_outline_rounded,
                    accent: K.primary,
                    accentSoft: K.primarySoft,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AuthPage(role: 'patient')),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _RoleCard(
                    title: S.t(lang, 'role.doctor'),
                    subtitle: S.t(lang, 'doctor.queue'),
                    icon: Icons.medical_services_outlined,
                    accent: K.accent,
                    accentSoft: K.accentSoft,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AuthPage(role: 'doctor')),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    S.t(lang, 'report.disclaimer'),
                    textAlign: TextAlign.center,
                    style: K.small,
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

/// The mark: a footprint stepping forward, which is what "khatwa" means.
/// The trailing print is the step already taken, the solid one is today.
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            color: K.primaryDark,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 13,
                top: 26,
                child: Transform.rotate(
                  angle: -0.20,
                  child: SizedBox(
                    width: 19,
                    height: 27,
                    child: CustomPaint(
                      painter: FootBadgePainter(
                        side: FootSide.left,
                        color: Color(0x4DFFFFFF),
                        filled: true,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: 14,
                child: Transform.rotate(
                  angle: -0.20,
                  child: SizedBox(
                    width: 25,
                    height: 36,
                    child: CustomPaint(
                      painter: FootBadgePainter(
                        side: FootSide.right,
                        color: Colors.white,
                        filled: true,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Khatwa', style: K.display),
        const SizedBox(height: 2),
        Container(width: 38, height: 3, color: K.accent),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Color accentSoft;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.accentSoft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return KCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accentSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: K.h2),
                const SizedBox(height: 2),
                Text(subtitle, style: K.small, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: K.muted),
        ],
      ),
    );
  }
}

/// Sign in and sign up, with real credential checks.
class AuthPage extends StatefulWidget {
  final String role;

  const AuthPage({super.key, required this.role});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool signUpMode = false;
  bool busy = false;
  String? error;

  final name = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  final speciality = TextEditingController();
  final facility = TextEditingController();
  final pin = TextEditingController();

  bool get isDoctor => widget.role == 'doctor';

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    password.dispose();
    confirm.dispose();
    speciality.dispose();
    facility.dispose();
    pin.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final lang = appLanguage.value;
    setState(() {
      busy = true;
      error = null;
    });

    final store = AuthStore.instance;
    final result = signUpMode
        ? await store.signUp(
            name: name.text,
            phone: phone.text,
            password: password.text,
            confirm: confirm.text,
            pin: pin.text,
            role: widget.role,
            speciality: speciality.text,
            facility: facility.text,
          )
        : await store.signIn(
            phone: phone.text,
            password: password.text,
            pin: pin.text,
            role: widget.role,
          );

    if (!mounted) return;

    if (result == AuthError.none) {
      // The data encryption key is now in memory: load and decrypt the store.
      await CaseStore.instance.unlock();
      await KhatwaStore.instance.reload();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    var message = S.t(lang, store.errorKey(result));
    if (result == AuthError.locked) {
      final seconds = store.lockedSeconds(phone.text, widget.role);
      message = '$message · $seconds ${S.t(lang, 'auth.lockedFor')}';
    }

    setState(() {
      busy = false;
      error = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = appLanguage.value;

    return KPage(
      title: signUpMode ? S.t(lang, 'auth.signup') : S.t(lang, 'auth.signin'),
      subtitle: isDoctor ? S.t(lang, 'role.doctor') : S.t(lang, 'role.patient'),
      actions: const [LanguageButton()],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 14),
          KCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (signUpMode)
                  KField(
                    label: S.t(lang, 'auth.name'),
                    controller: name,
                  ),
                KField(
                  label: S.t(lang, 'auth.phone'),
                  hint: '20 000 000',
                  controller: phone,
                  keyboard: TextInputType.phone,
                ),
                if (signUpMode && isDoctor) ...[
                  KField(label: S.t(lang, 'auth.speciality'), controller: speciality),
                  KField(label: S.t(lang, 'auth.facility'), controller: facility),
                ],
                KField(
                  label: S.t(lang, 'auth.password'),
                  controller: password,
                  obscure: true,
                ),
                if (signUpMode)
                  KField(
                    label: S.t(lang, 'auth.confirm'),
                    controller: confirm,
                    obscure: true,
                  ),
                KField(
                  label: S.t(lang, 'auth.pin'),
                  controller: pin,
                  obscure: true,
                  keyboard: TextInputType.number,
                  hint: '••••',
                ),
                if (signUpMode) ...[
                  Text(S.t(lang, 'auth.pinHint'), style: K.small),
                  const SizedBox(height: 14),
                ],
                if (error != null) ...[
                  KBanner(
                    text: error!,
                    icon: Icons.error_outline_rounded,
                    color: K.danger,
                    background: K.dangerSoft,
                  ),
                  const SizedBox(height: 14),
                ],
                FilledButton(
                  onPressed: busy ? null : submit,
                  child: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(signUpMode ? S.t(lang, 'auth.signup') : S.t(lang, 'auth.signin')),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: busy
                      ? null
                      : () => setState(() {
                            signUpMode = !signUpMode;
                            error = null;
                          }),
                  child: Text(signUpMode ? S.t(lang, 'auth.have') : S.t(lang, 'auth.none')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          KBanner(
            text: S.t(lang, 'auth.secure'),
            icon: Icons.lock_outline_rounded,
          ),
          const SizedBox(height: 10),
          KBanner(
            text: S.t(lang, 'security.encrypted'),
            icon: Icons.enhanced_encryption_outlined,
            color: K.ok,
            background: K.okSoft,
          ),
        ],
      ),
    );
  }
}
