import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:voxa/models/user_model.dart';

/// Fonte única da verdade para o perfil que está em uso no app.
///
/// Antes, a troca de perfil era devolvida à Home através de uma cadeia de
/// `Navigator.pop(result)`. Se o usuário apertasse o botão Home em uma tela
/// mais profunda, o resultado se perdia. Agora quem troca/edita o perfil
/// atualiza este notifier e a Home (e a tela de Perfil) reagem a ele.
class ActiveProfile {
  ActiveProfile._();

  static final ValueNotifier<UserModel?> notifier = ValueNotifier<UserModel?>(
    null,
  );

  static UserModel? get current => notifier.value;

  static void set(UserModel? profile) => notifier.value = profile;

  static void clear() => notifier.value = null;

  /// Busca o perfil do responsável (master) da conta logada.
  /// Retorna `null` se não houver sessão ou se a consulta falhar.
  static Future<UserModel?> loadMaster() async {
    final client = Supabase.instance.client;
    final authUser = client.auth.currentUser;
    if (authUser == null) return null;

    try {
      final data = await client
          .from('perfil')
          .select('id, nome, avatar_url')
          .eq('usuario_id', authUser.id)
          .eq('is_responsavel', true)
          .maybeSingle();

      if (data == null) return null;

      return UserModel(
        id: data['id'].toString(),
        name: (data['nome'] ?? 'Titular').toString(),
        email: authUser.email ?? '',
        avatarUrl: data['avatar_url']?.toString(),
        isResponsavel: true,
      );
    } catch (_) {
      return null;
    }
  }
}
