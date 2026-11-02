/// Model untuk kelas kata (word_classes table)
class WordClass {
  final String id;
  final String? parentId;
  final String code;
  final String name;
  final String? alias;
  final String? description;

  WordClass({
    required this.id,
    this.parentId,
    required this.code,
    required this.name,
    this.alias,
    this.description,
  });

  factory WordClass.fromJson(Map<String, dynamic> json) {
    return WordClass(
      id: json['id'] as String,
      parentId: json['parent_id'] as String?,
      code: json['code'] as String,
      name: json['name'] as String,
      alias: json['alias'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parent_id': parentId,
      'code': code,
      'name': name,
      'alias': alias,
      'description': description,
    };
  }

  @override
  String toString() => 'WordClass(id: $id, code: $code, name: $name)';
}
