import 'package:supabase_flutter/supabase_flutter.dart';

class AccountApi {
  AccountApi(this._client);

  final SupabaseClient _client;

  /// Materializa o registro público após o usuário confirmar o e-mail e entrar.
  Future<void> ensureUserRecord({
    required String id,
    required String name,
    required String email,
    String? phone,
    String? birthDate,
    String? avatarUrl,
  }) async {
    final existing = await _client
        .from('usuario')
        .select('id')
        .eq('id', id)
        .maybeSingle();
    if (existing != null) return;

    await _client.from('usuario').upsert({
      'id': id,
      'nome': name,
      'email': email,
      'telefone': phone,
      'data_nascimento': birthDate,
      'avatar_url': avatarUrl,
      'is_responsavel': true,
    }, onConflict: 'id');
  }
}
