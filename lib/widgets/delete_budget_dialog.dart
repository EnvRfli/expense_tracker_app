import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../l10n/localization_extension.dart';
import '../models/models.dart';
import '../utils/theme.dart';

class DeleteBudgetDialog extends StatelessWidget {
  final BudgetModel budget;

  const DeleteBudgetDialog({
    super.key,
    required this.budget,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer3<CategoryProvider, UserSettingsProvider, BudgetProvider>(
      builder:
          (context, categoryProvider, userSettings, budgetProvider, child) {
        final category = categoryProvider.getCategoryById(budget.categoryId);

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
                child: const Icon(
                  Icons.warning,
                  color: AppColors.error,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSizes.paddingMedium),
              Expanded(
                child: Text(context.tr('delete_budget')),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('confirm_delete_budget'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSizes.paddingMedium),
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.getCategoryDisplayName(category),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppSizes.paddingSmall),
                    Text(
                      'Budget: ${userSettings.formatCurrency(budget.amount)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      context.tr('used') +
                          ' : ${userSettings.formatCurrency(budget.spent)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.paddingMedium),
              Text(
                context.tr('deleting_budget_cannot_be_undone'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface,
              ),
              child: Text(context.tr('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  Navigator.of(context).pop(null);

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );

                  final success = await budgetProvider.deleteBudget(budget.id);

                  Navigator.of(context).pop();

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.tr('success_budget_deleted')),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );

                    Navigator.of(context).pop(true);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.tr('failed_to_delete_budget')),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: Text(context.tr('delete')),
            ),
          ],
        );
      },
    );
  }

  static Future<bool?> show(BuildContext context, BudgetModel budget) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return DeleteBudgetDialog(budget: budget);
      },
    );
  }
}
