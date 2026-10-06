class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? birthDate;
  final bool isResponsavel;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.birthDate,
    this.isResponsavel = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: map['nome'] ?? '',
      email: map['email'] ?? '',
      phone: map['telefone'] as String?,
      birthDate: map['data_nascimento'] as String?,
      isResponsavel: map['is_responsavel'] ?? false,
    );
  }
}