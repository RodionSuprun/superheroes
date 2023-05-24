import 'package:json_annotation/json_annotation.dart';

part 'server-image.g.dart';

@JsonSerializable()
class ServerImage {
  final String url;

  ServerImage({required this.url});

  factory ServerImage.fromJson(Map<String, dynamic> json) =>
      _$ServerImageFromJson(json);

  Map<String, dynamic> toJson() => _$ServerImageToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServerImage &&
          runtimeType == other.runtimeType &&
          url == other.url;

  @override
  int get hashCode => url.hashCode;
}
