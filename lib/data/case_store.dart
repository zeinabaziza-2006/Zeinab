import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_store.dart';
import 'crypto_box.dart';
import 'triage.dart';

/// One submitted self-check: photos, answers, AI triage and the clinician
/// decision that follows. This is the object the whole product is built around.
class FootCase {
  final String id;
  final String patientId;
  final String patientName;
  final String createdAt;
  final List<String> photoLabels;
  final List<String> photos; // base64, no data: prefix
  final Map<String, dynamic> answers;
  final Map<String, dynamic> profile;
  final TriageResult triage;

  String status; // 'draft' | 'submitted' | 'reviewed'
  Map<String, dynamic>? decision;

  /// Explicit consent captured at submission time, and whether the patient
  /// agreed to be identified. Without identity consent the clinician sees a
  /// pseudonym until they explicitly reveal it, and that reveal is audited.
  bool consent;
  bool shareIdentity;

  FootCase({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.createdAt,
    required this.photoLabels,
    required this.photos,
    required this.answers,
    required this.profile,
    required this.triage,
    this.status = 'draft',
    this.decision,
    this.consent = false,
    this.shareIdentity = false,
  });

  DateTime get date => DateTime.tryParse(createdAt) ?? DateTime.now();

  String get shortId => id.length <= 6 ? id : id.substring(id.length - 6);

  /// Pseudonym used in the clinician queue when identity was not shared.
  String get pseudonym {
    final parts = patientName.trim().split(RegExp(r'\s+'));
    final initials = parts
        .where((part) => part.isNotEmpty)
        .map((part) => part.substring(0, 1))
        .join('.');
    return initials.isEmpty ? 'Patient $shortId' : '$initials. · $shortId';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'patientName': patientName,
        'createdAt': createdAt,
        'photoLabels': photoLabels,
        'photos': photos,
        'answers': answers,
        'profile': profile,
        'triage': triage.toJson(),
        'status': status,
        'decision': decision,
        'consent': consent,
        'shareIdentity': shareIdentity,
      };

  static FootCase fromJson(Map<String, dynamic> json) {
    List<String> strings(dynamic value) {
      if (value is List) return value.map((item) => '$item').toList();
      return <String>[];
    }

    Map<String, dynamic> map(dynamic value) {
      if (value is Map) return Map<String, dynamic>.from(value);
      return <String, dynamic>{};
    }

    return FootCase(
      id: '${json['id'] ?? ''}',
      patientId: '${json['patientId'] ?? ''}',
      patientName: '${json['patientName'] ?? ''}',
      createdAt: '${json['createdAt'] ?? ''}',
      photoLabels: strings(json['photoLabels']),
      photos: strings(json['photos']),
      answers: map(json['answers']),
      profile: map(json['profile']),
      triage: TriageResult.fromJson(map(json['triage'])),
      status: '${json['status'] ?? 'submitted'}',
      decision: json['decision'] == null ? null : map(json['decision']),
      consent: json['consent'] == true,
      shareIdentity: json['shareIdentity'] == true,
    );
  }
}

/// One line of the access trail: who did what, on which case, when.
class AuditEntry {
  final String action;
  final String caseId;
  final String actor;
  final String role;
  final String date;

  const AuditEntry({
    required this.action,
    required this.caseId,
    required this.actor,
    required this.role,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'action': action,
        'caseId': caseId,
        'actor': actor,
        'role': role,
        'date': date,
      };

  static AuditEntry fromJson(Map<String, dynamic> json) => AuditEntry(
        action: '${json['action'] ?? ''}',
        caseId: '${json['caseId'] ?? ''}',
        actor: '${json['actor'] ?? ''}',
        role: '${json['role'] ?? ''}',
        date: '${json['date'] ?? ''}',
      );
}

class CaseStore extends ChangeNotifier {
  CaseStore._();

  static final CaseStore instance = CaseStore._();

  static const _key = 'khatwa_cases_v2';
  static const _auditKey = 'khatwa_audit_v1';

  SharedPreferences? _prefs;
  bool _ready = false;
  bool _unlocked = false;

  final List<FootCase> _cases = [];
  final List<AuditEntry> _audit = [];

  bool get unlocked => _unlocked;

  Future<void> init() async {
    if (_ready) return;
    _prefs = await SharedPreferences.getInstance();
    _ready = true;
    notifyListeners();
  }

  /// Called right after a successful sign in, when the data encryption key is
  /// available. Before this, the cases stay on disk as ciphertext.
  Future<void> unlock() async {
    await init();
    _cases.clear();
    _audit.clear();

    _cases.addAll(_readList(_key).map(FootCase.fromJson));
    _audit.addAll(_readList(_auditKey).map(AuditEntry.fromJson));

    _unlocked = true;
    notifyListeners();
  }

  /// Called on sign out: the decrypted records leave memory.
  void lock() {
    _cases.clear();
    _audit.clear();
    _unlocked = false;
    notifyListeners();
  }

  List<Map<String, dynamic>> _readList(String key) {
    final raw = _prefs?.getString(key);
    if (raw == null || raw.isEmpty) return [];

    String? plain = raw;
    if (CryptoBox.isSealed(raw)) {
      final dek = AuthStore.instance.dek;
      if (dek == null) return []; // no key, no data
      plain = CryptoBox.open(raw, dek);
      if (plain == null) return []; // wrong key or tampered store
    }

    try {
      final decoded = jsonDecode(plain);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> _writeList(String key, List<Map<String, dynamic>> value) async {
    _prefs ??= await SharedPreferences.getInstance();
    final json = jsonEncode(value);
    final dek = AuthStore.instance.dek;
    await _prefs!.setString(key, dek == null ? json : CryptoBox.seal(json, dek));
  }

  // ------------------------------------------------------------------ reads

  List<FootCase> get all {
    final copy = [..._cases];
    copy.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return copy;
  }

  List<FootCase> forPatient(String patientId) =>
      all.where((item) => item.patientId == patientId).toList();

  List<FootCase> get submitted =>
      all.where((item) => item.status != 'draft').toList();

  FootCase? byId(String id) {
    for (final item in _cases) {
      if (item.id == id) return item;
    }
    return null;
  }

  List<AuditEntry> auditFor(String caseId) {
    final rows = _audit.where((entry) => entry.caseId == caseId).toList();
    rows.sort((a, b) => b.date.compareTo(a.date));
    return rows;
  }

  List<AuditEntry> get auditAll {
    final rows = [..._audit];
    rows.sort((a, b) => b.date.compareTo(a.date));
    return rows;
  }

  bool hasCheckToday(String patientId) {
    final now = DateTime.now();
    for (final item in forPatient(patientId)) {
      final date = item.date;
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        return true;
      }
    }
    return false;
  }

  int streak(String patientId) {
    final days = forPatient(patientId)
        .map((item) => DateTime(item.date.year, item.date.month, item.date.day))
        .toSet()
        .toList();
    days.sort((a, b) => b.compareTo(a));
    if (days.isEmpty) return 0;

    final today = DateTime.now();
    var cursor = DateTime(today.year, today.month, today.day);
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!days.contains(cursor)) return 0;
    }

    var count = 0;
    while (days.contains(cursor)) {
      count++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }

  // ----------------------------------------------------------------- writes

  Future<void> save(FootCase footCase) async {
    final index = _cases.indexWhere((item) => item.id == footCase.id);
    if (index >= 0) {
      _cases[index] = footCase;
    } else {
      _cases.add(footCase);
    }
    _unlocked = true;
    await _persist();
    notifyListeners();
  }

  Future<void> submit(
    FootCase footCase, {
    bool consent = true,
    bool shareIdentity = false,
  }) async {
    footCase.status = 'submitted';
    footCase.consent = consent;
    footCase.shareIdentity = shareIdentity;
    await save(footCase);
    await record('submit', footCase.id);
  }

  Future<void> setDecision({
    required String caseId,
    required String level,
    required String orientation,
    required String note,
    required String doctorName,
  }) async {
    final footCase = byId(caseId);
    if (footCase == null) return;

    footCase.decision = {
      'level': level,
      'orientation': orientation,
      'note': note,
      'doctor': doctorName,
      'date': DateTime.now().toIso8601String(),
    };
    footCase.status = 'reviewed';

    await _persist();
    await record('validate', caseId);
    notifyListeners();
  }

  /// Every read or write of a case by a clinician leaves a trace. This is the
  /// same idea as an IHE ATNA audit record, kept local for now.
  Future<void> record(String action, String caseId) async {
    final account = AuthStore.instance.current;
    _audit.add(AuditEntry(
      action: action,
      caseId: caseId,
      actor: account?.name ?? 'unknown',
      role: account?.role ?? 'unknown',
      date: DateTime.now().toIso8601String(),
    ));
    await _writeList(_auditKey, _audit.map((entry) => entry.toJson()).toList());
    notifyListeners();
  }

  Future<void> _persist() async {
    await _writeList(_key, _cases.map((item) => item.toJson()).toList());
  }
}
