import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/theme.dart';
import '../services/image_picker_service.dart';
import '../l10n/localization_extension.dart';
import '../widgets/localized_category_name.dart';

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

class EditTransactionSheet extends StatefulWidget {
  final String transactionId;
  final bool isExpense;

  const EditTransactionSheet({
    super.key,
    required this.transactionId,
    required this.isExpense,
  });

  @override
  State<EditTransactionSheet> createState() => _EditTransactionSheetState();
}

class _EditTransactionSheetState extends State<EditTransactionSheet>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Form fields
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _sourceController = TextEditingController();
  CategoryModel? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  String _selectedPaymentMethod = 'cash';
  String? _receiptPhotoPath;
  bool _isRecurring = false;
  String _recurringPattern = 'monthly';
  bool _isLoading = false;

  ExpenseModel? _expense;
  IncomeModel? _income;

  @override
  void initState() {
    super.initState();
    _loadTransactionData();
  }

  void _loadTransactionData() {
    if (widget.isExpense) {
      _expense = context
          .read<ExpenseProvider>()
          .expenses
          .firstWhere((e) => e.id == widget.transactionId);

      // Format amount with thousand separator when loading
      _amountController.text = _formatAmountForDisplay(_expense!.amount);
      _descriptionController.text = _expense!.description;
      _locationController.text = _expense!.location ?? '';
      _selectedDate = _expense!.date;
      _selectedCategory = context
          .read<CategoryProvider>()
          .expenseCategories
          .firstWhere((cat) => cat.id == _expense!.categoryId);
      _selectedPaymentMethod = _expense!.paymentMethod;
      _receiptPhotoPath = _expense!.receiptPhotoPath;
      _isRecurring = _expense!.isRecurring;
      _recurringPattern = _expense!.recurringPattern ?? 'monthly';
    } else {
      _income = context
          .read<IncomeProvider>()
          .incomes
          .firstWhere((i) => i.id == widget.transactionId);

      // Format amount with thousand separator when loading
      _amountController.text = _formatAmountForDisplay(_income!.amount);
      _descriptionController.text = _income!.description;
      _sourceController.text = _income!.source;
      _selectedDate = _income!.date;
      _selectedCategory = context
          .read<CategoryProvider>()
          .incomeCategories
          .firstWhere((cat) => cat.id == _income!.categoryId);
      _isRecurring = _income!.isRecurring;
      _recurringPattern = _income!.recurringPattern ?? 'monthly';
    }
  }

  // Helper method to format amount for display
  String _formatAmountForDisplay(double amount) {
    // Convert double to integer string (remove decimal if it's .0)
    String amountString =
        amount % 1 == 0 ? amount.toInt().toString() : amount.toString();

    // Apply thousand separator formatting
    return _addThousandSeparator(amountString);
  }

  // Helper method to add thousand separator (same logic as in formatter)
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

  @override
  void dispose() {
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
                  (widget.isExpense ? AppColors.expense : AppColors.income)
                      .withOpacity(0.1),
                  (widget.isExpense ? AppColors.expense : AppColors.income)
                      .withOpacity(0.05),
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (widget.isExpense
                            ? AppColors.expense
                            : AppColors.income)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    widget.isExpense ? Icons.edit : Icons.edit,
                    color:
                        widget.isExpense ? AppColors.expense : AppColors.income,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('edit_transaction'),
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: widget.isExpense
                                      ? AppColors.expense
                                      : AppColors.income,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr('edit_transaction_desc'),
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
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color:
                        widget.isExpense ? AppColors.expense : AppColors.income,
                  ),
                ),
              ],
            ),
          ),

          // Form content
          Expanded(
            child: _buildTransactionForm(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingLarge,
          vertical: AppSizes.paddingMedium,
        ),
        child: Column(
          children: [
            // Amount field dengan design card
            _buildAmountCard(),
            const SizedBox(height: AppSizes.paddingMedium),

            // Description field
            _buildDescriptionCard(),
            const SizedBox(height: AppSizes.paddingMedium),

            // Category selection
            _buildCategoryCard(),
            const SizedBox(height: AppSizes.paddingMedium),

            // Date selection
            _buildDateCard(),

            // Additional fields for expense
            if (widget.isExpense) ...[
              const SizedBox(height: AppSizes.paddingMedium),
              _buildPaymentMethodCard(),
              const SizedBox(height: AppSizes.paddingMedium),
              _buildLocationCard(),
              const SizedBox(height: AppSizes.paddingMedium),
              _buildPhotoCard(),
            ],

            // Source field for income
            if (!widget.isExpense) ...[
              const SizedBox(height: AppSizes.paddingMedium),
              _buildSourceCard(),
            ],

            // Recurring transaction options
            const SizedBox(height: AppSizes.paddingMedium),
            _buildRecurringCard(),

            const SizedBox(height: AppSizes.paddingLarge),

            // Action buttons
            _buildActionButtons(context),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCard() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: (widget.isExpense ? AppColors.expense : AppColors.income)
            .withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (widget.isExpense ? AppColors.expense : AppColors.income)
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
                  color:
                      (widget.isExpense ? AppColors.expense : AppColors.income)
                          .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.attach_money,
                  color:
                      widget.isExpense ? AppColors.expense : AppColors.income,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                context
                    .tr(widget.isExpense ? 'expense_amount' : 'income_amount'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color:
                      widget.isExpense ? AppColors.expense : AppColors.income,
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
              prefixText: context.tr('currency_symbol_idr'),
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
              // Remove thousand separators before parsing
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

  Widget _buildCategoryCard() {
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
              final categories = widget.isExpense
                  ? categoryProvider.expenseCategories
                  : categoryProvider.incomeCategories;

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
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
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
              DropdownMenuItem(
                  value: 'ewallet', child: Text(context.tr('e_wallet'))),
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
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(context.tr('photo_updated_successfully')),
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
                          const Icon(Icons.error, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(context.tr('failed_to_take_photo')),
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

  Widget _buildRecurringCard() {
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
                  Icons.repeat,
                  color: AppTheme.primaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                context.tr('recurring_transaction'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Checkbox(
                value: _isRecurring,
                onChanged: (value) {
                  setState(() {
                    _isRecurring = value ?? false;
                  });
                  HapticFeedback.selectionClick();
                },
                activeColor: AppTheme.primaryColor,
              ),
              Expanded(
                child: Text(
                  context.tr('enable_recurring_transaction'),
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          if (_isRecurring) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _recurringPattern,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: context.tr('select_repeat_pattern'),
                hintStyle: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
              ),
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: AppTheme.primaryColor,
              ),
              items: [
                DropdownMenuItem(
                    value: 'daily', child: Text(context.tr('daily'))),
                DropdownMenuItem(
                    value: 'weekly', child: Text(context.tr('weekly'))),
                DropdownMenuItem(
                    value: 'monthly', child: Text(context.tr('monthly'))),
                DropdownMenuItem(
                    value: 'yearly', child: Text(context.tr('yearly'))),
              ],
              onChanged: (value) {
                setState(() {
                  _recurringPattern = value!;
                });
                HapticFeedback.selectionClick();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _deleteTransaction,
            icon: const Icon(Icons.delete),
            label: Text(context.tr('delete')),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(
                vertical: AppSizes.paddingMedium,
                horizontal: AppSizes.paddingMedium,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSizes.paddingMedium),
        Expanded(
          flex: 2,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.isExpense
                    ? [AppColors.expense, AppColors.expense.withOpacity(0.8)]
                    : [AppColors.income, AppColors.income.withOpacity(0.8)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color:
                      (widget.isExpense ? AppColors.expense : AppColors.income)
                          .withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isLoading
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        _updateTransaction();
                      },
                borderRadius: BorderRadius.circular(12),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.save,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              context.tr('save_changes'),
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
          ),
        ),
      ],
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

  Future<void> _updateTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Remove thousand separators before parsing
      final amount = double.parse(_amountController.text.replaceAll(',', ''));
      final description = _descriptionController.text.trim();

      bool success = false;

      if (widget.isExpense) {
        success = await context.read<ExpenseProvider>().updateExpense(
              id: widget.transactionId,
              amount: amount,
              categoryId: _selectedCategory!.id,
              description: description,
              date: _selectedDate,
              location: _locationController.text.trim().isEmpty
                  ? null
                  : _locationController.text.trim(),
              paymentMethod: _selectedPaymentMethod,
              receiptPhotoPath: _receiptPhotoPath,
              isRecurring: _isRecurring,
              recurringPattern: _isRecurring ? _recurringPattern : null,
            );
      } else {
        success = await context.read<IncomeProvider>().updateIncome(
              id: widget.transactionId,
              amount: amount,
              categoryId: _selectedCategory!.id,
              description: description,
              date: _selectedDate,
              source: _sourceController.text.trim(),
              isRecurring: _isRecurring,
              recurringPattern: _isRecurring ? _recurringPattern : null,
            );
      }

      if (success) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.isExpense
                          ? context.tr('success_expense_updated')
                          : context.tr('success_income_updated'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception(context.tr('failed_to_update_transaction'));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Error: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteTransaction() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            Expanded(
              child: Text(
                context.tr('confirm_delete'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
        content: Text(
          widget.isExpense
              ? context.tr('confirm_delete_expense')
              : context.tr('confirm_delete_income'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      bool success = false;

      if (widget.isExpense) {
        success = await context
            .read<ExpenseProvider>()
            .deleteExpense(widget.transactionId);
      } else {
        success = await context
            .read<IncomeProvider>()
            .deleteIncome(widget.transactionId);
      }

      if (success) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.isExpense
                          ? context.tr('success_expense_deleted')
                          : context.tr('success_income_deleted'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception(context.tr('failed_to_delete_transaction'));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Error: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
