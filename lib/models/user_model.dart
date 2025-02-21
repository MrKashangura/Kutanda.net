class UserModel {
  final String uid;
  final String email;
  final String phone;
  final String role;

  UserModel({required this.uid, required this.email, required this.phone, required this.role});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'],
      email: json['email'],
      phone: json['phone'],
      role: json['role'],
    );
  }
}
