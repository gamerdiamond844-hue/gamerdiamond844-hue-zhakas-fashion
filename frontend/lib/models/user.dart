class User {
  final int id;
  final String email;
  final String? fullName;
  final String? profileImage;

  User({required this.id, required this.email, this.fullName, this.profileImage});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      profileImage: json['profile_image'],
    );
  }
}
