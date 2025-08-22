import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
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
    return Consumer2<CategoryProvider, UserSettingsProvider>(
      builder: (context, categoryProvider, userSettings, child) {
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
              const Expanded(
                child: Text('Hapus Budget'),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apakah Anda yakin ingin menghapus budget ini?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSizes.paddingMedium),
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
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
                      category?.name ?? 'Unknown Category',
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
                      'Terpakai: ${userSettings.formatCurrency(budget.spent)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.paddingMedium),
              Text(
                'Tindakan ini tidak dapat dibatalkan.',
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
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  /// Static method untuk menampilkan delete confirmation dialog
  static Future<bool?> show(BuildContext context, BudgetModel budget) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return DeleteBudgetDialog(budget: budget);
      },
    );
  }
}
