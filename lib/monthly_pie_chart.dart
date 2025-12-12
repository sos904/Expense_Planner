import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models.dart';

class MonthlyPieChart extends StatefulWidget {
  final List<BudgetTransaction> transactions;
  const MonthlyPieChart({super.key, required this.transactions});

  @override
  State<MonthlyPieChart> createState() => _MonthlyPieChartState();
}

class _MonthlyPieChartState extends State<MonthlyPieChart> {
  DateTime selectedDate = DateTime.now();
  bool showByCategory = true; // toggle between Type vs Category

  List<BudgetTransaction> get filtered => widget.transactions
      .where(
        (t) =>
            t.date.year == selectedDate.year &&
            t.date.month == selectedDate.month,
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    final incomeTotal = filtered
        .where((t) => t.type == 'income')
        .fold(0.0, (a, b) => a + b.amount);
    final expenseTotal = filtered
        .where((t) => t.type == 'expense')
        .fold(0.0, (a, b) => a + b.amount);
    final total = incomeTotal + expenseTotal;

    return Column(
      children: [
        // Month + Year Picker
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${DateFormat('MMMM yyyy').format(selectedDate)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialEntryMode: DatePickerEntryMode.calendarOnly,
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: Colors.indigo,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (date != null) setState(() => selectedDate = date);
                },
              ),
            ],
          ),
        ),

        // Toggle: Type vs Category
        ToggleButtons(
          isSelected: [showByCategory, !showByCategory],
          onPressed: (i) => setState(() => showByCategory = i == 0),
          borderRadius: BorderRadius.circular(30),
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text("Category"),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text("Type"),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Pie Chart
        SizedBox(
          height: 180,
          child: total == 0
              ? Center(
                  child: Text(
                    "No data in ${DateFormat('MMM yyyy').format(selectedDate)}",
                  ),
                )
              : PieChart(
                  PieChartData(
                    sections: showByCategory
                        ? _buildCategorySections(filtered)
                        : _buildTypeSections(incomeTotal, expenseTotal, total),
                    centerSpaceRadius: 30,
                    sectionsSpace: 3,
                  ),
                ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildTypeSections(
    double income,
    double expense,
    double total,
  ) {
    return [
      PieChartSectionData(
        color: Colors.green,
        value: income,
        title: "${(income / total * 100).toStringAsFixed(0)}%",
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: Colors.red,
        value: expense,
        title: "${(expense / total * 100).toStringAsFixed(0)}%",
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }

  List<PieChartSectionData> _buildCategorySections(
    List<BudgetTransaction> items,
  ) {
    final Map<String, double> catMap = {};
    for (var t in items) {
      catMap[t.category] = (catMap[t.category] ?? 0) + t.amount;
    }

    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
      Colors.deepOrange,
    ];

    return catMap.entries.map((e) {
      final percent = (e.value / items.fold(0.0, (a, b) => a + b.amount) * 100);
      return PieChartSectionData(
        color: colors[catMap.keys.toList().indexOf(e.key) % colors.length],
        value: e.value,
        title: "${percent.toStringAsFixed(0)}%",
        radius: 45,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
}
