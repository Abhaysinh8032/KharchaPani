// lib/features/categories/presentation/screens/categories_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../data/category_model.dart';
import '../providers/category_providers.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAsync = ref.watch(allCategoriesProvider);

    return Scaffold(
      body: allAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: AppColors.expense))),
        data: (categories) {
          final income =
              categories.where((c) => c.type == CategoryType.income).toList();
          final expense =
              categories.where((c) => c.type == CategoryType.expense).toList();

          return ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              const SizedBox(height: 16),
              _SectionHeader('Income categories'),
              if (income.isEmpty)
                const _EmptyCategoryHint('No income categories yet')
              else
                ...income.map((c) => _CategoryTile(category: c, ref: ref)),
              const SizedBox(height: 8),
              _SectionHeader('Expense categories'),
              if (expense.isEmpty)
                const _EmptyCategoryHint('No expense categories yet')
              else
                ...expense.map((c) => _CategoryTile(category: c, ref: ref)),
            ],
          );
        },
      ),
      // ✅ Fixed: FAB fully wired up
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.gold,
        foregroundColor: Colors.black,
        onPressed: () => _showAddCategory(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('ADD NEW CATEGORY',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }

  void _showAddCategory(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddCategorySheet(
        onSave: (name, icon, color, type) async {
          await ref.read(categoryRepositoryProvider).create(
                name: name,
                icon: icon,
                color: color,
                type: type,
              );
          // ✅ Fixed: invalidate all three dependent providers
          ref.invalidate(allCategoriesProvider);
          ref.invalidate(expenseCategoriesProvider);
          ref.invalidate(incomeCategoriesProvider);
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const Divider(color: Color(0xFF3A3A3A)),
        ],
      ),
    );
  }
}

class _EmptyCategoryHint extends StatelessWidget {
  final String message;
  const _EmptyCategoryHint(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(message,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  final WidgetRef ref;

  const _CategoryTile({required this.category, required this.ref});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: category.color.withAlpha(51),
        child: Icon(CategoryIcons.get(category.icon),
            color: category.color, size: 20),
      ),
      title: Text(category.name,
          style: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w400)),
      trailing: PopupMenuButton<String>(
        color: AppColors.bgCard,
        icon: const Icon(Icons.more_vert, color: AppColors.textMuted, size: 20),
        onSelected: (val) async {
          if (val == 'delete') {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.bgCard,
                title: const Text('Delete Category',
                    style: TextStyle(color: AppColors.textPrimary)),
                content: Text(
                    'Delete "${category.name}"? Records using it won\'t be deleted.',
                    style: const TextStyle(color: AppColors.textSecondary)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel',
                          style: TextStyle(color: AppColors.textSecondary))),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete',
                          style: TextStyle(color: AppColors.expense))),
                ],
              ),
            );
            if (confirm == true) {
              await ref.read(categoryRepositoryProvider).delete(category.id);
              ref.invalidate(allCategoriesProvider);
              ref.invalidate(expenseCategoriesProvider);
              ref.invalidate(incomeCategoriesProvider);
            }
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, color: AppColors.expense, size: 18),
                SizedBox(width: 8),
                Text('Delete', style: TextStyle(color: AppColors.expense)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Add Category Bottom Sheet
// ============================================================
class _AddCategorySheet extends StatefulWidget {
  final void Function(String name, String icon, Color color, CategoryType type)
      onSave;

  const _AddCategorySheet({required this.onSave});

  @override
  State<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<_AddCategorySheet> {
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _icon = 'food';
  Color _color = AppColors.categoryColors[0];
  CategoryType _type = CategoryType.expense;

  static const _availableIcons = [
    'food',
    'shopping',
    'transportation',
    'health',
    'education',
    'entertainment',
    'family',
    'home',
    'sport',
    'beauty',
    'clothing',
    'bills',
    'car',
    'social',
    'salary',
    'telephone',
    'insurance',
    'knowledge',
    'selfcare',
    'data',
    'baby',
    'friends',
    'tax',
    'electronics',
    'awards',
    'coupons',
    'grants',
    'lottery',
    'refunds',
    'rental',
    'sale',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Add Category',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Type toggle
            Row(
              children: [
                Expanded(
                    child: _typeButton(
                        CategoryType.expense, 'Expense', AppColors.expense)),
                const SizedBox(width: 12),
                Expanded(
                    child: _typeButton(
                        CategoryType.income, 'Income', AppColors.income)),
              ],
            ),
            const SizedBox(height: 14),

            // Name field
            TextFormField(
              controller: _nameCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Category Name',
                prefixIcon: Icon(Icons.label_outline,
                    color: AppColors.textMuted, size: 20),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Name is required';
                if (v.trim().length < 2) return 'At least 2 characters';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Icon picker
            const Text('Icon',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            SizedBox(
              height: 54,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _availableIcons.length,
                itemBuilder: (_, i) {
                  final ic = _availableIcons[i];
                  final selected = _icon == ic;
                  return GestureDetector(
                    onTap: () => setState(() => _icon = ic),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: selected
                            ? _color.withAlpha(51)
                            : AppColors.bgElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? _color : const Color(0xFF3A3A3A),
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Icon(
                        CategoryIcons.get(ic),
                        color: selected ? _color : AppColors.textMuted,
                        size: 22,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // Color picker
            const Text('Color',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: AppColors.categoryColors.map((c) {
                final selected = _color == c;
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: selected
                          ? [BoxShadow(color: c.withAlpha(128), blurRadius: 6)]
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Preview + Save
            Row(
              children: [
                // Preview
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _color.withAlpha(51),
                  child:
                      Icon(CategoryIcons.get(_icon), color: _color, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  _nameCtrl.text.isEmpty ? 'Preview' : _nameCtrl.text,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _save,
                  child: const Text('SAVE'),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _typeButton(CategoryType type, String label, Color color) {
    final selected = _type == type;
    return GestureDetector(
      onTap: () => setState(() => _type = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(40) : AppColors.bgElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : const Color(0xFF3A3A3A),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (selected)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(Icons.check_circle, color: color, size: 16),
              ),
            Text(label,
                style: TextStyle(
                    color: selected ? color : AppColors.textMuted,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  void _save() {
    // Refresh name preview if user hasn't tapped elsewhere
    setState(() {});
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context);
    widget.onSave(_nameCtrl.text.trim(), _icon, _color, _type);
  }
}
