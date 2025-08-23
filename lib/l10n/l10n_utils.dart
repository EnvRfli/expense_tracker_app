import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../l10n/localization_extension.dart';

/// Global localization helper
class L10n {
  /// Get localized text using current context
  static String tr(BuildContext context, String key,
      {Map<String, String>? params}) {
    return context.tr(key, params: params);
  }

  /// Get localized text using language code directly
  static String translate(String key, String languageCode,
      {Map<String, String>? params}) {
    return AppLocalizations.translate(key, languageCode, params: params);
  }

  /// Common helper methods
  static String getMonthName(BuildContext context, int month) {
    return context.getMonthName(month);
  }

  static String getDayName(BuildContext context, int weekday) {
    return context.getDayName(weekday);
  }

  static String getCurrencyName(BuildContext context, String currencyCode) {
    return context.getCurrencyName(currencyCode);
  }

  static String getThemeName(BuildContext context, String theme) {
    return context.getThemeName(theme);
  }

  static String getLanguageName(BuildContext context, String languageCode) {
    return context.getLanguageName(languageCode);
  }

  static String getPaymentMethodName(
      BuildContext context, String paymentMethod) {
    return context.getPaymentMethodName(paymentMethod);
  }

  static String getBudgetStatusName(BuildContext context, String status) {
    return context.getBudgetStatusName(status);
  }

  static String getPeriodName(BuildContext context, String period) {
    return context.getPeriodName(period);
  }
}

/// Helper widget for responsive localized text
class LocalizedText extends StatelessWidget {
  final String textKey;
  final Map<String, String>? params;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const LocalizedText(
    this.textKey, {
    super.key,
    this.params,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      context.tr(textKey, params: params),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Helper to create localized app bar
AppBar localizedAppBar(
  BuildContext context,
  String titleKey, {
  List<Widget>? actions,
  Widget? leading,
  bool automaticallyImplyLeading = true,
  Color? backgroundColor,
  Color? foregroundColor,
  double? elevation,
}) {
  return AppBar(
    title: LocalizedText(titleKey),
    actions: actions,
    leading: leading,
    automaticallyImplyLeading: automaticallyImplyLeading,
    backgroundColor: backgroundColor,
    foregroundColor: foregroundColor,
    elevation: elevation,
  );
}
