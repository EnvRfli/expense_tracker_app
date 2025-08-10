import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../utils/theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: actions,
    );
  }
}

class BalanceSummaryCard extends StatelessWidget {
  const BalanceSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<ExpenseProvider, IncomeProvider, UserSettingsProvider>(
      builder: (context, expenseProvider, incomeProvider, userSettings, child) {
        final currentMonthExpenses = expenseProvider.getCurrentMonthTotal();
        final currentMonthIncomes = incomeProvider.getCurrentMonthTotal();
        final balance = currentMonthIncomes - currentMonthExpenses;

        return Card(
          elevation: 4,
          child: Container(
            padding: const EdgeInsets.all(AppSizes.paddingLarge),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saldo Bulan Ini',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: AppSizes.paddingSmall),
                Text(
                  userSettings.formatCurrency(balance),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSizes.paddingLarge),
                Row(
                  children: [
                    Expanded(
                      child: _buildBalanceItem(
                        context,
                        'Pemasukan',
                        currentMonthIncomes,
                        AppColors.income,
                        Icons.arrow_upward,
                        userSettings,
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingMedium),
                    Expanded(
                      child: _buildBalanceItem(
                        context,
                        'Pengeluaran',
                        currentMonthExpenses,
                        AppColors.expense,
                        Icons.arrow_downward,
                        userSettings,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBalanceItem(
    BuildContext context,
    String label,
    double amount,
    Color color,
    IconData icon,
    UserSettingsProvider userSettings,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: AppSizes.iconSmall),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            userSettings.formatCurrency(amount),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class QuickActionsCard extends StatelessWidget {
  const QuickActionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aksi Cepat',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSizes.paddingMedium),
            Row(
              children: [
                Expanded(
                  child: _buildQuickAction(
                    context,
                    'Tambah Pengeluaran',
                    Icons.remove_circle,
                    AppColors.expense,
                    () => _showAddExpenseDialog(context),
                  ),
                ),
                const SizedBox(width: AppSizes.paddingSmall),
                Expanded(
                  child: _buildQuickAction(
                    context,
                    'Tambah Pemasukan',
                    Icons.add_circle,
                    AppColors.income,
                    () => _showAddIncomeDialog(context),
                  ),
                ),
                const SizedBox(width: AppSizes.paddingSmall),
                Expanded(
                  child: _buildQuickAction(
                    context,
                    'Buat Budget',
                    Icons.pie_chart,
                    AppColors.budget,
                    () => _showAddBudgetDialog(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: AppSizes.iconLarge),
            const SizedBox(height: AppSizes.paddingSmall),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    // Implementation for add expense dialog
  }

  void _showAddIncomeDialog(BuildContext context) {
    // Implementation for add income dialog
  }

  void _showAddBudgetDialog(BuildContext context) {
    // Implementation for add budget dialog
  }
}

class BudgetOverviewCard extends StatelessWidget {
  const BudgetOverviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, budgetProvider, child) {
        final budgetStats = budgetProvider.getBudgetStatistics();
        final activeBudgets = budgetProvider.getCurrentActiveBudgets();

        if (activeBudgets.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              child: Column(
                children: [
                  Icon(
                    Icons.pie_chart_outline,
                    size: AppSizes.iconExtraLarge,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: AppSizes.paddingMedium),
                  Text(
                    'Belum ada budget aktif',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSizes.paddingSmall),
                  Text(
                    'Buat budget untuk memantau pengeluaran Anda',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Budget Overview',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to budget details
                      },
                      child: const Text('Lihat Semua'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                _buildBudgetSummary(context, budgetStats),
                const SizedBox(height: AppSizes.paddingMedium),
                ...activeBudgets
                    .take(3)
                    .map((budget) => _buildBudgetItem(context, budget)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBudgetSummary(BuildContext context, Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              context,
              'Total Budget',
              stats['totalBudgetAmount']?.toStringAsFixed(0) ?? '0',
              AppColors.budget,
            ),
          ),
          Expanded(
            child: _buildSummaryItem(
              context,
              'Terpakai',
              '${stats['averageUsagePercentage']?.toStringAsFixed(0) ?? '0'}%',
              AppColors.warning,
            ),
          ),
          Expanded(
            child: _buildSummaryItem(
              context,
              'Melampaui',
              '${stats['budgetsExceeded'] ?? 0}',
              AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBudgetItem(BuildContext context, budget) {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, child) {
        final category = categoryProvider.getCategoryById(budget.categoryId);

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 40,
                decoration: BoxDecoration(
                  color: _getBudgetStatusColor(budget.status),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: AppSizes.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category?.name ?? 'Unknown',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      '${budget.spent.toStringAsFixed(0)} / ${budget.amount.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                '${budget.usagePercentage.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _getBudgetStatusColor(budget.status),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getBudgetStatusColor(String status) {
    switch (status) {
      case 'exceeded':
        return AppColors.error;
      case 'warning':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }
}

class RecentTransactionsCard extends StatelessWidget {
  const RecentTransactionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaksi Terbaru',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to all transactions
                  },
                  child: const Text('Lihat Semua'),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingMedium),
            Consumer2<ExpenseProvider, IncomeProvider>(
              builder: (context, expenseProvider, incomeProvider, child) {
                final recentExpenses =
                    expenseProvider.expenses.take(3).toList();
                final recentIncomes = incomeProvider.incomes.take(2).toList();

                // Combine and sort by date
                final List<dynamic> recentTransactions = [
                  ...recentExpenses.map((e) => {'type': 'expense', 'data': e}),
                  ...recentIncomes.map((i) => {'type': 'income', 'data': i}),
                ];

                recentTransactions
                    .sort((a, b) => b['data'].date.compareTo(a['data'].date));

                if (recentTransactions.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: AppSizes.iconExtraLarge,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: AppSizes.paddingMedium),
                        Text(
                          'Belum ada transaksi',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: recentTransactions.take(5).map((transaction) {
                    return _buildTransactionItem(context, transaction);
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(
      BuildContext context, Map<String, dynamic> transaction) {
    final isExpense = transaction['type'] == 'expense';
    final data = transaction['data'];

    return Consumer2<CategoryProvider, UserSettingsProvider>(
      builder: (context, categoryProvider, userSettings, child) {
        final category = categoryProvider.getCategoryById(data.categoryId);

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (isExpense ? AppColors.expense : AppColors.income)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
                child: Icon(
                  isExpense ? Icons.remove : Icons.add,
                  color: isExpense ? AppColors.expense : AppColors.income,
                ),
              ),
              const SizedBox(width: AppSizes.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      '${category?.name ?? 'Unknown'} • ${DateFormat('dd MMM').format(data.date)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                '${isExpense ? '-' : '+'}${userSettings.formatCurrency(data.amount)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isExpense ? AppColors.expense : AppColors.income,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SpendingByCategoryCard extends StatelessWidget {
  const SpendingByCategoryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pengeluaran per Kategori',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSizes.paddingMedium),
            Consumer3<ExpenseProvider, CategoryProvider, UserSettingsProvider>(
              builder: (context, expenseProvider, categoryProvider,
                  userSettings, child) {
                final currentMonthExpenses =
                    expenseProvider.getCurrentMonthExpenses();
                final groupedExpenses =
                    expenseProvider.getExpensesGroupedByCategory();

                if (currentMonthExpenses.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.pie_chart_outline,
                          size: AppSizes.iconExtraLarge,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: AppSizes.paddingMedium),
                        Text(
                          'Belum ada pengeluaran bulan ini',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                final totalExpenses = expenseProvider.getCurrentMonthTotal();

                return Column(
                  children: groupedExpenses.entries.take(5).map((entry) {
                    final categoryId = entry.key;
                    final expenses = entry.value
                        .where((e) =>
                            e.date.month == DateTime.now().month &&
                            e.date.year == DateTime.now().year)
                        .toList();

                    if (expenses.isEmpty) return const SizedBox.shrink();

                    final categoryTotal = expenses.fold(
                        0.0, (sum, expense) => sum + expense.amount);
                    final percentage = totalExpenses > 0
                        ? (categoryTotal / totalExpenses) * 100
                        : 0;
                    final category =
                        categoryProvider.getCategoryById(categoryId);

                    return _buildCategoryItem(
                      context,
                      category?.name ?? 'Unknown',
                      categoryTotal,
                      percentage.toDouble(),
                      userSettings,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(
    BuildContext context,
    String categoryName,
    double amount,
    double percentage,
    UserSettingsProvider userSettings,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                categoryName,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                userSettings.formatCurrency(amount),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingSmall),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.getCategoryColor(categoryName.hashCode.abs()),
            ),
          ),
        ],
      ),
    );
  }
}

// Placeholder widgets for other tabs
class TransactionsList extends StatelessWidget {
  const TransactionsList({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Transactions List - Coming Soon'),
    );
  }
}

class BudgetList extends StatelessWidget {
  const BudgetList({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Budget List - Coming Soon'),
    );
  }
}

class ReportsView extends StatelessWidget {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Reports View - Coming Soon'),
    );
  }
}

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Settings View - Coming Soon'),
    );
  }
}
