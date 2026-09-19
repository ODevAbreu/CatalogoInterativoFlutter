/// Usuário logado na sessão (RF07).
///
/// Serve tanto para o login local (baseline) quanto para o Supabase Auth
/// (bônus) — [isRemote] diz qual dos dois originou a sessão.
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.isRemote,
  });

  /// Id do usuário: uuid do Supabase, ou o próprio e-mail no modo local.
  final String id;
  final String email;
  final bool isRemote;

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'isRemote': isRemote,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String? ?? '',
        email: json['email'] as String? ?? '',
        isRemote: json['isRemote'] as bool? ?? false,
      );
}
