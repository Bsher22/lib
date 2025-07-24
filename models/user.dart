// models/user.dart
import 'package:flutter/foundation.dart';

class User {
  final int? id;
  final String username;
  final String name;
  final String email;
  final String role;
  final DateTime? createdAt;

  User({
    this.id,
    required this.username,
    required this.name,
    required this.email,
    required this.role,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'email': email,
      'role': role,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  User copyWith({
    int? id,
    String? username,
    String? name,
    String? email,
    String? role,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool isCoach() {
    return role == 'coach';
  }

  bool isCoordinator() {
    return role == 'coordinator';
  }

  bool isDirector() {
    return role == 'director';
  }

  bool isAdmin() {
    return role == 'admin';
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, role: $role)';
  }
}