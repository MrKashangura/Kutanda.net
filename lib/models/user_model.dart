class UserModel {
  final String uid;
  final String email;
  final String phone;
  // Rename role to activeRole for clarity.
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
      activeRole: json['role'], // assuming backend returns role as 'buyer' or 'seller'
    );
  }
}
