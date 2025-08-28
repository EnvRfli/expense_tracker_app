import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../utils/theme.dart';
import '../widgets/dashboard_widgets.dart'; // Add this import for showFilteredTransactionsSheet
import '../l10n/localization_extension.dart'; // Add localization import
import 'package:fl_chart/fl_chart.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

// --- helper classes for charts ---
class _TimeSeriesPoint {
  final DateTime date;
  final double income;
  final double expense;

  _TimeSeriesPoint(
      {required this.date, required this.income, required this.expense});
}

class _TimeseriesChart extends StatelessWidget {
  final List<_TimeSeriesPoint> data;

  const _TimeseriesChart({required this.data, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(child: Text(context.tr('no_data')));
    }

    // Map data points to FlSpot using index as x value
    final spotsIncome = <FlSpot>[];
    final spotsExpense = <FlSpot>[];
    for (var i = 0; i < data.length; i++) {
      spotsIncome.add(FlSpot(i.toDouble(), data[i].income));
      spotsExpense.add(FlSpot(i.toDouble(), data[i].expense));
    }

    final interval =
        (data.length / 6).ceilToDouble().clamp(1.0, data.length.toDouble());

    // Hitung max value untuk menentukan interval yang tepat
    final maxValue = data
        .map((e) => e.income)
        .followedBy(data.map((e) => e.expense))
        .reduce((a, b) => a > b ? a : b);

    // Tentukan interval horizontal yang lebih baik untuk menghindari tumpang tindih
    double horizontalInterval;
    if (maxValue <= 0) {
      horizontalInterval = 1;
    } else if (maxValue <= 50000) {
      horizontalInterval = 10000;
    } else if (maxValue <= 100000) {
      horizontalInterval = 20000;
    } else if (maxValue <= 500000) {
      horizontalInterval = 100000;
    } else {
      horizontalInterval = maxValue / 4;
    }

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(enabled: true),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: horizontalInterval,
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.length)
                  return const SizedBox.shrink();
                final d = data[idx].date;
                final label = '${d.day}/${d.month}';
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child:
                      Text(label, style: Theme.of(context).textTheme.bodySmall),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: horizontalInterval,
              getTitlesWidget: (value, meta) {
                String formatValue(double val) {
                  if (val >= 1000000) {
                    return '${(val / 1000000).toStringAsFixed(1)}M';
                  } else if (val >= 1000) {
                    return '${(val / 1000).toStringAsFixed(0)}K';
                  } else {
                    return val.toStringAsFixed(0);
                  }
                }

                return Text(
                  formatValue(value),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                      ),
                  textAlign: TextAlign.right,
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        lineBarsData: [
          LineChartBarData(
            spots: spotsExpense,
            isCurved: true,
            color: AppColors.expense,
            barWidth: 2,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
                show: true, color: AppColors.expense.withOpacity(0.08)),
          ),
          LineChartBarData(
            spots: spotsIncome,
            isCurved: true,
            color: AppColors.income,
            barWidth: 2,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
                show: true, color: AppColors.income.withOpacity(0.08)),
          ),
        ],
      ),
    );
  }
}

class _CatDatum {
  final String name;
  final double amount;
  final Color color;
  _CatDatum({required this.name, required this.amount, required this.color});
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTimeRange _range = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 29)),
    end: DateTime.now(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('reports_title')),
        automaticallyImplyLeading: false,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            onPressed: () async {
              await _exportData();
            },
            icon: const Icon(Icons.download),
            tooltip: context.tr('export_csv'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<ExpenseProvider>().loadExpenses();
          await context.read<IncomeProvider>().loadIncomes();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          child: Column(
            children: [
              // Filter Range Section
              _buildFilterSection(),
              const SizedBox(height: AppSizes.paddingMedium),
              _buildSummaryCards(),
              const SizedBox(height: AppSizes.paddingMedium),
              _buildTimeSeriesPlaceholder(),
              const SizedBox(height: AppSizes.paddingMedium),
              LayoutBuilder(builder: (context, constraints) {
                // if narrow, stack vertically for breathing room
                if (constraints.maxWidth < 700) {
                  return Column(
                    children: [
                      _buildCategoryBreakdown(),
                      const SizedBox(height: AppSizes.paddingMedium),
                      _buildTopTransactions(),
                    ],
                  );
                }

                // otherwise keep side-by-side
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildCategoryBreakdown()),
                    const SizedBox(width: AppSizes.paddingMedium),
                    Expanded(child: _buildTopTransactions()),
                  ],
                );
              }),
              const SizedBox(height: AppSizes.paddingLarge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('filter_period'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSizes.paddingSmall),
            _buildRangeButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeButton(BuildContext context) {
    final label =
        '${_range.start.day}/${_range.start.month}/${_range.start.year} - ${_range.end.day}/${_range.end.month}/${_range.end.year}';
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingMedium,
            vertical: AppSizes.paddingSmall,
          ),
          side: BorderSide(color: AppTheme.primaryColor),
        ),
        onPressed: () async {
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
            lastDate: DateTime.now(),
            initialDateRange: _range,
          );
          if (picked != null) {
            setState(() => _range = picked);
          }
        },
        icon:
            Icon(Icons.calendar_today, size: 18, color: AppTheme.primaryColor),
        label: Text(
          label,
          style: TextStyle(color: AppTheme.primaryColor),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Consumer3<ExpenseProvider, IncomeProvider, UserSettingsProvider>(
      builder: (context, expenseProvider, incomeProvider, userSettings, child) {
        final expenses =
            expenseProvider.getExpensesByDateRange(_range.start, _range.end);
        final incomes =
            incomeProvider.getIncomesByDateRange(_range.start, _range.end);

        final totalExpense = expenseProvider.getTotalAmount(expenses);
        final totalIncome = incomeProvider.getTotalAmount(incomes);
        final net = totalIncome - totalExpense;

        Widget card(String title, String value, Color color,
            {VoidCallback? onTap}) {
          return Card(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: AppSizes.paddingSmall),
                    Text(
                      value,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: color, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            card(context.tr('balance'), userSettings.formatCurrency(net),
                net >= 0 ? AppColors.success : AppColors.error),
            const SizedBox(height: AppSizes.paddingSmall),
            Row(children: [
              Expanded(
                  flex: 1,
                  child: card(
                      context.tr('income'),
                      userSettings.formatCurrency(totalIncome),
                      AppColors.income,
                      onTap: () => showFilteredTransactionsSheet(
                            context,
                            isIncome: true,
                            dateRange: _range,
                          ))),
              const SizedBox(width: AppSizes.paddingSmall),
              Expanded(
                  flex: 1,
                  child: card(
                      context.tr('expense'),
                      userSettings.formatCurrency(totalExpense),
                      AppColors.expense,
                      onTap: () => showFilteredTransactionsSheet(
                            context,
                            isIncome: false,
                            dateRange: _range,
                          ))),
            ]),
          ],
        );
      },
    );
  }

  Widget _buildTimeSeriesPlaceholder() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('trend') + ' ${_rangeLabel()}',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSizes.paddingSmall),
            SizedBox(
              height: 200,
              child: Consumer2<ExpenseProvider, IncomeProvider>(
                builder: (context, expenseProvider, incomeProvider, child) {
                  final expenses = expenseProvider.getExpensesByDateRange(
                      _range.start, _range.end);
                  final incomes = incomeProvider.getIncomesByDateRange(
                      _range.start, _range.end);

                  // aggregate per day
                  final map = <DateTime, Map<String, double>>{};
                  DateTime cur = _range.start;
                  while (!cur.isAfter(_range.end)) {
                    map[DateTime(cur.year, cur.month, cur.day)] = {
                      'expense': 0.0,
                      'income': 0.0
                    };
                    cur = cur.add(const Duration(days: 1));
                  }

                  for (final e in expenses) {
                    final d = DateTime(e.date.year, e.date.month, e.date.day);
                    map[d] = map[d] ?? {'expense': 0.0, 'income': 0.0};
                    map[d]!['expense'] = (map[d]!['expense'] ?? 0) + e.amount;
                  }

                  for (final i in incomes) {
                    final d = DateTime(i.date.year, i.date.month, i.date.day);
                    map[d] = map[d] ?? {'expense': 0.0, 'income': 0.0};
                    map[d]!['income'] = (map[d]!['income'] ?? 0) + i.amount;
                  }

                  final days = map.keys.toList()..sort();
                  final data = days
                      .map((d) => _TimeSeriesPoint(
                          date: d,
                          income: map[d]!['income'] ?? 0.0,
                          expense: map[d]!['expense'] ?? 0.0))
                      .toList();

                  return _TimeseriesChart(data: data);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _rangeLabel() {
    final diff = _range.end.difference(_range.start).inDays;
    if (diff <= 1) return context.tr('daily');
    if (diff <= 31) return context.tr('monthly');
    return context.tr('period');
  }

  Widget _buildCategoryBreakdown() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Consumer2<ExpenseProvider, CategoryProvider>(
          builder: (context, expenseProvider, categoryProvider, child) {
            final expenses = expenseProvider.getExpensesByDateRange(
                _range.start, _range.end);
            final byCat = <String, double>{};
            for (final e in expenses) {
              byCat[e.categoryId] = (byCat[e.categoryId] ?? 0) + e.amount;
            }

            final entries = byCat.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            if (entries.isEmpty) {
              return SizedBox(
                height: 120,
                child: Center(child: Text(context.tr('no_expenses_in_period'))),
              );
            }

            // Prepare pie data (top 6)
            final topEntries = entries.take(6).toList();
            final pieData = List.generate(topEntries.length, (i) {
              final cat = categoryProvider.getCategoryById(topEntries[i].key);
              return _CatDatum(
                name: cat?.name ?? context.tr('others'),
                amount: topEntries[i].value,
                color: AppColors.getCategoryColor(i),
              );
            });
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('category_breakdown'),
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: AppSizes.paddingSmall),
                SizedBox(
                  height: 140,
                  child: PieChart(
                    PieChartData(
                      sections: pieData
                          .asMap()
                          .entries
                          .map((e) => PieChartSectionData(
                                value: e.value.amount,
                                color: e.value.color,
                                title: '',
                                radius: 40,
                              ))
                          .toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 20,
                      pieTouchData: PieTouchData(enabled: true),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.paddingSmall),
                ...List.generate(entries.length.clamp(0, 6), (i) {
                  final cat = categoryProvider.getCategoryById(entries[i].key);
                  final name = context.tr(cat?.name ?? 'others');
                  final amount = entries[i].value;
                  final color = AppColors.getCategoryColor(i);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      children: [
                        Container(width: 12, height: 12, color: color),
                        const SizedBox(width: 8),
                        Expanded(child: Text(name)),
                        Text(Provider.of<UserSettingsProvider>(context,
                                listen: false)
                            .formatCurrency(amount)),
                      ],
                    ),
                  );
                }),
                if (entries.length > 6)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSizes.paddingSmall),
                    child: Text(context.tr('more_categories',
                        params: {'count': '${entries.length - 6}'})),
                  )
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopTransactions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Consumer3<ExpenseProvider, IncomeProvider, UserSettingsProvider>(
          builder:
              (context, expenseProvider, incomeProvider, userSettings, child) {
            final expenses = expenseProvider.getExpensesByDateRange(
                _range.start, _range.end);
            final incomes =
                incomeProvider.getIncomesByDateRange(_range.start, _range.end);
            final all = [
              ...expenses.map((e) => {'type': 'expense', 'data': e}),
              ...incomes.map((i) => {'type': 'income', 'data': i}),
            ];

            all.sort((a, b) {
              final aData = a['data'];
              final bData = b['data'];
              final aAmt = (aData != null)
                  ? ((a['type'] == 'expense'
                      ? (aData as dynamic).amount
                      : (aData as dynamic).amount) as double)
                  : 0.0;
              final bAmt = (bData != null)
                  ? ((b['type'] == 'expense'
                      ? (bData as dynamic).amount
                      : (bData as dynamic).amount) as double)
                  : 0.0;
              return bAmt.compareTo(aAmt);
            });

            final top = all.take(6).toList();

            if (top.isEmpty) {
              return SizedBox(
                height: 120,
                child: Center(
                    child: Text(context.tr('no_transactions_in_period'))),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('top_transactions'),
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: AppSizes.paddingSmall),
                ...top.map((t) {
                  final isExpense = t['type'] == 'expense';
                  final raw = t['data'];
                  if (raw == null) return const SizedBox.shrink();

                  if (isExpense) {
                    final data = raw as dynamic; // ExpenseModel
                    final amt = data.amount as double;
                    final desc = (data.description as String?) ?? '';
                    final date = data.date as DateTime;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title:
                          Text(desc.isEmpty ? context.tr('top_expense') : desc),
                      trailing: Text(
                        '-${userSettings.formatCurrency(amt)}',
                        style: const TextStyle(color: AppColors.expense),
                      ),
                      subtitle: Text('${date.day}/${date.month}/${date.year}'),
                    );
                  } else {
                    final data = raw as dynamic; // IncomeModel
                    final amt = data.amount as double;
                    final desc = (data.description as String?) ?? '';
                    final date = data.date as DateTime;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title:
                          Text(desc.isEmpty ? context.tr('top_income') : desc),
                      trailing: Text(
                        '+${userSettings.formatCurrency(amt)}',
                        style: const TextStyle(color: AppColors.income),
                      ),
                      subtitle: Text('${date.day}/${date.month}/${date.year}'),
                    );
                  }
                })
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      // Show export confirmation dialog first
      final shouldExport = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.tr('export_data_confirmation')),
          content: Text(context.tr('export_data_message')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.tr('cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Export'),
            ),
          ],
        ),
      );

      // If user cancelled, return early
      if (shouldExport != true) return;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(context.tr('exporting_data')),
            ],
          ),
        ),
      );

      final userSettings =
          Provider.of<UserSettingsProvider>(context, listen: false);
      final exportedFiles = await userSettings.exportDataToDownloads();

      Navigator.pop(context); // Close loading dialog

      if (exportedFiles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('no_data_to_export')),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

      // Show success dialog with file locations
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('success_data_exported'),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr('success_data_exported') + ' :'),
              const SizedBox(height: 12),
              ...exportedFiles.entries.map((entry) {
                // Extract directory path from full file path
                final filePath = entry.value;
                final fileName = filePath.split('/').last;
                final dirPath =
                    filePath.substring(0, filePath.lastIndexOf('/'));

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• $fileName',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        '  Path: $dirPath',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.tr('csv_file_can_be_opened'),
                        style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr('close')),
            ),
          ],
        ),
      );
    } catch (e) {
      // Close loading dialog if still open
      Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(context.tr('error_when_exporting') + ' : ${e.toString()}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
