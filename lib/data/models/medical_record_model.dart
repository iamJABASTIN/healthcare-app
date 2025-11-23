import 'package:cloud_firestore/cloud_firestore.dart';

class MedicalRecordModel {
  final String id;
  final String fileUrl;
  final String fileName;
  final String fileType;
  final DateTime uploadedAt;
  final String? description;

  MedicalRecordModel({
    required this.id,
    required this.fileUrl,
    required this.fileName,
    required this.fileType,
    required this.uploadedAt,
    this.description,
  });

  factory MedicalRecordModel.fromMap(Map<String, dynamic> map, String id) {
    // uploadedAt in Firestore is usually a Timestamp; handle multiple formats.
    DateTime uploadedAt = DateTime.now();

    final raw = map['uploadedAt'];
    if (raw is Timestamp) {
      uploadedAt = raw.toDate();
    } else if (raw is DateTime) {
      uploadedAt = raw;
    } else if (raw is String) {
      uploadedAt = DateTime.tryParse(raw) ?? DateTime.now();
    }

    return MedicalRecordModel(
      id: id,
      fileUrl: map['fileUrl'] ?? '',
      fileName: map['fileName'] ?? '',
      fileType: map['fileType'] ?? '',
      uploadedAt: uploadedAt,
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileType': fileType,
      'uploadedAt': uploadedAt,
      'description': description,
    };
  }
}
