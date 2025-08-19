# Fitur Recurring Budget - Expense Tracker

## Fitur Baru: Budget Berulang Otomatis

### Apa itu Recurring Budget?

Recurring Budget adalah fitur yang memungkinkan aplikasi untuk **otomatis membuat budget baru** untuk periode berikutnya dengan jumlah dan pengaturan yang sama.

### Cara Kerja

#### 1. **Membuat Budget Recurring**
- Buka "Buat Budget Baru" atau edit budget yang sudah ada
- Aktifkan toggle "Budget Berulang Otomatis"
- Budget akan otomatis dibuat untuk periode berikutnya

#### 2. **Jenis Periode yang Didukung**
- **Harian**: Budget baru dibuat setiap hari
- **Mingguan**: Budget baru dibuat setiap minggu  
- **Bulanan**: Budget baru dibuat setiap bulan

#### 3. **Contoh Penggunaan**

**Skenario:** Budget harian untuk makan Rp 50.000

- **19 Agustus 2025**: Buat budget harian "Makan" Rp 50.000 dengan recurring ON
- **20 Agustus 2025**: Budget "Makan" Rp 50.000 otomatis dibuat untuk tanggal 20
- **21 Agustus 2025**: Budget "Makan" Rp 50.000 otomatis dibuat untuk tanggal 21
- Dan seterusnya...

### Teknologi

#### 1. **Model Budget**
```dart
@HiveField(13)
bool isRecurring; // Field baru untuk menandai budget recurring
```

#### 2. **BudgetProvider Methods**
```dart
// Auto-create recurring budgets
Future<void> createRecurringBudgets()

// Check for overdue recurring budgets
Future<void> checkAndCreateOverdueBudgets()

// Calculate next period dates
Map<String, DateTime> _calculateNextPeriodDates(String period, DateTime lastEndDate)
```

#### 3. **Background Service**
```dart
RecurringBudgetService.instance
- Timer periodic check setiap 1 jam
- Auto-create budget yang belum ada
- Handle budget yang terlewat (overdue)
```

### UI/UX Features

#### 1. **Toggle Setting**
- Switch untuk mengaktifkan recurring budget
- Deskripsi dinamis berdasarkan periode yang dipilih
- Info box dengan penjelasan fitur

#### 2. **Visual Indicators**
- Border dan warna berbeda untuk budget recurring
- Icon repeat untuk menunjukkan budget berulang
- Tooltip informatif

### Benefits

1. **Kemudahan**: Tidak perlu buat budget manual setiap periode
2. **Konsistensi**: Budget amount dan settings sama setiap periode
3. **Otomatis**: Background service handle semua proses
4. **Fleksibilitas**: Bisa di-disable kapan saja

### Error Handling

- Validasi overlap budget yang sudah ada
- Silent error handling untuk background tasks  
- Logging untuk debugging
- Graceful degradation jika service error

### Performance

- Efficient query dengan filtering
- Background processing tidak mengganggu UI
- Minimal database operations
- Smart caching dengan provider pattern
