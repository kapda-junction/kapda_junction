import 'package:equatable/equatable.dart';

class AdminUser extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role;

  const AdminUser({required this.id, required this.name, required this.email, required this.role});

  bool get isAdmin => role == 'admin';

  @override
  List<Object?> get props => [id, email, role];
}
