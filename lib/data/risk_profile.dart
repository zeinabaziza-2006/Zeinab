import 'khatwa_store.dart';

/// IWGDF risk stratification.
///
/// This is the standard the guidelines use to decide how often a diabetic foot
/// should be examined. Four questions, four categories, and a screening
/// frequency that follows from the category. It costs a minute and it is the
/// piece that turns a photo app into a follow-up pathway.
class RiskProfile {
  final bool neuropathy; // loss of protective sensation
  final bool arterial; // peripheral arterial disease
  final bool deformity; // foot deformity or callus under pressure
  final bool history; // previous ulcer or amputation
  final String date;

  const RiskProfile({
    required this.neuropathy,
    required this.arterial,
    required this.deformity,
    required this.history,
    required this.date,
  });

  /// 0 to 3, following the IWGDF categories.
  int get category {
    if (history) return 3;

    final factors = [neuropathy, arterial, deformity].where((f) => f).length;
    if (factors >= 2) return 2;
    if (factors == 1) return 1;
    return 0;
  }

  /// Screening interval recommended for this category.
  String get frequencyKey => 'risk.freq$category';

  String get labelKey => 'risk.cat$category';

  Map<String, dynamic> toJson() => {
        'type': 'risk_profile',
        'date': date,
        'neuropathy': neuropathy,
        'arterial': arterial,
        'deformity': deformity,
        'history': history,
        'category': category,
      };

  static RiskProfile fromJson(Map<String, dynamic> json) => RiskProfile(
        neuropathy: json['neuropathy'] == true,
        arterial: json['arterial'] == true,
        deformity: json['deformity'] == true,
        history: json['history'] == true,
        date: '${json['date'] ?? ''}',
      );

  /// The most recent profile the patient filled in, if any.
  static RiskProfile? latest() {
    final entries = KhatwaStore.instance.entriesOfType('risk_profile');
    if (entries.isEmpty) return null;
    entries.sort((a, b) => '${b['date']}'.compareTo('${a['date']}'));
    return fromJson(entries.first);
  }

  static Future<void> save(RiskProfile profile) =>
      KhatwaStore.instance.addEntry(profile.toJson());
}
