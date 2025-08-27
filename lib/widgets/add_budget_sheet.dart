import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../utils/theme.dart';
import '../l10n/localization_extension.dart';

class AddBudgetSheet extends StatefulWidget {
  final String? categoryId;
  final String? period;
  final BudgetModel? budgetToEdit;

  const AddBudgetSheet({
    super.key,
    this.categoryId,
    this.period,
    this.budgetToEdit,
  });

  @override
  State<AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends State<AddBudgetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedCategoryId;
  String _selectedPeriod = 'monthly';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _alertEnabled = true;
  int _alertPercentage = 80;
  bool _isRecurring = false;
  bool _isLoading = false;

  // Predefined periods - will be translated in build method
  final Map<String, String> _periodKeys = {
    'daily': 'budget_period_daily',
    'weekly': 'budget_period_weekly',
    'monthly': 'budget_period_monthly',
  };

  // Check if budget already exists
  bool get _hasExistingBudget {
    if (widget.budgetToEdit != null) return false; // Editing mode, no conflict
    if (_selectedCategoryId == null || _startDate == null || _endDate == null) {
      return false;
    }

    final budgetProvider = context.read<BudgetProvider>();
    return budgetProvider.budgets.any((budget) =>
        budget.categoryId == _selectedCategoryId &&
        budget.period == _selectedPeriod &&
        budget.isActive &&
        _isOverlappingPeriod(
            budget.startDate, budget.endDate, _startDate!, _endDate!));
  }

  bool _isOverlappingPeriod(
      DateTime start1, DateTime end1, DateTime start2, DateTime end2) {
    return start1.isBefore(end2) && end1.isAfter(start2);
  }

  BudgetModel? get _existingBudget {
    if (_hasExistingBudget) {
      final budgetProvider = context.read<BudgetProvider>();
      return budgetProvider.budgets.firstWhere(
        (budget) =>
            budget.categoryId == _selectedCategoryId &&
            budget.period == _selectedPeriod &&
            budget.isActive &&
            _isOverlappingPeriod(
                budget.startDate, budget.endDate, _startDate!, _endDate!),
      );
    }
    return null;
  }

  @override
  void initState() {
    super.initState();

    if (widget.budgetToEdit != null) {
      // Initialize with existing budget data
      final budget = widget.budgetToEdit!;
      _selectedCategoryId = budget.categoryId;
      _selectedPeriod = budget.period;
      _startDate = budget.startDate;
      _endDate = budget.endDate;
      _alertEnabled = budget.alertPercentage > 0;
      _alertPercentage =
          budget.alertPercentage > 0 ? budget.alertPercentage : 80;
      _isRecurring = budget.isRecurring;
      _amountController.text = budget.amount.toStringAsFixed(0);
      _notesController.text = budget.notes ?? '';
    } else {
      // Initialize with provided values or defaults
      _selectedCategoryId = widget.categoryId;
      _selectedPeriod = widget.period ?? 'monthly';
      _setDefaultDates();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _setDefaultDates() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'daily':
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'weekly':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        _startDate =
            DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        _endDate = _startDate!
            .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        break;
      case 'monthly':
      default:
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
    }
  }

  Future<void> _submitBudget() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      _showErrorSnackBar(context.tr('select_category_first'));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final budgetProvider = context.read<BudgetProvider>();
      bool success;

      if (widget.budgetToEdit != null) {
        // Update existing budget
        success = await budgetProvider.updateBudget(
          id: widget.budgetToEdit!.id,
          categoryId: _selectedCategoryId!,
          amount: double.parse(
              _amountController.text.replaceAll('.', '').replaceAll(',', '')),
          period: _selectedPeriod,
          startDate: _startDate!,
          endDate: _endDate!,
          alertEnabled: _alertEnabled,
          alertPercentage: _alertPercentage,
          isRecurring: _isRecurring,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

        if (success && mounted) {
          Navigator.of(context).pop();
          _showSuccessSnackBar(context.tr('budget_updated_successfully'));
        }
      } else {
        // Create new budget
        success = await budgetProvider.addBudget(
          categoryId: _selectedCategoryId!,
          amount: double.parse(
              _amountController.text.replaceAll('.', '').replaceAll(',', '')),
          period: _selectedPeriod,
          startDate: _startDate!,
          endDate: _endDate!,
          alertEnabled: _alertEnabled,
          alertPercentage: _alertPercentage,
          isRecurring: _isRecurring,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

        if (success && mounted) {
          Navigator.of(context).pop();
          _showSuccessSnackBar(context.tr('budget_created_successfully'));
        }
      }
    } catch (e) {
      final action = widget.budgetToEdit != null
          ? context.tr('failed_to_update_budget')
          : context.tr('failed_to_create_budget');
      _showErrorSnackBar('$action: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLarge),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingLarge),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSizes.radiusLarge),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
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
                  const SizedBox(height: AppSizes.paddingMedium),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.budget,
                              AppColors.budget.withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMedium),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.budget.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.pie_chart,
                          color: Colors.white,
                          size: AppSizes.iconMedium,
                        ),
                      ),
                      const SizedBox(width: AppSizes.paddingMedium),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.budgetToEdit != null
                                  ? context.tr('edit_budget')
                                  : context.tr('create_new_budget'),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.tr('set_spending_limit'),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.7),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Period Selection
                    _buildSectionTitle(context.tr('budget_period')),
                    _buildPeriodSelector(),
                    const SizedBox(height: AppSizes.paddingLarge),

                    // Category Selection
                    _buildSectionTitle(context.tr('category')),
                    _buildCategorySelector(),
                    const SizedBox(height: AppSizes.paddingLarge),

                    // Amount Input
                    _buildSectionTitle(context.tr('budget_amount')),
                    _buildAmountInput(),
                    const SizedBox(height: AppSizes.paddingLarge),

                    // Date Range (for custom periods)
                    if (_selectedPeriod != 'daily') ...[
                      _buildSectionTitle(context.tr('time_period')),
                      _buildDateRangeSelector(),
                      const SizedBox(height: AppSizes.paddingLarge),
                    ],

                    // Alert Settings
                    _buildSectionTitle(context.tr('notification_settings')),
                    _buildAlertSettings(),
                    const SizedBox(height: AppSizes.paddingLarge),

                    // Recurring Settings
                    _buildSectionTitle(context.tr('recurring_budget')),
                    _buildRecurringSettings(),
                    const SizedBox(height: AppSizes.paddingLarge),

                    // Notes
                    _buildSectionTitle(context.tr('notes_optional')),
                    _buildNotesInput(),
                    const SizedBox(height: AppSizes.paddingExtraLarge),
                  ],
                ),
              ),
            ),

            // Warning for existing budget
            Consumer<BudgetProvider>(
              builder: (context, budgetProvider, child) {
                if (_hasExistingBudget) {
                  final existingBudget = _existingBudget;
                  return Container(
                    margin: const EdgeInsets.fromLTRB(
                        AppSizes.paddingLarge, 0, AppSizes.paddingLarge, 0),
                    padding: const EdgeInsets.all(AppSizes.paddingMedium),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                      border: Border.all(
                        color: AppColors.warning.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.warning,
                              size: 20,
                            ),
                            const SizedBox(width: AppSizes.paddingSmall),
                            Expanded(
                              child: Text(
                                context.tr('budget_already_exists_title'),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.paddingSmall),
                        Text(
                          context.tr('budget_exists_message'),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.warning,
                                  ),
                        ),
                        if (existingBudget != null) ...[
                          const SizedBox(height: AppSizes.paddingSmall),
                          Consumer<UserSettingsProvider>(
                            builder: (context, userSettings, child) {
                              return Text(
                                '${context.tr('current_budget')}: ${userSettings.formatCurrency(existingBudget.amount)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.w500,
                                    ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Submit Button
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingLarge),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color:
                        Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Consumer<BudgetProvider>(
                builder: (context, budgetProvider, child) {
                  final isButtonDisabled = _isLoading || _hasExistingBudget;

                  return Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isButtonDisabled ? null : _submitBudget,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isButtonDisabled
                                ? Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withOpacity(0.3)
                                : AppColors.budget,
                            foregroundColor: isButtonDisabled
                                ? Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.5)
                                : Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSizes.paddingMedium),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusSmall),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text(
                                  widget.budgetToEdit != null
                                      ? context.tr('update_budget')
                                      : context.tr('create_budget'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      if (_hasExistingBudget) ...[
                        const SizedBox(height: AppSizes.paddingSmall),
                        Text(
                          context.tr('delete_existing_budget_first'),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: Column(
        children: _periodKeys.entries.map((entry) {
          final isSelected = _selectedPeriod == entry.key;
          return InkWell(
            onTap: () {
              setState(() {
                _selectedPeriod = entry.key;
                _setDefaultDates();
              });
            },
            child: Container(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.budget.withOpacity(0.1) : null,
                border: entry.key != _periodKeys.keys.last
                    ? Border(
                        bottom: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withOpacity(0.2),
                        ),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected
                        ? AppColors.budget
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                  ),
                  const SizedBox(width: AppSizes.paddingMedium),
                  Expanded(
                    child: Text(
                      context.tr(entry.value),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected ? AppColors.budget : null,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, child) {
        final expenseCategories = categoryProvider.categories
            .where((cat) => cat.type == 'expense')
            .toList();

        if (expenseCategories.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppSizes.paddingLarge),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.category_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                Text(
                  context.tr('no_expense_categories'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSizes.paddingSmall),
                Text(
                  context.tr('create_expense_category_first'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          ),
          child: Column(
            children: expenseCategories.map((category) {
              final isSelected = _selectedCategoryId == category.id;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedCategoryId = category.id;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? AppColors.budget.withOpacity(0.1) : null,
                    border: category != expenseCategories.last
                        ? Border(
                            bottom: BorderSide(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withOpacity(0.2),
                            ),
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: isSelected
                            ? AppColors.budget
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                      ),
                      const SizedBox(width: AppSizes.paddingMedium),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.getCategoryColor(
                                  category.name.hashCode.abs())
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.category,
                          size: 18,
                          color: AppColors.getCategoryColor(
                              category.name.hashCode.abs()),
                        ),
                      ),
                      const SizedBox(width: AppSizes.paddingMedium),
                      Expanded(
                        child: Text(
                          category.name,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isSelected ? AppColors.budget : null,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildAmountInput() {
    return Consumer<UserSettingsProvider>(
      builder: (context, userSettings, child) {
        return TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            ThousandsFormatter(),
          ],
          decoration: InputDecoration(
            hintText: context.tr('enter_budget_amount'),
            prefixText: 'Rp ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              borderSide: const BorderSide(color: AppColors.budget, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return context.tr('budget_amount_required');
            }
            final amount =
                double.tryParse(value.replaceAll('.', '').replaceAll(',', ''));
            if (amount == null || amount <= 0) {
              return context.tr('budget_amount_must_be_positive');
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildDateRangeSelector() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _selectStartDate(context),
            child: Container(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('start_date'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _startDate != null
                        ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                        : context.tr('select_date'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSizes.paddingMedium),
        Expanded(
          child: InkWell(
            onTap: () => _selectEndDate(context),
            child: Container(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('end_date'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _endDate != null
                        ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                        : context.tr('select_date'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertSettings() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: Text(context.tr('enable_notifications')),
            subtitle: Text(context.tr('notification_subtitle')),
            value: _alertEnabled,
            onChanged: (value) {
              setState(() {
                _alertEnabled = value;
              });
            },
            activeColor: AppColors.budget,
          ),
          if (_alertEnabled) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('warning_at_percentage',
                        params: {'percentage': _alertPercentage.toString()}),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSizes.paddingSmall),
                  Slider(
                    value: _alertPercentage.toDouble(),
                    min: 50,
                    max: 100,
                    divisions: 5,
                    label: '${_alertPercentage}%',
                    activeColor: AppColors.budget,
                    onChanged: (value) {
                      setState(() {
                        _alertPercentage = value.round();
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '50%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                      ),
                      Text(
                        '100%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecurringSettings() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(
          color: _isRecurring
              ? AppColors.budget.withOpacity(0.3)
              : Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingSmall),
                decoration: BoxDecoration(
                  color: _isRecurring
                      ? AppColors.budget.withOpacity(0.1)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
                child: Icon(
                  Icons.repeat,
                  color: _isRecurring
                      ? AppColors.budget
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                  size: AppSizes.iconSmall,
                ),
              ),
              const SizedBox(width: AppSizes.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('auto_recurring_budget'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getRecurringDescription(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _isRecurring,
                onChanged: (value) {
                  setState(() {
                    _isRecurring = value;
                  });
                },
                activeColor: AppColors.budget,
              ),
            ],
          ),
          if (_isRecurring) ...[
            const SizedBox(height: AppSizes.paddingMedium),
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.budget.withOpacity(0.05),
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                border: Border.all(
                  color: AppColors.budget.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.budget,
                    size: AppSizes.iconSmall,
                  ),
                  const SizedBox(width: AppSizes.paddingSmall),
                  Expanded(
                    child: Text(
                      context.tr('auto_budget_info'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.budget,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getRecurringDescription() {
    switch (_selectedPeriod) {
      case 'daily':
        return context.tr('budget_will_be_created_daily');
      case 'weekly':
        return context.tr('budget_will_be_created_weekly');
      case 'monthly':
        return context.tr('budget_will_be_created_monthly');
      default:
        return context.tr('budget_will_be_created_next_period');
    }
  }

  Widget _buildNotesInput() {
    return TextFormField(
      controller: _notesController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: context.tr('example_budget_note'),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          borderSide: const BorderSide(color: AppColors.budget, width: 2),
        ),
        alignLabelWithHint: true,
      ),
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        // Auto-adjust end date if needed
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = _startDate!.add(const Duration(days: 30));
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }
}

// Custom input formatter for thousands separator
class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-digit characters
    final String cleanValue = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanValue.isEmpty) {
      return const TextEditingValue();
    }

    // Add thousands separator
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < cleanValue.length; i++) {
      if (i > 0 && (cleanValue.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(cleanValue[i]);
    }

    final String formattedValue = buffer.toString();

    return TextEditingValue(
      text: formattedValue,
      selection: TextSelection.collapsed(offset: formattedValue.length),
    );
  }
}
