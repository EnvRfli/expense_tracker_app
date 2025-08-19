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
              _buildBudgetList(budgetProvider.activeBudgets, 'active'),
              _buildBudgetList(
                budgetProvider.budgets.where((b) => !b.isActive).toList(),
                'inactive',
              ),
              _buildBudgetList(budgetProvider.budgets, 'all'),
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
    if (budgets.isEmpty) {
      return _buildEmptyState(type);
    }

    return Column(
      children: [
        // Statistics Card
        _buildStatisticsCard(budgets),

        // Filter
        _buildPeriodFilter(),

        // Budget List
        Expanded(
          child: ListView.builder(
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
    final exceededCount = budgets.where((b) => b.status == 'exceeded').length;

    return Container(
      margin: const EdgeInsets.all(AppSizes.paddingMedium),
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
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

              // Progress Section
              Container(
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

              const SizedBox(height: AppSizes.paddingLarge),

              // Details
              Expanded(
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

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Edit budget
                        Navigator.pop(context);
                      },
                      child: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingMedium),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Delete budget
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Hapus'),
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
}
