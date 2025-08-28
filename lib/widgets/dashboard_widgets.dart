import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import './add_transaction_sheet.dart';
import './edit_transaction_sheet.dart';
import './add_budget_sheet.dart';
import './budget_details_sheet.dart';
import '../utils/theme.dart';
import '../screens/transaction_list_screen.dart';
import '../screens/budget_list_screen.dart';
import '../l10n/localization_extension.dart';

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

class BalanceSummaryCard extends StatefulWidget {
  const BalanceSummaryCard({super.key});

  @override
  State<BalanceSummaryCard> createState() => _BalanceSummaryCardState();
}

class _BalanceSummaryCardState extends State<BalanceSummaryCard> {
  bool _showCurrentMonth = true;

  @override
  Widget build(BuildContext context) {
    return Consumer3<ExpenseProvider, IncomeProvider, UserSettingsProvider>(
      builder: (context, expenseProvider, incomeProvider, userSettings, child) {
        final currentMonthExpenses = expenseProvider.getCurrentMonthTotal();
        final currentMonthIncomes = incomeProvider.getCurrentMonthTotal();

        final totalExpenses =
            expenseProvider.getTotalAmount(expenseProvider.expenses);
        final totalIncomes =
            incomeProvider.getTotalAmount(incomeProvider.incomes);

        final displayExpenses =
            _showCurrentMonth ? currentMonthExpenses : totalExpenses;
        final displayIncomes =
            _showCurrentMonth ? currentMonthIncomes : totalIncomes;
        final balance = displayIncomes - displayExpenses;

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _showCurrentMonth
                          ? context.tr('balance_this_month')
                          : context.tr('total_balance'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                    Row(
                      children: [
                        // Hide/Show Amount Button
                        InkWell(
                          onTap: () {
                            userSettings.updateAmountVisibility(
                                !userSettings.isAmountVisible);
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              userSettings.isAmountVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Switch Month/Total Button
                        InkWell(
                          onTap: () {
                            setState(() {
                              _showCurrentMonth = !_showCurrentMonth;
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _showCurrentMonth
                                      ? Icons.calendar_month
                                      : Icons.timeline,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _showCurrentMonth
                                      ? context.tr('switch_to_total')
                                      : context.tr('switch_to_monthly'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.paddingSmall),
                Text(
                  userSettings.isAmountVisible
                      ? userSettings.formatCurrency(balance)
                      : 'Rp *********',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSizes.paddingLarge),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () =>
                            _navigateToFilteredTransactions(context, true),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusSmall),
                        child: _buildBalanceItem(
                          context,
                          context.tr('income'),
                          displayIncomes,
                          AppColors.income,
                          Icons.arrow_upward,
                          userSettings,
                          userSettings.isAmountVisible,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingSmall),
                    Expanded(
                      child: InkWell(
                        onTap: () => _navigateToFilteredTransactions(
                            context, false), // false = expense
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusSmall),
                        child: _buildBalanceItem(
                          context,
                          context.tr('expense'),
                          displayExpenses,
                          AppColors.expense,
                          Icons.arrow_downward,
                          userSettings,
                          userSettings.isAmountVisible,
                        ),
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
    bool isAmountVisible,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingSmall), // Reduced padding
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
              const SizedBox(width: 2), // Reduced spacing
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isAmountVisible ? userSettings.formatCurrency(amount) : 'Rp ******',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  void _navigateToFilteredTransactions(BuildContext context, bool isIncome) {
    showFilteredTransactionsSheet(
      context,
      isIncome: isIncome,
      showCurrentMonth: _showCurrentMonth,
    );
  }
}

class _FilteredTransactionsSheet extends StatelessWidget {
  final bool isIncome;
  final bool showCurrentMonth;
  final DateTimeRange? dateRange; // Add date range parameter

  const _FilteredTransactionsSheet({
    required this.isIncome,
    required this.showCurrentMonth,
    this.dateRange, // Optional date range
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.paddingLarge),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingSmall),
                decoration: BoxDecoration(
                  color: (isIncome ? AppColors.income : AppColors.expense)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
                child: Icon(
                  isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isIncome ? AppColors.income : AppColors.expense,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSizes.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTransactionTitle(context),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Consumer2<ExpenseProvider, IncomeProvider>(
                      builder:
                          (context, expenseProvider, incomeProvider, child) {
                        final total =
                            _calculateTotal(expenseProvider, incomeProvider);

                        return Consumer<UserSettingsProvider>(
                          builder: (context, userSettings, child) {
                            return Text(
                              'Total: ${userSettings.formatCurrency(total)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: isIncome
                                        ? AppColors.income
                                        : AppColors.expense,
                                    fontWeight: FontWeight.w600,
                                  ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingLarge),

          Expanded(
            child: Consumer3<ExpenseProvider, IncomeProvider, CategoryProvider>(
              builder: (context, expenseProvider, incomeProvider,
                  categoryProvider, child) {
                List<dynamic> transactions =
                    _getFilteredTransactions(expenseProvider, incomeProvider);

                // Sort by date (newest first)
                transactions.sort((a, b) => b.date.compareTo(a.date));

                if (transactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isIncome ? Icons.trending_up : Icons.trending_down,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: AppSizes.paddingMedium),
                        Text(
                          context.tr('no_income_expense', params: {
                            'type': isIncome
                                ? context.tr('income').toLowerCase()
                                : context.tr('expense').toLowerCase()
                          }),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                        const SizedBox(height: AppSizes.paddingSmall),
                        Text(
                          _getDisplayTitle(context).toLowerCase(),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[500],
                                  ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: transactions.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    final category = categoryProvider
                        .getCategoryById(transaction.categoryId);

                    return Consumer<UserSettingsProvider>(
                      builder: (context, userSettings, child) {
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.paddingSmall,
                            vertical: AppSizes.paddingSmall,
                          ),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: (isIncome
                                      ? AppColors.income
                                      : AppColors.expense)
                                  .withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusSmall),
                            ),
                            child: Icon(
                              isIncome ? Icons.add : Icons.remove,
                              color: isIncome
                                  ? AppColors.income
                                  : AppColors.expense,
                              size: 24,
                            ),
                          ),
                          title: Text(
                            transaction.description,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                context.getCategoryDisplayName(category),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.6),
                                    ),
                              ),
                              Text(
                                '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.5),
                                    ),
                              ),
                            ],
                          ),
                          trailing: Text(
                            userSettings.formatCurrency(transaction.amount),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isIncome
                                      ? AppColors.income
                                      : AppColors.expense,
                                ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getDisplayTitle(BuildContext context) {
    if (dateRange != null) {
      final start = dateRange!.start;
      final end = dateRange!.end;
      return '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
    } else if (showCurrentMonth) {
      return context.tr('this_month');
    } else {
      return context.tr('overall');
    }
  }

  String _getTransactionTitle(BuildContext context) {
    if (dateRange != null) {
      final start = dateRange!.start;
      final end = dateRange!.end;
      final dateRangeText =
          '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
      return '${isIncome ? context.tr('income') : context.tr('expense')} $dateRangeText';
    } else if (showCurrentMonth) {
      return isIncome
          ? context.tr('income_this_month')
          : context.tr('expense_this_month');
    } else {
      return isIncome
          ? context.tr('income_overall')
          : context.tr('expense_overall');
    }
  }

  double _calculateTotal(
      ExpenseProvider expenseProvider, IncomeProvider incomeProvider) {
    if (isIncome) {
      if (dateRange != null) {
        final incomes = incomeProvider.getIncomesByDateRange(
            dateRange!.start, dateRange!.end);
        return incomeProvider.getTotalAmount(incomes);
      } else if (showCurrentMonth) {
        return incomeProvider.getCurrentMonthTotal();
      } else {
        return incomeProvider.getTotalAmount(incomeProvider.incomes);
      }
    } else {
      if (dateRange != null) {
        final expenses = expenseProvider.getExpensesByDateRange(
            dateRange!.start, dateRange!.end);
        return expenseProvider.getTotalAmount(expenses);
      } else if (showCurrentMonth) {
        return expenseProvider.getCurrentMonthTotal();
      } else {
        return expenseProvider.getTotalAmount(expenseProvider.expenses);
      }
    }
  }

  // Helper method to get filtered transactions
  List<dynamic> _getFilteredTransactions(
      ExpenseProvider expenseProvider, IncomeProvider incomeProvider) {
    if (isIncome) {
      if (dateRange != null) {
        return incomeProvider.getIncomesByDateRange(
            dateRange!.start, dateRange!.end);
      } else if (showCurrentMonth) {
        final allIncomes = incomeProvider.incomes;
        return allIncomes
            .where((income) =>
                income.date.month == DateTime.now().month &&
                income.date.year == DateTime.now().year)
            .toList();
      } else {
        return incomeProvider.incomes;
      }
    } else {
      if (dateRange != null) {
        return expenseProvider.getExpensesByDateRange(
            dateRange!.start, dateRange!.end);
      } else if (showCurrentMonth) {
        final allExpenses = expenseProvider.expenses;
        return allExpenses
            .where((expense) =>
                expense.date.month == DateTime.now().month &&
                expense.date.year == DateTime.now().year)
            .toList();
      } else {
        return expenseProvider.expenses;
      }
    }
  }
}

// Helper function to show filtered transactions sheet
void showFilteredTransactionsSheet(
  BuildContext context, {
  required bool isIncome,
  bool showCurrentMonth = false,
  DateTimeRange? dateRange,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSizes.radiusLarge),
      ),
    ),
    builder: (context) => _FilteredTransactionsSheet(
      isIncome: isIncome,
      showCurrentMonth: showCurrentMonth,
      dateRange: dateRange,
    ),
  );
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
              context.tr('quick_actions'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSizes.paddingMedium),
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _buildQuickAction(
                      context,
                      context.tr('add_expense'),
                      Icons.remove_circle,
                      AppColors.expense,
                      () => _showAddExpenseDialog(context),
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingSmall),
                  Expanded(
                    child: _buildQuickAction(
                      context,
                      context.tr('add_income'),
                      Icons.add_circle,
                      AppColors.income,
                      () => _showAddIncomeDialog(context),
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingSmall),
                  Expanded(
                    child: _buildQuickAction(
                      context,
                      context.tr('create_budget'),
                      Icons.pie_chart,
                      AppColors.budget,
                      () => _showAddBudgetDialog(context),
                    ),
                  ),
                ],
              ),
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
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: AppSizes.iconLarge),
            const SizedBox(height: AppSizes.paddingSmall),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLarge),
        ),
      ),
      builder: (context) {
        return AddTransactionSheet(
          key: key,
          initialTabIndex: 0,
        );
      },
    );
  }

  void _showAddIncomeDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLarge),
        ),
      ),
      builder: (context) {
        return AddTransactionSheet(
          key: key,
          initialTabIndex: 1,
        );
      },
    );
  }

  void _showAddBudgetDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLarge),
        ),
      ),
      builder: (context) => const AddBudgetSheet(),
    );
  }
}

class BudgetOverviewCard extends StatelessWidget {
  const BudgetOverviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<BudgetProvider, UserSettingsProvider>(
      builder: (context, budgetProvider, userSettings, child) {
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
                    context.tr('no_active_budget'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSizes.paddingSmall),
                  Text(
                    context.tr('create_budget_desc'),
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
                      context.tr('budget_overview'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const BudgetListScreen(),
                          ),
                        );
                      },
                      child: Text(context.tr('see_all')),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                _buildBudgetSummary(context, budgetStats, userSettings),
                const SizedBox(height: AppSizes.paddingMedium),
                ...activeBudgets.take(3).map((budget) =>
                    _buildBudgetItem(context, budget, userSettings)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBudgetSummary(BuildContext context, Map<String, dynamic> stats,
      UserSettingsProvider userSettings) {
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
              context.tr('total_budget'),
              userSettings.formatCurrency(stats['totalBudgetAmount'] ?? 0),
              AppColors.budget,
            ),
          ),
          Expanded(
            child: _buildSummaryItem(
              context,
              context.tr('average_usage'),
              '${stats['averageUsagePercentage']?.toStringAsFixed(0) ?? '0'}%',
              AppColors.warning,
            ),
          ),
          Expanded(
            child: _buildSummaryItem(
              context,
              context.tr('exceeded_budgets'),
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
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

  Widget _buildBudgetItem(
      BuildContext context, budget, UserSettingsProvider userSettings) {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, child) {
        final category = categoryProvider.getCategoryById(budget.categoryId);

        return InkWell(
          onTap: () => BudgetDetailsSheet.show(context, budget),
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          child: Padding(
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
                        context.getCategoryDisplayName(category),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        '${userSettings.formatCurrency(budget.spent)} / ${userSettings.formatCurrency(budget.amount)}',
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
          ),
        );
      },
    );
  }

  Color _getBudgetStatusColor(String status) {
    switch (status) {
      case 'exceeded':
      case 'full':
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
                  context.tr('recent_transactions'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const TransactionListScreen(),
                      ),
                    );
                  },
                  child: Text(context.tr('see_all')),
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
                          context.tr('no_transactions'),
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

        return InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppSizes.radiusLarge),
                ),
              ),
              builder: (context) => EditTransactionSheet(
                transactionId: data.id,
                isExpense: isExpense,
              ),
            );
          },
          child: Padding(
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
                        '${context.getCategoryDisplayName(category)} • ${data.date.day}/${data.date.month}',
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
              context.tr('spending_by_category'),
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
                          context.tr('no_expenses_this_month'),
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
                      context.getCategoryDisplayName(category),
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
    return const TransactionListScreen();
  }
}

class BudgetList extends StatelessWidget {
  const BudgetList({super.key});

  @override
  Widget build(BuildContext context) {
    return const BudgetListScreen();
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
