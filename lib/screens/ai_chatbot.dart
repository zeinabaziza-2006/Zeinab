import 'package:flutter/material.dart';

import '../data/ai_gateway.dart';
import '../data/case_store.dart';
import '../data/khatwa_store.dart';
import '../data/triage.dart';
import '../ui/app_state.dart';
import '../ui/app_theme.dart';
import '../ui/strings.dart';

/// Conversational assistant, backed by Gemini when a key is configured and by
/// a safe scripted fallback when it is not. It never diagnoses, and it escalates
/// red flags to a human.
class AiChatbotPage extends StatefulWidget {
  final String language;
  final String role;

  const AiChatbotPage({
    super.key,
    required this.language,
    this.role = 'patient',
  });

  @override
  State<AiChatbotPage> createState() => _AiChatbotPageState();
}

class _AiChatbotPageState extends State<AiChatbotPage> {
  final KhatwaStore store = KhatwaStore.instance;
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final List<Map<String, String>> messages = [];
  bool sending = false;

  bool get isDoctor => widget.role == 'doctor';

  String get lang => appLanguage.value;

  @override
  void initState() {
    super.initState();
    messages.add({'role': 'model', 'text': _greeting()});
  }

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  String _greeting() {
    if (isDoctor) {
      switch (lang) {
        case 'Français':
          return 'Bonjour. Posez vos questions sur un cas de la file, le triage ou le protocole.';
        case 'English':
          return 'Hello. Ask about a case in the queue, the triage or the protocol.';
        case 'العربية':
          return 'مرحبا. اسأل عن أي حالة في القائمة أو عن الفرز أو البروتوكول.';
        default:
          return 'أهلا. أسأل على أي حالة في القائمة ولا على الفرز.';
      }
    }
    switch (lang) {
      case 'Français':
        return 'Bonjour. Je peux vous aider sur vos pieds, vos contrôles et vos habitudes. Je ne remplace pas votre médecin.';
      case 'English':
        return 'Hello. I can help with your feet, your checks and your habits. I do not replace your doctor.';
      case 'العربية':
        return 'مرحبا. نجم نعاونك في متابعة قدميك وعاداتك اليومية. أنا لا أعوض الطبيب.';
      default:
        return 'أهلا. نجم نعاونك في ساقيك وفي المتابعة متاعك. أما ما نعوضش الطبيب.';
    }
  }

  Map<String, dynamic> _context() {
    final cases = CaseStore.instance.all;
    final last = cases.isNotEmpty ? cases.first : null;
    return {
      'patientName': store.patientName,
      'diabetesType': store.diabetesType,
      'medications': store.medications,
      'allergies': store.allergies,
      'otherConditions': store.otherConditions,
      'lastCheck': last == null
          ? 'aucun contrôle enregistré'
          : {
              'date': last.createdAt,
              'level': levelToString(last.triage.level),
              'findings': last.triage.findings.map((f) => f.label).toList(),
              'status': last.status,
            },
      'queueSize': isDoctor ? CaseStore.instance.submitted.length : null,
    };
  }

  String _fallbackReply(String question) {
    final q = question.toLowerCase();
    final urgent = q.contains('plaie') ||
        q.contains('wound') ||
        q.contains('جرح') ||
        q.contains('fièvre') ||
        q.contains('fever') ||
        q.contains('سخانة');

    if (urgent) {
      switch (lang) {
        case 'Français':
          return 'Une plaie ou une fièvre chez une personne diabétique se voit aujourd hui, pas demain. Contactez votre centre de santé de base ou l hôpital régional, et faites un contrôle photo dans l application pour que le professionnel voie l évolution.';
        case 'English':
          return 'A wound or fever in a person with diabetes is seen today, not tomorrow. Contact your primary care centre or regional hospital, and run a photo check in the app so the professional can see it.';
        case 'العربية':
          return 'الجرح أو الحمى عند مريض السكري يعاين اليوم لا غدا. اتصل بمركز الصحة الأساسية أو المستشفى الجهوي، وقم بفحص بالصور في التطبيق.';
        default:
          return 'الجرح ولا السخانة عند مريض السكري يتعاين اليوم موش غدوة. أتصل بمركز الصحة ولا بالسبيطار، وأعمل فحص بالتصاور في التطبيق.';
      }
    }

    switch (lang) {
      case 'Français':
        return 'Réponse hors ligne: contrôlez vos pieds chaque jour, lavez et séchez entre les orteils, évitez de marcher pieds nus, et faites le contrôle photo quotidien. Ajoutez une clé Gemini dans Paramètres pour une réponse détaillée.';
      case 'English':
        return 'Offline answer: check your feet daily, wash and dry between the toes, avoid walking barefoot, and run the daily photo check. Add a Gemini key in Settings for a detailed answer.';
      case 'العربية':
        return 'إجابة دون اتصال: افحص قدميك يوميا، اغسل وجفف بين الأصابع، تجنب المشي حافيا، وقم بالفحص اليومي. أضف مفتاح Gemini في الإعدادات لإجابة مفصلة.';
      default:
        return 'إجابة بلا إنترنت: شوف ساقيك كل يوم، أغسل ونشف بين الصوابع، ما تمشيش حافي، وأعمل الفحص اليومي. زيد مفتاح Gemini في الإعدادات باش الإجابة تولي مفصلة.';
    }
  }

  Future<void> send() async {
    final text = controller.text.trim();
    if (text.isEmpty || sending) return;

    setState(() {
      messages.add({'role': 'user', 'text': text});
      controller.clear();
      sending = true;
    });
    _scroll();

    await store.saveChatMessage('patient', text);

    final reply = await AiGateway.chat(
          history: messages,
          profile: _context(),
          lang: lang,
          isDoctor: isDoctor,
        ) ??
        _fallbackReply(text);

    if (!mounted) return;

    setState(() {
      messages.add({'role': 'model', 'text': reply});
      sending = false;
    });
    await store.saveChatMessage('assistant', reply);
    _scroll();
  }

  void _scroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: K.paper,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: K.paper,
                border: Border(bottom: BorderSide(color: K.line)),
              ),
              padding: const EdgeInsets.fromLTRB(10, 10, 14, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: K.ink),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(S.t(lang, 'tool.chat'), style: K.h1),
                        Text(
                          ApiConfig.hasKey ? 'Gemini' : S.t(lang, 'settings.keyMissing'),
                          style: K.small,
                        ),
                      ],
                    ),
                  ),
                  const LanguageButton(),
                ],
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length + (sending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= messages.length) {
                        return const _Bubble(text: '...', mine: false);
                      }
                      final message = messages[index];
                      return _Bubble(
                        text: message['text'] ?? '',
                        mine: message['role'] == 'user',
                      );
                    },
                  ),
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: K.card,
                border: Border(top: BorderSide(color: K.line)),
              ),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          onSubmitted: (_) => send(),
                          style: const TextStyle(fontSize: 15, color: K.ink),
                          decoration: InputDecoration(
                            hintText: '...',
                            filled: true,
                            fillColor: K.paper,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(999),
                              borderSide: const BorderSide(color: K.line),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(999),
                              borderSide: const BorderSide(color: K.primary, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filled(
                        onPressed: sending ? null : send,
                        style: IconButton.styleFrom(
                          backgroundColor: K.primary,
                          minimumSize: const Size(48, 48),
                        ),
                        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  final bool mine;

  const _Bubble({required this.text, required this.mine});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: mine ? K.primary : K.card,
          border: Border.all(color: mine ? K.primary : K.line),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 15,
            height: 1.45,
            color: mine ? Colors.white : K.ink,
          ),
        ),
      ),
    );
  }
}
