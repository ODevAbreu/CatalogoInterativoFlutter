/// Configuração sensível do app.
///
/// As credenciais do Supabase NÃO ficam no repositório: elas são injetadas em
/// tempo de compilação com `--dart-define-from-file=env.json` (arquivo que
/// está no .gitignore). Quando nada é injetado, [isCloudEnabled] fica `false`
/// e o app roda no modo 100% local (login local + shared_preferences), que é
/// o baseline obrigatório do RF06/RF07.
class Env {
  const Env._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  /// `true` quando o app foi compilado com as credenciais da nuvem.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static bool _cloudReady = false;

  /// `true` somente quando as credenciais existem **e** o
  /// `Supabase.initialize` deu certo. Se a inicialização falhar (URL errada,
  /// sem internet no start), o app continua no modo local em vez de quebrar.
  static bool get isCloudEnabled => isConfigured && _cloudReady;

  static void markCloudReady() => _cloudReady = true;
}
