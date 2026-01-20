import '../core/utils/uuid_helper.dart';

/// User model based on class diagram
/// Attributes: userID, fullName, email, password, registrationDate
/// Methods: isLoggedIn, login(), logout(), updateProfile(), createAccount()
class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String? password; // Hashed password - not stored in plain text
  final DateTime dateOfBirth;
  final DateTime registrationDate;
  final DateTime createdAt;
  final bool isLoggedIn;
  final bool isVerified;
  final bool biometricEnabled;

  UserModel({
    String? id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.password,
    required this.dateOfBirth,
    DateTime? registrationDate,
    DateTime? createdAt,
    this.isLoggedIn = false,
    this.isVerified = false,
    this.biometricEnabled = false,
  })  : id = id ?? UuidHelper.generateV4(),
        registrationDate = registrationDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  /// Login method - returns updated user with isLoggedIn = true
  UserModel login() {
    return copyWith(isLoggedIn: true);
  }

  /// Logout method - returns updated user with isLoggedIn = false
  UserModel logout() {
    return copyWith(isLoggedIn: false);
  }

  /// Update profile method
  UserModel updateProfile({
    String? fullName,
    String? email,
    String? phoneNumber,
    DateTime? dateOfBirth,
    bool? biometricEnabled,
  }) {
    return copyWith(
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      dateOfBirth: dateOfBirth,
      biometricEnabled: biometricEnabled,
    );
  }

  /// Create account - factory method
  static UserModel createAccount({
    required String fullName,
    required String email,
    required String phoneNumber,
    required DateTime dateOfBirth,
    String? password,
  }) {
    return UserModel(
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      dateOfBirth: dateOfBirth,
      password: password,
      registrationDate: DateTime.now(),
      isLoggedIn: false,
      isVerified: false,
    );
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? password,
    DateTime? dateOfBirth,
    DateTime? registrationDate,
    DateTime? createdAt,
    bool? isLoggedIn,
    bool? isVerified,
    bool? biometricEnabled,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      password: password ?? this.password,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      registrationDate: registrationDate ?? this.registrationDate,
      createdAt: createdAt ?? this.createdAt,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isVerified: isVerified ?? this.isVerified,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'registrationDate': registrationDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isLoggedIn': isLoggedIn,
      'isVerified': isVerified,
      'biometricEnabled': biometricEnabled,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullName: json['fullName'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      dateOfBirth: DateTime.parse(json['dateOfBirth']),
      registrationDate: json['registrationDate'] != null 
          ? DateTime.parse(json['registrationDate']) 
          : DateTime.now(),
      createdAt: DateTime.parse(json['createdAt']),
      isLoggedIn: json['isLoggedIn'] ?? false,
      isVerified: json['isVerified'] ?? false,
      biometricEnabled: json['biometricEnabled'] ?? false,
    );
  }

  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }
}
