// lib/features/transactions/application/transactions_state.dart
import 'package:equatable/equatable.dart';
import '../domain/transaction.dart';

enum TransactionsStatus { initial, loading, loaded, error }

class TransactionsState extends Equatable {
  final TransactionsStatus status;
  final List<Transaction> items;
  final String? error;
  final bool submitting;

  const TransactionsState({
    required this.status,
    required this.items,
    this.error,
    this.submitting = false,
  });

  factory TransactionsState.initial() => const TransactionsState(
        status: TransactionsStatus.initial,
        items: [],
        submitting: false,
      );

  TransactionsState copyWith({
    TransactionsStatus? status,
    List<Transaction>? items,
    String? error,
    bool? submitting,
  }) {
    return TransactionsState(
      status: status ?? this.status,
      items: items ?? this.items,
      error: error,
      submitting: submitting ?? this.submitting,
    );
  }

  @override
  List<Object?> get props => [status, items, error, submitting];
}
