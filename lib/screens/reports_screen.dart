import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../providers/category_provider.dart';
import '../providers/budget_provider.dart';
import '../utils/theme.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedPeriod = 'monthly';
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final incomeProvider = Provider.of<IncomeProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final budgetProvider = Provider.of<BudgetProvider>(context);

    // Filter data by period
    DateTime start, end;
    if (_selectedPeriod == 'daily') {
      start =
          DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      end = start;
    } else if (_selectedPeriod == 'weekly') {
      start = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
      end = start.add(const Duration(days: 6));
    } else {
      // monthly
      start = DateTime(_selectedDate.year, _selectedDate.month, 1);
      end = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    }

    final expenses = expenseProvider.getExpensesByDateRange(start, end);
    final incomes = incomeProvider.getIncomesByDateRange(start, end);
    final totalExpense = expenseProvider.getTotalAmount(expenses);
    final totalIncome = incomeProvider.getTotalAmount(incomes);
    final balance = totalIncome - totalExpense;

    // Grouped by category
    final Map<String, double> expenseByCategory = {};
    for (final expense in expenses) {
      expenseByCategory[expense.categoryId] =
          (expenseByCategory[expense.categoryId] ?? 0) + expense.amount;
    }
    final Map<String, double> incomeByCategory = {};
    for (final income in incomes) {
      incomeByCategory[income.categoryId] =
          (incomeByCategory[income.categoryId] ?? 0) + income.amount;
    }

    // Budget analysis
    final budgetStats = budgetProvider.getBudgetStatistics();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PeriodSelector(
                selectedPeriod: _selectedPeriod,
                selectedDate: _selectedDate,
                onPeriodChanged: (period) =>
                    setState(() => _selectedPeriod = period),
                onDateChanged: (date) => setState(() => _selectedDate = date),
              ),
              const SizedBox(height: AppSizes.paddingLarge),
              _SummaryCard(
                totalIncome: totalIncome,
                totalExpense: totalExpense,
                balance: balance,
                periodLabel: _periodLabel(_selectedPeriod, _selectedDate),
              ),
              const SizedBox(height: AppSizes.paddingLarge),
              _CategoryAnalysis(
                expenseByCategory: expenseByCategory,
                incomeByCategory: incomeByCategory,
                categoryProvider: categoryProvider,
              ),
              const SizedBox(height: AppSizes.paddingLarge),
              _BudgetAnalysis(budgetStats: budgetStats),
              const SizedBox(height: AppSizes.paddingLarge),
              _ExpenseIncomeChart(
                expenses: expenses,
                incomes: incomes,
                start: start,
                end: end,
                period: _selectedPeriod,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _periodLabel(String period, DateTime date) {
    if (period == 'daily') {
      return DateFormat('dd MMM yyyy').format(date);
    } else if (period == 'weekly') {
      final start = date.subtract(Duration(days: date.weekday - 1));
      final end = start.add(const Duration(days: 6));
      return '${DateFormat('dd MMM').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}';
    } else {
      return DateFormat('MMMM yyyy').format(date);
    }
  }
}

class _PeriodSelector extends StatelessWidget {
  final String selectedPeriod;
  final DateTime selectedDate;
  final ValueChanged<String> onPeriodChanged;
  final ValueChanged<DateTime> onDateChanged;

  const _PeriodSelector({
    required this.selectedPeriod,
    required this.selectedDate,
    required this.onPeriodChanged,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DropdownButton<String>(
          value: selectedPeriod,
          items: const [
            DropdownMenuItem(value: 'daily', child: Text('Harian')),
            DropdownMenuItem(value: 'weekly', child: Text('Mingguan')),
            DropdownMenuItem(value: 'monthly', child: Text('Bulanan')),
          ],
          onChanged: (val) {
            if (val != null) onPeriodChanged(val);
          },
        ),
        const SizedBox(width: AppSizes.paddingMedium),
        OutlinedButton.icon(
          icon: const Icon(Icons.calendar_today),
          label: Text(_dateLabel(selectedPeriod, selectedDate)),
          onPressed: () async {
            DateTime? picked;
            if (selectedPeriod == 'monthly') {
              picked = await showMonthPicker(
                  context: context, initialDate: selectedDate);
            } else {
              picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
            }
            if (picked != null) onDateChanged(picked);
          },
        ),
      ],
    );
  }

  String _dateLabel(String period, DateTime date) {
    if (period == 'daily') {
      return DateFormat('dd MMM yyyy').format(date);
    } else if (period == 'weekly') {
      final start = date.subtract(Duration(days: date.weekday - 1));
      final end = start.add(const Duration(days: 6));
      return '${DateFormat('dd MMM').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}';
    } else {
      return DateFormat('MMMM yyyy').format(date);
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final String periodLabel;

  const _SummaryCard({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(periodLabel,
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSizes.paddingMedium),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SummaryItem(
                  label: 'Pemasukan',
                  value: totalIncome,
                  color: AppColors.income,
                ),
                _SummaryItem(
                  label: 'Pengeluaran',
                  value: totalExpense,
                  color: AppColors.expense,
                ),
                _SummaryItem(
                  label: 'Saldo',
                  value: balance,
                  color: AppColors.budget,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _SummaryItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(
          NumberFormat.currency(locale: 'id', symbol: 'Rp').format(value),
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _CategoryAnalysis extends StatelessWidget {
  final Map<String, double> expenseByCategory;
  final Map<String, double> incomeByCategory;
  final CategoryProvider categoryProvider;

  const _CategoryAnalysis({
    required this.expenseByCategory,
    required this.incomeByCategory,
    required this.categoryProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Analisis Kategori',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSizes.paddingMedium),
            if (expenseByCategory.isEmpty && incomeByCategory.isEmpty)
              const Text('Tidak ada data'),
            if (expenseByCategory.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pengeluaran per Kategori:'),
                  ...expenseByCategory.entries.map((e) {
                    final cat = categoryProvider.getCategoryById(e.key);
                    return ListTile(
                      leading: Icon(Icons.label, color: AppColors.expense),
                      title: Text(cat?.name ?? '-'),
                      trailing: Text(
                          NumberFormat.currency(locale: 'id', symbol: 'Rp')
                              .format(e.value)),
                    );
                  }).toList(),
                ],
              ),
            if (incomeByCategory.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pemasukan per Kategori:'),
                  ...incomeByCategory.entries.map((e) {
                    final cat = categoryProvider.getCategoryById(e.key);
                    return ListTile(
                      leading: Icon(Icons.label, color: AppColors.income),
                      title: Text(cat?.name ?? '-'),
                      trailing: Text(
                          NumberFormat.currency(locale: 'id', symbol: 'Rp')
                              .format(e.value)),
                    );
                  }).toList(),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _BudgetAnalysis extends StatelessWidget {
  final Map<String, dynamic> budgetStats;
  const _BudgetAnalysis({required this.budgetStats});

  @override
  Widget build(BuildContext context) {
    if (budgetStats.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: const Text('Tidak ada data budget aktif'),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Analisis Budget',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSizes.paddingMedium),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _BudgetStat(
                    label: 'Total Budget',
                    value: budgetStats['totalBudgetAmount'] ?? 0,
                    color: AppColors.budget),
                _BudgetStat(
                    label: 'Total Spent',
                    value: budgetStats['totalSpent'] ?? 0,
                    color: AppColors.expense),
                _BudgetStat(
                    label: 'Sisa',
                    value: budgetStats['totalRemaining'] ?? 0,
                    color: AppColors.success),
              ],
            ),
            const SizedBox(height: AppSizes.paddingMedium),
            LinearProgressIndicator(
              value: ((budgetStats['averageUsagePercentage'] ?? 0) / 100)
                  .clamp(0.0, 1.0),
              backgroundColor: AppColors.budget.withOpacity(0.2),
              color: AppColors.expense,
            ),
            const SizedBox(height: 8),
            Text(
                'Rata-rata penggunaan: ${budgetStats['averageUsagePercentage']?.toStringAsFixed(1) ?? '0'}%'),
            const SizedBox(height: 8),
            Row(
              children: [
                _BudgetChip(
                    label: 'On Track',
                    count: budgetStats['budgetsOnTrack'] ?? 0,
                    color: AppColors.success),
                const SizedBox(width: 8),
                _BudgetChip(
                    label: 'Warning',
                    count: budgetStats['budgetsWarning'] ?? 0,
                    color: AppColors.warning),
                const SizedBox(width: 8),
                _BudgetChip(
                    label: 'Exceeded',
                    count: budgetStats['budgetsExceeded'] ?? 0,
                    color: AppColors.error),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetStat extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _BudgetStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(
          NumberFormat.currency(locale: 'id', symbol: 'Rp').format(value),
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _BudgetChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _BudgetChip(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $count'),
      backgroundColor: color.withOpacity(0.15),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
    );
  }
}

class _ExpenseIncomeChart extends StatelessWidget {
  final List expenses;
  final List incomes;
  final DateTime start;
  final DateTime end;
  final String period;

  const _ExpenseIncomeChart({
    required this.expenses,
    required this.incomes,
    required this.start,
    required this.end,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    // Placeholder for chart, you can use charts_flutter or fl_chart for real chart
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Grafik Pemasukan & Pengeluaran',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSizes.paddingMedium),
            Container(
              height: 180,
              width: double.infinity,
              color: AppColors.budget.withOpacity(0.08),
              child: const Center(
                  child: Text(
                      'Chart Placeholder')), // TODO: Integrate with chart package
            ),
          ],
        ),
      ),
    );
  }
}

// Helper for month picker (you can use a package like flutter_month_picker_dialog)
Future<DateTime?> showMonthPicker(
    {required BuildContext context, required DateTime initialDate}) async {
  // For now, fallback to date picker
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(2000),
    lastDate: DateTime.now(),
    helpText: 'Pilih Bulan',
    fieldLabelText: 'Bulan',
    fieldHintText: 'Bulan/Tahun',
    initialDatePickerMode: DatePickerMode.year,
  );
}
