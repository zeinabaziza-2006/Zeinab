import '../ui/strings.dart';
import 'triage.dart';

/// Deterministic clinical rules.
///
/// This layer runs on every check, with or without network, and it can only
/// raise the triage level produced by the AI layer. It encodes the red flags
/// a clinician would not want an image model to be the only judge of.
class RuleEngine {
  static TriageResult evaluate({
    required Map<String, dynamic> answers,
    required Map<String, dynamic> profile,
    required String lang,
  }) {
    final findings = <TriageFinding>[];
    final advice = <String>[];
    var level = TriageLevel.green;

    void raise(TriageLevel candidate) {
      if (levelRank(candidate) > levelRank(level)) level = candidate;
    }

    bool yes(String key) => answers[key] == true;

    // ---- red flags -------------------------------------------------------
    if (yes('wound')) {
      raise(TriageLevel.red);
      findings.add(TriageFinding(
        label: _s(lang, 'plaie ouverte signalée', 'Open wound reported', 'جرح مفتوح تم الإبلاغ عنه', 'جرح مفتوح'),
        detail: _s(
          lang,
          'Le patient déclare une plaie nouvelle. Toute plaie du pied diabétique est une urgence relative.',
          'The person reports a new wound. Any diabetic foot wound needs prompt review.',
          'المريض أبلغ عن جرح جديد. أي جرح في القدم السكرية يستوجب مراجعة سريعة.',
          'المريض قال ثمة جرح جديد. أي جرح في الساق لازم يتشاف فيسع.',
        ),
        severity: 'urgent',
        source: 'questionnaire',
      ));
    }

    if (yes('smell') || (yes('fever') && yes('pain'))) {
      raise(TriageLevel.red);
      findings.add(TriageFinding(
        label: _s(lang, 'signes évocateurs d infection', 'Possible infection signs', 'علامات قد تدل على التهاب', 'علامات تلوث ممكنة'),
        detail: _s(
          lang,
          'Mauvaise odeur, ou fièvre associée à une douleur du pied.',
          'Bad smell, or fever together with foot pain.',
          'رائحة كريهة، أو حمى مصحوبة بألم في القدم.',
          'ريحة موش باهية، ولا سخانة مع وجيعة في الساق.',
        ),
        severity: 'urgent',
        source: 'questionnaire',
      ));
    }

    if (yes('wound') && yes('numbness')) {
      raise(TriageLevel.red);
      findings.add(TriageFinding(
        label: _s(lang, 'plaie sur pied insensible', 'Wound on an insensate foot', 'جرح مع فقدان الإحساس', 'جرح مع نقص إحساس'),
        detail: _s(
          lang,
          'Une plaie que la personne ne sent pas évolue sans alerte: priorité haute.',
          'A wound the person cannot feel progresses silently: high priority.',
          'الجرح الذي لا يشعر به المريض يتطور دون إنذار: أولوية عالية.',
          'الجرح إلي ما تحسش بيه يتطور بلا ما تعرف: أولوية عالية.',
        ),
        severity: 'urgent',
        source: 'rule',
      ));
    }

    // ---- amber flags -----------------------------------------------------
    if (yes('swelling')) {
      raise(TriageLevel.amber);
      findings.add(TriageFinding(
        label: _s(lang, 'gonflement', 'Swelling', 'انتفاخ', 'نفخة'),
        detail: _s(
          lang,
          'Gonflement déclaré: à surveiller de près, comparer les deux pieds.',
          'Reported swelling: monitor closely and compare both feet.',
          'انتفاخ تم الإبلاغ عنه: يجب المتابعة ومقارنة القدمين.',
          'ثمة نفخة: تبّع مليح وقارن بين الساقين.',
        ),
        source: 'questionnaire',
      ));
    }

    if (yes('color')) {
      raise(TriageLevel.amber);
      findings.add(TriageFinding(
        label: _s(lang, 'changement de couleur', 'Colour change', 'تغير اللون', 'تبدل اللون'),
        detail: _s(
          lang,
          'Un changement de coloration peut traduire une inflammation ou un trouble vasculaire.',
          'A colour change can indicate inflammation or a vascular problem.',
          'تغير اللون قد يدل على التهاب أو مشكل في الدورة الدموية.',
          'تبدل اللون ينجم يكون التهاب ولا مشكل في الدم.',
        ),
        source: 'questionnaire',
      ));
    }

    if (yes('pain') || yes('numbness')) {
      raise(TriageLevel.amber);
      findings.add(TriageFinding(
        label: _s(lang, 'symptômes neuropathiques', 'Neuropathic symptoms', 'أعراض عصبية', 'أعراض في الأعصاب'),
        detail: _s(
          lang,
          'Douleur ou perte de sensation: facteur de risque majeur d ulcération.',
          'Pain or loss of feeling: a major ulceration risk factor.',
          'ألم أو فقدان إحساس: عامل خطر رئيسي للتقرح.',
          'وجيعة ولا نقص إحساس: خطر كبير على التقرح.',
        ),
        source: 'questionnaire',
      ));
    }

    if (yes('barefoot')) {
      advice.add(_s(
        lang,
        'Évitez de marcher pieds nus, même à la maison.',
        'Avoid walking barefoot, even at home.',
        'تجنب المشي حافيا، حتى في المنزل.',
        'ما تمشيش حافي، حتى في الدار.',
      ));
    }

    // ---- glucose ---------------------------------------------------------
    final glucose = double.tryParse('${answers['glucose'] ?? ''}'.replaceAll(',', '.'));
    if (glucose != null && glucose > 0) {
      if (glucose >= 250 || glucose < 54) {
        raise(TriageLevel.red);
        findings.add(TriageFinding(
          label: _s(lang, 'glycémie critique', 'Critical glucose', 'سكري حرج', 'سكر خطير'),
          detail: '${glucose.toStringAsFixed(0)} mg/dL',
          severity: 'urgent',
          source: 'questionnaire',
        ));
      } else if (glucose > 180 || glucose < 70) {
        raise(TriageLevel.amber);
        findings.add(TriageFinding(
          label: _s(lang, 'glycémie hors cible', 'Glucose out of range', 'سكري خارج المعدل', 'السكر موش في المعدل'),
          detail: '${glucose.toStringAsFixed(0)} mg/dL',
          source: 'questionnaire',
        ));
      }
    }

    // ---- advice ----------------------------------------------------------
    switch (level) {
      case TriageLevel.red:
        advice.insert(
          0,
          _s(
            lang,
            'Contactez aujourd hui votre centre de santé de base ou l hôpital régional.',
            'Contact your primary care centre or the regional hospital today.',
            'اتصل اليوم بمركز الصحة الأساسية أو المستشفى الجهوي.',
            'أتصل اليوم بمركز الصحة ولا بالسبيطار الجهوي.',
          ),
        );
        advice.add(_s(
          lang,
          'Ne percez rien, ne coupez pas la corne, protégez la zone et limitez la marche.',
          'Do not pierce anything, do not cut the callus, protect the area and limit walking.',
          'لا تثقب شيئا ولا تقص الجلد الميت، احم المنطقة وقلل المشي.',
          'ما تثقب شي ولا تقص الجلد، أحمي البلاصة وقلل المشي.',
        ));
        break;
      case TriageLevel.amber:
        advice.insert(
          0,
          _s(
            lang,
            'Refaites le contrôle demain et parlez-en lors de votre prochaine consultation.',
            'Repeat the check tomorrow and mention it at your next consultation.',
            'أعد الفحص غدا وتحدث عنه في الموعد القادم.',
            'عاود الفحص غدوة واحكي عليه في الموعد الجاي.',
          ),
        );
        break;
      case TriageLevel.green:
        advice.add(_s(
          lang,
          'Aucun signe détecté aujourd hui. Continuez le contrôle quotidien et consultez en cas de plaie, rougeur ou fièvre.',
          'No sign detected today. Keep checking daily and consult if a wound, redness or fever appears.',
          'لم تُرصد أي علامة اليوم. واصل الفحص يوميا واستشر عند ظهور جرح أو احمرار أو حمى.',
          'ما تلاحظت حتى علامة اليوم. كمّل الفحص كل يوم وأمشي للطبيب كان طلع جرح ولا حمرة ولا سخانة.',
        ));
        break;
    }

    advice.add(_s(
      lang,
      'Lavez et séchez vos pieds chaque jour, surtout entre les orteils.',
      'Wash and dry your feet daily, especially between the toes.',
      'اغسل وجفف قدميك يوميا، خاصة بين الأصابع.',
      'أغسل وجفف ساقيك كل يوم، خاصة بين الصوابع.',
    ));

    final summary = S.t(lang, 'level.${level == TriageLevel.green ? 'none' : level == TriageLevel.amber ? 'yellow' : 'red'}');

    final clinician = StringBuffer();
    clinician.writeln('Auto-surveillance ${_dateLabel()}');
    clinician.writeln('Niveau proposé par les règles cliniques: ${levelToString(level)}');
    if (findings.isEmpty) {
      clinician.writeln('Aucun drapeau rouge déclaré par le patient.');
    } else {
      for (final finding in findings) {
        clinician.writeln('- ${finding.label}: ${finding.detail}');
      }
    }
    clinician.writeln('Validation soignante requise avant toute orientation.');

    return TriageResult(
      level: level,
      findings: findings,
      advice: advice,
      patientSummary: summary,
      clinicianSummary: clinician.toString(),
      confidence: 0.55,
      photoQuality: 'fair',
      source: 'rules',
    );
  }

  static String _dateLabel() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  /// Order: fr, en, ar, tn.
  static String _s(String lang, String fr, String en, String ar, String tn) {
    switch (lang) {
      case 'Français':
        return fr;
      case 'English':
        return en;
      case 'العربية':
        return ar;
      default:
        return tn;
    }
  }
}
