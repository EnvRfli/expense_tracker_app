import 'package:flutter/material.dart';
import '../models/models.dart';
import '../l10n/localization_extension.dart';

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

    if (category.isDefault && category.name.startsWith('category_')) {
      displayName = context.tr(category.name);
    } else {
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

String getLocalizedCategoryName(BuildContext context, CategoryModel category) {
  if (category.isDefault && category.name.startsWith('category_')) {
    return context.tr(category.name);
  }
  return category.name;
}

String getLocalizedCategoryNameById(BuildContext context, String categoryId) {
  return categoryId;
}
