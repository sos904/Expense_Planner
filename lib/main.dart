import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db_helper.dart';
import 'models.dart';
import 'add_transaction_page.dart';
import 'filter_chips.dart';
import 'monthly_pie_chart.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

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
      default:
        return transactions;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Budget Planner"), centerTitle: true),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTransactionPage()),
        ).then((_) => loadTransactions()),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: loadTransactions,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      SummaryCard(
                        balance: balance,
                        totalIncome: totalIncome,
                        totalExpense: totalExpense,
                        transactions: transactions,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: FilterChips(
                          current: filter,
                          onChange: (f) => setState(() => filter = f),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (loading)
                        const Center(child: CircularProgressIndicator())
                      else if (filtered.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            "No transactions yet.\nTap + to add one",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(12),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
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
                              child: TransactionTile(transaction: t),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("Balance", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              "GHS ${balance.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: balance >= 0 ? Colors.green[700] : Colors.red[700],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _SummaryItem(
                  icon: Icons.trending_up,
                  color: Colors.green,
                  label: "Income",
                  amount: totalIncome,
                ),
                _SummaryItem(
                  icon: Icons.trending_down,
                  color: Colors.red,
                  label: "Expense",
                  amount: totalExpense,
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 295, // reduced height to avoid overflow
              child: MonthlyPieChart(transactions: transactions),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final double amount;

  const _SummaryItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(
          "GHS ${amount.toStringAsFixed(0)}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(label),
      ],
    );
  }
}

class TransactionTile extends StatelessWidget {
  final BudgetTransaction transaction;
  const TransactionTile({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: transaction.type == 'income'
              ? Colors.green[100]
              : Colors.red[100],
          child: Icon(
            transaction.type == 'income'
                ? Icons.trending_up
                : Icons.trending_down,
            color: transaction.type == 'income' ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          transaction.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(DateFormat('dd MMM yyyy').format(transaction.date)),
        trailing: Text(
          "GHS ${transaction.amount.toStringAsFixed(2)}",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: transaction.type == 'income'
                ? Colors.green[700]
                : Colors.red[700],
          ),
        ),
      ),
    );
  }
}
