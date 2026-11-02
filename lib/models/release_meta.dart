/// Model untuk metadata rilis dari database kamus
class ReleaseMeta {
  final String key;
  final String value;

  ReleaseMeta({required this.key, required this.value});

  factory ReleaseMeta.fromJson(Map<String, dynamic> json) {
    return ReleaseMeta(
      key: json['key'] as String,
      value: json['value'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'key': key, 'value': value};
  }

  @override
  String toString() => 'ReleaseMeta(key: $key, value: $value)';
}
