// lib/add_transaction_page.dart
import 'package:expense_planner/constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db_helper.dart';
import 'models.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});
  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  String title = '', amount = '', type = 'expense', category = '', notes = '';
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => selectedDate = date);
  }

  void submit() async {
    if (!_formKey.currentState!.validate()) return;

    final transaction = BudgetTransaction(
      title: title,
      amount: double.parse(amount),
      type: type,
      category: category.isEmpty
          ? (type == 'income' ? "Salary" : "Food")
          : category,
      date: selectedDate,
    );

    await DBHelper.instance.insertTransaction(transaction);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Transaction"),
        bottom: TabBar(
          controller: _tabController,
          onTap: (i) => type = i == 0 ? 'expense' : 'income',
          tabs: const [
            Tab(icon: Icon(Icons.remove_circle_outline), text: "Expense"),
            Tab(icon: Icon(Icons.add_circle_outline), text: "Income"),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Title *",
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => title = v,
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Amount (GHS) *",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => amount = v,
                validator: (v) =>
                    double.tryParse(v!) == null ? "Invalid amount" : null,
              ),
              const SizedBox(height: 16),
              // Inside your Form, replace the old Category TextFormField with:
              const SizedBox(height: 16),
              Text("Category", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: category.isEmpty
                    ? (type == 'income'
                          ? incomeCategories[0]
                          : expenseCategories[0])
                    : category,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                ),
                items: (type == 'income' ? incomeCategories : expenseCategories)
                    .map(
                      (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => category = val!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Notes",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (v) => notes = v,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  "Date: ${DateFormat('dd MMMM yyyy').format(selectedDate)}",
                ),
                trailing: const Icon(Icons.edit_calendar),
                onTap: pickDate,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Save Transaction",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
