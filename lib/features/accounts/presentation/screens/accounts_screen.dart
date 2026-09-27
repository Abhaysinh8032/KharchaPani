// lib/features/accounts/presentation/screens/accounts_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../data/account_model.dart';
import '../providers/account_providers.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAccounts = ref.watch(accountsProvider);

    return Scaffold(
      body: asyncAccounts.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: AppColors.expense))),
        data: (accounts) {
          final totalBalance = accounts.fold(0.0, (s, a) => s + a.balance);

          return ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              const SizedBox(height: 16),

              // ── Overall card ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF3A3A3A)),
                  ),
                  child: Column(
                    children: [
                      const Text('TOTAL BALANCE',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 12)),
                      const SizedBox(height: 6),
                      Text(
                        '₹${totalBalance.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: totalBalance >= 0
                              ? AppColors.income
                              : AppColors.expense,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Accounts',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 8),

              ...accounts.map((acc) => _AccountTile(account: acc, ref: ref)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold,
        foregroundColor: Colors.black,
        onPressed: () => _showAddAccount(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddAccount(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AccountSheet(
        onSave: (name, icon, color, balance) async {
          await ref
              .read(accountRepositoryProvider)
              .create(name: name, icon: icon, color: color, balance: balance);
          ref.invalidate(accountsProvider);
        },
      ),
    );
  }
}

// ─── Account tile with Edit + Delete ──────────────────────────────────────────
class _AccountTile extends StatelessWidget {
  final Account account;
  final WidgetRef ref;

  const _AccountTile({required this.account, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3A3A3A)),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: account.color.withAlpha(40),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(CategoryIcons.accountIcon(account.icon),
                  color: account.color, size: 24),
            ),
            const SizedBox(width: 14),

            // Name + balance
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(account.name,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                          fontSize: 15)),
                  const SizedBox(height: 2),
                  Text('Balance',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            Text(
              '₹${account.balance.toStringAsFixed(2)}',
              style: TextStyle(
                color:
                    account.balance >= 0 ? AppColors.income : AppColors.expense,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 4),

            // ✅ Three-dot menu: Edit + Delete
            PopupMenuButton<String>(
              color: AppColors.bgCard,
              icon: const Icon(Icons.more_vert,
                  color: AppColors.textMuted, size: 20),
              onSelected: (val) async {
                if (val == 'edit') _showEdit(context);
                if (val == 'delete') _confirmDelete(context);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    Icon(Icons.edit_outlined, color: AppColors.gold, size: 18),
                    SizedBox(width: 8),
                    Text('Edit',
                        style: TextStyle(color: AppColors.textPrimary)),
                  ]),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline,
                        color: AppColors.expense, size: 18),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: AppColors.expense)),
                  ]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEdit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AccountSheet(
        existing: account,
        onSave: (name, icon, color, _) async {
          await ref
              .read(accountRepositoryProvider)
              .edit(id: account.id, name: name, icon: icon, color: color);
          ref.invalidate(accountsProvider);
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Delete Account',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text('Delete "${account.name}"? Records linked to it remain.',
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
    if (ok == true) {
      await ref.read(accountRepositoryProvider).delete(account.id);
      ref.invalidate(accountsProvider);
    }
  }
}

// ─── Add / Edit Sheet ─────────────────────────────────────────────────────────

class _AccountSheet extends StatefulWidget {
  final Account? existing;
  final void Function(String name, String icon, Color color, double balance)
      onSave;
  const _AccountSheet({this.existing, required this.onSave});

  @override
  State<_AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends State<_AccountSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _balanceCtrl;
  late String _icon;
  late Color _color;
  final _formKey = GlobalKey<FormState>();

  bool get _isEdit => widget.existing != null;

  static const _icons = ['card', 'cash', 'savings', 'bank', 'wallet'];
  static const _colors = [
    Color(0xFF2196F3),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF795548),
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _balanceCtrl = TextEditingController(
        text: e != null ? e.balance.toStringAsFixed(2) : '0');
    _icon = e?.icon ?? 'bank';
    _color = e?.color ?? _colors[0];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
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
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_isEdit ? 'Edit Account' : 'Add Account',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
                IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 14),

            // Name
            TextFormField(
              controller: _nameCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Account Name',
                prefixIcon: Icon(Icons.label_outline,
                    color: AppColors.textMuted, size: 20),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),

            // Balance (only for add; not shown on edit to avoid confusion)
            if (!_isEdit)
              TextFormField(
                controller: _balanceCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Opening Balance',
                  prefixText: '₹ ',
                ),
              ),
            if (!_isEdit) const SizedBox(height: 12),

            // Icon picker
            const Text('Icon',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: _icons.map((ic) {
                final sel = _icon == ic;
                return GestureDetector(
                  onTap: () => setState(() => _icon = ic),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: sel ? _color.withAlpha(40) : AppColors.bgElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: sel ? _color : const Color(0xFF3A3A3A),
                        width: sel ? 1.5 : 1,
                      ),
                    ),
                    child: Icon(CategoryIcons.accountIcon(ic),
                        color: sel ? _color : AppColors.textMuted, size: 24),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Color picker
            const Text('Color',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: _colors.map((c) {
                final sel = _color == c;
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 10),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: sel ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: sel
                          ? [BoxShadow(color: c.withAlpha(120), blurRadius: 6)]
                          : null,
                    ),
                    child: sel
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(_isEdit ? 'SAVE CHANGES' : 'ADD ACCOUNT'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final balance = double.tryParse(_balanceCtrl.text) ?? 0.0;
    Navigator.pop(context);
    widget.onSave(_nameCtrl.text.trim(), _icon, _color, balance);
  }
}
