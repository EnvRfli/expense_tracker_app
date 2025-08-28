import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/providers.dart';
import '../models/models.dart';
import '../utils/theme.dart';
import '../services/image_picker_service.dart';
import '../l10n/localization_extension.dart';
import '../widgets/localized_category_name.dart';

// Custom formatter untuk format ribuan dengan koma
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove all non-digit characters
    String newText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // If empty, return empty
    if (newText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Format with thousand separators
    String formattedText = _addThousandSeparator(newText);

    // Calculate cursor position
    int selectionIndex = formattedText.length;
    if (newValue.selection.end < newValue.text.length) {
      // If cursor is not at the end, try to maintain relative position
      int originalCursorPos = newValue.selection.end;
      int separatorsBeforeCursor =
          ','.allMatches(newValue.text.substring(0, originalCursorPos)).length;
      int newSeparatorsBeforeCursor =
          ','.allMatches(formattedText.substring(0, originalCursorPos)).length;
      selectionIndex = originalCursorPos +
          (newSeparatorsBeforeCursor - separatorsBeforeCursor);
      selectionIndex = selectionIndex.clamp(0, formattedText.length);
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }

  String _addThousandSeparator(String value) {
    if (value.length <= 3) return value;

    String result = '';
    int counter = 0;

    for (int i = value.length - 1; i >= 0; i--) {
      if (counter == 3) {
        result = ',$result';
        counter = 0;
      }
      result = value[i] + result;
      counter++;
    }

    return result;
  }
}

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
  final _locationController = TextEditingController();
  final _sourceController = TextEditingController();
  CategoryModel? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  String _selectedPaymentMethod = 'cash';
  String? _receiptPhotoPath;

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
          _locationController.clear();
          _sourceController.clear();
          _selectedCategory = null;
          _selectedDate = DateTime.now();
          _selectedPaymentMethod = 'cash';
          _receiptPhotoPath = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _sourceController.dispose();
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
                  context.tr('add_transaction'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('add_transaction_desc'),
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
                      Text(context.tr('expense')),
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
                      Text(context.tr('income')),
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
                _buildTransactionForm(context, false),
                _buildTransactionForm(context, true),
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

            // Additional fields for expense
            if (!isIncome) ...[
              const SizedBox(height: AppSizes.paddingMedium),
              _buildPaymentMethodCard(),
              const SizedBox(height: AppSizes.paddingMedium),
              _buildLocationCard(),
              const SizedBox(height: AppSizes.paddingMedium),
              _buildPhotoCard(),
            ],

            // Source field for income
            if (isIncome) ...[
              const SizedBox(height: AppSizes.paddingMedium),
              _buildSourceCard(),
            ],

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
                context.tr(isIncome ? 'income_amount' : 'expense_amount'),
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
              ThousandsSeparatorInputFormatter(),
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
                return context.tr('amount_is_required');
              }
              // Remove commas for validation
              String cleanValue = value.replaceAll(',', '');
              if (double.tryParse(cleanValue) == null ||
                  double.parse(cleanValue) <= 0) {
                return context.tr('valid_amount_required');
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
                context.tr('description'),
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
              hintText: context.tr('example_description'),
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
                return context.tr('description_is_required');
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
                context.tr('category'),
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
                decoration: InputDecoration(
                  hintText: context.tr('select_category'),
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
                    child: LocalizedCategoryName(category: category),
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
                    return context.tr('select_category');
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
                  context.tr('date'),
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

  Widget _buildPaymentMethodCard() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.warning.withOpacity(0.2),
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
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.payment,
                  color: AppColors.warning,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                context.tr('payment_method'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedPaymentMethod,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 4),
            ),
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.warning,
            ),
            items: [
              DropdownMenuItem(value: 'cash', child: Text(context.tr('cash'))),
              DropdownMenuItem(
                  value: 'card', child: Text(context.tr('credit_card'))),
              DropdownMenuItem(
                  value: 'transfer', child: Text(context.tr('bank_transfer'))),
              DropdownMenuItem(value: 'ewallet', child: Text('E-Wallet')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedPaymentMethod = value!;
              });
              HapticFeedback.selectionClick();
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return context.tr('select_payment_method');
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
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
                  Icons.location_on,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                context.tr('location_optional'),
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
            controller: _locationController,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: context.tr('location_example'),
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                fontSize: 14,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard() {
    return Container(
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
                  Icons.camera_alt,
                  color: AppColors.info,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                context.tr('receipt_photo'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_receiptPhotoPath != null) ...[
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.info.withOpacity(0.3),
                ),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.file(
                      File(_receiptPhotoPath!),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          color: AppColors.info.withOpacity(0.1),
                          child: Icon(
                            Icons.broken_image,
                            color: AppColors.info,
                            size: 24,
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () async {
                        // Delete image file if it exists
                        if (_receiptPhotoPath != null) {
                          await ImagePickerService.deleteImage(
                              _receiptPhotoPath!);
                        }
                        setState(() {
                          _receiptPhotoPath = null;
                        });
                        HapticFeedback.selectionClick();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          InkWell(
            onTap: () async {
              HapticFeedback.selectionClick();

              // Show image source selection dialog and pick image
              final File? imageFile =
                  await ImagePickerService.showImageSourceDialogAndPick(
                      context);
              if (imageFile != null) {
                setState(() {
                  _receiptPhotoPath = imageFile.path;
                });

                // Show success message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Text(context.tr('success_photo_added')),
                        ],
                      ),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } else {
                // Show error message if image picking failed
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.error, color: Colors.white),
                          SizedBox(width: 8),
                          Text(context.tr('failed_photo_add')),
                        ],
                      ),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.info.withOpacity(0.3),
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    color: AppColors.info,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _receiptPhotoPath != null
                        ? context.tr('change_photo')
                        : context.tr('add_photo'),
                    style: TextStyle(
                      color: AppColors.info,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceCard() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.success.withOpacity(0.2),
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
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.source,
                  color: AppColors.success,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                context.tr('income_source'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _sourceController,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: context.tr('income_source_example'),
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
                return context.tr('income_source_is_required');
              }
              return null;
            },
          ),
        ],
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
                  isIncome
                      ? context.tr('add_income')
                      : context.tr('add_expense'),
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
      // Remove commas before parsing
      final cleanAmountText = _amountController.text.replaceAll(',', '');
      final amount = double.parse(cleanAmountText);
      final description = _descriptionController.text;

      // Haptic feedback untuk success
      HapticFeedback.lightImpact();

      if (isIncome) {
        context.read<IncomeProvider>().addIncome(
              amount: amount,
              categoryId: _selectedCategory!.id,
              description: description,
              date: _selectedDate,
              source: _sourceController.text.isNotEmpty
                  ? _sourceController.text
                  : 'Manual Entry',
            );
      } else {
        context.read<ExpenseProvider>().addExpense(
              amount: amount,
              categoryId: _selectedCategory!.id,
              description: description,
              date: _selectedDate,
              location: _locationController.text.isNotEmpty
                  ? _locationController.text
                  : null,
              paymentMethod: _selectedPaymentMethod,
              receiptPhotoPath: _receiptPhotoPath,
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
                  isIncome
                      ? context.tr('success_income_added')
                      : context.tr('success_expense_added'),
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
            context.tr('fast_add'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSizes.paddingLarge),

          // Quick expense buttons
          _buildQuickActionSection(
            context,
            context.tr('quick_general_expense'),
            [
              {
                'name': context.tr('quick_food'),
                'icon': Icons.restaurant,
                'color': Colors.orange
              },
              {
                'name': context.tr('quick_transport'),
                'icon': Icons.directions_car,
                'color': Colors.blue
              },
              {
                'name': context.tr('category_shopping'),
                'icon': Icons.shopping_cart,
                'color': Colors.green
              },
              {
                'name': context.tr('category_entertainment'),
                'icon': Icons.movie,
                'color': Colors.purple
              },
            ],
            false,
          ),

          const SizedBox(height: AppSizes.paddingLarge),

          // Quick income buttons
          _buildQuickActionSection(
            context,
            context.tr('quick_general_income'),
            [
              {
                'name': context.tr('category_salary'),
                'icon': Icons.work,
                'color': Colors.teal
              },
              {
                'name': context.tr('category_bonus'),
                'icon': Icons.card_giftcard,
                'color': Colors.amber
              },
              {
                'name': context.tr('category_investment'),
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
              label: Text(context.tr('custom_transaction')),
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
        title: Text(
            isIncome ? context.tr('add_income') : context.tr('add_expense')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Category: $category'),
            const SizedBox(height: AppSizes.paddingMedium),
            TextFormField(
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: context.tr('total'),
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
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              if (amountController.text.isNotEmpty) {
                // Add quick transaction logic here
                Navigator.of(context).pop();
                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '$category' + ' ' + context.tr('successfully_added')),
                    backgroundColor:
                        isIncome ? AppColors.income : AppColors.expense,
                  ),
                );
              }
            },
            child: Text(context.tr('save')),
          ),
        ],
      ),
    );
  }
}
