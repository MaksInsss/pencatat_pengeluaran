import 'category_model.dart';

class TransactionModel {
  final int id;
  final int categoryId;
  final String type;
  final double amount;
  final String? description;
  final DateTime date;
  final CategoryModel? category;

  TransactionModel({
    required this.id,
    required this.categoryId,
    required this.type,
    required this.amount,
    this.description,
    required this.date,
    this.category,
  });

  factory TransactionModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final dateString =
        json['transaction_date']
            .toString()
            .substring(0, 10);

    return TransactionModel(
      id: json['id'],
      categoryId: json['category_id'],
      type: json['type'],
      amount: double.parse(
        json['amount'].toString(),
      ),
      description: json['description'],
      date: DateTime.parse(
        dateString,
      ),
      category: json['category'] != null
          ? CategoryModel.fromJson(
              json['category'],
            )
          : null,
    );
  }
}