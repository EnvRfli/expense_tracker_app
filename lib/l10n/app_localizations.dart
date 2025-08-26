abstract class AppLocalizations {
  // Common
  static const Map<String, String> _id = {
    // Navigation & General
    'halo': 'Halo!',
    'dashboard': 'Dashboard',
    'transactions': 'Transaksi',
    'budgets': 'Budget',
    'reports': 'Laporan',
    'settings': 'Pengaturan',
    'cancel': 'Batal',
    'save': 'Simpan',
    'delete': 'Hapus',
    'edit': 'Edit',
    'add': 'Tambah',
    'search': 'Cari',
    'filter': 'Filter',
    'export': 'Export',
    'import': 'Import',
    'ok': 'OK',
    'yes': 'Ya',
    'no': 'Tidak',
    'loading': 'Memuat...',
    'error': 'Error',
    'success': 'Berhasil',
    'warning': 'Peringatan',
    'info': 'Informasi',

    // Dashboard
    'welcome': 'Selamat Datang',
    'this_month': 'Bulan Ini',
    'Overall': 'Keseluruhan',
    'balance_this_month': 'Saldo Bulan Ini',
    'total_balance': 'Saldo Keseluruhan',
    'switch_to_total': 'Total',
    'total': 'jumlah',
    'switch_to_monthly': 'Bulan',
    'income': 'Pemasukan',
    'expense': 'Pengeluaran',
    'balance': 'Saldo',
    'quick_actions': 'Aksi Cepat',
    'add_expense': 'Tambah Pengeluaran',
    'add_income': 'Tambah Pemasukan',
    'create_budget': 'Buat Budget',
    'budget_overview': 'Budget Overview',
    'see_all': 'Lihat Semua',
    'recent_transactions': 'Transaksi Terbaru',
    'spending_by_category': 'Pengeluaran per Kategori',
    'no_active_budget': 'Belum ada budget aktif',
    'create_budget_desc': 'Buat budget untuk memantau pengeluaran Anda',
    'no_transactions': 'Belum ada transaksi',
    'no_expenses_this_month': 'Belum ada pengeluaran bulan ini',
    'no_income_expense': 'Belum ada {type}',
    'no_income_expense_period': '{period}',

    // Combined titles for filtered transactions
    'income_this_month': 'This Month Income',
    'expense_this_month': 'This Month Expense',
    'income_overall': 'Overall Income',
    'expense_overall': 'Overall Expense',

    'total_income': 'Total Income',
    'total_expense': 'Total Expense',

    'income_amount': 'Jumlah Pemasukan',
    'expense_amount': 'Jumlah Pengeluaran',

    // Transactions
    'add_transaction': 'Tambah Transaksi',
    'add_transaction_desc': 'Catat pemasukan atau pengeluaran Anda',
    'edit_transaction': 'Edit Transaksi',
    'transaction_type': 'Jenis Transaksi',
    'amount': 'Jumlah',
    'description': 'Deskripsi',
    'category': 'Kategori',
    'date': 'Tanggal',
    'notes': 'Catatan',
    'location': 'Lokasi',
    'payment_method': 'Metode Pembayaran',
    'cash': 'Tunai',
    'credit_card': 'Kartu Kredit',
    'debit_card': 'Kartu Debit',
    'e_wallet': 'E-Wallet',
    'bank_transfer': 'Transfer Bank',
    'attachment': 'Lampiran',
    'take_photo': 'Ambil Foto',
    'choose_from_gallery': 'Pilih dari Galeri',
    'recurring': 'Berulang',
    'repeat_pattern': 'Pola Pengulangan',
    'daily': 'Harian',
    'weekly': 'Mingguan',
    'monthly': 'Bulanan',
    'yearly': 'Tahunan',
    'amount_is_required': 'Jumlah tidak boleh kosong',
    'valid_amount_required': 'Masukkan jumlah yang valid',
    'example_description': 'Contoh: Makan Siang di Restoran',
    'description_is_required': 'Deskripsi tidak boleh kosong',
    'select_category': 'Pilih Kategori',

    // Budget
    'budget_management': 'Budget Management',
    'add_budget': 'Tambah Budget',
    'edit_budget': 'Edit Budget',
    'budget_amount': 'Jumlah Budget',
    'budget_period': 'Periode Budget',
    'start_date': 'Tanggal Mulai',
    'end_date': 'Tanggal Selesai',
    'alert_enabled': 'Aktifkan Peringatan',
    'alert_percentage': 'Persentase Peringatan',
    'budget_notes': 'Catatan Budget',
    'used': 'Terpakai',
    'remaining': 'Sisa',
    'budget_status_normal': 'Normal',
    'budget_status_warning': 'Peringatan',
    'budget_status_exceeded': 'Melampaui',
    'budget_status_full': 'Habis',
    'active_budgets': 'Aktif',
    'completed_budgets': 'Selesai',
    'all_budgets': 'Semua',
    'no_budget_filter': 'Tidak ada budget {filter}',
    'try_different_filter':
        'Coba pilih filter periode yang berbeda atau buat budget {filter} baru',
    'budget_already_exists': 'Budget sudah ada untuk kategori dan periode ini',
    'total_budget': 'Total Budget',
    'average_usage': 'Terpakai',
    'exceeded_budgets': 'Melebihi',

    // Reports
    'reports_title': 'Laporan',
    'export_csv': 'Export CSV',
    'filter_period': 'Filter Periode',
    'trend': 'Trend',
    'category_breakdown': 'Breakdown Kategori',
    'top_transactions': 'Transaksi Teratas',
    'no_data': 'Tidak ada data',
    'period_range': '{start} - {end}',

    // Settings
    'currency': 'Mata Uang',
    'language': 'Bahasa',
    'theme': 'Tema',
    'daily_reminder': 'Pengingat Harian',
    'notification_enabled_desc':
        'Aktif - Pengingat setiap hari sekitar jam 20:00',
    'notification_disabled_desc': 'Nonaktif - Tidak ada pengingat harian',
    'theme_light': 'Terang',
    'theme_dark': 'Gelap',
    'theme_system': 'Sistem',
    'language_indonesian': 'Bahasa Indonesia',
    'language_english': 'English',
    'backup_restore': 'Backup & Restore',
    'backup_to_google_drive': 'Backup ke Google Drive',
    'restore_from_google_drive': 'Restore dari Google Drive',
    'about': 'Tentang',
    'app_version': 'Versi Aplikasi',
    'privacy_policy': 'Kebijakan Privasi',
    'terms_of_service': 'Syarat & Ketentuan',

    // Currencies
    'currency_idr': 'Rupiah Indonesia (IDR)',
    'currency_usd': 'US Dollar (USD)',
    'currency_eur': 'Euro (EUR)',
    'currency_sgd': 'Singapore Dollar (SGD)',
    'currency_myr': 'Malaysian Ringgit (MYR)',

    // Months
    'month_january': 'Januari',
    'month_february': 'Februari',
    'month_march': 'Maret',
    'month_april': 'April',
    'month_may': 'Mei',
    'month_june': 'Juni',
    'month_july': 'Juli',
    'month_august': 'Agustus',
    'month_september': 'September',
    'month_october': 'Oktober',
    'month_november': 'November',
    'month_december': 'Desember',

    // Days
    'day_monday': 'Senin',
    'day_tuesday': 'Selasa',
    'day_wednesday': 'Rabu',
    'day_thursday': 'Kamis',
    'day_friday': 'Jumat',
    'day_saturday': 'Sabtu',
    'day_sunday': 'Minggu',

    // Error Messages
    'error_required_field': 'Field ini wajib diisi',
    'error_invalid_amount': 'Jumlah tidak valid',
    'error_amount_too_large': 'Jumlah terlalu besar',
    'error_invalid_date': 'Tanggal tidak valid',
    'error_network': 'Kesalahan jaringan',
    'error_unknown': 'Terjadi kesalahan yang tidak diketahui',

    // Success Messages
    'success_transaction_added': 'Transaksi berhasil ditambahkan',
    'success_transaction_updated': 'Transaksi berhasil diperbarui',
    'success_transaction_deleted': 'Transaksi berhasil dihapus',
    'success_budget_added': 'Budget berhasil ditambahkan',
    'success_budget_updated': 'Budget berhasil diperbarui',
    'success_budget_deleted': 'Budget berhasil dihapus',
    'success_backup_completed': 'Backup berhasil diselesaikan',
    'success_restore_completed': 'Restore berhasil diselesaikan',
  };

  static const Map<String, String> _en = {
    // Navigation & General
    'halo': 'Hello!',
    'dashboard': 'Dashboard',
    'transactions': 'Transactions',
    'budgets': 'Budgets',
    'reports': 'Reports',
    'settings': 'Settings',
    'cancel': 'Cancel',
    'save': 'Save',
    'delete': 'Delete',
    'edit': 'Edit',
    'add': 'Add',
    'search': 'Search',
    'filter': 'Filter',
    'export': 'Export',
    'import': 'Import',
    'ok': 'OK',
    'yes': 'Yes',
    'no': 'No',
    'loading': 'Loading...',
    'error': 'Error',
    'success': 'Success',
    'warning': 'Warning',
    'info': 'Information',

    // Dashboard
    'welcome': 'Welcome',
    'this_month': 'This Month',
    'Overall': 'Overall',
    'balance_this_month': 'This Month Balance',
    'total_balance': 'Total Balance',
    'switch_to_total': 'Total',
    'total': 'Amount',
    'switch_to_monthly': 'Month',
    'income': 'Income',
    'expense': 'Expense',
    'balance': 'Balance',
    'quick_actions': 'Quick Actions',
    'add_expense': 'Add Expense',
    'add_income': 'Add Income',
    'create_budget': 'Create Budget',
    'budget_overview': 'Budget Overview',
    'see_all': 'See All',
    'recent_transactions': 'Recent Transactions',
    'spending_by_category': 'Spending by Category',
    'no_active_budget': 'No active budget',
    'create_budget_desc': 'Create budget to track your expenses',
    'no_transactions': 'No transactions yet',
    'no_expenses_this_month': 'No expenses this month',
    'no_income_expense': 'No {type} yet',
    'no_income_expense_period': '{period}',

    // Combined titles for filtered transactions
    'income_this_month': 'This Month Income',
    'expense_this_month': 'This Month Expense',
    'income_overall': 'Overall Income',
    'expense_overall': 'Overall Expense',

    'income_amount': 'Income Amount',
    'expense_amount': 'Expense Amount',

    // Transactions
    'add_transaction': 'Add Transaction',
    'add_transaction_desc': 'Record your income or expense',
    'edit_transaction': 'Edit Transaction',
    'transaction_type': 'Transaction Type',
    'amount': 'Amount',
    'description': 'Description',
    'category': 'Category',
    'date': 'Date',
    'notes': 'Notes',
    'location': 'Location',
    'payment_method': 'Payment Method',
    'cash': 'Cash',
    'credit_card': 'Credit Card',
    'debit_card': 'Debit Card',
    'e_wallet': 'E-Wallet',
    'bank_transfer': 'Bank Transfer',
    'attachment': 'Attachment',
    'take_photo': 'Take Photo',
    'choose_from_gallery': 'Choose from Gallery',
    'recurring': 'Recurring',
    'repeat_pattern': 'Repeat Pattern',
    'daily': 'Daily',
    'weekly': 'Weekly',
    'monthly': 'Monthly',
    'yearly': 'Yearly',
    'amount_is_required': 'Amount is required',
    'valid_amount_required': 'Enter a valid amount',
    'example_description': 'E.g.: Lunch at Restaurant',
    'description_is_required': 'Description is required',
    'select_category': 'Select Category',

    // Budget
    'budget_management': 'Budget Management',
    'add_budget': 'Add Budget',
    'edit_budget': 'Edit Budget',
    'budget_amount': 'Budget Amount',
    'budget_period': 'Budget Period',
    'start_date': 'Start Date',
    'end_date': 'End Date',
    'alert_enabled': 'Enable Alerts',
    'alert_percentage': 'Alert Percentage',
    'budget_notes': 'Budget Notes',
    'used': 'Used',
    'remaining': 'Remaining',
    'budget_status_normal': 'Normal',
    'budget_status_warning': 'Warning',
    'budget_status_exceeded': 'Exceeded',
    'budget_status_full': 'Full',
    'active_budgets': 'Active',
    'completed_budgets': 'Completed',
    'all_budgets': 'All',
    'no_budget_filter': 'No {filter} budget',
    'try_different_filter':
        'Try selecting a different period filter or create a new {filter} budget',
    'budget_already_exists':
        'Budget already exists for this category and period',
    'total_budget': 'Total Budget',
    'average_usage': 'Used',
    'exceeded_budgets': 'Exceeded',

    // Reports
    'reports_title': 'Reports',
    'export_csv': 'Export CSV',
    'filter_period': 'Filter Period',
    'trend': 'Trend',
    'category_breakdown': 'Category Breakdown',
    'top_transactions': 'Top Transactions',
    'no_data': 'No data',
    'period_range': '{start} - {end}',

    // Settings
    'currency': 'Currency',
    'language': 'Language',
    'theme': 'Theme',
    'daily_reminder': 'Daily Reminder',
    'notification_enabled_desc': 'Active - Daily reminder around 8:00 PM',
    'notification_disabled_desc': 'Inactive - No daily reminders',
    'theme_light': 'Light',
    'theme_dark': 'Dark',
    'theme_system': 'System',
    'language_indonesian': 'Bahasa Indonesia',
    'language_english': 'English',
    'backup_restore': 'Backup & Restore',
    'backup_to_google_drive': 'Backup to Google Drive',
    'restore_from_google_drive': 'Restore from Google Drive',
    'about': 'About',
    'app_version': 'App Version',
    'privacy_policy': 'Privacy Policy',
    'terms_of_service': 'Terms of Service',

    // Currencies
    'currency_idr': 'Indonesian Rupiah (IDR)',
    'currency_usd': 'US Dollar (USD)',
    'currency_eur': 'Euro (EUR)',
    'currency_sgd': 'Singapore Dollar (SGD)',
    'currency_myr': 'Malaysian Ringgit (MYR)',

    // Months
    'month_january': 'January',
    'month_february': 'February',
    'month_march': 'March',
    'month_april': 'April',
    'month_may': 'May',
    'month_june': 'June',
    'month_july': 'July',
    'month_august': 'August',
    'month_september': 'September',
    'month_october': 'October',
    'month_november': 'November',
    'month_december': 'December',

    // Days
    'day_monday': 'Monday',
    'day_tuesday': 'Tuesday',
    'day_wednesday': 'Wednesday',
    'day_thursday': 'Thursday',
    'day_friday': 'Friday',
    'day_saturday': 'Saturday',
    'day_sunday': 'Sunday',

    // Error Messages
    'error_required_field': 'This field is required',
    'error_invalid_amount': 'Invalid amount',
    'error_amount_too_large': 'Amount is too large',
    'error_invalid_date': 'Invalid date',
    'error_network': 'Network error',
    'error_unknown': 'An unknown error occurred',

    // Success Messages
    'success_transaction_added': 'Transaction added successfully',
    'success_transaction_updated': 'Transaction updated successfully',
    'success_transaction_deleted': 'Transaction deleted successfully',
    'success_budget_added': 'Budget added successfully',
    'success_budget_updated': 'Budget updated successfully',
    'success_budget_deleted': 'Budget deleted successfully',
    'success_backup_completed': 'Backup completed successfully',
    'success_restore_completed': 'Restore completed successfully',
  };

  static String translate(String key, String languageCode,
      {Map<String, String>? params}) {
    Map<String, String> translations;

    switch (languageCode) {
      case 'en':
        translations = _en;
        break;
      case 'id':
      default:
        translations = _id;
        break;
    }

    String text = translations[key] ?? key;

    // Simple parameter replacement
    if (params != null) {
      params.forEach((param, value) {
        text = text.replaceAll('{$param}', value);
      });
    }

    return text;
  }

  // Helper methods for common translations
  static String t(String key, String languageCode,
      {Map<String, String>? params}) {
    return translate(key, languageCode, params: params);
  }
}
