import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../providers/category_provider.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../widgets/add_transaction_sheet.dart';
import '../widgets/edit_transaction_sheet.dart';
import '../utils/theme.dart';
import '../l10n/localization_extension.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  DateTimeRange? _selectedDateRange;
  String _selectedType = 'all';
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final incomeProvider = context.watch<IncomeProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    // Filter transactions
    List<_TransactionItem> transactions = [];
    if (_selectedType == 'all' || _selectedType == 'expense') {
      var filtered = expenseProvider.expenses;
      if (_selectedCategoryId != null) {
        filtered =
            filtered.where((e) => e.categoryId == _selectedCategoryId).toList();
      }
      if (_selectedDateRange != null) {
        filtered = filtered.where((e) {
          final expenseDate = DateTime(e.date.year, e.date.month, e.date.day);
          final startDate = DateTime(_selectedDateRange!.start.year,
              _selectedDateRange!.start.month, _selectedDateRange!.start.day);
          final endDate = DateTime(_selectedDateRange!.end.year,
              _selectedDateRange!.end.month, _selectedDateRange!.end.day);
          return expenseDate.isAtSameMomentAs(startDate) ||
              expenseDate.isAtSameMomentAs(endDate) ||
              (expenseDate.isAfter(startDate) && expenseDate.isBefore(endDate));
        }).toList();
      }
      transactions.addAll(filtered.map((e) => _TransactionItem.expense(e)));
    }
    if (_selectedType == 'all' || _selectedType == 'income') {
      var filtered = incomeProvider.incomes;
      if (_selectedCategoryId != null) {
        filtered =
            filtered.where((i) => i.categoryId == _selectedCategoryId).toList();
      }
      if (_selectedDateRange != null) {
        filtered = filtered.where((i) {
          final incomeDate = DateTime(i.date.year, i.date.month, i.date.day);
          final startDate = DateTime(_selectedDateRange!.start.year,
              _selectedDateRange!.start.month, _selectedDateRange!.start.day);
          final endDate = DateTime(_selectedDateRange!.end.year,
              _selectedDateRange!.end.month, _selectedDateRange!.end.day);
          return incomeDate.isAtSameMomentAs(startDate) ||
              incomeDate.isAtSameMomentAs(endDate) ||
              (incomeDate.isAfter(startDate) && incomeDate.isBefore(endDate));
        }).toList();
      }
      transactions.addAll(filtered.map((i) => _TransactionItem.income(i)));
    }
    transactions.sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('transactions')),
      ),
      body: Column(
        children: [
          _buildFilterBar(context, categoryProvider),
          Expanded(
            child: transactions.isEmpty
                ? Center(
                    child: Text(context.tr('no_transactions'),
                        style: Theme.of(context).textTheme.bodyLarge),
                  )
                : ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final item = transactions[index];
                      return Column(
                        children: [
                          _TransactionTile(
                              item: item, categoryProvider: categoryProvider),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "transaction_list_fab",
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        onPressed: () {
          // Show add transaction bottom sheet (reuse from dashboard)
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppSizes.radiusLarge)),
            ),
            builder: (context) => const AddTransactionSheet(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterBar(
      BuildContext context, CategoryProvider categoryProvider) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First row: Type and Reset button
          Row(
            children: [
              Expanded(
                child: _buildTypeFilterChips(),
              ),
              IconButton(
                icon: const Icon(Icons.filter_alt_off),
                tooltip: context.tr('reset_filter'),
                onPressed: () {
                  setState(() {
                    _selectedType = 'all';
                    _selectedCategoryId = null;
                    _selectedDateRange = null;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingSmall),
          // Second row: Category and Date filters
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildCategoryFilter(categoryProvider),
              ),
              const SizedBox(width: AppSizes.paddingSmall),
              Expanded(
                flex: 3,
                child: _buildDateFilter(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilterChips() {
    return Row(
      children: [
        _buildFilterChip(
          context.tr('filter_all'),
          _selectedType == 'all',
          () => setState(() => _selectedType = 'all'),
        ),
        const SizedBox(width: 8),
        _buildFilterChip(
          context.tr('filter_expense'),
          _selectedType == 'expense',
          () => setState(() => _selectedType = 'expense'),
        ),
        const SizedBox(width: 8),
        _buildFilterChip(
          context.tr('filter_income'),
          _selectedType == 'income',
          () => setState(() => _selectedType = 'income'),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(CategoryProvider categoryProvider) {
    return GestureDetector(
      onTap: () => _showCategoryDialog(categoryProvider),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Row(
          children: [
            Icon(
              Icons.category,
              size: AppSizes.iconSmall,
              color: Theme.of(context).iconTheme.color,
            ),
            const SizedBox(width: AppSizes.paddingSmall),
            Expanded(
              child: Text(
                _selectedCategoryId == null
                    ? context.tr('category')
                    : categoryProvider
                            .getCategoryById(_selectedCategoryId!)
                            ?.name ??
                        context.tr('category'),
                style: TextStyle(
                  fontSize: 12,
                  color: _selectedCategoryId == null
                      ? Theme.of(context).hintColor
                      : Theme.of(context).textTheme.bodyMedium?.color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              size: AppSizes.iconSmall,
              color: Theme.of(context).iconTheme.color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilter() {
    return GestureDetector(
      onTap: _showDateRangePicker,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Row(
          children: [
            Icon(
              Icons.date_range,
              size: AppSizes.iconSmall,
              color: Theme.of(context).iconTheme.color,
            ),
            const SizedBox(width: AppSizes.paddingSmall),
            Expanded(
              child: Text(
                _selectedDateRange == null
                    ? context.tr('date')
                    : '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}',
                style: TextStyle(
                  fontSize: 12,
                  color: _selectedDateRange == null
                      ? Theme.of(context).hintColor
                      : Theme.of(context).textTheme.bodyMedium?.color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryDialog(CategoryProvider categoryProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('select_category')),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: Text(context.tr('all_categories')),
                onTap: () {
                  setState(() => _selectedCategoryId = null);
                  Navigator.pop(context);
                },
                trailing: _selectedCategoryId == null
                    ? const Icon(Icons.check, color: AppTheme.primaryColor)
                    : null,
              ),
              const Divider(),
              ...(_selectedType == 'income'
                      ? categoryProvider.incomeCategories
                      : _selectedType == 'expense'
                          ? categoryProvider.expenseCategories
                          : categoryProvider.categories)
                  .map((cat) => ListTile(
                        title: Text(cat.name),
                        onTap: () {
                          setState(() => _selectedCategoryId = cat.id);
                          Navigator.pop(context);
                        },
                        trailing: _selectedCategoryId == cat.id
                            ? const Icon(Icons.check,
                                color: AppTheme.primaryColor)
                            : null,
                      )),
            ],
          ),
        ),
      ),
    );
  }

  void _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }
}

class _TransactionItem {
  final bool isExpense;
  final ExpenseModel? expense;
  final IncomeModel? income;
  _TransactionItem.expense(this.expense)
      : isExpense = true,
        income = null;
  _TransactionItem.income(this.income)
      : isExpense = false,
        expense = null;
  DateTime get date => isExpense ? expense!.date : income!.date;
  double get amount => isExpense ? expense!.amount : income!.amount;
  String get description =>
      isExpense ? expense!.description : income!.description;
  String get categoryId => isExpense ? expense!.categoryId : income!.categoryId;
}

class _TransactionTile extends StatelessWidget {
  final _TransactionItem item;
  final CategoryProvider categoryProvider;
  const _TransactionTile({required this.item, required this.categoryProvider});

  @override
  Widget build(BuildContext context) {
    final category = categoryProvider.getCategoryById(item.categoryId);
    final color = item.isExpense ? AppColors.expense : AppColors.income;
    Color? categoryColor;
    if (category != null && category.colorValue.isNotEmpty) {
      try {
        categoryColor =
            Color(int.parse(category.colorValue.replaceFirst('#', '0xff')));
      } catch (_) {
        categoryColor = color;
      }
    } else {
      categoryColor = color;
    }
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: categoryColor,
        child: Icon(item.isExpense ? Icons.remove : Icons.add,
            color: Colors.white),
      ),
      title:
          Text(item.description, style: Theme.of(context).textTheme.bodyLarge),
      subtitle: Text(category?.name ?? '-',
          style: Theme.of(context).textTheme.bodyMedium),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            (item.isExpense ? '-' : '+') +
                context.tr('currency_symbol_idr') +
                item.amount.toStringAsFixed(0),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            '${item.date.day}/${item.date.month}/${item.date.year}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
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
            transactionId: item.isExpense ? item.expense!.id : item.income!.id,
            isExpense: item.isExpense,
          ),
        );
      },
    );
  }
}
