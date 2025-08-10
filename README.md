# Expense Tracker App

Aplikasi pengelola keuangan pribadi dengan backup ke Google Drive.

## Fitur Utama

### ✅ Sudah Dikembangkan
- **Model Data Lengkap**: 7 model dengan Hive database dan JSON serialization
- **Provider Architecture**: State management dengan Provider pattern
- **Google Drive Integration**: Backup dan restore data otomatis
- **Local Database**: Penyimpanan lokal dengan Hive
- **Notification System**: Notifikasi pengingat dan alerts
- **Splash Screen**: Animasi loading dengan provider initialization
- **Onboarding**: Setup awal untuk pengaturan mata uang, bahasa, dan notifikasi
- **Dashboard Utama**: Interface dengan bottom navigation dan widget dashboard
- **Add Transaction Modal**: Form untuk menambah pemasukan dan pengeluaran

### 🔄 Dalam Pengembangan
- Transaction List View
- Budget Management Interface
- Reports & Analytics
- Settings Screen
- Google Account Linking UI

### 📱 Layar Aplikasi
1. **Splash Screen** - Loading dengan animasi
2. **Onboarding** - Setup awal aplikasi
3. **Dashboard** - Halaman utama dengan 5 tab:
   - Home: Ringkasan saldo dan transaksi terbaru
   - Transactions: Daftar semua transaksi
   - Budget: Pengelolaan budget
   - Reports: Laporan dan analisis
   - Settings: Pengaturan aplikasi

### 💾 Arsitektur Data
- **Models**: ExpenseModel, IncomeModel, CategoryModel, UserModel, BudgetModel, TransactionModel, SyncDataModel
- **Services**: DatabaseService, GoogleDriveService, SyncService, NotificationService
- **Providers**: ExpenseProvider, IncomeProvider, CategoryProvider, BudgetProvider, SyncProvider, UserSettingsProvider

### 🎨 UI/UX Features
- Material Design 3
- Light/Dark theme support
- Google Fonts integration
- Responsive design
- Indonesian language support
- Currency formatting (IDR)

## Teknologi

- **Flutter** - Framework UI
- **Hive** - Local database
- **Provider** - State management
- **Google Drive API** - Cloud backup
- **Google Sign-In** - Authentication
- **Local Notifications** - Push notifications

## Setup dan Instalasi

1. Clone repository
2. Install dependencies: `flutter pub get`
3. Generate Hive adapters: `flutter packages pub run build_runner build`
4. Setup Google Drive API credentials
5. Run: `flutter run`

## Struktur Folder

```
lib/
├── models/          # Data models dengan Hive
├── services/        # Backend services
├── providers/       # State management
├── screens/         # UI screens
├── widgets/         # Reusable widgets
├── utils/           # Utilities dan theme
└── main.dart        # Entry point
```

## Progress

- [x] Model Layer (100%)
- [x] Service Layer (100%)
- [x] Provider Layer (100%)
- [x] Theme System (100%)
- [x] App Structure (100%)
- [x] Splash Screen (100%)
- [x] Onboarding (100%)
- [x] Dashboard Structure (100%)
- [x] Dashboard Widgets (100%)
- [x] Add Transaction Modal (100%)
- [ ] Transaction List (0%)
- [ ] Budget Interface (0%)
- [ ] Reports Screen (0%)
- [ ] Settings Screen (0%)

## Berikutnya

1. Implementasi layar daftar transaksi
2. Interface pengelolaan budget
3. Layar laporan dan analisis
4. Pengaturan aplikasi
5. Integrasi Google Drive UI
6. Testing dan debugging
7. Performance optimization

---

**Status**: 🔥 **Siap untuk development UI lanjutan** - Backend architecture lengkap, dashboard utama sudah berjalan.
