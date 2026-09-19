import 'dart:async';

import 'package:flutter/material.dart';

import 'data/ai_gateway.dart';
import 'data/auth_store.dart';
import 'data/case_store.dart';
import 'data/khatwa_store.dart';
import 'screens/auth_pages.dart';
import 'screens/doctor_home.dart';
import 'screens/patient_home.dart';
import 'ui/app_state.dart';
import 'ui/app_theme.dart';
import 'ui/strings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await KhatwaStore.instance.init();
  await AuthStore.instance.init();
  await CaseStore.instance.init();
  await ApiConfig.load();
  await loadTextScale();

  runApp(const KhatwaApp());
}

class KhatwaApp extends StatelessWidget {
  const KhatwaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: appTextScale,
      builder: (context, scale, __) => ValueListenableBuilder<String>(
      valueListenable: appLanguage,
      builder: (context, language, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Khatwa',
          theme: K.theme(),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
              ),
              child: Directionality(
                textDirection:
                    S.isRtl(language) ? TextDirection.rtl : TextDirection.ltr,
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
          home: const RootGate(),
        );
      },
      ),
    );
  }
}

/// Decides where the app opens, and enforces the idle timeout.
///
/// A shared clinician workstation must not stay open on a patient record, so
/// after ten minutes without interaction the session is closed and the
/// decrypted records are dropped from memory.
class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    _idleTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (AuthStore.instance.idleExpired) {
        CaseStore.instance.lock();
        AuthStore.instance.signOut();
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    });
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => AuthStore.instance.touch(),
      onPointerSignal: (_) => AuthStore.instance.touch(),
      child: AnimatedBuilder(
        animation: AuthStore.instance,
        builder: (context, _) {
          final account = AuthStore.instance.current;
          if (account == null) return const LandingPage();
          if (account.role == 'doctor') {
            return DoctorHomePage(language: appLanguage.value);
          }
          return PatientHomePage(language: appLanguage.value);
        },
      ),
    );
  }
}
