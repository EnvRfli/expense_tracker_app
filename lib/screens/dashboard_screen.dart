import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../utils/theme.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/add_transaction_sheet.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import '../l10n/localization_extension.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    final expenseProvider = context.read<ExpenseProvider>();
    final incomeProvider = context.read<IncomeProvider>();
    final budgetProvider = context.read<BudgetProvider>();

    expenseProvider.onExpenseChanged = () async {
      print('=== Expense Changed - Refreshing Budget Data ===');
      await budgetProvider.loadBudgets();
      await budgetProvider.refreshAllBudgetSpentAmounts();
    };

    await Future.wait([
      expenseProvider.loadExpenses(),
      incomeProvider.loadIncomes(),
      budgetProvider.loadBudgets(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          DashboardHomeTab(),
          DashboardTransactionsTab(),
          DashboardBudgetTab(),
          DashboardReportsTab(),
          DashboardSettingsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Transaksi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: 'Budget',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Laporan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0 || _selectedIndex == 1
          ? FloatingActionButton(
              heroTag: "dashboard_fab",
              onPressed: _showAddTransactionBottomSheet,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showAddTransactionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLarge),
        ),
      ),
      builder: (context) => const AddTransactionSheet(),
    );
  }
}

class DashboardHomeTab extends StatelessWidget {
  const DashboardHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await context.read<ExpenseProvider>().loadExpenses();
        await context.read<IncomeProvider>().loadIncomes();
        await context.read<BudgetProvider>().updateBudgetSpentAmounts();
      },
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('halo'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  Text(
                    'Hari ini, ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                ],
              ),
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
            ),
            actions: [
              Consumer<SyncProvider>(
                builder: (context, syncProvider, child) {
                  return IconButton(
                    icon: Stack(
                      children: [
                        const Icon(Icons.cloud_sync),
                        if (syncProvider.pendingItemsCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 12,
                                minHeight: 12,
                              ),
                              child: Text(
                                '${syncProvider.pendingItemsCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: () {
                      // Show sync options
                    },
                  );
                },
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Balance Summary Card
                const BalanceSummaryCard(),

                const SizedBox(height: AppSizes.paddingMedium),

                // Quick Actions
                const QuickActionsCard(),

                const SizedBox(height: AppSizes.paddingMedium),

                // Budget Overview
                const BudgetOverviewCard(),

                const SizedBox(height: AppSizes.paddingMedium),

                // Recent Transactions
                const RecentTransactionsCard(),

                const SizedBox(height: AppSizes.paddingMedium),

                // Spending by Category
                const SpendingByCategoryCard(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardTransactionsTab extends StatelessWidget {
  const DashboardTransactionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: TransactionsList(),
    );
  }
}

class DashboardBudgetTab extends StatelessWidget {
  const DashboardBudgetTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: BudgetList(),
    );
  }
}

class DashboardReportsTab extends StatelessWidget {
  const DashboardReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const ReportsScreen(),
    );
  }
}

class DashboardSettingsTab extends StatelessWidget {
  const DashboardSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsScreen();
  }
}

class AddTransactionBottomSheet extends StatefulWidget {
  const AddTransactionBottomSheet({super.key});

  @override
  State<AddTransactionBottomSheet> createState() =>
      _AddTransactionBottomSheetState();
}

class _AddTransactionBottomSheetState extends State<AddTransactionBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  String _selectedPaymentMethod = 'cash';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLarge),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: AppSizes.paddingSmall),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryColor,
            tabs: const [
              Tab(
                icon: Icon(Icons.remove),
                text: 'Pengeluaran',
              ),
              Tab(
                icon: Icon(Icons.add),
                text: 'Pemasukan',
              ),
            ],
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildExpenseForm(),
                _buildIncomeForm(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseForm() {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Amount Field
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah',
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Masukkan jumlah';
                }
                return null;
              },
            ),

            const SizedBox(height: AppSizes.paddingMedium),

            // Category Dropdown
            Consumer<CategoryProvider>(
              builder: (context, categoryProvider, child) {
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedCategoryId,
                  items: categoryProvider.expenseCategories.map((category) {
                    return DropdownMenuItem(
                      value: category.id,
                      child: Text(category.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Pilih kategori';
                    }
                    return null;
                  },
                );
              },
            ),

            const SizedBox(height: AppSizes.paddingMedium),

            // Description Field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Masukkan deskripsi';
                }
                return null;
              },
            ),

            const Spacer(),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveExpense,
                child: const Text('Simpan Pengeluaran'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeForm() {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Amount Field
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah',
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Masukkan jumlah';
                }
                return null;
              },
            ),

            const SizedBox(height: AppSizes.paddingMedium),

            // Category Dropdown
            Consumer<CategoryProvider>(
              builder: (context, categoryProvider, child) {
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedCategoryId,
                  items: categoryProvider.incomeCategories.map((category) {
                    return DropdownMenuItem(
                      value: category.id,
                      child: Text(category.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Pilih kategori';
                    }
                    return null;
                  },
                );
              },
            ),

            const SizedBox(height: AppSizes.paddingMedium),

            // Description Field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Masukkan deskripsi';
                }
                return null;
              },
            ),

            const Spacer(),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveIncome,
                child: const Text('Simpan Pemasukan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      final expenseProvider = context.read<ExpenseProvider>();

      final success = await expenseProvider.addExpense(
        amount: double.parse(_amountController.text),
        categoryId: _selectedCategoryId!,
        description: _descriptionController.text,
        date: _selectedDate,
        paymentMethod: _selectedPaymentMethod,
      );

      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengeluaran berhasil disimpan')),
        );
      }
    }
  }

  Future<void> _saveIncome() async {
    if (_formKey.currentState!.validate()) {
      final incomeProvider = context.read<IncomeProvider>();

      final success = await incomeProvider.addIncome(
        amount: double.parse(_amountController.text),
        categoryId: _selectedCategoryId!,
        description: _descriptionController.text,
        date: _selectedDate,
        source: 'Manual Entry',
      );

      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pemasukan berhasil disimpan')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
