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
  final _formKey = GlobalKey<FormState>();

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
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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

          // Tab bar
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                icon: const Icon(Icons.remove_circle),
                text: 'Pengeluaran',
              ),
              Tab(
                icon: const Icon(Icons.add_circle),
                text: 'Pemasukan',
              ),
            ],
          ),

          // Tab content
          Flexible(
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
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount field
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                labelText: 'Jumlah',
                prefixText: 'Rp ',
                border: const OutlineInputBorder(),
                hintText: '0',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Jumlah tidak boleh kosong';
                }
                if (double.tryParse(value) == null ||
                    double.parse(value) <= 0) {
                  return 'Masukkan jumlah yang valid';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSizes.paddingMedium),

            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi',
                border: OutlineInputBorder(),
                hintText: 'Contoh: Makan siang',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Deskripsi tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSizes.paddingMedium),

            // Category selection
            Consumer<CategoryProvider>(
              builder: (context, categoryProvider, child) {
                final categories = isIncome
                    ? categoryProvider.incomeCategories
                    : categoryProvider.expenseCategories;

                return DropdownButtonFormField<CategoryModel>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    border: OutlineInputBorder(),
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

            // Date selection
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tanggal',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                ),
              ),
            ),
            const SizedBox(height: AppSizes.paddingLarge),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _submitTransaction(context, isIncome),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isIncome ? AppColors.income : AppColors.expense,
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSizes.paddingMedium),
                ),
                child: Text(
                  'Tambah ${isIncome ? 'Pemasukan' : 'Pengeluaran'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitTransaction(BuildContext context, bool isIncome) {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);
      final description = _descriptionController.text;

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

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${isIncome ? 'Pemasukan' : 'Pengeluaran'} berhasil ditambahkan',
          ),
          backgroundColor: isIncome ? AppColors.income : AppColors.expense,
        ),
      );

      // Close the modal
      Navigator.of(context).pop();
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
