import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../utils/theme.dart';
import '../l10n/localization_extension.dart';

class PaymentMethodManagementScreen extends StatefulWidget {
  const PaymentMethodManagementScreen({super.key});

  @override
  State<PaymentMethodManagementScreen> createState() =>
      _PaymentMethodManagementScreenState();
}

class _PaymentMethodManagementScreenState
    extends State<PaymentMethodManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentMethodProvider>().loadPaymentMethods();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('payment_methods')),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEditDialog(context),
          ),
        ],
      ),
      body: Consumer<PaymentMethodProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('error_loading_data'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.errorMessage ?? context.tr('unknown_error'),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadPaymentMethods(),
                    child: Text(context.tr('retry')),
                  ),
                ],
              ),
            );
          }

          final paymentMethods = provider.paymentMethods;

          if (paymentMethods.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.payment,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('no_payment_methods'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('add_payment_method_desc'),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditDialog(context),
                    icon: const Icon(Icons.add),
                    label: Text(context.tr('add_payment_method')),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            itemCount: paymentMethods.length,
            itemBuilder: (context, index) {
              final paymentMethod = paymentMethods[index];
              return _buildPaymentMethodCard(context, paymentMethod, provider);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPaymentMethodCard(
    BuildContext context,
    PaymentMethodModel paymentMethod,
    PaymentMethodProvider provider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: paymentMethod.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            paymentMethod.icon,
            color: paymentMethod.color,
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                paymentMethod.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            if (paymentMethod.isDefault)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  context.tr('default'),
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          paymentMethod.isBuiltIn
              ? context.tr('built_in_method')
              : context.tr('custom_method'),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) =>
              _handleMenuAction(context, value, paymentMethod, provider),
          itemBuilder: (context) => [
            if (!paymentMethod.isDefault)
              PopupMenuItem(
                value: 'set_default',
                child: Row(
                  children: [
                    const Icon(Icons.star_outline, size: 20),
                    const SizedBox(width: 8),
                    Text(context.tr('set_as_default')),
                  ],
                ),
              ),
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit_outlined, size: 20),
                  const SizedBox(width: 8),
                  Text(context.tr('edit')),
                ],
              ),
            ),
            if (!paymentMethod.isBuiltIn && provider.paymentMethods.length > 1)
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline,
                        size: 20, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      context.tr('delete'),
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
          ],
        ),
        onTap: () => _showAddEditDialog(context, paymentMethod: paymentMethod),
      ),
    );
  }

  void _handleMenuAction(
    BuildContext context,
    String action,
    PaymentMethodModel paymentMethod,
    PaymentMethodProvider provider,
  ) async {
    switch (action) {
      case 'set_default':
        _showSetDefaultConfirmation(context, paymentMethod, provider);
        break;
      case 'edit':
        _showAddEditDialog(context, paymentMethod: paymentMethod);
        break;
      case 'delete':
        _showDeleteConfirmation(context, paymentMethod, provider);
        break;
    }
  }

  void _showSetDefaultConfirmation(
    BuildContext context,
    PaymentMethodModel paymentMethod,
    PaymentMethodProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('set_default_payment_method')),
        content: Text(
          context.tr('set_default_payment_method_confirmation',
              params: {'name': paymentMethod.name}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _setAsDefault(context, paymentMethod, provider);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.budget),
            child: Text(context.tr('set_default')),
          ),
        ],
      ),
    );
  }

  Future<void> _setAsDefault(
    BuildContext context,
    PaymentMethodModel paymentMethod,
    PaymentMethodProvider provider,
  ) async {
    final success = await provider.setDefaultPaymentMethod(paymentMethod.id);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('default_payment_method_updated',
              params: {'name': paymentMethod.name})),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ??
              context.tr('error_updating_payment_method')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showDeleteConfirmation(
    BuildContext context,
    PaymentMethodModel paymentMethod,
    PaymentMethodProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('delete_payment_method')),
        content: Text(
          context.tr('delete_payment_method_confirmation',
              params: {'name': paymentMethod.name}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deletePaymentMethod(context, paymentMethod, provider);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePaymentMethod(
    BuildContext context,
    PaymentMethodModel paymentMethod,
    PaymentMethodProvider provider,
  ) async {
    final success = await provider.deletePaymentMethod(paymentMethod.id);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('payment_method_deleted')),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ??
              context.tr('error_deleting_payment_method')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showAddEditDialog(
    BuildContext context, {
    PaymentMethodModel? paymentMethod,
  }) {
    showDialog(
      context: context,
      builder: (context) => _PaymentMethodDialog(
        paymentMethod: paymentMethod,
        onSaved: (success, message) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: success ? AppColors.success : AppColors.error,
              ),
            );
          }
        },
      ),
    );
  }
}

class _PaymentMethodDialog extends StatefulWidget {
  final PaymentMethodModel? paymentMethod;
  final Function(bool success, String message)? onSaved;

  const _PaymentMethodDialog({
    this.paymentMethod,
    this.onSaved,
  });

  @override
  State<_PaymentMethodDialog> createState() => _PaymentMethodDialogState();
}

class _PaymentMethodDialogState extends State<_PaymentMethodDialog> {
  late TextEditingController _nameController;
  late String _selectedIcon;
  late Color _selectedColor;
  bool _setAsDefault = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.paymentMethod?.name ?? '',
    );
    _selectedIcon = widget.paymentMethod?.iconName ?? 'payment';
    _selectedColor = widget.paymentMethod?.color ?? Colors.blue;
    _setAsDefault = widget.paymentMethod?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.paymentMethod != null;

    return AlertDialog(
      title: Text(
        isEdit
            ? context.tr('edit_payment_method')
            : context.tr('add_payment_method'),
        style: Theme.of(context).textTheme.titleLarge,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: context.tr('payment_method_name'),
                hintText: context.tr('enter_payment_method_name'),
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('select_icon'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildIconSelector(),
            const SizedBox(height: 16),
            Text(
              context.tr('select_color'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildColorSelector(),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _setAsDefault,
              onChanged: (value) {
                setState(() {
                  _setAsDefault = value ?? false;
                });
              },
              title: Text(context.tr('set_as_default')),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('cancel')),
        ),
        ElevatedButton(
          onPressed: _savePaymentMethod,
          child: Text(isEdit ? context.tr('update') : context.tr('add')),
        ),
      ],
    );
  }

  Widget _buildIconSelector() {
    final availableIcons = PaymentMethodModel.getAvailableIcons();

    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: availableIcons.length,
        itemBuilder: (context, index) {
          final iconData = availableIcons[index];
          final isSelected = iconData['name'] == _selectedIcon;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedIcon = iconData['name'];
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      isSelected ? AppTheme.primaryColor : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Icon(
                iconData['icon'],
                color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
                size: 24,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildColorSelector() {
    final availableColors = PaymentMethodModel.getAvailableColors();

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: availableColors.length,
        itemBuilder: (context, index) {
          final color = availableColors[index];
          final isSelected = color == _selectedColor;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedColor = color;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.black : Colors.grey,
                  width: isSelected ? 3 : 1,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  Future<void> _savePaymentMethod() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      widget.onSaved?.call(false, context.tr('payment_method_name_required'));
      return;
    }

    final provider = context.read<PaymentMethodProvider>();
    bool success = false;

    if (widget.paymentMethod != null) {
      success = await provider.updatePaymentMethod(
        id: widget.paymentMethod!.id,
        name: name,
        iconName: _selectedIcon,
        iconColor: _selectedColor.value,
        setAsDefault: _setAsDefault,
      );
    } else {
      success = await provider.addPaymentMethod(
        name: name,
        iconName: _selectedIcon,
        iconColor: _selectedColor.value,
        setAsDefault: _setAsDefault,
      );
    }

    if (success) {
      Navigator.pop(context);
      final message = widget.paymentMethod != null
          ? context.tr('payment_method_updated')
          : context.tr('payment_method_added');
      widget.onSaved?.call(true, message);
    } else {
      final message =
          provider.errorMessage ?? context.tr('error_saving_payment_method');
      widget.onSaved?.call(false, message);
    }
  }
}
