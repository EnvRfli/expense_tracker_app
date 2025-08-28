import 'package:flutter/material.dart';
import '../models/models.dart';
import '../l10n/localization_extension.dart';

/// Widget to display localized category name
class LocalizedCategoryName extends StatelessWidget {
  final CategoryModel category;
  final TextStyle? style;
  final TextOverflow? overflow;
  final int? maxLines;

  const LocalizedCategoryName({
    super.key,
    required this.category,
    this.style,
    this.overflow,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    String displayName;

    // If category name is a localization key (for default categories)
    if (category.isDefault && category.name.startsWith('category_')) {
      displayName = context.tr(category.name);
    } else {
      // For custom categories, return the original name
      displayName = category.name;
    }

    return Text(
      displayName,
      style: style,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}

/// Helper function to get localized category name as string
String getLocalizedCategoryName(BuildContext context, CategoryModel category) {
  if (category.isDefault && category.name.startsWith('category_')) {
    return context.tr(category.name);
  }
  return category.name;
}

/// Helper function to get localized category name by ID
String getLocalizedCategoryNameById(BuildContext context, String categoryId) {
  // You would need to get the category from your provider here
  // This is a placeholder - you should implement this based on your architecture
  return categoryId;
}
