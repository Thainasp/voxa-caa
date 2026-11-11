import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  AppConfig._();

  /// Deep link usado pelos e-mails do Supabase (recuperação de senha etc.) no
  /// Android. Precisa bater com o `intent-filter` do AndroidManifest.xml e
  /// estar na lista de "Redirect URLs" do painel do Supabase.
  static const String mobileAuthRedirect = 'io.supabase.voxa://login-callback/';

  /// No web volta para a própria origem do app; no celular usa o deep link.
  static String get authRedirectUrl =>
      kIsWeb ? Uri.base.origin : mobileAuthRedirect;
}
