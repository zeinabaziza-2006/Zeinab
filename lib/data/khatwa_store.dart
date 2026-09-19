import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_store.dart';
import 'crypto_box.dart';

class KhatwaStore extends ChangeNotifier {
  KhatwaStore._();

  static final KhatwaStore instance = KhatwaStore._();

  SharedPreferences? _prefs;
  bool initialized = false;

  String patientId = '';
  String patientName = '';
  String diabetesType = '';
  String medications = '';
  String allergies = '';
  String otherConditions = '';

  List<Map<String, dynamic>> entries = [];
  List<Map<String, dynamic>> chatMessages = [];
  List<Map<String, dynamic>> doctorRequests = [];

  /// Encryption at rest: every value written here is sealed with the data
  /// encryption key unwrapped by the signed in account's PIN. Without a session
  /// the file on disk is ciphertext.
  String _seal(String value) {
    final dek = AuthStore.instance.dek;
    if (dek == null || value.isEmpty) return value;
    return CryptoBox.seal(value, dek);
  }

  String _open(String? value) {
    if (value == null || value.isEmpty) return '';
    if (!CryptoBox.isSealed(value)) return value;
    final dek = AuthStore.instance.dek;
    if (dek == null) return '';
    return CryptoBox.open(value, dek) ?? '';
  }

  /// Called after sign in, when the key becomes available.
  Future<void> reload() async {
    initialized = false;
    await init();
  }

  Future<void> init() async {
    if (initialized) return;

    _prefs = await SharedPreferences.getInstance();

    patientId = _open(_prefs!.getString('patient_id'));
    patientName = _open(_prefs!.getString('patient_name'));
    diabetesType = _open(_prefs!.getString('diabetes_type'));
    medications = _open(_prefs!.getString('medications'));
    allergies = _open(_prefs!.getString('allergies'));
    otherConditions = _open(_prefs!.getString('other_conditions'));

    entries = _loadList('entries');
    chatMessages = _loadList('chat_messages');
    doctorRequests = _loadList('doctor_requests');

    initialized = true;
    notifyListeners();
  }

  List<Map<String, dynamic>> _loadList(String key) {
    final raw = _open(_prefs?.getString(key));

    if (raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map(
              (item) => Map<String, dynamic>.from(item),
            )
            .toList();
      }
    } catch (_) {}

    return [];
  }

  Future<void> _save() async {
    _prefs ??= await SharedPreferences.getInstance();

    await _prefs!.setString('patient_id', _seal(patientId));
    await _prefs!.setString('patient_name', _seal(patientName));
    await _prefs!.setString('diabetes_type', _seal(diabetesType));
    await _prefs!.setString('medications', _seal(medications));
    await _prefs!.setString('allergies', _seal(allergies));
    await _prefs!.setString('other_conditions', _seal(otherConditions));

    await _prefs!.setString('entries', _seal(jsonEncode(entries)));
    await _prefs!.setString('chat_messages', _seal(jsonEncode(chatMessages)));
    await _prefs!.setString(
      'doctor_requests',
      _seal(jsonEncode(doctorRequests)),
    );
  }

  Future<void> saveMedicalInformation({
    String? name,
    String? patientName,
    String? diabetesType,
    String? medications,
    String? allergies,
    String? otherConditions,
  }) async {
    if (name != null) {
      this.patientName = name;
    }

    if (patientName != null) {
      this.patientName = patientName;
    }

    if (diabetesType != null) {
      this.diabetesType = diabetesType;
    }

    if (medications != null) {
      this.medications = medications;
    }

    if (allergies != null) {
      this.allergies = allergies;
    }

    if (otherConditions != null) {
      this.otherConditions = otherConditions;
    }

    await _save();
    notifyListeners();
  }

  Future<void> setPatient({
    required String id,
    required String name,
  }) async {
    patientId = id;
    patientName = name;

    await _save();
    notifyListeners();
  }

  Future<void> addEntry(Map<String, dynamic> entry) async {
    final copy = Map<String, dynamic>.from(entry);

    copy['date'] ??= DateTime.now().toIso8601String();

    entries.add(copy);

    await _save();
    notifyListeners();
  }

  Future<void> saveChatMessage(
    String sender,
    String message,
  ) async {
    chatMessages.add({
      'sender': sender,
      'message': message,
      'date': DateTime.now().toIso8601String(),
    });

    await _save();
    notifyListeners();
  }

  Future<void> requestDoctor({
    required String doctorName,
    required String specialty,
    required bool consent,
    bool anonymous = true,
    bool shareDossier = false,
  }) async {
    doctorRequests.add({
      'doctor': doctorName,
      'specialty': specialty,
      'consent': consent,
      'anonymous': anonymous,
      'shareDossier': shareDossier,
      'status': 'pending',
      'patientId': patientId,
      'patientName': anonymous ? '' : patientName,
      'date': DateTime.now().toIso8601String(),
    });

    await _save();
    notifyListeners();
  }

  Future<void> updateDoctorRequestStatus(
    int index,
    String status,
  ) async {
    if (index < 0 || index >= doctorRequests.length) {
      return;
    }

    doctorRequests[index]['status'] = status;

    await _save();
    notifyListeners();
  }

  Map<String, dynamic> dossier() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'diabetesType': diabetesType,
      'medications': medications,
      'allergies': allergies,
      'otherConditions': otherConditions,
      'entries': List<Map<String, dynamic>>.from(entries),
      'chatMessages': List<Map<String, dynamic>>.from(chatMessages),
      'doctorRequests': List<Map<String, dynamic>>.from(
        doctorRequests,
      ),
    };
  }

  List<Map<String, dynamic>> entriesOfType(String type) {
    return entries
        .where((entry) => entry['type'] == type)
        .toList();
  }

  List<Map<String, dynamic>> photoEntries() {
    return entriesOfType('foot_photo');
  }

  Future<void> clearAll() async {
    patientId = '';
    patientName = '';
    diabetesType = '';
    medications = '';
    allergies = '';
    otherConditions = '';

    entries.clear();
    chatMessages.clear();
    doctorRequests.clear();

    await _save();
    notifyListeners();
  }
}