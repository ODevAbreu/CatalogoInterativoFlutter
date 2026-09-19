import '../core/utils/pokemon_utils.dart';

/// Versão enxuta de um Pokémon: o suficiente para desenhar um card na grade
/// (RF01) e para persistir favoritos/capturados sem precisar de rede (RF06).
class PokemonSummary {
  const PokemonSummary({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  final int id;

  /// Nome cru da API (minúsculo, com hífens). Use [displayName] na UI.
  final String name;

  /// Pode ser vazio: nesse caso a UI mostra o placeholder (RF01).
  final String imageUrl;

  String get displayName => PokemonUtils.displayName(name);
  String get formattedId => PokemonUtils.formattedId(id);

  /// Constrói a partir de um item de `/pokemon?limit=&offset=`,
  /// que traz apenas `{ "name": ..., "url": ... }`.
  factory PokemonSummary.fromListItem(Map<String, dynamic> json) {
    final id = PokemonUtils.idFromUrl(json['url'] as String? ?? '');
    return PokemonSummary(
      id: id,
      name: json['name'] as String? ?? '',
      imageUrl: id > 0 ? PokemonUtils.artworkUrl(id) : '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'imageUrl': imageUrl,
      };

  factory PokemonSummary.fromJson(Map<String, dynamic> json) => PokemonSummary(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        imageUrl: json['imageUrl'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      other is PokemonSummary && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}
