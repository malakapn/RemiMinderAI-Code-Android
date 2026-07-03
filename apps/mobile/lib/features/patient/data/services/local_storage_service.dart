import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/medication.dart';
import '../../../../shared/models/reminder.dart';
import '../models/appointment.dart';
import '../models/visit.dart';
import '../models/caregiver.dart';

class LocalStorageService {
  static const String _medicationsKey = 'medications';
  static const String _remindersKey = 'reminders';
  static const String _appointmentsKey = 'appointments';
  static const String _visitsKey = 'visits';
  static const String _caregiversKey = 'caregivers';

  // Encryption key for PHI data
  static const String _encryptionKeyName = 'phi_encryption_key';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>>? _userCollection(String name) {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return null;
    }
    return _firestore.collection('users').doc(uid).collection(name);
  }

  Future<encrypt.Key> _getEncryptionKey() async {
    final keyString = await _secureStorage.read(key: _encryptionKeyName);
    if (keyString != null) {
      return encrypt.Key(base64.decode(keyString));
    }

    final key = encrypt.Key.fromSecureRandom(32);
    await _secureStorage.write(
      key: _encryptionKeyName,
      value: base64.encode(key.bytes),
    );
    return key;
  }

  Future<String> _encryptData(String plainText) async {
    final key = await _getEncryptionKey();
    final iv = encrypt.IV.fromSecureRandom(16);

    final encrypted =
        encrypt.Encrypter(encrypt.AES(key)).encrypt(plainText, iv: iv);
    return '${base64.encode(iv.bytes)}:${encrypted.base64}';
  }

  Future<String> _decryptData(String encryptedText) async {
    final key = await _getEncryptionKey();
    final parts = encryptedText.split(':');
    if (parts.length != 2) throw Exception('Invalid encrypted data format');

    final iv = encrypt.IV(base64.decode(parts[0]));
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final decrypted = encrypter.decrypt64(parts[1], iv: iv);
    return decrypted;
  }

  Future<void> _cacheRemindersLocally(List<Reminder> reminders) async {
    final prefs = await _prefs;
    final remindersJson = reminders.map((r) => r.toMap()).toList();
    final jsonString = json.encode(remindersJson);
    final encryptedData = await _encryptData(jsonString);
    await prefs.setString(_remindersKey, encryptedData);
  }

  Future<void> _cacheVisitsLocally(List<Visit> visits) async {
    final prefs = await _prefs;
    final visitsJson = visits.map((v) => v.toJson()).toList();
    final jsonString = json.encode(visitsJson);
    final encryptedData = await _encryptData(jsonString);
    await prefs.setString(_visitsKey, encryptedData);
  }

  // Medications
  Future<void> saveMedications(List<Medication> medications) async {
    final prefs = await _prefs;
    final medicationsJson = medications.map((m) => m.toJson()).toList();
    final jsonString = json.encode(medicationsJson);
    final encryptedData = await _encryptData(jsonString);
    await prefs.setString(_medicationsKey, encryptedData);
  }

  Future<List<Medication>> getMedications() async {
    final prefs = await _prefs;
    final encryptedData = prefs.getString(_medicationsKey);
    if (encryptedData == null) return [];

    final jsonString = await _decryptData(encryptedData);
    final List<dynamic> medicationsJson = json.decode(jsonString);
    return medicationsJson.map((json) => Medication.fromJson(json)).toList();
  }

  // Reminders
  Future<void> saveReminders(List<Reminder> reminders) async {
    await _cacheRemindersLocally(reminders);

    final remindersCollection = _userCollection('reminders');
    if (remindersCollection != null) {
      final batch = _firestore.batch();
      final snapshot = await remindersCollection.get();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      for (final reminder in reminders) {
        batch.set(remindersCollection.doc(reminder.id), reminder.toFirestoreMap());
      }
      await batch.commit();
    }
  }

  Future<List<Reminder>> getReminders() async {
    final remindersCollection = _userCollection('reminders');
    if (remindersCollection != null) {
      final snapshot = await remindersCollection.get();
      if (snapshot.docs.isNotEmpty) {
        final reminders = snapshot.docs
            .map((doc) => Reminder.fromMap(doc.data()))
            .toList(growable: false);
        await _cacheRemindersLocally(reminders);
        return reminders;
      }
    }

    final prefs = await _prefs;
    final encryptedData = prefs.getString(_remindersKey);
    if (encryptedData == null) return [];

    final jsonString = await _decryptData(encryptedData);
    final List<dynamic> remindersJson = json.decode(jsonString);
    return remindersJson.map((json) => Reminder.fromMap(json)).toList();
  }

  // Appointments
  Future<void> saveAppointments(List<Appointment> appointments) async {
    final prefs = await _prefs;
    final appointmentsJson = appointments.map((a) => a.toJson()).toList();
    final jsonString = json.encode(appointmentsJson);
    final encryptedData = await _encryptData(jsonString);
    await prefs.setString(_appointmentsKey, encryptedData);
  }

  Future<List<Appointment>> getAppointments() async {
    final prefs = await _prefs;
    final encryptedData = prefs.getString(_appointmentsKey);
    if (encryptedData == null) return [];

    final jsonString = await _decryptData(encryptedData);
    final List<dynamic> appointmentsJson = json.decode(jsonString);
    return appointmentsJson.map((json) => Appointment.fromJson(json)).toList();
  }

  // Visits
  Future<void> saveVisits(List<Visit> visits) async {
    await _cacheVisitsLocally(visits);

    final visitsCollection = _userCollection('visits');
    if (visitsCollection != null) {
      final batch = _firestore.batch();
      final snapshot = await visitsCollection.get();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      for (final visit in visits) {
        batch.set(visitsCollection.doc(visit.id), visit.toJson());
      }
      await batch.commit();
    }
  }

  Future<List<Visit>> getVisits() async {
    final visitsCollection = _userCollection('visits');
    if (visitsCollection != null) {
      final snapshot = await visitsCollection.get();
      if (snapshot.docs.isNotEmpty) {
        final visits = snapshot.docs
            .map((doc) => Visit.fromJson(doc.data()))
            .toList(growable: false);
        await _cacheVisitsLocally(visits);
        return visits;
      }
    }

    final prefs = await _prefs;
    final encryptedData = prefs.getString(_visitsKey);
    if (encryptedData == null) return [];

    final jsonString = await _decryptData(encryptedData);
    final List<dynamic> visitsJson = json.decode(jsonString);
    return visitsJson.map((json) => Visit.fromJson(json)).toList();
  }

  // Caregivers
  Future<void> saveCaregivers(List<Caregiver> caregivers) async {
    final prefs = await _prefs;
    final caregiversJson = caregivers.map((c) => c.toJson()).toList();
    final jsonString = json.encode(caregiversJson);
    final encryptedData = await _encryptData(jsonString);
    await prefs.setString(_caregiversKey, encryptedData);
  }

  Future<List<Caregiver>> getCaregivers() async {
    final prefs = await _prefs;
    final encryptedData = prefs.getString(_caregiversKey);
    if (encryptedData == null) return [];

    final jsonString = await _decryptData(encryptedData);
    final List<dynamic> caregiversJson = json.decode(jsonString);
    return caregiversJson.map((json) => Caregiver.fromJson(json)).toList();
  }

  Future<void> clearAllData() async {
    final prefs = await _prefs;
    final phiKeys = [
      _medicationsKey,
      _remindersKey,
      _appointmentsKey,
      _visitsKey,
      _caregiversKey
    ];

    for (final key in phiKeys) {
      await prefs.remove(key);
    }

    await _secureStorage.delete(key: _encryptionKeyName);
  }

  // Get last sync timestamp
  Future<DateTime?> getLastSyncTimestamp() async {
    final prefs = await _prefs;
    final timestampString = prefs.getString('last_sync_timestamp');
    return timestampString != null ? DateTime.parse(timestampString) : null;
  }

  Future<void> setLastSyncTimestamp(DateTime timestamp) async {
    final prefs = await _prefs;
    await prefs.setString('last_sync_timestamp', timestamp.toIso8601String());
  }
}
