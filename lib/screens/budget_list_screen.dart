import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../utils/theme.dart';
import '../widgets/add_budget_sheet.dart';

class BudgetListScreen extends StatefulWidget {
  const BudgetListScreen({super.key});

  @override
  State<BudgetListScreen> createState() => _BudgetListScreenState();
}

class _BudgetListScreenState extends State<BudgetListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _setupExpenseCallback();
  }

  void _setupExpenseCallback() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final expenseProvider = context.read<ExpenseProvider>();
      final budgetProvider = context.read<BudgetProvider>();

      // Setup callback untuk refresh budget saat expense berubah
      expenseProvider.onExpenseChanged = () async {
        print('=== Expense Changed - Refreshing Budget in Budget Screen ===');
        await budgetProvider.loadBudgets();
        await budgetProvider.refreshAllBudgetSpentAmounts();
      };
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddBudgetDialog(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Aktif'),
            Tab(text: 'Selesai'),
            Tab(text: 'Semua'),
          ],
        ),
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, budgetProvider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildBudgetList(
                  _filterBudgetsByPeriod(budgetProvider.activeBudgets),
                  'active'),
              _buildBudgetList(
                _filterBudgetsByPeriod(
                    budgetProvider.budgets.where((b) => !b.isActive).toList()),
                'inactive',
              ),
              _buildBudgetList(
                  _filterBudgetsByPeriod(budgetProvider.budgets), 'all'),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBudgetDialog(context),
        backgroundColor: AppColors.budget,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBudgetList(List<BudgetModel> budgets, String type) {
    // Get original budgets before filtering untuk statistik
    final originalBudgets = _getOriginalBudgets(type);

    // Check if no data at all (before filtering)
    if (originalBudgets.isEmpty) {
      return _buildEmptyState(type);
    }

    // Data ada, tapi mungkin kosong setelah filtering
    return Column(
      children: [
        // Statistics Card - gunakan data asli sebelum filter
        _buildStatisticsCard(originalBudgets),

        // Filter
        _buildPeriodFilter(),

        // Budget List - gunakan data setelah filter
        Expanded(
          child: budgets.isEmpty
              ? _buildFilteredEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  itemCount: budgets.length,
                  itemBuilder: (context, index) {
                    final budget = budgets[index];
                    return _buildBudgetCard(budget);
                  },
                ),
        ),
      ],
    );
  }

  // Fungsi untuk mendapatkan data budget asli sebelum filtering
  List<BudgetModel> _getOriginalBudgets(String type) {
    final budgetProvider = context.read<BudgetProvider>();

    switch (type) {
      case 'active':
        return budgetProvider.activeBudgets;
      case 'inactive':
        return budgetProvider.budgets.where((b) => !b.isActive).toList();
      case 'all':
      default:
        return budgetProvider.budgets;
    }
  }

  // Widget untuk empty state karena filter (bukan karena tidak ada data)
  Widget _buildFilteredEmptyState() {
    final filterText = _getFilterText();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list_off,
              size: 60,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: AppSizes.paddingLarge),
            Text(
              'Tidak ada budget $filterText',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.paddingSmall),
            Text(
              'Coba pilih filter periode yang berbeda atau buat budget $filterText baru',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Fungsi untuk mendapatkan text filter yang dipilih
  String _getFilterText() {
    switch (_selectedPeriod) {
      case 'daily':
        return 'harian';
      case 'weekly':
        return 'mingguan';
      case 'monthly':
        return 'bulanan';
      case 'all':
      default:
        return '';
    }
  }

  Widget _buildEmptyState(String type) {
    String title, subtitle;
    IconData icon;

    switch (type) {
      case 'active':
        title = 'Belum ada budget aktif';
        subtitle = 'Buat budget untuk memantau pengeluaran Anda';
        icon = Icons.pie_chart_outline;
        break;
      case 'inactive':
        title = 'Belum ada budget yang selesai';
        subtitle = 'Budget yang telah selesai akan muncul di sini';
        icon = Icons.history;
        break;
      default:
        title = 'Belum ada budget';
        subtitle = 'Mulai dengan membuat budget pertama Anda';
        icon = Icons.pie_chart_outline;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: AppSizes.paddingLarge),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.paddingSmall),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  ),
              textAlign: TextAlign.center,
            ),
            if (type != 'inactive') ...[
              const SizedBox(height: AppSizes.paddingLarge),
              ElevatedButton.icon(
                onPressed: () => _showAddBudgetDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Buat Budget'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.budget,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingLarge,
                    vertical: AppSizes.paddingMedium,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard(List<BudgetModel> budgets) {
    final totalBudget = budgets.fold(0.0, (sum, budget) => sum + budget.amount);
    final totalSpent = budgets.fold(0.0, (sum, budget) => sum + budget.spent);
    final averageUsage = totalBudget > 0 ? (totalSpent / totalBudget * 100) : 0;
    final exceededCount = budgets
        .where((b) => b.status == 'exceeded' || b.status == 'full')
        .length;

    return Container(
      margin: const EdgeInsets.all(AppSizes.paddingMedium),
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.budget,
            AppColors.budget.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      child: Column(
        children: [
          Text(
            'Budget Overview',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSizes.paddingLarge),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Budget',
                  'Rp ${_formatNumber(totalBudget)}',
                  Icons.pie_chart,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Terpakai',
                  '${averageUsage.toStringAsFixed(0)}%',
                  Icons.trending_up,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Melebihi',
                  '$exceededCount Budget',
                  Icons.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingSmall),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: AppSizes.paddingSmall),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Fungsi untuk memfilter budget berdasarkan periode yang dipilih
  List<BudgetModel> _filterBudgetsByPeriod(List<BudgetModel> budgets) {
    if (_selectedPeriod == 'all') {
      return budgets;
    }

    return budgets.where((budget) {
      switch (_selectedPeriod) {
        case 'daily':
          return budget.period == 'daily';
        case 'weekly':
          return budget.period == 'weekly';
        case 'monthly':
          return budget.period == 'monthly';
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildPeriodFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
      child: Row(
        children: [
          const Text('Filter: '),
          const SizedBox(width: AppSizes.paddingSmall),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'Semua'),
                  _buildFilterChip('daily', 'Harian'),
                  _buildFilterChip('weekly', 'Mingguan'),
                  _buildFilterChip('monthly', 'Bulanan'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedPeriod == value;
    return Padding(
      padding: const EdgeInsets.only(right: AppSizes.paddingSmall),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedPeriod = value;
          });
        },
        selectedColor: AppColors.budget.withOpacity(0.2),
        checkmarkColor: AppColors.budget,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.budget : null,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildBudgetCard(BudgetModel budget) {
    return Consumer2<CategoryProvider, UserSettingsProvider>(
      builder: (context, categoryProvider, userSettings, child) {
        final category = categoryProvider.getCategoryById(budget.categoryId);
        final progress = budget.usagePercentage / 100;
        final statusColor = _getBudgetStatusColor(budget.status);

        return Card(
          margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
          child: InkWell(
            onTap: () => _showBudgetDetails(budget),
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusSmall),
                        ),
                        child: Icon(
                          Icons.pie_chart,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: AppSizes.paddingMedium),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category?.name ?? 'Unknown Category',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            Text(
                              _getPeriodText(budget),
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
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingSmall,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusText(budget.status),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSizes.paddingMedium),

                  // Progress
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Terpakai: ${userSettings.formatCurrency(budget.spent)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            '${budget.usagePercentage.toStringAsFixed(0)}%',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.paddingSmall),
                      LinearProgressIndicator(
                        value: progress > 1 ? 1 : progress,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        minHeight: 6,
                      ),
                      const SizedBox(height: AppSizes.paddingSmall),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Budget: ${userSettings.formatCurrency(budget.amount)}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.6),
                                    ),
                          ),
                          Text(
                            'Sisa: ${userSettings.formatCurrency(budget.remaining)}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: budget.remaining >= 0
                                          ? AppColors.success
                                          : AppColors.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
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

  String _getStatusText(String status) {
    switch (status) {
      case 'exceeded':
        return 'Melampaui';
      case 'full':
        return 'Habis';
      case 'warning':
        return 'Peringatan';
      default:
        return 'Normal';
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

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toStringAsFixed(0);
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

  void _showBudgetDetails(BudgetModel budget) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLarge),
        ),
      ),
      builder: (context) => _buildBudgetDetailsSheet(budget),
    );
  }

  void _showBudgetExpenseDetails(BudgetModel budget) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLarge),
        ),
      ),
      builder: (context) => _buildBudgetExpenseDetailsSheet(budget),
    );
  }

  Widget _buildBudgetExpenseDetailsSheet(BudgetModel budget) {
    return Consumer2<CategoryProvider, UserSettingsProvider>(
      builder: (context, categoryProvider, userSettings, child) {
        final category = categoryProvider.getCategoryById(budget.categoryId);
        final statusColor = _getBudgetStatusColor(budget.status);

        // Get expenses for this budget period
        final expenses = _getBudgetExpenses(budget);

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
                          'Pengeluaran ${category?.name ?? 'Unknown'}',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          _getPeriodText(budget),
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

              // Budget Summary
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  border: Border.all(
                    color: statusColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Terpakai',
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
                          'Budget',
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

              // Expense List Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detail Pengeluaran (${expenses.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (expenses.isNotEmpty)
                    Text(
                      'Total: ${userSettings.formatCurrency(expenses.fold(0.0, (sum, e) => sum + e.amount))}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                ],
              ),

              const SizedBox(height: AppSizes.paddingMedium),

              // Expense List
              Expanded(
                child: expenses.isEmpty
                    ? _buildEmptyExpenseState()
                    : ListView.separated(
                        itemCount: expenses.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final expense = expenses[index];
                          return _buildExpenseItem(expense, userSettings);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyExpenseState() {
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

  Widget _buildExpenseItem(
      ExpenseModel expense, UserSettingsProvider userSettings) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingSmall,
        vertical: AppSizes.paddingSmall,
      ),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.expense.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        ),
        child: Icon(
          Icons.shopping_cart,
          color: AppColors.expense,
          size: 24,
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

  List<ExpenseModel> _getBudgetExpenses(BudgetModel budget) {
    final expenseProvider = context.read<ExpenseProvider>();
    final allExpenses = expenseProvider.expenses;

    return allExpenses.where((expense) {
      // Check category match
      if (expense.categoryId != budget.categoryId) return false;

      // Check if expense date is within budget period (inclusive)
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
    final months = [
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

  Widget _buildBudgetDetailsSheet(BudgetModel budget) {
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
                          category?.name ?? 'Unknown Category',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          overflow: TextOverflow.visible,
                          softWrap: true,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getPeriodText(budget),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                  ),
                          overflow: TextOverflow.visible,
                          softWrap: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.paddingLarge),

              // Progress Section
              InkWell(
                onTap: () => _showBudgetExpenseDetails(budget),
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.paddingLarge),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${budget.usagePercentage.toStringAsFixed(1)}%',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSizes.paddingMedium,
                                  vertical: AppSizes.paddingSmall,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  _getStatusText(budget.status),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSizes.paddingSmall),
                              Icon(
                                Icons.receipt_long,
                                color: statusColor.withOpacity(0.7),
                                size: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.paddingMedium),
                      LinearProgressIndicator(
                        value: (budget.usagePercentage / 100) > 1
                            ? 1
                            : (budget.usagePercentage / 100),
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        minHeight: 8,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSizes.paddingLarge),

              // Details
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildDetailRow('Budget Amount',
                          userSettings.formatCurrency(budget.amount)),
                      _buildDetailRow(
                          'Spent', userSettings.formatCurrency(budget.spent)),
                      _buildDetailRow('Remaining',
                          userSettings.formatCurrency(budget.remaining)),
                      _buildDetailRow(
                          'Alert Threshold', '${budget.alertPercentage}%'),
                      if (budget.notes?.isNotEmpty == true)
                        _buildDetailRow('Notes', budget.notes!),
                    ],
                  ),
                ),
              ),

              // Actions
              !budget.isActive
                  ? const SizedBox()
                  : Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _editBudget(context, budget),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit'),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.info),
                              foregroundColor: AppColors.info,
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSizes.paddingMedium,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.paddingMedium),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _deleteBudget(context, budget),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Hapus'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSizes.paddingMedium,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
            ),
          ),
          const SizedBox(width: AppSizes.paddingMedium),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.visible,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  void _editBudget(BuildContext context, BudgetModel budget) {
    Navigator.pop(context); // Close detail sheet first
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLarge),
        ),
      ),
      builder: (context) => AddBudgetSheet(budgetToEdit: budget),
    );
  }

  void _deleteBudget(BuildContext context, BudgetModel budget) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingSmall),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
                child: Icon(
                  Icons.warning_outlined,
                  color: AppColors.error,
                  size: AppSizes.iconMedium,
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
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Consumer<CategoryProvider>(
                      builder: (context, categoryProvider, child) {
                        final category =
                            categoryProvider.getCategoryById(budget.categoryId);
                        return Text(
                          category?.name ?? 'Unknown Category',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getPeriodText(budget),
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
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(
                foregroundColor:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close dialog
                Navigator.of(context).pop(); // Close detail sheet

                final budgetProvider =
                    Provider.of<BudgetProvider>(context, listen: false);

                try {
                  final success = await budgetProvider.deleteBudget(budget.id);

                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Budget berhasil dihapus'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusSmall),
                        ),
                      ),
                    );
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Gagal menghapus budget'),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusSmall),
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusSmall),
                        ),
                      ),
                    );
                  }
                }
              },
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
}
