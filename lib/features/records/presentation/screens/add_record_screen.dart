// lib/features/records/presentation/screens/add_record_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../accounts/data/account_model.dart';
import '../../../accounts/data/account_repository.dart';
import '../../../categories/data/category_model.dart';
import '../../../categories/data/category_repository.dart';
import '../../data/record_model.dart';
import '../providers/record_providers.dart';

class AddRecordScreen extends ConsumerStatefulWidget {
  final FinancialRecord? recordToEdit;
  const AddRecordScreen({super.key, this.recordToEdit});

  @override
  ConsumerState<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends ConsumerState<AddRecordScreen> {
  RecordType _type = RecordType.expense;
  Account? _account;
  Account? _toAccount;
  Category? _category;
  String _amtStr = '0';
  DateTime _date = DateTime.now();
  bool _saving = false;
  final _notesCtrl = TextEditingController();

  double get _amount => double.tryParse(_amtStr) ?? 0;

  @override
  void initState() {
    super.initState();
    final edit = widget.recordToEdit;
    if (edit != null) {
      _type = edit.type;
      _amtStr = edit.amount.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
      _date = edit.date;
      _notesCtrl.text = edit.notes ?? '';
      _account = Account(
          id: edit.accountId,
          name: edit.accountName ?? 'Unknown',
          icon: '',
          color: Colors.transparent,
          balance: 0,
          createdAt: DateTime.now());

      if (edit.toAccountId != null) {
        _toAccount = Account(
            id: edit.toAccountId!,
            name: edit.toAccountName ?? 'Unknown',
            icon: '',
            color: Colors.transparent,
            balance: 0,
            createdAt: DateTime.now());
      }
      if (edit.categoryId != null) {
        _category = Category(
            id: edit.categoryId!,
            name: edit.categoryName ?? 'Unknown',
            icon: edit.categoryIcon ?? '',
            color: edit.categoryColor != null
                ? Color(edit.categoryColor!)
                : Colors.transparent,
            type: edit.type == RecordType.income
                ? CategoryType.income
                : CategoryType.expense,
            createdAt: DateTime.now());
      }
    }
  }

  void _key(String k) => setState(() {
        if (k == '⌫') {
          _amtStr = _amtStr.length > 1
              ? _amtStr.substring(0, _amtStr.length - 1)
              : '0';
        } else if (k == '.') {
          if (!_amtStr.contains('.')) _amtStr += '.';
        } else {
          if (_amtStr == '0') {
            _amtStr = k;
          } else if (_amtStr.contains('.')) {
            if (_amtStr.split('.')[1].length < 2) _amtStr += k;
          } else {
            _amtStr += k;
          }
        }
      });

  Future<void> _save() async {
    if (_amount <= 0) {
      _snack('Enter an amount');
      return;
    }
    if (_account == null) {
      _snack('Select an account');
      return;
    }
    if (_type != RecordType.transfer && _category == null) {
      _snack('Select a category');
      return;
    }
    if (_type == RecordType.transfer && _toAccount == null) {
      _snack('Select destination account');
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(recordRepositoryProvider);
      if (widget.recordToEdit != null) {
        await repo.update(
          widget.recordToEdit!.id,
          type: _type,
          amount: _amount,
          accountId: _account!.id,
          categoryId: _category?.id,
          toAccountId: _toAccount?.id,
          notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
          date: _date,
        );
      } else {
        await repo.create(
          type: _type,
          amount: _amount,
          accountId: _account!.id,
          categoryId: _category?.id,
          toAccountId: _toAccount?.id,
          notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
          date: _date,
        );
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final amtColor = _type == RecordType.expense
        ? AppColors.expense
        : _type == RecordType.income
            ? AppColors.income
            : AppColors.transfer;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        leading: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: AppColors.expense, size: 18),
          label: const Text('CANCEL',
              style: TextStyle(color: AppColors.expense, fontSize: 13)),
        ),
        leadingWidth: 110,
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check, color: AppColors.gold, size: 18),
            label: const Text('SAVE',
                style: TextStyle(color: AppColors.gold, fontSize: 13)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Type selector
          _TypeRow(
              selected: _type,
              onChanged: (t) => setState(() {
                    _type = t;
                    _category = null;
                  })),
          const SizedBox(height: 10),

          // Account + Category/ToAccount
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Expanded(
                  child: _SelBtn(
                      icon: Icons.account_balance_wallet,
                      label: _account?.name ?? 'Account',
                      active: _account != null,
                      onTap: () => _pickAccount(false))),
              const SizedBox(width: 12),
              Expanded(
                  child: _type == RecordType.transfer
                      ? _SelBtn(
                          icon: Icons.account_balance_wallet_outlined,
                          label: _toAccount?.name ?? 'To Account',
                          active: _toAccount != null,
                          onTap: () => _pickAccount(true))
                      : _SelBtn(
                          icon: Icons.local_offer,
                          label: _category?.name ?? 'Category',
                          active: _category != null,
                          onTap: _pickCategory)),
            ]),
          ),
          const SizedBox(height: 10),

          // Notes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _notesCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                  hintText: 'Add notes',
                  prefixIcon:
                      Icon(Icons.notes, color: AppColors.textMuted, size: 20)),
              maxLines: 2,
            ),
          ),
          const Spacer(),

          // Amount display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                    child: Text('₹$_amtStr',
                        style: TextStyle(
                            color: amtColor,
                            fontSize: 36,
                            fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 10),
                GestureDetector(
                    onTap: () => _key('⌫'),
                    child: const Icon(Icons.backspace_outlined,
                        color: AppColors.textSecondary, size: 24)),
              ],
            ),
          ),

          // Date bar
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              color: AppColors.bgElevated,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                      '${_date.day} ${Formatters.monthName(_date.month)} ${_date.year}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 14)),
                  const Text('|', style: TextStyle(color: AppColors.textMuted)),
                  Text(
                      '${_date.hour.toString().padLeft(2, '0')}:${_date.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 14)),
                ],
              ),
            ),
          ),

          // Calculator
          _Calculator(onKey: _key),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
          data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(primary: AppColors.gold)),
          child: child!),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickAccount(bool isTo) async {
    final accounts = await AccountRepository().getAll();
    if (!mounted) return;
    final picked = await showModalBottomSheet<Account>(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AccountSheet(accounts: accounts),
    );
    if (picked != null)
      setState(() => isTo ? _toAccount = picked : _account = picked);
  }

  Future<void> _pickCategory() async {
    final cats = _type == RecordType.income
        ? await CategoryRepository().getByType(CategoryType.income)
        : await CategoryRepository().getByType(CategoryType.expense);
    if (!mounted) return;
    final picked = await showModalBottomSheet<Category>(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CategorySheet(categories: cats),
    );
    if (picked != null) setState(() => _category = picked);
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _TypeRow extends StatelessWidget {
  final RecordType selected;
  final ValueChanged<RecordType> onChanged;
  const _TypeRow({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: RecordType.values.map((t) {
          final isSel = selected == t;
          final label = t.name.toUpperCase();
          return GestureDetector(
            onTap: () => onChanged(t),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                if (isSel)
                  const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.check_circle,
                          color: AppColors.gold, size: 16)),
                Text(label,
                    style: TextStyle(
                        color: isSel ? AppColors.gold : AppColors.textMuted,
                        fontWeight: isSel ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 13)),
              ]),
            ),
          );
        }).toList(),
      );
}

class _SelBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _SelBtn(
      {required this.icon,
      required this.label,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.bgElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: active
                    ? AppColors.gold.withAlpha(100)
                    : const Color(0xFF3A3A3A)),
          ),
          child: Row(children: [
            Icon(icon,
                color: active ? AppColors.gold : AppColors.textMuted, size: 18),
            const SizedBox(width: 8),
            Expanded(
                child: Text(label,
                    style: TextStyle(
                        color: active ? AppColors.gold : AppColors.textMuted,
                        fontSize: 13),
                    overflow: TextOverflow.ellipsis)),
          ]),
        ),
      );
}

class _Calculator extends StatelessWidget {
  final ValueChanged<String> onKey;
  const _Calculator({required this.onKey});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['+', '7', '8', '9'],
      ['-', '4', '5', '6'],
      ['×', '1', '2', '3'],
      ['÷', '0', '.', '='],
    ];
    return Container(
      color: AppColors.bgElevated,
      child: Column(
        children: rows
            .map((row) => Row(
                  children: row.map((k) {
                    final isOp = '+-×÷='.contains(k);
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!isOp) onKey(k);
                        },
                        child: Container(
                          height: 58,
                          decoration: BoxDecoration(
                              border: Border.all(
                                  color: const Color(0xFF222222), width: 0.5),
                              color: isOp
                                  ? AppColors.bgCard
                                  : AppColors.bgElevated),
                          alignment: Alignment.center,
                          child: Text(k,
                              style: TextStyle(
                                  color: isOp
                                      ? AppColors.gold
                                      : AppColors.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ),
                    );
                  }).toList(),
                ))
            .toList(),
      ),
    );
  }
}

class _AccountSheet extends StatelessWidget {
  final List<Account> accounts;
  const _AccountSheet({required this.accounts});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Select an account',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600))),
          ...accounts.map((a) => ListTile(
                leading: CircleAvatar(
                    backgroundColor: a.color.withAlpha(40),
                    child: Icon(CategoryIcons.accountIcon(a.icon),
                        color: a.color, size: 20)),
                title: Text(a.name,
                    style: const TextStyle(color: AppColors.textPrimary)),
                trailing: Text('₹${a.balance.toStringAsFixed(2)}',
                    style: TextStyle(
                        color: a.balance >= 0
                            ? AppColors.income
                            : AppColors.expense,
                        fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(context, a),
              )),
          const SizedBox(height: 24),
        ],
      );
}

class _CategorySheet extends StatelessWidget {
  final List<Category> categories;
  const _CategorySheet({required this.categories});

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, ctrl) => Column(
          children: [
            const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Select a category',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600))),
            Expanded(
              child: GridView.builder(
                controller: ctrl,
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.9,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12),
                itemCount: categories.length,
                itemBuilder: (_, i) {
                  final c = categories[i];
                  return GestureDetector(
                    onTap: () => Navigator.pop(context, c),
                    child: Column(children: [
                      CircleAvatar(
                          radius: 28,
                          backgroundColor: c.color.withAlpha(50),
                          child: Icon(CategoryIcons.get(c.icon),
                              color: c.color, size: 26)),
                      const SizedBox(height: 6),
                      Text(c.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ]),
                  );
                },
              ),
            ),
          ],
        ),
      );
}

// Inline to avoid extra import
class Formatters {
  static String monthName(int m) {
    const n = [
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
    return n[m - 1];
  }
}
