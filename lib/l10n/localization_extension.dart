import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_settings_provider.dart';
import '../models/models.dart';
import 'app_localizations.dart';

extension LocalizationExtension on BuildContext {
  /// Get the current language code from user settings
  String get languageCode {
    return read<UserSettingsProvider>().language;
  }

  /// Translate a key to the current language
  String tr(String key, {Map<String, String>? params}) {
    return AppLocalizations.translate(key, languageCode, params: params);
  }

  /// Short alias for translate
  String t(String key, {Map<String, String>? params}) {
    return tr(key, params: params);
  }

  /// Get month name in current language
  String getMonthName(int month) {
    const monthKeys = [
      'month_january',
      'month_february',
      'month_march',
      'month_april',
      'month_may',
      'month_june',
      'month_july',
      'month_august',
      'month_september',
      'month_october',
      'month_november',
      'month_december'
    ];

    if (month >= 1 && month <= 12) {
      return tr(monthKeys[month - 1]);
    }
    return month.toString();
  }

  /// Get short month name in current language
  String getShortMonthName(int month) {
    const monthShortKeys = [
      'month_short_january',
      'month_short_february',
      'month_short_march',
      'month_short_april',
      'month_short_may',
      'month_short_june',
      'month_short_july',
      'month_short_august',
      'month_short_september',
      'month_short_october',
      'month_short_november',
      'month_short_december'
    ];

    if (month >= 1 && month <= 12) {
      return tr(monthShortKeys[month - 1]);
    }
    return month.toString();
  }

  /// Get day name in current language
  String getDayName(int weekday) {
    const dayKeys = [
      'day_monday',
      'day_tuesday',
      'day_wednesday',
      'day_thursday',
      'day_friday',
      'day_saturday',
      'day_sunday'
    ];

    if (weekday >= 1 && weekday <= 7) {
      return tr(dayKeys[weekday - 1]);
    }
    return weekday.toString();
  }

  /// Get currency name in current language
  String getCurrencyName(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'IDR':
        return tr('currency_idr');
      case 'USD':
        return tr('currency_usd');
      case 'EUR':
        return tr('currency_eur');
      case 'SGD':
        return tr('currency_sgd');
      case 'MYR':
        return tr('currency_myr');
      default:
        return currencyCode;
    }
  }

  /// Get theme name in current language
  String getThemeName(String theme) {
    switch (theme) {
      case 'light':
        return tr('theme_light');
      case 'dark':
        return tr('theme_dark');
      case 'system':
        return tr('theme_system');
      default:
        return theme;
    }
  }

  /// Get language name in current language
  String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'id':
        return tr('language_indonesian');
      case 'en':
        return tr('language_english');
      default:
        return languageCode;
    }
  }

  /// Get payment method name in current language
  String getPaymentMethodName(String paymentMethod) {
    switch (paymentMethod) {
      case 'cash':
        return tr('cash');
      case 'credit_card':
        return tr('credit_card');
      case 'debit_card':
        return tr('debit_card');
      case 'e_wallet':
        return tr('e_wallet');
      case 'bank_transfer':
        return tr('bank_transfer');
      default:
        return paymentMethod;
    }
  }

  /// Get budget status name in current language
  String getBudgetStatusName(String status) {
    switch (status) {
      case 'normal':
        return tr('budget_status_normal');
      case 'warning':
        return tr('budget_status_warning');
      case 'exceeded':
        return tr('budget_status_exceeded');
      case 'full':
        return tr('budget_status_full');
      default:
        return status;
    }
  }

  /// Get period name in current language
  String getPeriodName(String period) {
    switch (period) {
      case 'daily':
        return tr('daily');
      case 'weekly':
        return tr('weekly');
      case 'monthly':
        return tr('monthly');
      case 'yearly':
        return tr('yearly');
      default:
        return period;
    }
  }

  /// Get category name in current language based on category ID
  String getCategoryName(String categoryId) {
    switch (categoryId) {
      // Expense categories
      case 'exp_food':
        return tr('category_food_drink');
      case 'exp_transport':
        return tr('category_transportation');
      case 'exp_shopping':
        return tr('category_shopping');
      case 'exp_entertainment':
        return tr('category_entertainment');
      case 'exp_health':
        return tr('category_health');
      case 'exp_bills':
        return tr('category_bills');

      // Income categories
      case 'inc_salary':
        return tr('category_salary');
      case 'inc_freelance':
        return tr('category_freelance');
      case 'inc_investment':
        return tr('category_investment');
      case 'inc_other':
        return tr('category_other_income');

      default:
        return categoryId;
    }
  }

  /// Get localized category name for default categories
  String getDefaultCategoryName(String name) {
    switch (name) {
      // Expense categories
      case 'Makanan & Minuman':
        return tr('category_food_drink');
      case 'Transportasi':
        return tr('category_transportation');
      case 'Belanja':
        return tr('category_shopping');
      case 'Hiburan':
        return tr('category_entertainment');
      case 'Kesehatan':
        return tr('category_health');
      case 'Tagihan':
        return tr('category_bills');

      // Income categories
      case 'Gaji':
        return tr('category_salary');
      case 'Freelance':
        return tr('category_freelance');
      case 'Investasi':
        return tr('category_investment');
      case 'Lainnya':
        return tr('category_other_income');

      // Quick action categories
      case 'Makan':
        return tr('quick_food');
      case 'Transport':
        return tr('quick_transport');
      case 'Bonus':
        return tr('category_bonus');

      default:
        return name;
    }
  }

  /// Get localized category name from CategoryModel
  /// This is a shorthand helper to avoid repetitive conditionals
  String getCategoryDisplayName(CategoryModel? category) {
    if (category == null) return 'Unknown';

    if (category.isDefault && category.name.startsWith('category_')) {
      return tr(category.name);
    }

    return category.name;
  }

  /// Static method to get category display name without BuildContext
  /// Uses Indonesian as fallback for notification services
  static String getCategoryDisplayNameStatic(CategoryModel? category) {
    if (category == null) return 'Unknown';

    if (category.isDefault && category.name.startsWith('category_')) {
      // Use Indonesian as fallback for notifications
      return AppLocalizations.translate(category.name, 'id');
    }

    return category.name;
  }
}
