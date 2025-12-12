class BudgetTransaction {
  final int? id;
  final String title;
  final double amount;
  final String type; // 'income' or 'expense'
  final String category; // NEW: e.g. Food, Salary, Transport
  final DateTime date;

  BudgetTransaction({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type,
      'category': category,
      'date': date.toIso8601String(),
    };
  }

  factory BudgetTransaction.fromMap(Map<String, dynamic> m) {
    return BudgetTransaction(
      id: m['id'] as int?,
      title: m['title'],
      amount: (m['amount'] as num).toDouble(),
      type: m['type'],
      category: m['category'] ?? 'Uncategorized',
      date: DateTime.parse(m['date']),
    );
  }
}
