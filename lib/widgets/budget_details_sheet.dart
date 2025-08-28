import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../utils/theme.dart';
import './budget_expense_details_sheet.dart';
import './add_budget_sheet.dart';
import './delete_budget_dialog.dart';
import '../l10n/localization_extension.dart';

class BudgetDetailsSheet extends StatelessWidget {
  final BudgetModel budget;
  final bool showNavigationActions;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const BudgetDetailsSheet({
    super.key,
    required this.budget,
    this.showNavigationActions = true,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<CategoryProvider, UserSettingsProvider>(
      builder: (context, categoryProvider, userSettings, child) {
        final category = categoryProvider.getCategoryById(budget.categoryId);
        final statusColor = _getBudgetStatusColor(budget.status);

        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
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
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.paddingLarge),

              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                    ),
                    child: Icon(
                      Icons.pie_chart,
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
                          context.getCategoryDisplayName(category),
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: AppSizes.paddingSmall),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.paddingSmall,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusSmall),
                          ),
                          child: Text(
                            _getBudgetStatusText(context, budget.status),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: statusColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.paddingLarge),
              InkWell(
                onTap: () {
                  Navigator.pop(context); // Close current sheet
                  BudgetExpenseDetailsSheet.show(context, budget);
                },
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                    border: Border.all(
                      color: statusColor.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.tr('progress'),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Row(
                            children: [
                              Text(
                                '${budget.usagePercentage.toStringAsFixed(0)}%',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(width: AppSizes.paddingSmall),
                              Icon(
                                Icons.receipt_long,
                                color: statusColor,
                                size: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.paddingSmall),
                      LinearProgressIndicator(
                        value: budget.usagePercentage / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                      const SizedBox(height: AppSizes.paddingSmall),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${context.tr('used')}: ${userSettings.formatCurrency(budget.spent)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            '${context.tr('total')}: ${userSettings.formatCurrency(budget.amount)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.paddingSmall),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            context.tr('tap_to_view_details'),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: statusColor,
                                      fontStyle: FontStyle.italic,
                                    ),
                          ),
                          const SizedBox(width: AppSizes.paddingSmall),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: statusColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSizes.paddingLarge),

              _buildDetailRow(context, context.tr('period'),
                  _getPeriodText(context, budget)),

              _buildDetailRow(
                context,
                context.tr('remaining_budget'),
                userSettings.formatCurrency(budget.amount - budget.spent),
              ),

              _buildDetailRow(context, context.tr('alert_threshold'),
                  '${budget.alertPercentage}%'),
              if (budget.notes?.isNotEmpty == true)
                _buildDetailRow(context, context.tr('notes'), budget.notes!),

              const Spacer(),

              // Always show Edit and Delete buttons for active budgets
              if (budget.isActive) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit ??
                            () {
                              Navigator.pop(context);
                              // Default edit action - you can customize this
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(AppSizes.radiusLarge),
                                  ),
                                ),
                                builder: (context) =>
                                    AddBudgetSheet(budgetToEdit: budget),
                              );
                            },
                        icon: const Icon(Icons.edit),
                        label: Text(context.tr('edit')),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.info),
                          foregroundColor: AppColors.info,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingMedium),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onDelete ??
                            () {
                              Navigator.pop(context);
                              DeleteBudgetDialog.show(context, budget);
                            },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.delete),
                        label: Text(context.tr('delete')),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
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

  String _getBudgetStatusText(BuildContext context, String status) {
    switch (status) {
      case 'exceeded':
        return context.tr('budget_status_exceeded_alt');
      case 'full':
        return context.tr('budget_status_full_alt');
      case 'warning':
        return context.tr('budget_status_warning_alt');
      default:
        return context.tr('budget_status_normal_alt');
    }
  }

  String _getPeriodText(BuildContext context, BudgetModel budget) {
    switch (budget.period) {
      case 'daily':
        return '${context.tr('budget_period_daily')} • ${budget.startDate.day}/${budget.startDate.month}/${budget.startDate.year}';
      case 'weekly':
        return '${context.tr('budget_period_weekly')} • ${budget.startDate.day}/${budget.startDate.month} - ${budget.endDate.day}/${budget.endDate.month}';
      case 'monthly':
        return '${context.tr('budget_period_monthly')} • ${context.getMonthName(budget.startDate.month)} ${budget.startDate.year}';
      default:
        return '${context.tr('budget_period_custom')} • ${budget.startDate.day}/${budget.startDate.month} - ${budget.endDate.day}/${budget.endDate.month}';
    }
  }

  /// Static method untuk menampilkan budget details sheet
  static void show(
    BuildContext context,
    BudgetModel budget, {
    bool showNavigationActions = true,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLarge),
        ),
      ),
      builder: (context) => BudgetDetailsSheet(
        budget: budget,
        showNavigationActions: showNavigationActions,
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    );
  }
}
