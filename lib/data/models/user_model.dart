class UserModel {
  final String uid;
  final String email;
  final String role; // 'patient', 'doctor'
  final bool isVerified; // Logic to block unverified doctors

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.isVerified = false,
  });

  // Convert Object -> Map (For sending to Firestore)
  Map<String, dynamic> toMap() {
    return {'uid': uid, 'email': email, 'role': role, 'isVerified': isVerified};
  }

  // Create Object <- Map (For reading from Firestore)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'patient',
      isVerified: map['isVerified'] ?? false,
    );
  }
}
