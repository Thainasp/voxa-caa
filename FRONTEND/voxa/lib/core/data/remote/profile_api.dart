import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:voxa/models/user_model.dart';

/// Camada de rede dos perfis (tabelas `usuario` e `perfil`).
class ProfileApi {
  ProfileApi([SupabaseClient? client])
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Tempo máximo de espera do app por uma operação de exclusão. Antes a tela
  /// ficava carregando até o banco cancelar a consulta (erro 57014).
  static const deleteTimeout = Duration(seconds: 20);

  Future<List<UserModel>> fetchDependents(String usuarioId) async {
    final data = await _client
        .from('perfil')
        .select('id, nome, avatar_url, is_responsavel')
        .eq('usuario_id', usuarioId)
        .eq('is_responsavel', false)
        .order('nome', ascending: true);
    return (data as List)
        .map<UserModel>(
          (item) => UserModel(
            id: item['id'] as String,
            name: item['nome'] as String? ?? 'Dependente',
            avatarUrl: item['avatar_url'] as String?,
            isResponsavel: false,
          ),
        )
        .toList();
  }

  /// Telefone cadastrado do responsável (destino do SMS de emergência).
  Future<String?> fetchResponsiblePhone(String usuarioId) async {
    final row = await _client
        .from('usuario')
        .select('telefone')
        .eq('id', usuarioId)
        .maybeSingle();
    final phone = row?['telefone']?.toString().trim();
    return (phone == null || phone.isEmpty) ? null : phone;
  }

  /// Exclui um perfil dependente e todo o seu conteúdo numa transação no banco
  /// (função `excluir_dependente`, em BACKEND/database/voxa_migracao_v2.sql).
  ///
  /// Se a função ainda não foi criada no Supabase, cai no DELETE direto antigo.
  Future<void> deleteDependent(String perfilId, String usuarioId) async {
    try {
      await _client
          .rpc('excluir_dependente', params: {'p_perfil_id': perfilId})
          .timeout(deleteTimeout);
    } on PostgrestException catch (error) {
      final functionMissing =
          error.code == 'PGRST202' || error.code == '42883';
      if (!functionMissing) rethrow;
      await _client
          .from('perfil')
          .delete()
          .eq('id', perfilId)
          .eq('usuario_id', usuarioId)
          .eq('is_responsavel', false)
          .timeout(deleteTimeout);
    }
  }
}
