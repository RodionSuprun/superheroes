import 'biography.dart';
import 'server-image.dart';
import 'powerstats.dart';
import 'package:json_annotation/json_annotation.dart';

part 'superhero.g.dart';

@JsonSerializable()
class Superhero {
  final String id;
  String name;
  final Biography biography;
  final ServerImage image;
  final Powerstats powerstats;

  Superhero({required this.id, required this.name, required this.biography, required this.image, required this.powerstats});

  factory Superhero.fromJson(Map<String, dynamic> json) =>
      _$SuperheroFromJson(json);

  Map<String, dynamic> toJson() => _$SuperheroToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Superhero &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          biography.toString() == other.biography.toString() &&
          image.toString() == other.image.toString() &&
          powerstats.toString() == other.powerstats.toString();

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      biography.hashCode ^
      image.hashCode ^
      powerstats.hashCode;
}
