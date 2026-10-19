class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? birthDate;
  final bool isResponsavel;
  final String? avatarUrl;
  final bool isDependent;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.birthDate,
    this.isResponsavel = false,
    this.avatarUrl,
    this.isDependent = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: map['nome'] as String? ?? map['name'] as String? ?? '',
      email: map['email'] ?? '',
      phone: map['telefone'] as String?,
      birthDate: map['data_nascimento'] as String?,
      isResponsavel: map['is_responsavel'] ?? false,
      avatarUrl: map['avatar_url'] as String? ?? map['avatarUrl'] as String?,
      isDependent: map['is_dependent'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMetadataMap() {
    return {
      'id': id,
      'nome': name,
      'email': email,
      'telefone': phone,
      'data_nascimento': birthDate,
      'is_responsavel': isResponsavel,
      'avatar_url': avatarUrl,
      'is_dependent': isDependent,
    };
  }
}
