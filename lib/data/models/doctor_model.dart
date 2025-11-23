class DoctorModel {
  final String uid;
  final String name;
  final String email;
  final String location;
  final String specialization;
  final String status;
  final String gender;
  final String experience;
  final String qualification;
  final String identityProofUrl;
  final String profileImageUrl; // New field
  final String regNumber;

  DoctorModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.location,
    required this.specialization,
    required this.status,
    required this.gender,
    required this.experience,
    required this.qualification,
    required this.identityProofUrl,
    required this.profileImageUrl, // New field
    required this.regNumber,
  });

  factory DoctorModel.fromMap(Map<String, dynamic> map) {
    // Handle nested profile map safely
    final profile = map['profile'] as Map<String, dynamic>? ?? {};
    final education = profile['education'] as Map<String, dynamic>? ?? {};

    return DoctorModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      location: map['location'] ?? '',
      specialization: map['specialization'] ?? '',
      status: map['status'] ?? 'pending',
      // Nested fields
      gender: profile['gender'] ?? '',
      experience: profile['experience'] ?? '',
      profileImageUrl:
          profile['profileImageUrl'] ?? '', // Read from profile map
      qualification: education['qualification'] ?? '',
      identityProofUrl: education['identityProofUrl'] ?? '',
      regNumber: education['regNumber'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'location': location,
      'specialization': specialization,
      'status': status,
      'profile': {
        'gender': gender,
        'experience': experience,
        'profileImageUrl': profileImageUrl, // Save to profile map
        'education': {
          'qualification': qualification,
          'identityProofUrl': identityProofUrl,
          'regNumber': regNumber,
        },
      },
    };
  }
}
