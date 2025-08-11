import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../providers/category_provider.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/category.dart';
import '../widgets/add_transaction_sheet.dart';
import '../utils/theme.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  DateTimeRange? _selectedDateRange;
  String _selectedType = 'all'; // all, income, expense
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
        filtered = filtered
            .where((e) =>
                e.date.isAfter(_selectedDateRange!.start
                    .subtract(const Duration(days: 1))) &&
                e.date.isBefore(
                    _selectedDateRange!.end.add(const Duration(days: 1))))
            .toList();
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
        filtered = filtered
            .where((i) =>
                i.date.isAfter(_selectedDateRange!.start
                    .subtract(const Duration(days: 1))) &&
                i.date.isBefore(
                    _selectedDateRange!.end.add(const Duration(days: 1))))
            .toList();
      }
      transactions.addAll(filtered.map((i) => _TransactionItem.income(i)));
    }
    transactions.sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Transaksi'),
      ),
      body: Column(
        children: [
          _buildFilterBar(context, categoryProvider),
          const Divider(height: 0),
          Expanded(
            child: transactions.isEmpty
                ? Center(
                    child: Text('Tidak ada transaksi',
                        style: Theme.of(context).textTheme.bodyLarge),
                  )
                : ListView.separated(
                    itemCount: transactions.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (context, index) {
                      final item = transactions[index];
                      return _TransactionTile(
                          item: item, categoryProvider: categoryProvider);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
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
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMedium, vertical: AppSizes.paddingSmall),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Type filter
            DropdownButton<String>(
              value: _selectedType,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Semua Transaksi')),
                DropdownMenuItem(value: 'expense', child: Text('Pengeluaran')),
                DropdownMenuItem(value: 'income', child: Text('Pemasukan')),
              ],
              onChanged: (val) => setState(() => _selectedType = val!),
            ),
            const SizedBox(width: 8),
            // Category filter
            DropdownButton<String?>(
              value: _selectedCategoryId,
              hint: const Text('Kategori'),
              items: [
                const DropdownMenuItem(
                    value: null, child: Text('Semua Kategori')),
                ...(_selectedType == 'income'
                        ? categoryProvider.incomeCategories
                        : _selectedType == 'expense'
                            ? categoryProvider.expenseCategories
                            : categoryProvider.categories)
                    .map((cat) =>
                        DropdownMenuItem(value: cat.id, child: Text(cat.name)))
              ],
              onChanged: (val) => setState(() => _selectedCategoryId = val),
            ),
            const SizedBox(width: 8),
            // Date filter
            OutlinedButton.icon(
              icon: const Icon(Icons.date_range, size: 18),
              label: Text(_selectedDateRange == null
                  ? 'Tanggal'
                  : '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month}/${_selectedDateRange!.start.year} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}/${_selectedDateRange!.end.year}'),
              onPressed: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  initialDateRange: _selectedDateRange,
                );
                if (picked != null) {
                  setState(() => _selectedDateRange = picked);
                }
              },
            ),
            const SizedBox(width: 8),
            // Reset filter
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              tooltip: 'Reset Filter',
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
      ),
    );
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
                'Rp ${item.amount.toStringAsFixed(0)}',
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
        // TODO: Show detail or edit
      },
    );
  }
}
