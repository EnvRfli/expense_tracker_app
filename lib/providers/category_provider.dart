import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'base_provider.dart';

class CategoryProvider extends BaseProvider {
  final _uuid = const Uuid();
  List<CategoryModel> _categories = [];
  CategoryModel? _selectedCategory;

  List<CategoryModel> get categories => _categories;
  List<CategoryModel> get expenseCategories => _categories
      .where((cat) => cat.type == 'expense' && cat.isActive)
      .toList();
  List<CategoryModel> get incomeCategories =>
      _categories.where((cat) => cat.type == 'income' && cat.isActive).toList();
  CategoryModel? get selectedCategory => _selectedCategory;

  // Initialize provider
  Future<void> initialize() async {
    await loadCategories();
  }

  // Load all categories
  Future<void> loadCategories() async {
    await handleAsync(() async {
      _categories = DatabaseService.instance.categories.values.toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
    });
  }

  // Add new category
  Future<bool> addCategory({
    required String name,
    required String type,
    required String iconCodePoint,
    required String colorValue,
  }) async {
    final result = await handleAsync(() async {
      final now = DateTime.now();
      final category = CategoryModel(
        id: _uuid.v4(),
        name: name,
        type: type,
        iconCodePoint: iconCodePoint,
        colorValue: colorValue,
        createdAt: now,
        updatedAt: now,
      );

      // Save to database
      await DatabaseService.instance.categories.put(category.id, category);

      // Track change for sync
      await SyncService.instance.trackChange(
        dataType: 'category',
        dataId: category.id,
        action: SyncAction.create,
        dataSnapshot: category.toJson(),
      );

      // Reload categories
      await loadCategories();

      return true;
    });

    return result ?? false;
  }

  // Update category
  Future<bool> updateCategory({
    required String id,
    String? name,
    String? type,
    String? iconCodePoint,
    String? colorValue,
    bool? isActive,
  }) async {
    final result = await handleAsync(() async {
      final existingCategory = DatabaseService.instance.categories.get(id);
      if (existingCategory == null) {
        throw Exception('Category not found');
      }

      // Don't allow deactivating default categories
      if (existingCategory.isDefault && isActive == false) {
        throw Exception('Cannot deactivate default category');
      }

      final updatedCategory = existingCategory.copyWith(
        name: name,
        type: type,
        iconCodePoint: iconCodePoint,
        colorValue: colorValue,
        isActive: isActive,
        updatedAt: DateTime.now(),
      );

      // Save to database
      await DatabaseService.instance.categories.put(id, updatedCategory);

      // Track change for sync
      await SyncService.instance.trackChange(
        dataType: 'category',
        dataId: id,
        action: SyncAction.update,
        dataSnapshot: updatedCategory.toJson(),
      );

      // Reload categories
      await loadCategories();

      return true;
    });

    return result ?? false;
  }

  // Delete category (soft delete for default categories)
  Future<bool> deleteCategory(String id) async {
    final result = await handleAsync(() async {
      final category = DatabaseService.instance.categories.get(id);
      if (category == null) {
        throw Exception('Category not found');
      }

      // Check if category is being used
      final expenseCount = DatabaseService.instance.expenses.values
          .where((expense) => expense.categoryId == id)
          .length;

      final incomeCount = DatabaseService.instance.incomes.values
          .where((income) => income.categoryId == id)
          .length;

      final budgetCount = DatabaseService.instance.budgets.values
          .where((budget) => budget.categoryId == id)
          .length;

      if (expenseCount > 0 || incomeCount > 0 || budgetCount > 0) {
        throw Exception('Cannot delete category that is being used');
      }

      if (category.isDefault) {
        // Soft delete for default categories
        final updatedCategory = category.copyWith(
          isActive: false,
          updatedAt: DateTime.now(),
        );
        await DatabaseService.instance.categories.put(id, updatedCategory);
      } else {
        // Hard delete for custom categories
        await DatabaseService.instance.categories.delete(id);
      }

      // Track change for sync
      await SyncService.instance.trackChange(
        dataType: 'category',
        dataId: id,
        action: SyncAction.delete,
        dataSnapshot: category.toJson(),
      );

      // Reload categories
      await loadCategories();

      return true;
    });

    return result ?? false;
  }

  // Get category by ID
  CategoryModel? getCategoryById(String id) {
    return _categories.firstWhere(
      (category) => category.id == id,
      orElse: () => CategoryModel(
        id: 'unknown',
        name: 'Unknown',
        type: 'expense',
        iconCodePoint: '0xe5c3',
        colorValue: '#757575',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  // Get categories by type
  List<CategoryModel> getCategoriesByType(String type) {
    return _categories
        .where((category) => category.type == type && category.isActive)
        .toList();
  }

  // Set selected category
  void setSelectedCategory(CategoryModel? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // Search categories
  List<CategoryModel> searchCategories(String query) {
    if (query.isEmpty) return _categories;

    final lowercaseQuery = query.toLowerCase();
    return _categories.where((category) {
      return category.name.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Get category usage statistics
  Map<String, dynamic> getCategoryUsageStats(String categoryId) {
    final category = getCategoryById(categoryId);
    if (category == null) return {};

    final expenses = DatabaseService.instance.expenses.values
        .where((expense) => expense.categoryId == categoryId)
        .toList();

    final incomes = DatabaseService.instance.incomes.values
        .where((income) => income.categoryId == categoryId)
        .toList();

    final totalExpenses =
        expenses.fold(0.0, (sum, expense) => sum + expense.amount);
    final totalIncomes =
        incomes.fold(0.0, (sum, income) => sum + income.amount);

    // Get current month stats
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final monthlyExpenses = expenses
        .where((expense) =>
            expense.date
                .isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
            expense.date.isBefore(endOfMonth.add(const Duration(days: 1))))
        .toList();

    final monthlyIncomes = incomes
        .where((income) =>
            income.date
                .isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
            income.date.isBefore(endOfMonth.add(const Duration(days: 1))))
        .toList();

    final monthlyExpensesTotal =
        monthlyExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
    final monthlyIncomesTotal =
        monthlyIncomes.fold(0.0, (sum, income) => sum + income.amount);

    return {
      'categoryId': categoryId,
      'categoryName': category.name,
      'categoryType': category.type,
      'totalTransactions': expenses.length + incomes.length,
      'totalExpenses': totalExpenses,
      'totalIncomes': totalIncomes,
      'expenseCount': expenses.length,
      'incomeCount': incomes.length,
      'monthlyExpenses': monthlyExpensesTotal,
      'monthlyIncomes': monthlyIncomesTotal,
      'monthlyExpenseCount': monthlyExpenses.length,
      'monthlyIncomeCount': monthlyIncomes.length,
      'averageExpenseAmount':
          expenses.isNotEmpty ? totalExpenses / expenses.length : 0.0,
      'averageIncomeAmount':
          incomes.isNotEmpty ? totalIncomes / incomes.length : 0.0,
    };
  }

  // Get all categories usage stats
  List<Map<String, dynamic>> getAllCategoriesUsageStats() {
    return _categories
        .map((category) => getCategoryUsageStats(category.id))
        .toList();
  }

  // Check if category name already exists
  bool isCategoryNameExists(String name, {String? excludeId}) {
    return _categories.any((category) =>
        category.name.toLowerCase() == name.toLowerCase() &&
        category.id != excludeId);
  }

  // Get most used categories
  List<CategoryModel> getMostUsedCategories({int limit = 5}) {
    final stats = getAllCategoriesUsageStats();
    stats.sort((a, b) => (b['totalTransactions'] as int)
        .compareTo(a['totalTransactions'] as int));

    final topCategoryIds =
        stats.take(limit).map((stat) => stat['categoryId'] as String).toList();
    return _categories
        .where((category) => topCategoryIds.contains(category.id))
        .toList();
  }

  // Restore default categories
  Future<bool> restoreDefaultCategories() async {
    final result = await handleAsync(() async {
      // This would recreate the default categories
      // You can implement the logic to restore deleted default categories
      await loadCategories();
      return true;
    });

    return result ?? false;
  }
}
