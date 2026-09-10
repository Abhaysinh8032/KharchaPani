// lib/features/categories/presentation/providers/category_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/category_model.dart';
import '../../data/category_repository.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

final allCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  return ref.read(categoryRepositoryProvider).getAll();
});

final expenseCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  return ref.read(categoryRepositoryProvider).getByType(CategoryType.expense);
});

final incomeCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  return ref.read(categoryRepositoryProvider).getByType(CategoryType.income);
});
