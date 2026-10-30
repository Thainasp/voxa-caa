class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? birthDate;
  final bool isResponsavel;
  final String? avatarUrl;

  const UserModel({
    required this.id,
    required this.name,
    this.email = '',
    this.phone,
    this.birthDate,
    this.isResponsavel = false,
    this.avatarUrl,
  });

  bool get isDependent => !isResponsavel;

  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Trata tanto a coluna 'is_responsavel' quanto eventual 'is_dependente' legada
    final isResp =
        map['is_responsavel'] as bool? ??
        (map.containsKey('is_dependente')
            ? !(map['is_dependente'] as bool? ?? false)
            : false);

    return UserModel(
      id: map['id']?.toString() ?? '',
      name: (map['nome'] ?? map['name'] ?? map['display_name'] ?? '')
          .toString(),
      email: (map['email'] ?? '').toString(),
      phone: map['telefone']?.toString(),
      birthDate: map['data_nascimento']?.toString(),
      isResponsavel: isResp,
      avatarUrl: (map['avatar_url'] ?? map['avatarUrl'])?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': name,
      'email': email,
      'telefone': phone,
      'data_nascimento': birthDate,
      'is_responsavel': isResponsavel,
      'avatar_url': avatarUrl,
    };
  }

  Map<String, dynamic> toMetadataMap() => toMap();

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? birthDate,
    bool? isResponsavel,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      isResponsavel: isResponsavel ?? this.isResponsavel,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
