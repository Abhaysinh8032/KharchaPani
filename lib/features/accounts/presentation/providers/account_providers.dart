// lib/features/accounts/presentation/providers/account_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/account_model.dart';
import '../../data/account_repository.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository();
});

final accountsProvider = FutureProvider<List<Account>>((ref) async {
  return ref.read(accountRepositoryProvider).getAll();
});

final overallSummaryProvider = Provider<({double expense, double income, double balance})>((ref) {
  final accounts = ref.watch(accountsProvider);
  return accounts.when(
    data: (list) {
      double balance = list.fold(0, (s, a) => s + a.balance);
      return (expense: 0.0, income: 0.0, balance: balance);
    },
    loading: () => (expense: 0.0, income: 0.0, balance: 0.0),
    error: (_, __) => (expense: 0.0, income: 0.0, balance: 0.0),
  );
});
