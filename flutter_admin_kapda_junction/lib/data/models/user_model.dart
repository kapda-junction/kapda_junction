import '../../domain/entities/user.dart';

class AdminUserModel extends AdminUser {
  const AdminUserModel({required super.id, required super.name, required super.email, required super.role});

  factory AdminUserModel.fromJson(Map<String, dynamic> j) => AdminUserModel(
    id: j['_id'] as String? ?? j['id'] as String? ?? '',
    name: j['name'] as String? ?? '',
    email: j['email'] as String? ?? '',
    role: j['role'] as String? ?? 'customer',
  );

  Map<String, dynamic> toJson() => {'_id': id, 'name': name, 'email': email, 'role': role};
}
