// lib/features/records/presentation/screens/add_record_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../accounts/data/account_model.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../categories/data/category_model.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../data/record_model.dart';
import '../providers/record_providers.dart';

class AddRecordScreen extends ConsumerStatefulWidget {
  final FinancialRecord? record;

  const AddRecordScreen({super.key, this.record});

  @override
  ConsumerState<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends ConsumerState<AddRecordScreen> {
  RecordType _type = RecordType.expense;
  Account? _selectedAccount;
  Account? _toAccount;
  Category? _selectedCategory;
  String _amountStr = '0';
  String _operator = '';
  String _previousValue = '0';
  final _notesController = TextEditingController();
  DateTime _date = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.record != null) {
      final record = widget.record!;
      _type = record.type;
      _amountStr = record.amount.toString();
      _date = record.date;
      _notesController.text = record.notes ?? '';
      // Load associated data asynchronously
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
    }
  }

  void _loadInitialData() async {
    if (widget.record == null) return;
    final record = widget.record!;
    final accountRepo = ref.read(accountRepositoryProvider);
    final catRepo = ref.read(categoryRepositoryProvider);

    // Load account
    final acc = await accountRepo.getById(record.accountId);
    if (acc != null && mounted) {
      setState(() => _selectedAccount = acc);
    }

    // Load to account for transfers
    if (record.toAccountId != null) {
      final toAcc = await accountRepo.getById(record.toAccountId!);
      if (toAcc != null && mounted) {
        setState(() => _toAccount = toAcc);
      }
    }

    // Load category
    if (record.categoryId != null) {
      final allCats = _type == RecordType.income
          ? await catRepo.getByType(CategoryType.income)
          : await catRepo.getByType(CategoryType.expense);
      try {
        final cat = allCats.firstWhere(
          (c) => c.id == record.categoryId,
        );
        if (mounted) {
          setState(() => _selectedCategory = cat);
        }
      } catch (_) {
        // Category not found
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_amountStr) ?? 0;

  void _onKey(String key) {
    setState(() {
      if (key == 'C') {
        _amountStr = '0';
        _operator = '';
        _previousValue = '0';
      } else if (key == '⌫') {
        if (_amountStr.length > 1) {
          _amountStr = _amountStr.substring(0, _amountStr.length - 1);
        } else {
          _amountStr = '0';
        }
      } else if (key == '.') {
        if (!_amountStr.contains('.')) _amountStr += '.';
      } else if (['+', '-', '×', '÷'].contains(key)) {
        if (_operator.isNotEmpty && _amountStr != _previousValue) {
          _calculate();
        }
        _operator = key;
        _previousValue = _amountStr;
        _amountStr = '0';
      } else if (key == '=') {
        _calculate();
        _operator = '';
      } else {
        if (_amountStr == '0') {
          _amountStr = key;
        } else {
          // Limit decimal places to 2
          if (_amountStr.contains('.')) {
            final parts = _amountStr.split('.');
            if (parts[1].length < 2) _amountStr += key;
          } else {
            _amountStr += key;
          }
        }
      }
    });
  }

  void _calculate() {
    final current = double.tryParse(_amountStr) ?? 0;
    final previous = double.tryParse(_previousValue) ?? 0;
    double result = 0;

    switch (_operator) {
      case '+':
        result = previous + current;
        break;
      case '-':
        result = previous - current;
        break;
      case '×':
        result = previous * current;
        break;
      case '÷':
        result = current != 0 ? previous / current : 0;
        break;
    }

    // Format result: remove trailing zeros and unnecessary decimal point
    final resultStr = result.toStringAsFixed(2);
    _amountStr = double.parse(resultStr).toString();
    if (_amountStr.endsWith('.0')) {
      _amountStr = _amountStr.replaceAll('.0', '');
    }
    _previousValue = _amountStr;
  }

  Future<void> _save() async {
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }
    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account')),
      );
      return;
    }
    if (_type != RecordType.transfer && _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }
    if (_type == RecordType.transfer && _toAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select destination account')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(recordRepositoryProvider);
      if (widget.record != null) {
        // Update existing record
        await repo.update(
          id: widget.record!.id,
          type: _type,
          amount: _amount,
          accountId: _selectedAccount!.id,
          categoryId: _selectedCategory?.id,
          toAccountId: _toAccount?.id,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          date: _date,
        );
      } else {
        // Create new record
        await repo.create(
          type: _type,
          amount: _amount,
          accountId: _selectedAccount!.id,
          categoryId: _selectedCategory?.id,
          toAccountId: _toAccount?.id,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          date: _date,
        );
      }
      ref.invalidate(monthRecordsProvider);
      ref.invalidate(accountsProvider);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        title: Text(
          widget.record != null ? 'Edit Record' : 'Add Record',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
        leading: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: AppColors.expense, size: 18),
          label: const Text('CANCEL',
              style: TextStyle(color: AppColors.expense, fontSize: 13)),
        ),
        leadingWidth: 110,
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: const Icon(Icons.check, color: AppColors.gold, size: 18),
            label: const Text('SAVE',
                style: TextStyle(color: AppColors.gold, fontSize: 13)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Type selector
          _TypeSelector(
            selected: _type,
            onChanged: (t) => setState(() {
              _type = t;
              _selectedCategory = null;
            }),
          ),
          const SizedBox(height: 12),

          // Account & Category buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _SelectorButton(
                    icon: Icons.account_balance_wallet,
                    label: _selectedAccount?.name ?? 'Account',
                    color: _selectedAccount != null
                        ? AppColors.gold
                        : AppColors.textMuted,
                    onTap: () => _showAccountPicker(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _type == RecordType.transfer
                      ? _SelectorButton(
                          icon: Icons.account_balance_wallet_outlined,
                          label: _toAccount?.name ?? 'To Account',
                          color: _toAccount != null
                              ? AppColors.gold
                              : AppColors.textMuted,
                          onTap: () => _showAccountPicker(context, isTo: true),
                        )
                      : _SelectorButton(
                          icon: Icons.local_offer,
                          label: _selectedCategory?.name ?? 'Category',
                          color: _selectedCategory != null
                              ? AppColors.gold
                              : AppColors.textMuted,
                          onTap: () => _showCategoryPicker(context),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Notes field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _notesController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Add notes',
                prefixIcon:
                    Icon(Icons.notes, color: AppColors.textMuted, size: 20),
              ),
              maxLines: 2,
            ),
          ),
          const Spacer(),

          // Amount display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '₹$_amountStr',
                  style: TextStyle(
                    color: _type == RecordType.expense
                        ? AppColors.expense
                        : _type == RecordType.income
                            ? AppColors.income
                            : AppColors.transfer,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _onKey('⌫'),
                  child: const Icon(Icons.backspace_outlined,
                      color: AppColors.textSecondary, size: 24),
                ),
              ],
            ),
          ),

          // Date bar
          GestureDetector(
            onTap: () => _pickDate(context),
            child: Container(
              color: AppColors.bgElevated,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    '${_date.day} ${_monthName(_date.month)} ${_date.year}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const Text('|', style: TextStyle(color: AppColors.textMuted)),
                  Text(
                    '${_date.hour.toString().padLeft(2, '0')}:${_date.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          // Calculator
          _Calculator(onKey: _onKey),
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.gold),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      if (!context.mounted) return;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_date),
        builder: (ctx, child) => Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: AppColors.gold),
          ),
          child: child!,
        ),
      );
      if (pickedTime != null) {
        setState(() => _date = DateTime(
              picked.year,
              picked.month,
              picked.day,
              pickedTime.hour,
              pickedTime.minute,
            ));
      } else {
        setState(() => _date = picked);
      }
    }
  }

  Future<void> _showAccountPicker(BuildContext context,
      {bool isTo = false}) async {
    final accounts = await ref.read(accountRepositoryProvider).getAll();
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AccountPickerSheet(
        accounts: accounts,
        onSelected: (acc) {
          setState(() {
            if (isTo) {
              _toAccount = acc;
            } else {
              _selectedAccount = acc;
            }
          });
        },
      ),
    );
  }

  Future<void> _showCategoryPicker(BuildContext context) async {
    final catRepo = ref.read(categoryRepositoryProvider);
    final categories = _type == RecordType.income
        ? await catRepo.getByType(CategoryType.income)
        : await catRepo.getByType(CategoryType.expense);
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CategoryPickerSheet(
        categories: categories,
        onSelected: (cat) => setState(() => _selectedCategory = cat),
      ),
    );
  }

  String _monthName(int m) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return names[m - 1];
  }
}

class _TypeSelector extends StatelessWidget {
  final RecordType selected;
  final ValueChanged<RecordType> onChanged;

  const _TypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _TypeTab('INCOME', RecordType.income, selected, onChanged),
        Container(width: 1, height: 20, color: AppColors.textMuted),
        _TypeTab('EXPENSE', RecordType.expense, selected, onChanged,
            checked: true),
        Container(width: 1, height: 20, color: AppColors.textMuted),
        _TypeTab('TRANSFER', RecordType.transfer, selected, onChanged),
      ],
    );
  }
}

class _TypeTab extends StatelessWidget {
  final String label;
  final RecordType type;
  final RecordType selected;
  final ValueChanged<RecordType> onChanged;
  final bool checked;

  const _TypeTab(this.label, this.type, this.selected, this.onChanged,
      {this.checked = false});

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == type;
    return GestureDetector(
      onTap: () => onChanged(type),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child:
                    Icon(Icons.check_circle, color: AppColors.gold, size: 16),
              ),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.gold : AppColors.textMuted,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectorButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SelectorButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF3A3A3A)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: color, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Calculator extends StatelessWidget {
  final ValueChanged<String> onKey;

  const _Calculator({required this.onKey});

  @override
  Widget build(BuildContext context) {
    final keys = [
      ['+', '7', '8', '9'],
      ['-', '4', '5', '6'],
      ['×', '1', '2', '3'],
      ['÷', '0', '.', '='],
    ];

    return Container(
      color: AppColors.bgElevated,
      child: Column(
        children: keys.map((row) {
          return Row(
            children: row.map((k) {
              final isOp = ['+', '-', '×', '÷', '='].contains(k);
              return Expanded(
                child: GestureDetector(
                  onTap: () => onKey(k),
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: const Color(0xFF2A2A2A), width: 0.5),
                      color: isOp ? AppColors.bgCard : AppColors.bgElevated,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      k,
                      style: TextStyle(
                        color: isOp ? AppColors.gold : AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}

class _AccountPickerSheet extends StatelessWidget {
  final List<Account> accounts;
  final ValueChanged<Account> onSelected;

  const _AccountPickerSheet({required this.accounts, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Select an account',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
        ),
        ...accounts.map((acc) => ListTile(
              leading: CircleAvatar(
                backgroundColor: acc.color.withAlpha(51),
                child: Icon(CategoryIcons.accountIcon(acc.icon),
                    color: acc.color, size: 20),
              ),
              title: Text(acc.name,
                  style: const TextStyle(color: AppColors.textPrimary)),
              trailing: Text(
                '₹${acc.balance.toStringAsFixed(2)}',
                style: TextStyle(
                  color:
                      acc.balance >= 0 ? AppColors.income : AppColors.expense,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                onSelected(acc);
              },
            )),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _CategoryPickerSheet extends StatelessWidget {
  final List<Category> categories;
  final ValueChanged<Category> onSelected;

  const _CategoryPickerSheet(
      {required this.categories, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Select a category',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: GridView.builder(
              controller: controller,
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.9,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: categories.length,
              itemBuilder: (_, i) {
                final cat = categories[i];
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onSelected(cat);
                  },
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: cat.color.withAlpha(64),
                        child: Icon(CategoryIcons.get(cat.icon),
                            color: cat.color, size: 26),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cat.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
