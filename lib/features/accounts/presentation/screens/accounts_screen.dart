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
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      body: accountsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (accounts) {
          // Overall totals
          double totalBalance = accounts.fold(0.0, (s, a) => s + a.balance);

          return ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              const SizedBox(height: 16),
              // Overall card
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
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                const Text('EXPENSE SO FAR',
                                    style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 11)),
                                const SizedBox(height: 4),
                                Text(
                                  '-₹0.00',
                                  style: const TextStyle(
                                      color: AppColors.expense,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                          Container(
                              width: 1,
                              height: 40,
                              color: const Color(0xFF3A3A3A)),
                          Expanded(
                            child: Column(
                              children: [
                                const Text('INCOME SO FAR',
                                    style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 11)),
                                const SizedBox(height: 4),
                                Text(
                                  '₹0.00',
                                  style: const TextStyle(
                                      color: AppColors.income,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20, color: Color(0xFF3A3A3A)),
                      const Text('TOTAL BALANCE',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(
                        '₹${totalBalance.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: totalBalance >= 0
                              ? AppColors.income
                              : AppColors.expense,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
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
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddAccountSheet(
        onSave: (name, icon, colorVal, balance) async {
          await ref.read(accountRepositoryProvider).create(
                name: name,
                icon: icon,
                colorValue: colorVal,
                balance: balance,
              );
          ref.invalidate(accountsProvider);
        },
      ),
    );
  }
}

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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: account.color.withAlpha(51),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                CategoryIcons.accountIcon(account.icon),
                color: account.color,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(account.name,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                          fontSize: 15)),
                  Text(
                    'Balance:',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                  ),
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
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              color: AppColors.bgCard,
              icon: const Icon(Icons.more_vert,
                  color: AppColors.textMuted, size: 20),
              onSelected: (val) async {
                if (val == 'delete') {
                  await ref.read(accountRepositoryProvider).delete(account.id);
                  ref.invalidate(accountsProvider);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete',
                      style: TextStyle(color: AppColors.expense)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddAccountSheet extends StatefulWidget {
  final void Function(String name, String icon, int colorVal, double balance)
      onSave;

  const _AddAccountSheet({required this.onSave});

  @override
  State<_AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends State<_AddAccountSheet> {
  final _nameCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController(text: '0');
  String _icon = 'bank';
  int _colorVal = 0xFF2196F3;

  final _icons = ['card', 'cash', 'savings', 'bank', 'wallet'];
  final _colors = [
    0xFF2196F3,
    0xFF4CAF50,
    0xFFFF9800,
    0xFFE91E63,
    0xFF9C27B0,
    0xFF795548,
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add Account',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(labelText: 'Account Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _balanceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
                labelText: 'Initial Balance', prefixText: '₹ '),
          ),
          const SizedBox(height: 12),
          const Text('Icon',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: _icons
                .map((ic) => GestureDetector(
                      onTap: () => setState(() => _icon = ic),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _icon == ic
                              ? AppColors.gold.withAlpha(51)
                              : AppColors.bgElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _icon == ic
                                ? AppColors.gold
                                : const Color(0xFF3A3A3A),
                          ),
                        ),
                        child: Icon(CategoryIcons.accountIcon(ic),
                            color: _icon == ic
                                ? AppColors.gold
                                : AppColors.textMuted,
                            size: 22),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          const Text('Color',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: _colors
                .map((c) => GestureDetector(
                      onTap: () => setState(() => _colorVal = c),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Color(c),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _colorVal == c
                                ? Colors.white
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_nameCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter an account name')),
                  );
                  return;
                }
                Navigator.pop(context);
                widget.onSave(
                  _nameCtrl.text,
                  _icon,
                  _colorVal,
                  double.tryParse(_balanceCtrl.text) ?? 0,
                );
              },
              child: const Text('ADD ACCOUNT'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
