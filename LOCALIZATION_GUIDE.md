# Internationalization (i18n) Implementation Guide

## Overview

Aplikasi expense tracker sekarang mendukung multiple bahasa dengan sistem localization yang sederhana dan mudah digunakan. Sistem ini mendukung Bahasa Indonesia (default) dan English.

## Struktur File

```
lib/
  l10n/
    app_localizations.dart      - File utama yang berisi semua teks terjemahan
    localization_extension.dart - Extension methods untuk kemudahan akses
    l10n_utils.dart            - Utility helpers dan widgets
```

## Cara Menggunakan

### 1. Import Extension

```dart
import '../l10n/localization_extension.dart';
```

### 2. Menggunakan Localized Text

#### Metode Context Extension (Recommended)
```dart
// Basic usage
Text(context.tr('welcome'))

// Dengan parameter
Text(context.tr('no_income_expense', params: {'type': 'pemasukan'}))

// Helper methods
Text(context.getMonthName(DateTime.now().month))
Text(context.getCurrencyName('IDR'))
Text(context.getLanguageName('id'))
```

#### Metode Widget Helper
```dart
// Menggunakan LocalizedText widget
LocalizedText('welcome', style: TextStyle(fontSize: 16))

// AppBar dengan localization
localizedAppBar(context, 'reports_title')
```

### 3. Menambahkan Terjemahan Baru

Edit file `lib/l10n/app_localizations.dart`:

```dart
// Tambahkan ke map _id (Bahasa Indonesia)
static const Map<String, String> _id = {
  'key_baru': 'Teks dalam Bahasa Indonesia',
  // ... existing keys
};

// Tambahkan ke map _en (English)
static const Map<String, String> _en = {
  'key_baru': 'Text in English',
  // ... existing keys
};
```

### 4. Contoh Implementasi

#### Dashboard
```dart
// Before
Text('Saldo Bulan Ini')

// After
Text(context.tr('balance_this_month'))
```

#### Settings
```dart
// Before
title: const Text('Bahasa'),
subtitle: Text(_getLanguageName(userSettings.language)),

// After
title: Text(context.tr('language')),
subtitle: Text(context.getLanguageName(userSettings.language)),
```

#### Reports
```dart
// Before
appBar: AppBar(title: const Text('Laporan'))

// After
appBar: AppBar(title: Text(context.tr('reports_title')))
```

## Available Helper Methods

### Context Extensions
- `context.tr(key, params: {...})` - Translate text
- `context.getMonthName(month)` - Get localized month name
- `context.getDayName(weekday)` - Get localized day name
- `context.getCurrencyName(code)` - Get localized currency name
- `context.getThemeName(theme)` - Get localized theme name
- `context.getLanguageName(code)` - Get localized language name
- `context.getPaymentMethodName(method)` - Get localized payment method
- `context.getBudgetStatusName(status)` - Get localized budget status
- `context.getPeriodName(period)` - Get localized period name

### Global Helpers
```dart
// Direct translation without context
L10n.translate('key', 'id') // For Indonesian
L10n.translate('key', 'en') // For English
```

## Parameter Replacement

Untuk teks dengan parameter dinamis:

```dart
// Translation keys
'no_income_expense': 'Belum ada {type}',
'period_range': '{start} - {end}',

// Usage
context.tr('no_income_expense', params: {'type': 'pemasukan'})
context.tr('period_range', params: {
  'start': '1/1/2025', 
  'end': '31/1/2025'
})
```

## Best Practices

1. **Gunakan key yang deskriptif**
   - ✅ `balance_this_month`
   - ❌ `text1`, `label_a`

2. **Grouping keys berdasarkan feature**
   - `dashboard_*` untuk dashboard
   - `transaction_*` untuk transactions
   - `budget_*` untuk budget management
   - `error_*` untuk error messages

3. **Konsistency dalam naming**
   - Gunakan snake_case untuk keys
   - Gunakan prefix yang sama untuk related features

4. **Parameter naming**
   - Gunakan nama parameter yang jelas
   - Hindari singkatan yang ambigu

## Switching Language

User dapat mengganti bahasa melalui Settings > Bahasa. Perubahan akan tersimpan otomatis dan diterapkan ke seluruh aplikasi.

## Migration Guide

Untuk mengupdate existing code:

1. Import localization extension
2. Replace hard-coded text dengan `context.tr('key')`
3. Tambahkan translation keys ke app_localizations.dart
4. Test dengan switching language

## Common Translation Keys

### Navigation
- `dashboard`, `transactions`, `budgets`, `reports`, `settings`

### Actions
- `add`, `edit`, `delete`, `save`, `cancel`, `search`, `filter`

### Transaction Related
- `income`, `expense`, `amount`, `description`, `category`, `date`

### Budget Related
- `budget_amount`, `used`, `remaining`, `active_budgets`

### Status
- `success`, `error`, `warning`, `loading`

## Testing

Untuk memastikan localization bekerja dengan baik:

1. Test switching language di Settings
2. Navigate ke semua screen untuk memastikan tidak ada missing translations
3. Test dengan parameter replacement
4. Verify helper methods (month names, currency names, etc.)

## Future Improvements

1. **Lazy loading** untuk terjemahan yang besar
2. **External translation files** (JSON/ARB format)
3. **Pluralization support** untuk count-based texts
4. **RTL language support** jika diperlukan
5. **Translation management tools** untuk non-developer

## Troubleshooting

### Missing Translation
Jika key tidak ditemukan, sistem akan menampilkan key itu sendiri sebagai fallback.

### Context Not Available
Gunakan `L10n.translate(key, languageCode)` jika context tidak tersedia.

### Performance
Extension methods di-cache untuk performa yang optimal.
