class TransactionModel {
  String type;
  String account;
  String category;
  double amount;
  DateTime dateTime;

  TransactionModel({
    required this.type,
    required this.account,
    required this.category,
    required this.amount,
    required this.dateTime,
  });
}