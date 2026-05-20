class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.businessName,
  });

  final int id;
  final String name;
  final String email;
  final String phone;
  final String? businessName;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      phone: (json['phone'] ?? '') as String,
      businessName: json['business_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id' => id,
      'name' => name,
      'email' => email,
      'phone' => phone,
      'business_name' => businessName,
    };
  }
}
