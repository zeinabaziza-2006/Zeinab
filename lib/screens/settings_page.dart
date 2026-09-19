import 'package:flutter/material.dart';

import '../data/ai_gateway.dart';
import '../ui/app_state.dart';
import '../ui/app_theme.dart';
import '../ui/strings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final key = TextEditingController();
  bool testing = false;
  bool obscure = true;

  String get lang => appLanguage.value;

  @override
  void initState() {
    super.initState();
    if (ApiConfig.source == 'device') key.text = ApiConfig.key;
  }

  @override
  void dispose() {
    key.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configured = ApiConfig.hasKey;

    return KPage(
      title: S.t(lang, 'settings.title'),
      actions: const [LanguageButton()],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 14),
          KBanner(
            text: configured
                ? '${S.t(lang, 'settings.key')} · ${ApiConfig.source == 'build' ? '--dart-define' : 'device'}'
                : S.t(lang, 'settings.keyMissing'),
            icon: configured ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded,
            color: configured ? K.ok : K.warn,
            background: configured ? K.okSoft : K.warnSoft,
          ),
          const SizedBox(height: 16),
          KCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KField(
                  label: S.t(lang, 'settings.key'),
                  controller: key,
                  obscure: obscure,
                  hint: 'AIza...',
                  suffix: IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 20,
                      color: K.muted,
                    ),
                    onPressed: () => setState(() => obscure = !obscure),
                  ),
                ),
                Text(S.t(lang, 'settings.keyHint'), style: K.small),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    await ApiConfig.setKey(key.text);
                    if (!mounted) return;
                    setState(() {});
                    kToast(context, S.t(lang, 'common.save'));
                  },
                  child: Text(S.t(lang, 'common.save')),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: testing
                      ? null
                      : () async {
                          setState(() => testing = true);
                          final ok = await AiGateway.testKey();
                          if (!mounted) return;
                          setState(() => testing = false);
                          kToast(
                            context,
                            ok ? S.t(lang, 'settings.ok') : S.t(lang, 'common.error'),
                            error: !ok,
                          );
                        },
                  icon: testing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_tethering_rounded, size: 18),
                  label: Text(S.t(lang, 'settings.test')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          KSectionLabel(S.t(lang, 'settings.textSize')),
          KCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(S.t(lang, 'settings.textSizeHint'), style: K.small),
                const SizedBox(height: 12),
                ValueListenableBuilder<double>(
                  valueListenable: appTextScale,
                  builder: (context, scale, _) => Row(
                    children: [
                      for (final option in const [1.0, 1.15, 1.3]) ...[
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(K.r14),
                            onTap: () => saveTextScale(option),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: scale == option ? K.primarySoft : K.card,
                                border: Border.all(
                                  color: scale == option ? K.primary : K.line,
                                  width: scale == option ? 1.6 : 1,
                                ),
                                borderRadius: BorderRadius.circular(K.r14),
                              ),
                              child: Text(
                                'A',
                                style: TextStyle(
                                  fontSize: 14 * option * 1.2,
                                  fontWeight: FontWeight.w700,
                                  color: scale == option ? K.primaryDark : K.muted,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (option != 1.3) const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          KCard(
            color: K.paper,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Khatwa', style: K.h2),
                const SizedBox(height: 6),
                Text(S.t(lang, 'app.tagline'), style: K.small),
                const SizedBox(height: 12),
                const Text(
                  'Future Health Connectathon 2026 · Défi 3.1\n'
                  'Repérer plus tôt les signes d alerte du pied diabétique',
                  style: K.small,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
