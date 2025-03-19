class UserModel {
  final String uid;
  final String email;
  final String phone;
  String activeRole; // e.g., "buyer" or "seller"

  UserModel({
    required this.uid,
    required this.email,
    required this.phone,
    required this.activeRole,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'],
      email: json['email'],
      phone: json['phone'],
      activeRole: json['role'] ?? 'buyer', // Add fallback to prevent null errors
    );
  }
  
  // Add this method to properly save to database
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'phone': phone,
      'role': activeRole, // Map activeRole back to 'role' in the database
    };
  }
}