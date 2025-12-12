// lib/main.dart
import 'package:expense_planner/filter_chips.dart';
import 'package:expense_planner/monthly_pie_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db_helper.dart';
import 'models.dart';
import 'add_transaction_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BudgetApp());
}

class BudgetApp extends StatelessWidget {
  const BudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Budget Planner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

// ==========================
// HomePage
// ==========================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<BudgetTransaction> transactions = [];
  bool loading = true;
  FilterType filter = FilterType.all;

  @override
  void initState() {
    super.initState();
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    setState(() => loading = true);
    transactions = await DBHelper.instance.getAllTransactions();
    setState(() => loading = false);
  }

  double get totalIncome => transactions
      .where((t) => t.type == 'income')
      .fold(0.0, (a, b) => a + b.amount);

  double get totalExpense => transactions
      .where((t) => t.type == 'expense')
      .fold(0.0, (a, b) => a + b.amount);

  double get balance => totalIncome - totalExpense;

  List<BudgetTransaction> get filtered {
    switch (filter) {
      case FilterType.income:
        return transactions.where((t) => t.type == 'income').toList();
      case FilterType.expense:
        return transactions.where((t) => t.type == 'expense').toList();
      case FilterType.all:
      default:
        return transactions;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Budget Planner"), centerTitle: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTransactionPage()),
        ).then((_) => loadTransactions()),
        icon: const Icon(Icons.add),
        label: const Text("Add"),
      ),
      body: RefreshIndicator(
        onRefresh: loadTransactions,
        child: SafeArea(
          child: Column(
            children: [
              // Scrollable top card
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 16),
                child: SummaryCard(
                  balance: balance,
                  totalIncome: totalIncome,
                  totalExpense: totalExpense,
                  transactions: transactions,
                ),
              ),

              // Filter chips
              FilterChips(
                current: filter,
                onChange: (f) => setState(() => filter = f),
              ),

              const SizedBox(height: 8),

              // Transaction list in Expanded so it scrolls properly
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                    ? const Center(
                        child: Text(
                          "No transactions yet\nTap + to add one",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final t = filtered[i];
                          return Dismissible(
                            key: ValueKey(t.id),
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            onDismissed: (_) => DBHelper.instance
                                .deleteTransaction(t.id!)
                                .then((_) => loadTransactions()),
                            child: Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: t.type == 'income'
                                      ? Colors.green[100]
                                      : Colors.red[100],
                                  child: Icon(
                                    t.type == 'income'
                                        ? Icons.trending_up
                                        : Icons.trending_down,
                                    color: t.type == 'income'
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                                title: Text(
                                  t.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  DateFormat('dd MMM yyyy').format(t.date),
                                ),
                                trailing: Text(
                                  "GHS ${t.amount.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: t.type == 'income'
                                        ? Colors.green[700]
                                        : Colors.red[700],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================
// SummaryCard Widget
// ==========================
class SummaryCard extends StatelessWidget {
  final double balance;
  final double totalIncome;
  final double totalExpense;
  final List<BudgetTransaction> transactions;

  const SummaryCard({
    super.key,
    required this.balance,
    required this.totalIncome,
    required this.totalExpense,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize:
              MainAxisSize.min, // <-- ensures column height fits content
          children: [
            Text(
              "Current Balance",
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              "GHS ${balance.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: balance >= 0 ? Colors.green[700] : Colors.red[700],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _SummaryColumn(
                  icon: Icons.trending_up,
                  color: Colors.green,
                  amount: totalIncome,
                  label: "Income",
                ),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                _SummaryColumn(
                  icon: Icons.trending_down,
                  color: Colors.red,
                  amount: totalExpense,
                  label: "Expense",
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              "Breakdown",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: MonthlyPieChart(transactions: transactions),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper for income/expense summary
class _SummaryColumn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double amount;
  final String label;

  const _SummaryColumn({
    required this.icon,
    required this.color,
    required this.amount,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color),
        Text(
          "GHS ${amount.toStringAsFixed(0)}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(label),
      ],
    );
  }
}

// ==========================
// TransactionList Widget
// ==========================
class TransactionList extends StatelessWidget {
  final List<BudgetTransaction> transactions;
  final Function(int) onDelete;

  const TransactionList({
    super.key,
    required this.transactions,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (_, i) {
        final t = transactions[i];
        return Dismissible(
          key: ValueKey(t.id),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => DBHelper.instance
              .deleteTransaction(t.id!)
              .then((_) => onDelete(t.id!)),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: t.type == 'income'
                    ? Colors.green[100]
                    : Colors.red[100],
                child: Icon(
                  t.type == 'income' ? Icons.trending_up : Icons.trending_down,
                  color: t.type == 'income' ? Colors.green : Colors.red,
                ),
              ),
              title: Text(
                t.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(DateFormat('dd MMM yyyy').format(t.date)),
              trailing: Text(
                "GHS ${t.amount.toStringAsFixed(2)}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: t.type == 'income'
                      ? Colors.green[700]
                      : Colors.red[700],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
