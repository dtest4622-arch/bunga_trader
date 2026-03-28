import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String email;
  
  @HiveField(2)
  final String phoneNumber;
  
  @HiveField(3)
  final String mpesaNumber;
  
  @HiveField(4)
  final bool isKycVerified;
  
  @HiveField(5)
  final DateTime createdAt;
  
  @HiveField(6)
  final String? authToken;
  
  @HiveField(7)
  final String? refreshToken;
  
  @HiveField(8)
  final String? fullName;
  
  @HiveField(9)
  final String? avatarUrl;
  
  @HiveField(10)
  final bool isActive;
  
  @HiveField(11)
  final DateTime? lastLogin;

  UserModel({
    required this.id,
    required this.email,
    required this.phoneNumber,
    required this.mpesaNumber,
    this.isKycVerified = false,
    required this.createdAt,
    this.authToken,
    this.refreshToken,
    this.fullName,
    this.avatarUrl,
    this.isActive = true,
    this.lastLogin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      mpesaNumber: json['mpesa_number'] ?? '',
      isKycVerified: json['is_kyc_verified'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      authToken: json['auth_token'],
      refreshToken: json['refresh_token'],
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
      isActive: json['is_active'] ?? true,
      lastLogin: json['last_login'] != null 
          ? DateTime.parse(json['last_login']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'phone_number': phoneNumber,
    'mpesa_number': mpesaNumber,
    'is_kyc_verified': isKycVerified,
    'created_at': createdAt.toIso8601String(),
    'auth_token': authToken,
    'refresh_token': refreshToken,
    'full_name': fullName,
    'avatar_url': avatarUrl,
    'is_active': isActive,
    'last_login': lastLogin?.toIso8601String(),
  };

  UserModel copyWith({
    String? id,
    String? email,
    String? phoneNumber,
    String? mpesaNumber,
    bool? isKycVerified,
    DateTime? createdAt,
    String? authToken,
    String? refreshToken,
    String? fullName,
    String? avatarUrl,
    bool? isActive,
    DateTime? lastLogin,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      mpesaNumber: mpesaNumber ?? this.mpesaNumber,
      isKycVerified: isKycVerified ?? this.isKycVerified,
      createdAt: createdAt ?? this.createdAt,
      authToken: authToken ?? this.authToken,
      refreshToken: refreshToken ?? this.refreshToken,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  String get displayName => fullName ?? email.split('@').first;
  
  String get initials {
    if (fullName != null && fullName!.isNotEmpty) {
      final parts = fullName!.split(' ');
      if (parts.length > 1) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return fullName![0].toUpperCase();
    }
    return email[0].toUpperCase();
  }

  bool get canTrade => isKycVerified && isActive;
}
