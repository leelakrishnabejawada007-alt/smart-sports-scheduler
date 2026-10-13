class AppUser {
  final String id;
  final String name;
  final String email;
  final String studentId;

  /// 'student' or 'admin'.
  final String role;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.studentId,
    this.role = 'student',
  });

  bool get isAdmin => role == 'admin';

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'].toString(),
        name: json['name'] as String,
        email: json['email'] as String,
        studentId: json['studentId'] as String,
        role: json['role'] as String? ?? 'student',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'studentId': studentId,
        'role': role,
      };
}
