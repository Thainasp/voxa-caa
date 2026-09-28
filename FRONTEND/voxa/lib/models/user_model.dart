class UserModel {
  final String name;
  final String email;
  final String phone;
  final String birthDate;
  final String password;

  UserModel({
    required this.name,
    required this.email,
    required this.phone,
    required this.birthDate,
    required this.password,
  });
}

// Repositório que mantém os usuários em memória durante a sessão do aplicativo
class UserRepository {
  static final List<UserModel> _users = [];

  static void addUser(UserModel user) {
    _users.add(user);
  }

  static UserModel? findUser(String email, String password) {
    try {
      return _users.firstWhere(
        (u) =>
            u.email.trim().toLowerCase() == email.trim().toLowerCase() &&
            u.password == password,
      );
    } catch (_) {
      return null;
    }
  }
}
