# Expense Tracker App

A personal finance management application with Google Drive backup functionality.

### 📱 Application Screens
1. **Splash Screen** - Loading with animations
2. **Onboarding** - Initial app setup
3. **Dashboard** - Main page with 5 tabs:
   - Home: Balance summary and recent transactions with interactive elements
   - Transactions: Complete transaction list with filtering and search capabilities
   - Budget: Budget management with visual progress indicators
   - Reports: Reports and analytics
   - Settings: Application settings

### 💾 Data Architecture
- **Models**: ExpenseModel, IncomeModel, CategoryModel, UserModel, BudgetModel, TransactionModel, SyncDataModel
- **Services**: DatabaseService, GoogleDriveService, SyncService, NotificationService, ImagePickerService
- **Providers**: ExpenseProvider, IncomeProvider, CategoryProvider, BudgetProvider, SyncProvider, UserSettingsProvider

### 🎨 UI/UX Features
- Material Design 3
- Light/Dark theme support
- Google Fonts integration
- Responsive design
- Indonesian language support
- Currency formatting (IDR) with thousand separators
- Smooth animations and transitions
- Custom sliver layouts for optimal scrolling
- Interactive bottom sheets and modals
- Haptic feedback integration

## Technology Stack

- **Flutter** - UI Framework
- **Hive** - Local database
- **Provider** - State management
- **Google Drive API** - Cloud backup
- **Google Sign-In** - Authentication
- **Local Notifications** - Push notifications
- **Image Picker** - Receipt photo capture

## Setup and Installation

1. Clone repository
2. Install dependencies: `flutter pub get`
3. Generate Hive adapters: `flutter packages pub run build_runner build`
4. Setup Google Drive API credentials
5. Run: `flutter run`

## Project Structure

```
lib/
├── l10n/            # Languange localization
├── models/          # Data models with Hive
├── services/        # Backend services
├── providers/       # State management
├── screens/         # UI screens
├── widgets/         # Reusable widgets
└── utils/           # Utilities and theme
```