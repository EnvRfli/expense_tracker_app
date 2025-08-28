import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../utils/theme.dart';
import '../l10n/localization_extension.dart';

class BudgetExpenseDetailsSheet extends StatelessWidget {
  final BudgetModel budget;

  const BudgetExpenseDetailsSheet({
    super.key,
    required this.budget,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<CategoryProvider, UserSettingsProvider>(
      builder: (context, categoryProvider, userSettings, child) {
        final category = categoryProvider.getCategoryById(budget.categoryId);
        final statusColor = _getBudgetStatusColor(budget.status);
        final expenses = _getBudgetExpenses(context, budget);

        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.paddingLarge),
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                    ),
                    child: Icon(
                      Icons.receipt_long,
                      color: statusColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detail Pengeluaran',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          context.getCategoryDisplayName(category),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.paddingLarge),
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Pengeluaran',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                  ),
                        ),
                        Text(
                          userSettings.formatCurrency(budget.spent),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Dari Budget',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                  ),
                        ),
                        Text(
                          userSettings.formatCurrency(budget.amount),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.paddingLarge),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daftar Pengeluaran (${expenses.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child: Text(
                      _getPeriodText(budget),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.paddingMedium),
              Expanded(
                child: expenses.isEmpty
                    ? _buildEmptyExpenseState(context)
                    : ListView.builder(
                        itemCount: expenses.length,
                        itemBuilder: (context, index) {
                          final expense = expenses[index];
                          return _buildExpenseItem(
                              context, expense, userSettings);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyExpenseState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: AppSizes.paddingMedium),
          Text(
            'Belum ada pengeluaran',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
          const SizedBox(height: AppSizes.paddingSmall),
          Text(
            'Pengeluaran dalam periode ini akan muncul di sini',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseItem(BuildContext context, ExpenseModel expense,
      UserSettingsProvider userSettings) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingSmall,
      ),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.expense.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        ),
        child: const Icon(
          Icons.shopping_cart,
          color: AppColors.expense,
          size: AppSizes.iconMedium,
        ),
      ),
      title: Text(
        expense.description,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
            _formatDate(expense.date),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
          if (expense.paymentMethod.isNotEmpty)
            Text(
              expense.paymentMethod,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  ),
            ),
        ],
      ),
      trailing: Text(
        userSettings.formatCurrency(expense.amount),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.expense,
            ),
      ),
    );
  }

  List<ExpenseModel> _getBudgetExpenses(
      BuildContext context, BudgetModel budget) {
    final expenseProvider = context.read<ExpenseProvider>();
    final allExpenses = expenseProvider.expenses;

    return allExpenses.where((expense) {
      if (expense.categoryId != budget.categoryId) return false;
      final expenseDate = expense.date;
      final isAfterStart = expenseDate.isAfter(budget.startDate) ||
          expenseDate.isAtSameMomentAs(budget.startDate);
      final isBeforeEnd = expenseDate.isBefore(budget.endDate) ||
          expenseDate.isAtSameMomentAs(budget.endDate);

      return isAfterStart && isBeforeEnd;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Sort by date descending
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];

    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day $month $year • $hour:$minute';
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

  String _getPeriodText(BudgetModel budget) {
    switch (budget.period) {
      case 'daily':
        return 'Harian • ${budget.startDate.day}/${budget.startDate.month}/${budget.startDate.year}';
      case 'weekly':
        return 'Mingguan • ${budget.startDate.day}/${budget.startDate.month} - ${budget.endDate.day}/${budget.endDate.month}';
      case 'monthly':
        return 'Bulanan • ${_getMonthName(budget.startDate.month)} ${budget.startDate.year}';
      default:
        return 'Custom • ${budget.startDate.day}/${budget.startDate.month} - ${budget.endDate.day}/${budget.endDate.month}';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return months[month - 1];
  }

  /// Static method untuk menampilkan budget expense details sheet
  static void show(BuildContext context, BudgetModel budget) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLarge),
        ),
      ),
      builder: (context) => BudgetExpenseDetailsSheet(budget: budget),
    );
  }
}
