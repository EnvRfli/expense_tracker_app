import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../utils/theme.dart';

class AddTransactionSheet extends StatefulWidget {
  final int initialTabIndex;

  const AddTransactionSheet({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _expenseFormKey = GlobalKey<FormState>();
  final _incomeFormKey = GlobalKey<FormState>();

  // Form fields
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  CategoryModel? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );

    // Reset form when switching tabs
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _amountController.clear();
          _descriptionController.clear();
          _selectedCategory = null;
          _selectedDate = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLarge),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header dengan gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingLarge,
              vertical: AppSizes.paddingMedium,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor.withOpacity(0.1),
                  AppTheme.primaryColor.withOpacity(0.05),
                ],
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Tambah Transaksi',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Catat keuangan Anda dengan mudah',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                ),
              ],
            ),
          ),

          // Tab bar dengan custom design
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingLarge,
              vertical: AppSizes.paddingMedium,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorPadding: const EdgeInsets.all(2),
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor:
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              tabs: [
                Tab(
                  height: 45,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.remove_circle, size: 18),
                      const SizedBox(width: 6),
                      Text('Pengeluaran'),
                    ],
                  ),
                ),
                Tab(
                  height: 45,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle, size: 18),
                      const SizedBox(width: 6),
                      Text('Pemasukan'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTransactionForm(context, false), // Expense
                _buildTransactionForm(context, true), // Income
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionForm(BuildContext context, bool isIncome) {
    return Form(
      key: isIncome ? _incomeFormKey : _expenseFormKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingLarge,
          vertical: AppSizes.paddingMedium,
        ),
        child: Column(
          children: [
            // Amount field dengan design card
            _buildAmountCard(isIncome),
            const SizedBox(height: AppSizes.paddingMedium),

            // Description field
            _buildDescriptionCard(),
            const SizedBox(height: AppSizes.paddingMedium),

            // Category selection
            _buildCategoryCard(isIncome),
            const SizedBox(height: AppSizes.paddingMedium),

            // Date selection
            _buildDateCard(),
            const SizedBox(height: AppSizes.paddingLarge),

            // Submit button dengan animasi
            _buildSubmitButton(context, isIncome),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCard(bool isIncome) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color:
            (isIncome ? AppColors.income : AppColors.expense).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isIncome ? AppColors.income : AppColors.expense)
              .withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (isIncome ? AppColors.income : AppColors.expense)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.attach_money,
                  color: isIncome ? AppColors.income : AppColors.expense,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Jumlah ${isIncome ? 'Pemasukan' : 'Pengeluaran'}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isIncome ? AppColors.income : AppColors.expense,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                fontSize: 16,
              ),
              prefixText: 'Rp ',
              prefixStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Jumlah tidak boleh kosong';
              }
              if (double.tryParse(value) == null || double.parse(value) <= 0) {
                return 'Masukkan jumlah yang valid';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.description,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Deskripsi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descriptionController,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'Contoh: Makan siang di restoran',
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                fontSize: 14,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Deskripsi tidak boleh kosong';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(bool isIncome) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.category,
                  color: AppTheme.primaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Kategori',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Consumer<CategoryProvider>(
            builder: (context, categoryProvider, child) {
              final categories = isIncome
                  ? categoryProvider.incomeCategories
                  : categoryProvider.expenseCategories;

              // Reset selected category if it's not in the current list
              if (_selectedCategory != null &&
                  !categories.any((cat) => cat.id == _selectedCategory!.id)) {
                _selectedCategory = null;
              }

              return DropdownButtonFormField<CategoryModel>(
                value: _selectedCategory,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: const InputDecoration(
                  hintText: 'Pilih kategori',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 4),
                ),
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: AppTheme.primaryColor,
                ),
                items: categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                  // Haptic feedback
                  HapticFeedback.selectionClick();
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
        ],
      ),
    );
  }

  Widget _buildDateCard() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        decoration: BoxDecoration(
          color: AppColors.info.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.info.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: AppColors.info,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Tanggal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.info,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.edit,
                  color: AppColors.info.withOpacity(0.6),
                  size: 14,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context, bool isIncome) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isIncome
              ? [AppColors.income, AppColors.income.withOpacity(0.8)]
              : [AppColors.expense, AppColors.expense.withOpacity(0.8)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isIncome ? AppColors.income : AppColors.expense)
                .withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            _submitTransaction(context, isIncome);
          },
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isIncome ? Icons.add_circle : Icons.remove_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tambah ${isIncome ? 'Pemasukan' : 'Pengeluaran'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    // Haptic feedback saat membuka date picker
    HapticFeedback.selectionClick();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.primaryColor,
                  onPrimary: Colors.white,
                  surface: Theme.of(context).colorScheme.surface,
                  onSurface: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      // Haptic feedback saat tanggal berubah
      HapticFeedback.lightImpact();
    }
  }

  void _submitTransaction(BuildContext context, bool isIncome) {
    final formKey = isIncome ? _incomeFormKey : _expenseFormKey;

    if (formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);
      final description = _descriptionController.text;

      // Haptic feedback untuk success
      HapticFeedback.lightImpact();

      if (isIncome) {
        context.read<IncomeProvider>().addIncome(
              amount: amount,
              categoryId: _selectedCategory!.id,
              description: description,
              date: _selectedDate,
              source: 'Manual Entry',
            );
      } else {
        context.read<ExpenseProvider>().addExpense(
              amount: amount,
              categoryId: _selectedCategory!.id,
              description: description,
              date: _selectedDate,
            );
      }

      // Show success message with animation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isIncome ? Icons.check_circle : Icons.check_circle,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${isIncome ? 'Pemasukan' : 'Pengeluaran'} berhasil ditambahkan',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: isIncome ? AppColors.income : AppColors.expense,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );

      // Close the modal dengan delay sedikit untuk UX yang lebih smooth
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    } else {
      // Haptic feedback untuk error
      HapticFeedback.heavyImpact();
    }
  }
}

// Quick add buttons for specific categories
class QuickAddSheet extends StatelessWidget {
  const QuickAddSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin:
                const EdgeInsets.symmetric(vertical: AppSizes.paddingMedium),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Text(
            'Tambah Cepat',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSizes.paddingLarge),

          // Quick expense buttons
          _buildQuickActionSection(
            context,
            'Pengeluaran Umum',
            [
              {
                'name': 'Makan',
                'icon': Icons.restaurant,
                'color': Colors.orange
              },
              {
                'name': 'Transport',
                'icon': Icons.directions_car,
                'color': Colors.blue
              },
              {
                'name': 'Belanja',
                'icon': Icons.shopping_cart,
                'color': Colors.green
              },
              {'name': 'Hiburan', 'icon': Icons.movie, 'color': Colors.purple},
            ],
            false,
          ),

          const SizedBox(height: AppSizes.paddingLarge),

          // Quick income buttons
          _buildQuickActionSection(
            context,
            'Pemasukan Umum',
            [
              {'name': 'Gaji', 'icon': Icons.work, 'color': Colors.teal},
              {
                'name': 'Bonus',
                'icon': Icons.card_giftcard,
                'color': Colors.amber
              },
              {
                'name': 'Investasi',
                'icon': Icons.trending_up,
                'color': Colors.indigo
              },
            ],
            true,
          ),

          const SizedBox(height: AppSizes.paddingLarge),

          // Custom transaction button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppSizes.radiusLarge),
                      ),
                    ),
                    child: const AddTransactionSheet(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Transaksi Custom'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionSection(
    BuildContext context,
    String title,
    List<Map<String, dynamic>> actions,
    bool isIncome,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSizes.paddingMedium),
        Wrap(
          spacing: AppSizes.paddingSmall,
          runSpacing: AppSizes.paddingSmall,
          children: actions.map((action) {
            return _buildQuickActionChip(
              context,
              action['name'],
              action['icon'],
              action['color'],
              isIncome,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuickActionChip(
    BuildContext context,
    String name,
    IconData icon,
    Color color,
    bool isIncome,
  ) {
    return InkWell(
      onTap: () => _showQuickAmountDialog(context, name, isIncome),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMedium,
          vertical: AppSizes.paddingSmall,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: AppSizes.iconSmall),
            const SizedBox(width: AppSizes.paddingSmall),
            Text(
              name,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickAmountDialog(
      BuildContext context, String category, bool isIncome) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tambah ${isIncome ? 'Pemasukan' : 'Pengeluaran'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Kategori: $category'),
            const SizedBox(height: AppSizes.paddingMedium),
            TextFormField(
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Jumlah',
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (amountController.text.isNotEmpty) {
                // Add quick transaction logic here
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Close the quick add sheet too

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$category berhasil ditambahkan'),
                    backgroundColor:
                        isIncome ? AppColors.income : AppColors.expense,
                  ),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
