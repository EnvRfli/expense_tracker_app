import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../utils/theme.dart';
import '../widgets/add_budget_sheet.dart';
import '../widgets/budget_details_sheet.dart';
import '../widgets/delete_budget_dialog.dart';
import '../l10n/localization_extension.dart';

class BudgetListScreen extends StatefulWidget {
  const BudgetListScreen({super.key});

  @override
  State<BudgetListScreen> createState() => _BudgetListScreenState();
}

class _BudgetListScreenState extends State<BudgetListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotationAnimation;
  String _selectedPeriod = 'all';
  bool _isStatisticsExpanded = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (_isStatisticsExpanded) {
      _animationController.value = 1.0;
    }

    _setupExpenseCallback();
  }

  void _setupExpenseCallback() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final expenseProvider = context.read<ExpenseProvider>();
      final budgetProvider = context.read<BudgetProvider>();
      expenseProvider.onExpenseChanged = () async {
        await budgetProvider.loadBudgets();
        await budgetProvider.refreshAllBudgetSpentAmounts();
      };
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('budget_management')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddBudgetDialog(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: context.tr('active_budgets')),
            Tab(text: context.tr('completed_budgets')),
            Tab(text: context.tr('all_budgets')),
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
    final originalBudgets = _getOriginalBudgets(type);
    if (originalBudgets.isEmpty) {
      return _buildEmptyState(type);
    }
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildStatisticsCard(originalBudgets),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _FilterHeaderDelegate(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: _buildPeriodFilter(),
            ),
          ),
        ),
        budgets.isEmpty
            ? SliverFillRemaining(
                child: _buildFilteredEmptyState(),
              )
            : SliverPadding(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final budget = budgets[index];
                      return _buildBudgetCard(budget);
                    },
                    childCount: budgets.length,
                  ),
                ),
              ),
      ],
    );
  }

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
              context.tr('no_budget_filter', params: {'filter': filterText}),
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
              context
                  .tr('try_different_filter', params: {'filter': filterText}),
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
        return context.tr('budget_period_daily');
      case 'weekly':
        return context.tr('budget_period_weekly');
      case 'monthly':
        return context.tr('budget_period_monthly');
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
        title = context.tr('no_budget_active');
        subtitle = context.tr('create_budget_desc');
        icon = Icons.pie_chart_outline;
        break;
      case 'inactive':
        title = context.tr('no_budget_completed');
        subtitle = context.tr('completed_budgets_desc');
        icon = Icons.history;
        break;
      default:
        title = context.tr('no_budget_all');
        subtitle = context.tr('create_budget_first');
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
                label: Text(context.tr('create_budget')),
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
          // Header dengan tombol expand/collapse
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSizes.radiusMedium),
                topRight: Radius.circular(AppSizes.radiusMedium),
              ),
              splashColor: Colors.white.withOpacity(0.1),
              highlightColor: Colors.white.withOpacity(0.05),
              onTap: () {
                setState(() {
                  _isStatisticsExpanded = !_isStatisticsExpanded;
                });

                if (_isStatisticsExpanded) {
                  _animationController.forward();
                } else {
                  _animationController.reverse();
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.bar_chart,
                          color: Colors.white.withOpacity(0.9),
                          size: 20,
                        ),
                        const SizedBox(width: AppSizes.paddingSmall),
                        Text(
                          context.tr('budget_overview'),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    AnimatedBuilder(
                      animation: _rotationAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotationAnimation.value *
                              3.14159, // Convert to radians
                          child: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content yang bisa di-expand/collapse dengan animasi smooth
          ClipRect(
            child: AnimatedBuilder(
              animation: _expandAnimation,
              builder: (context, child) {
                return Align(
                  alignment: Alignment.topCenter,
                  heightFactor: _expandAnimation.value,
                  child: FadeTransition(
                    opacity: _expandAnimation,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: AppSizes.paddingMedium,
                        right: AppSizes.paddingMedium,
                        bottom: AppSizes.paddingMedium,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: AnimatedBuilder(
                              animation: _expandAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _expandAnimation.value,
                                  child: _buildStatItem(
                                    context.tr('total_budget'),
                                    'Rp ${_formatNumber(totalBudget)}',
                                    Icons.pie_chart,
                                  ),
                                );
                              },
                            ),
                          ),
                          Expanded(
                            child: AnimatedBuilder(
                              animation: _expandAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _expandAnimation.value,
                                  child: _buildStatItem(
                                    context.tr('average_usage'),
                                    '${averageUsage.toStringAsFixed(0)}%',
                                    Icons.trending_up,
                                  ),
                                );
                              },
                            ),
                          ),
                          Expanded(
                            child: AnimatedBuilder(
                              animation: _expandAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _expandAnimation.value,
                                  child: _buildStatItem(
                                    context.tr('exceeded_budgets'),
                                    '$exceededCount Budget',
                                    Icons.warning,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMedium,
        vertical: AppSizes.paddingSmall, // Mengurangi padding vertikal
      ),
      child: Row(
        children: [
          Text(
            context.tr('filter_colon'),
            style: const TextStyle(fontSize: 12), // Font lebih kecil
          ),
          const SizedBox(width: AppSizes.paddingSmall),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', context.tr('all_periods')),
                  _buildFilterChip('daily', context.tr('budget_period_daily')),
                  _buildFilterChip(
                      'weekly', context.tr('budget_period_weekly')),
                  _buildFilterChip(
                      'monthly', context.tr('budget_period_monthly')),
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
        label: Text(
          label,
          style: const TextStyle(fontSize: 12), // Font lebih kecil
        ),
        selected: isSelected,
        materialTapTargetSize:
            MaterialTapTargetSize.shrinkWrap, // Mengurangi tap target
        visualDensity: VisualDensity.compact, // Density yang lebih kompak
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
                              category?.name ?? context.tr('unknown_category'),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${context.tr('used')}: ${userSettings.formatCurrency(budget.spent)}',
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
                            '${context.tr('budgets')}: ${userSettings.formatCurrency(budget.amount)}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.6),
                                    ),
                          ),
                          Text(
                            '${context.tr('remaining')}: ${userSettings.formatCurrency(budget.remaining)}',
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
        return context.tr('budget_status_exceeded');
      case 'full':
        return context.tr('budget_status_full');
      case 'warning':
        return context.tr('budget_status_warning');
      default:
        return context.tr('budget_status_normal');
    }
  }

  String _getPeriodText(BudgetModel budget) {
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
    BudgetDetailsSheet.show(
      context,
      budget,
      showNavigationActions: false,
      onEdit: () => _editBudget(context, budget),
      onDelete: () => _deleteBudget(context, budget),
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
    DeleteBudgetDialog.show(context, budget);
  }
}

// Custom SliverPersistentHeaderDelegate untuk filter yang sticky
class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _FilterHeaderDelegate({required this.child});

  @override
  double get minExtent => 45; // Tinggi minimum yang lebih kecil

  @override
  double get maxExtent =>
      45; // Tinggi maksimum (sama dengan minimum untuk fixed height)

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
