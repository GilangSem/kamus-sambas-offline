/// Model untuk kategori (categories table)
class Category {
  final String id;
  final String? parentId;
  final String name;
  final String? description;

  Category({
    required this.id,
    this.parentId,
    required this.name,
    this.description,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      parentId: json['parent_id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parent_id': parentId,
      'name': name,
      'description': description,
    };
  }

  @override
  String toString() => 'Category(id: $id, name: $name)';
}
