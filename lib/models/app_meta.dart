/// Model untuk metadata aplikasi lokal
class AppMeta {
  final String key;
  final String value;

  AppMeta({required this.key, required this.value});

  factory AppMeta.fromJson(Map<String, dynamic> json) {
    return AppMeta(key: json['key'] as String, value: json['value'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'key': key, 'value': value};
  }

  @override
  String toString() => 'AppMeta(key: $key, value: $value)';
}
