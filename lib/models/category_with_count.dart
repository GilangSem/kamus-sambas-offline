import 'category.dart';

/// Kategori beserta jumlah kata published di dalamnya.
class CategoryWithCount {
  final Category category;
  final int wordCount;

  CategoryWithCount({required this.category, required this.wordCount});

  String get id => category.id;
  String get name => category.name;
  String? get description => category.description;

  @override
  String toString() => 'CategoryWithCount(name: $name, count: $wordCount)';
}
