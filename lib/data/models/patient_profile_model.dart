class PatientProfileModel {
  // Personal
  String? contactNumber;
  String? gender;
  String? dob;
  String? bloodGroup;
  String? maritalStatus;
  String? height;
  String? weight;
  String? emergencyContact;
  String? location;

  // Medical
  String? allergies;
  String? currentMedications;
  String? pastMedications;
  String? chronicDiseases;
  String? injuries;
  String? surgeries;

  // Lifestyle
  String? smokingHabits;
  String? alcoholConsumption;
  String? activityLevel;
  String? foodPreference;
  String? occupation;

  PatientProfileModel({
    this.contactNumber,
    this.gender,
    this.dob,
    this.bloodGroup,
    this.maritalStatus,
    this.height,
    this.weight,
    this.emergencyContact,
    this.location,
    this.allergies,
    this.currentMedications,
    this.pastMedications,
    this.chronicDiseases,
    this.injuries,
    this.surgeries,
    this.smokingHabits,
    this.alcoholConsumption,
    this.activityLevel,
    this.foodPreference,
    this.occupation,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'contactNumber': contactNumber,
      'gender': gender,
      'dob': dob,
      'bloodGroup': bloodGroup,
      'maritalStatus': maritalStatus,
      'height': height,
      'weight': weight,
      'emergencyContact': emergencyContact,
      'location': location,
      'allergies': allergies,
      'currentMedications': currentMedications,
      'pastMedications': pastMedications,
      'chronicDiseases': chronicDiseases,
      'injuries': injuries,
      'surgeries': surgeries,
      'smokingHabits': smokingHabits,
      'alcoholConsumption': alcoholConsumption,
      'activityLevel': activityLevel,
      'foodPreference': foodPreference,
      'occupation': occupation,
    };
  }

  // Create from Map
  factory PatientProfileModel.fromMap(Map<String, dynamic> map) {
    return PatientProfileModel(
      contactNumber: map['contactNumber'],
      gender: map['gender'],
      dob: map['dob'],
      bloodGroup: map['bloodGroup'],
      maritalStatus: map['maritalStatus'],
      height: map['height'],
      weight: map['weight'],
      emergencyContact: map['emergencyContact'],
      location: map['location'],
      allergies: map['allergies'],
      currentMedications: map['currentMedications'],
      pastMedications: map['pastMedications'],
      chronicDiseases: map['chronicDiseases'],
      injuries: map['injuries'],
      surgeries: map['surgeries'],
      smokingHabits: map['smokingHabits'],
      alcoholConsumption: map['alcoholConsumption'],
      activityLevel: map['activityLevel'],
      foodPreference: map['foodPreference'],
      occupation: map['occupation'],
    );
  }

  // Helper to calculate percentage
  int get completionPercentage {
    int total = 20; // Total number of fields
    int filled = 0;
    // Check every field manually or use a list to loop
    if (contactNumber != null) filled++;
    if (gender != null) filled++;
    if (dob != null) filled++;
    if (bloodGroup != null) filled++;
    if (maritalStatus != null) filled++;
    if (height != null) filled++;
    if (weight != null) filled++;
    if (emergencyContact != null) filled++;
    if (location != null) filled++;
    if (allergies != null) filled++;
    if (currentMedications != null) filled++;
    if (pastMedications != null) filled++;
    if (chronicDiseases != null) filled++;
    if (injuries != null) filled++;
    if (surgeries != null) filled++;
    if (smokingHabits != null) filled++;
    if (alcoholConsumption != null) filled++;
    if (activityLevel != null) filled++;
    if (foodPreference != null) filled++;
    if (occupation != null) filled++;

    return ((filled / total) * 100).toInt();
  }
}
