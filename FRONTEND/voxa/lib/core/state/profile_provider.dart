import 'package:flutter/foundation.dart';

import 'package:voxa/core/state/active_profile.dart';
import 'package:voxa/models/user_model.dart';

/// Perfil ativo compartilhado pelo Provider (BRADEMO CR5).
///
/// Espelha o [ActiveProfile] (usado pelas telas de perfil já existentes) para
/// que qualquer widget leia o perfil com `context.watch<ProfileProvider>()`,
/// como o botão de emergência e o indicador de sincronização da Home.
class ProfileProvider extends ChangeNotifier {
  ProfileProvider() {
    ActiveProfile.notifier.addListener(notifyListeners);
  }

  UserModel? get current => ActiveProfile.current;
  bool get hasProfile => current != null;

  void select(UserModel? profile) => ActiveProfile.set(profile);

  void clear() => ActiveProfile.clear();

  @override
  void dispose() {
    ActiveProfile.notifier.removeListener(notifyListeners);
    super.dispose();
  }
}
