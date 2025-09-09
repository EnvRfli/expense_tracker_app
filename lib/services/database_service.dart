import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();
  DatabaseService._();

  static const String expenseBox = 'expenses';
  static const String incomeBox = 'incomes';
  static const String categoryBox = 'categories';
  static const String userBox = 'user';
  static const String budgetBox = 'budgets';
  static const String transactionBox = 'transactions';
  static const String syncBox = 'sync_data';
  static const String paymentMethodBox = 'payment_methods';

  late Box<ExpenseModel> _expenseBox;
  late Box<IncomeModel> _incomeBox;
  late Box<CategoryModel> _categoryBox;
  late Box<UserModel> _userBox;
  late Box<BudgetModel> _budgetBox;
  late Box<TransactionModel> _transactionBox;
  late Box<SyncDataModel> _syncBox;
  late Box<PaymentMethodModel> _paymentMethodBox;

  Box<ExpenseModel> get expenses => _expenseBox;
  Box<IncomeModel> get incomes => _incomeBox;
  Box<CategoryModel> get categories => _categoryBox;
  Box<UserModel> get user => _userBox;
  Box<BudgetModel> get budgets => _budgetBox;
  Box<TransactionModel> get transactions => _transactionBox;
  Box<SyncDataModel> get syncData => _syncBox;
  Box<PaymentMethodModel> get paymentMethods => _paymentMethodBox;

  Future<void> initialize() async {
    await Hive.initFlutter();

    Hive.registerAdapter(ExpenseModelAdapter());
    Hive.registerAdapter(IncomeModelAdapter());
    Hive.registerAdapter(CategoryModelAdapter());
    Hive.registerAdapter(UserModelAdapter());
    Hive.registerAdapter(BudgetModelAdapter());
    Hive.registerAdapter(TransactionModelAdapter());
    Hive.registerAdapter(SyncDataModelAdapter());
    Hive.registerAdapter(PaymentMethodModelAdapter());

    _expenseBox = await Hive.openBox<ExpenseModel>(expenseBox);
    _incomeBox = await Hive.openBox<IncomeModel>(incomeBox);
    _categoryBox = await Hive.openBox<CategoryModel>(categoryBox);
    _userBox = await Hive.openBox<UserModel>(userBox);
    _budgetBox = await Hive.openBox<BudgetModel>(budgetBox);
    _transactionBox = await Hive.openBox<TransactionModel>(transactionBox);
    _syncBox = await Hive.openBox<SyncDataModel>(syncBox);
    _paymentMethodBox =
        await Hive.openBox<PaymentMethodModel>(paymentMethodBox);

    await _initializeDefaultData();
  }

  Future<void> _initializeDefaultData() async {
    if (_userBox.isEmpty) {
      final defaultUser = UserModel(
        id: 'default_user',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _userBox.put('default_user', defaultUser);
    }

    if (_categoryBox.isEmpty) {
      await _createDefaultCategories();
    } else {
      await migrateCategoryNamesToLocalizationKeys();
    }
  }

  Future<void> _createDefaultCategories() async {
    final defaultCategories = [
      CategoryModel(
        id: 'exp_food',
        name: 'category_food_drink', // Using localization key
        type: 'expense',
        iconCodePoint: '0xe57d', // Icons.restaurant
        colorValue: '#FF5722',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDefault: true,
      ),
      CategoryModel(
        id: 'exp_transport',
        name: 'category_transportation', // Using localization key
        type: 'expense',
        iconCodePoint: '0xe1a5', // Icons.directions_car
        colorValue: '#2196F3',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDefault: true,
      ),
      CategoryModel(
        id: 'exp_shopping',
        name: 'category_shopping', // Using localization key
        type: 'expense',
        iconCodePoint: '0xe59c', // Icons.shopping_cart
        colorValue: '#E91E63',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDefault: true,
      ),
      CategoryModel(
        id: 'exp_entertainment',
        name: 'category_entertainment', // Using localization key
        type: 'expense',
        iconCodePoint: '0xe5d2', // Icons.movie
        colorValue: '#9C27B0',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDefault: true,
      ),
      CategoryModel(
        id: 'exp_health',
        name: 'category_health', // Using localization key
        type: 'expense',
        iconCodePoint: '0xe571', // Icons.local_hospital
        colorValue: '#4CAF50',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDefault: true,
      ),
      CategoryModel(
        id: 'exp_bills',
        name: 'category_bills', // Using localization key
        type: 'expense',
        iconCodePoint: '0xe8e7', // Icons.receipt_long
        colorValue: '#FF9800',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDefault: true,
      ),
      CategoryModel(
        id: 'inc_salary',
        name: 'category_salary', // Using localization key
        type: 'income',
        iconCodePoint: '0xe8e8', // Icons.work
        colorValue: '#4CAF50',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDefault: true,
      ),
      CategoryModel(
        id: 'inc_freelance',
        name: 'category_freelance', // Using localization key
        type: 'income',
        iconCodePoint: '0xe3b6', // Icons.laptop_mac
        colorValue: '#00BCD4',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDefault: true,
      ),
      CategoryModel(
        id: 'inc_investment',
        name: 'category_investment', // Using localization key
        type: 'income',
        iconCodePoint: '0xe227', // Icons.trending_up
        colorValue: '#8BC34A',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDefault: true,
      ),
      CategoryModel(
        id: 'inc_other',
        name: 'category_other_income', // Using localization key
        type: 'income',
        iconCodePoint: '0xe83a', // Icons.more_horiz
        colorValue: '#607D8B',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDefault: true,
      ),
    ];

    for (final category in defaultCategories) {
      await _categoryBox.put(category.id, category);
    }
  }

  Future<void> migrateCategoryNamesToLocalizationKeys() async {
    final categoryMigrationMap = {
      'Makanan & Minuman': 'category_food_drink',
      'Transportasi': 'category_transportation',
      'Belanja': 'category_shopping',
      'Hiburan': 'category_entertainment',
      'Kesehatan': 'category_health',
      'Tagihan': 'category_bills',
      'Gaji': 'category_salary',
      'Freelance': 'category_freelance',
      'Investasi': 'category_investment',
      'Lainnya': 'category_other_income',
    };

    final allCategories = _categoryBox.values.toList();

    for (final category in allCategories) {
      if (category.isDefault &&
          categoryMigrationMap.containsKey(category.name)) {
        final updatedCategory = category.copyWith(
          name: categoryMigrationMap[category.name]!,
          updatedAt: DateTime.now(),
        );

        await _categoryBox.put(category.id, updatedCategory);
      }
    }
  }

  Future<void> close() async {
    await _expenseBox.close();
    await _incomeBox.close();
    await _categoryBox.close();
    await _userBox.close();
    await _budgetBox.close();
    await _transactionBox.close();
    await _syncBox.close();
    await _paymentMethodBox.close();
  }

  Future<void> clearAllData() async {
    await _expenseBox.clear();
    await _incomeBox.clear();
    await _categoryBox.clear();
    await _userBox.clear();
    await _budgetBox.clear();
    await _transactionBox.clear();
    await _syncBox.clear();
    await _paymentMethodBox.clear();

    await _initializeDefaultData();
  }

  UserModel? getCurrentUser() {
    return _userBox.get('default_user');
  }

  Future<void> updateUser(UserModel user) async {
    await _userBox.put('default_user', user);
  }
}
