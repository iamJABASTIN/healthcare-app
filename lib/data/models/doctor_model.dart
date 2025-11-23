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
  final String profileImageUrl;
  final String regNumber;
  final double rating; // New field

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
    required this.profileImageUrl,
    required this.regNumber,
    this.rating = 0.0,
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
      rating: (map['rating'] ?? 4.5).toDouble(), // Default to 4.5 for testing
      // Nested fields
      gender: profile['gender'] ?? '',
      experience: profile['experience'] ?? '',
      profileImageUrl: profile['profileImageUrl'] ?? '',
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
      'rating': rating,
      'profile': {
        'gender': gender,
        'experience': experience,
        'profileImageUrl': profileImageUrl,
        'education': {
          'qualification': qualification,
          'identityProofUrl': identityProofUrl,
          'regNumber': regNumber,
        },
      },
    };
  }
}
