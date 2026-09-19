import 'package:flutter/material.dart';

/// Khatwa design system.
/// Warm paper surfaces, deep clinical teal, terracotta accent.
/// Everything the app draws goes through these tokens.
class K {
  // ---- palette ----
  static const ink = Color(0xFF12262B);
  static const inkSoft = Color(0xFF3D5158);
  static const muted = Color(0xFF7A8A8F);
  static const line = Color(0xFFE2DDD3);
  static const paper = Color(0xFFF7F4EF);
  static const card = Color(0xFFFFFFFF);

  static const primary = Color(0xFF0D5C63);
  static const primaryDark = Color(0xFF083E45);
  static const primarySoft = Color(0xFFE3EFEF);

  static const accent = Color(0xFFC96A3C);
  static const accentSoft = Color(0xFFF6E9E1);

  static const ok = Color(0xFF2F7A5B);
  static const okSoft = Color(0xFFE5F0EA);
  static const warn = Color(0xFFB8791B);
  static const warnSoft = Color(0xFFFBF0DC);
  static const danger = Color(0xFFB4392C);
  static const dangerSoft = Color(0xFFF8E6E3);

  // ---- spacing / radius ----
  static const r8 = 8.0;
  static const r14 = 14.0;
  static const r20 = 20.0;

  // ---- type ----
  static const display = TextStyle(
      fontSize: 30, height: 1.15, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.6);
  static const h1 = TextStyle(
      fontSize: 22, height: 1.2, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.3);
  static const h2 = TextStyle(
      fontSize: 17, height: 1.25, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.2);
  static const body = TextStyle(fontSize: 15, height: 1.45, color: inkSoft);
  static const bodyStrong =
      TextStyle(fontSize: 15, height: 1.45, color: ink, fontWeight: FontWeight.w600);
  static const small = TextStyle(fontSize: 13, height: 1.4, color: muted);
  static const label = TextStyle(
      fontSize: 11, fontWeight: FontWeight.w700, color: muted, letterSpacing: 0.9);

  static ThemeData theme() {
    final scheme = const ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      secondary: accent,
      onSecondary: Colors.white,
      surface: card,
      onSurface: ink,
      error: danger,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: paper,
      splashFactory: InkRipple.splashFactory,
      textTheme: const TextTheme(
        titleLarge: h1,
        titleMedium: h2,
        bodyMedium: body,
        bodySmall: small,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Page shell: fixed header, scrollable body, max content width for web.
class KPage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;
  final bool showBack;
  final Widget? bottom;
  final Color background;

  const KPage({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
    this.showBack = true,
    this.bottom,
    this.background = K.paper,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(title: title, subtitle: subtitle, actions: actions, showBack: showBack),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
                    child: child,
                  ),
                ),
              ),
            ),
            if (bottom != null)
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: K.card,
                  border: Border(top: BorderSide(color: K.line)),
                ),
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: bottom,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final bool showBack;

  const _Header({
    required this.title,
    required this.subtitle,
    required this.actions,
    required this.showBack,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = showBack && Navigator.of(context).canPop();
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: K.paper,
        border: Border(bottom: BorderSide(color: K.line)),
      ),
      padding: const EdgeInsets.fromLTRB(10, 10, 14, 14),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (canPop)
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded, color: K.ink),
                  tooltip: 'Back',
                )
              else
                const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: K.h1),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: K.small),
                    ],
                  ],
                ),
              ),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}

class KCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;

  const KCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final body = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? K.card,
        borderRadius: BorderRadius.circular(K.r20),
        border: Border.all(color: borderColor ?? K.line),
      ),
      child: child,
    );
    if (onTap == null) return body;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(K.r20),
        onTap: onTap,
        child: body,
      ),
    );
  }
}

class KSectionLabel extends StatelessWidget {
  final String text;
  const KSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(text.toUpperCase(), style: K.label));
}

class KField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboard;
  final String? errorText;
  final Widget? suffix;
  final int maxLines;

  const KField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.obscure = false,
    this.keyboard,
    this.errorText,
    this.suffix,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: K.bodyStrong),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboard,
          maxLines: obscure ? 1 : maxLines,
          style: const TextStyle(fontSize: 16, color: K.ink),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: K.muted, fontSize: 15),
            errorText: errorText,
            filled: true,
            fillColor: K.card,
            suffixIcon: suffix,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(K.r14),
              borderSide: const BorderSide(color: K.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(K.r14),
              borderSide: const BorderSide(color: K.primary, width: 1.6),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(K.r14),
              borderSide: const BorderSide(color: K.danger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(K.r14),
              borderSide: const BorderSide(color: K.danger, width: 1.6),
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}

class KBanner extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final Color background;

  const KBanner({
    super.key,
    required this.text,
    this.icon = Icons.info_outline_rounded,
    this.color = K.primaryDark,
    this.background = K.primarySoft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(K.r14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 13.5, height: 1.4, color: color, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class KTag extends StatelessWidget {
  final String text;
  final Color color;
  final Color background;
  const KTag(this.text, {super.key, this.color = K.inkSoft, this.background = K.primarySoft});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
        child: Text(text,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.2)),
      );
}

void kToast(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: error ? K.danger : K.ink,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(K.r14)),
      margin: const EdgeInsets.all(14),
    ),
  );
}
