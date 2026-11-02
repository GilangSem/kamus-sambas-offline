/// Model untuk bahasa (languages table)
class Language {
  final String id;
  final String code;
  final String name;
  final String? nativeName;
  final String? description;
  final int isActive;

  Language({
    required this.id,
    required this.code,
    required this.name,
    this.nativeName,
    this.description,
    this.isActive = 1,
  });

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      nativeName: json['native_name'] as String?,
      description: json['description'] as String?,
      isActive: json['is_active'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'native_name': nativeName,
      'description': description,
      'is_active': isActive,
    };
  }

  @override
  String toString() => 'Language(id: $id, code: $code, name: $name)';
}
