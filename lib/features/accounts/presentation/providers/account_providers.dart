// lib/features/accounts/presentation/providers/account_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/account_model.dart';
import '../../data/account_repository.dart';

final accountRepositoryProvider = Provider<AccountRepository>((_) => AccountRepository());

final accountsProvider = FutureProvider<List<Account>>(
  (ref) => ref.read(accountRepositoryProvider).getAll());
