import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import '../data/models/medical_record_model.dart';
import '../core/services/cloudinary_service.dart';

class PatientMedicalRecordsViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String? _error;
  List<MedicalRecordModel> _records = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<MedicalRecordModel> get records => _records;

  Future<void> fetchRecords() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final snap = await _firestore.collection('patients').doc(user.uid).collection('medical_records').orderBy('uploadedAt', descending: true).get();

      _records = snap.docs.map((d) => MedicalRecordModel.fromMap(d.data(), d.id)).toList();
    } catch (e) {
      _error = e.toString();
      _records = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> pickAndUpload({String? description}) async {
    // Uses file_picker to allow images / pdfs / docs
    final result = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (result == null || result.files.isEmpty) return;

    final path = result.files.first.path;
    if (path == null) return;

    final file = File(path);
    await uploadFile(file, description: description);
  }

  Future<void> uploadFile(File file, {String? description}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final uploadedUrl = await CloudinaryService.uploadFile(file);
      if (uploadedUrl == null) throw Exception('Upload failed');

      final meta = {
        'fileUrl': uploadedUrl,
        'fileName': file.path.split(Platform.pathSeparator).last,
        'fileType': file.path.split('.').last,
        'uploadedAt': DateTime.now(),
        'description': description ?? '',
      };

      final ref = await _firestore.collection('patients').doc(user.uid).collection('medical_records').add(meta);

      _records.insert(0, MedicalRecordModel.fromMap({...meta}, ref.id));
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
