import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../utils/theme.dart';
import '../l10n/localization_extension.dart';

class CategoriesManagementScreen extends StatefulWidget {
  const CategoriesManagementScreen({super.key});

  @override
  State<CategoriesManagementScreen> createState() =>
      _CategoriesManagementScreenState();
}

class _CategoriesManagementScreenState extends State<CategoriesManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: Text(context.tr('manage_categories')),
        foregroundColor: Colors.white,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: context.tr('expense_categories')),
            Tab(text: context.tr('income_categories')),
          ],
        ),
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, categoryProvider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildCategoryList(categoryProvider, 'expense'),
              _buildCategoryList(categoryProvider, 'income'),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryList(CategoryProvider categoryProvider, String type) {
    final categories = categoryProvider.getCategoriesByType(type);

    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('no_categories_found'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('add_category_description'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryTile(category, categoryProvider);
      },
    );
  }

  Widget _buildCategoryTile(
      CategoryModel category, CategoryProvider categoryProvider) {
    final color = Color(int.parse(category.colorValue.startsWith('#')
        ? category.colorValue.replaceFirst('#', '0xFF')
        : category.colorValue));
    final iconData = IconData(
      int.parse(
          category.iconCodePoint.startsWith('0x')
              ? category.iconCodePoint.substring(2)
              : category.iconCodePoint,
          radix: 16),
      fontFamily: 'MaterialIcons',
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            iconData,
            color: color,
            size: 24,
          ),
        ),
        title: Text(
          category.isDefault
              ? context.getDefaultCategoryName(category.name)
              : category.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category.type == 'expense'
                  ? context.tr('expense')
                  : context.tr('income'),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            if (category.isDefault)
              Text(
                context.tr('default_category'),
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        trailing: category.isDefault
            ? Icon(Icons.lock, color: Colors.grey[400], size: 20)
            : PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showEditCategoryDialog(category);
                      break;
                    case 'delete':
                      _showDeleteConfirmation(category, categoryProvider);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit, size: 20),
                        const SizedBox(width: 8),
                        Text(context.tr('edit')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Text(context.tr('delete'),
                            style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
        onTap:
            category.isDefault ? null : () => _showEditCategoryDialog(category),
      ),
    );
  }

  void _showAddCategoryDialog() {
    final currentIndex = _tabController.index;
    final type = currentIndex == 0 ? 'expense' : 'income';

    showDialog(
      context: context,
      builder: (context) => CategoryFormDialog(
        title: context.tr('add_category'),
        categoryType: type,
      ),
    );
  }

  void _showEditCategoryDialog(CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => CategoryFormDialog(
        title: context.tr('edit_category'),
        category: category,
        categoryType: category.type,
      ),
    );
  }

  void _showDeleteConfirmation(
      CategoryModel category, CategoryProvider categoryProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('delete_category')),
        content: Text(
          context.tr('delete_category_confirmation',
              params: {'name': category.name}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final success =
                  await categoryProvider.deleteCategory(category.id);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? context.tr('category_deleted_success')
                          : context.tr('category_delete_failed'),
                    ),
                    backgroundColor:
                        success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
  }
}

class CategoryFormDialog extends StatefulWidget {
  final String title;
  final String categoryType;
  final CategoryModel? category;

  const CategoryFormDialog({
    super.key,
    required this.title,
    required this.categoryType,
    this.category,
  });

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  Color _selectedColor = AppColors.categoryColors[0];
  IconData _selectedIcon = Icons.category;
  bool _isLoading = false;

  final List<IconData> _availableIcons = [
    // Expense icons
    Icons.restaurant,
    Icons.local_taxi,
    Icons.shopping_cart,
    Icons.movie,
    Icons.local_hospital,
    Icons.receipt_long,
    Icons.home,
    Icons.school,
    Icons.fitness_center,
    Icons.pets,
    Icons.local_gas_station,
    Icons.phone,
    Icons.wifi,
    Icons.electrical_services,
    Icons.water_drop,
    Icons.checkroom,
    Icons.spa,
    Icons.flight,
    Icons.hotel,
    Icons.local_cafe,
    // Income icons
    Icons.work,
    Icons.business,
    Icons.trending_up,
    Icons.card_giftcard,
    Icons.savings,
    Icons.account_balance,
    Icons.monetization_on,
    Icons.payment,
    Icons.star,
    Icons.celebration,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _selectedColor = Color(int.parse(
          widget.category!.colorValue.startsWith('#')
              ? widget.category!.colorValue.replaceFirst('#', '0xFF')
              : widget.category!.colorValue));
      _selectedIcon = IconData(
        int.parse(
            widget.category!.iconCodePoint.startsWith('0x')
                ? widget.category!.iconCodePoint.substring(2)
                : widget.category!.iconCodePoint,
            radix: 16),
        fontFamily: 'MaterialIcons',
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: context.tr('category_name'),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.tr('category_name_required');
                  }

                  final categoryProvider =
                      Provider.of<CategoryProvider>(context, listen: false);
                  if (categoryProvider.isCategoryNameExists(value.trim(),
                      excludeId: widget.category?.id)) {
                    return context.tr('category_name_exists');
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Color Selection
              Text(
                context.tr('select_color'),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppColors.categoryColors.map((color) {
                  final isSelected = color.value == _selectedColor.value;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.grey[300]!,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Icon Selection
              Text(
                context.tr('select_icon'),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Container(
                height: 200,
                width: double.maxFinite,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _availableIcons.length,
                  itemBuilder: (context, index) {
                    final icon = _availableIcons[index];
                    final isSelected =
                        icon.codePoint == _selectedIcon.codePoint;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedIcon = icon),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _selectedColor.withOpacity(0.2)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                isSelected ? _selectedColor : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: isSelected ? _selectedColor : Colors.grey[600],
                          size: 24,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Preview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _selectedColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _selectedIcon,
                        color: _selectedColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nameController.text.isEmpty
                                ? context.tr('category_name')
                                : _nameController.text,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            widget.categoryType == 'expense'
                                ? context.tr('expense')
                                : context.tr('income'),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(context.tr('cancel')),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveCategory,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.tr('save')),
        ),
      ],
    );
  }

  void _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final categoryProvider =
          Provider.of<CategoryProvider>(context, listen: false);
      final name = _nameController.text.trim();
      final colorValue =
          '#${_selectedColor.value.toRadixString(16).substring(2).toUpperCase()}';
      final iconCodePoint =
          _selectedIcon.codePoint.toRadixString(16).toUpperCase();

      bool success;
      if (widget.category != null) {
        // Update existing category
        success = await categoryProvider.updateCategory(
          id: widget.category!.id,
          name: name,
          iconCodePoint: iconCodePoint,
          colorValue: colorValue,
        );
      } else {
        // Add new category
        success = await categoryProvider.addCategory(
          name: name,
          type: widget.categoryType,
          iconCodePoint: iconCodePoint,
          colorValue: colorValue,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? (widget.category != null
                      ? context.tr('category_updated_success')
                      : context.tr('category_added_success'))
                  : context.tr('category_save_failed'),
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('category_save_error')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
