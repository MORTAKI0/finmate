import 'transaction.dart';

abstract class TransactionsRepository {
  Future<List<Transaction>> getHistory(String holdingId);
  Future<Transaction> addTransaction(Transaction draft);
}
