import 'pokemon_summary.dart';

/// Um Pokémon dentro da coleção do usuário, com as duas marcações do
/// enunciado: favorito (RF04/RF05) e capturado (RF07).
///
/// Guardar o [pokemon] junto das flags permite desenhar as telas de favoritos
/// e capturados offline, sem uma nova chamada à API.
class CollectionEntry {
  const CollectionEntry({
    required this.pokemon,
    required this.isFavorite,
    required this.isCaptured,
    required this.updatedAt,
  });

  final PokemonSummary pokemon;
  final bool isFavorite;
  final bool isCaptured;

  /// Usado para resolver conflitos entre o que está local e o que está na
  /// nuvem: vence a marcação mais recente.
  final DateTime updatedAt;

  int get id => pokemon.id;

  /// Entrada sem nenhuma marcação pode ser descartada do armazenamento.
  bool get isEmpty => !isFavorite && !isCaptured;

  CollectionEntry copyWith({
    PokemonSummary? pokemon,
    bool? isFavorite,
    bool? isCaptured,
    DateTime? updatedAt,
  }) =>
      CollectionEntry(
        pokemon: pokemon ?? this.pokemon,
        isFavorite: isFavorite ?? this.isFavorite,
        isCaptured: isCaptured ?? this.isCaptured,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'pokemon': pokemon.toJson(),
        'isFavorite': isFavorite,
        'isCaptured': isCaptured,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory CollectionEntry.fromJson(Map<String, dynamic> json) =>
      CollectionEntry(
        pokemon:
            PokemonSummary.fromJson(json['pokemon'] as Map<String, dynamic>),
        isFavorite: json['isFavorite'] as bool? ?? false,
        isCaptured: json['isCaptured'] as bool? ?? false,
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );

  /// Formato da tabela `user_items` no Supabase (bônus RF06).
  Map<String, dynamic> toRemoteJson(String userId) => {
        'user_id': userId,
        'pokemon_id': pokemon.id,
        'name': pokemon.name,
        'image_url': pokemon.imageUrl,
        'is_favorite': isFavorite,
        'is_captured': isCaptured,
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

  factory CollectionEntry.fromRemoteJson(Map<String, dynamic> json) =>
      CollectionEntry(
        pokemon: PokemonSummary(
          id: (json['pokemon_id'] as num?)?.toInt() ?? 0,
          name: json['name'] as String? ?? '',
          imageUrl: json['image_url'] as String? ?? '',
        ),
        isFavorite: json['is_favorite'] as bool? ?? false,
        isCaptured: json['is_captured'] as bool? ?? false,
        updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '')
                ?.toLocal() ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}
