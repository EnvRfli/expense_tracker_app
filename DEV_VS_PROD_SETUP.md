# 📱 Development vs Production Apps - Setup Guide

## 🎯 Problem Solved
- Production app (v1.0.0) installed on device
- Want to test development features without affecting production
- Need both apps to coexist on same device

## ✅ Solution: Debug vs Release Build Types

### **📦 App Configurations:**

| Build Type | Application ID | App Name | Purpose |
|------------|---------------|----------|---------|
| **Release** | `com.example.expense_tracker_app` | "Expense Tracker" | Stable releases |
| **Debug** | `com.example.expense_tracker_app.debug` | "Expense Tracker DEV" | Development & testing |

## 🚀 Usage Commands

### **Development Testing (Debug):**
```bash
# Run debug version (separate app)
flutter run --debug

# OR simply
flutter run
```

### **Production Testing (Release):**
```bash
# Run release version (production app)
flutter run --release
```

### **Build APKs:**
```bash
# Build debug APK (for development sharing)
flutter build apk --debug

# Build release APK (for production distribution)
flutter build apk --release --split-per-abi
```

## 📱 Result on Device

**You'll have 2 separate apps:**

1. **"Expense Tracker"** (Production)
   - App ID: `com.example.expense_tracker_app`
   - Your stable v1.0.0 app (release build)
   - Production data

2. **"Expense Tracker DEV"** (Development)
   - App ID: `com.example.expense_tracker_app.debug`
   - Development features (debug build)
   - Separate data storage

## ✅ Benefits

- ✅ **Production app untouched** - continues working normally
- ✅ **Separate data** - debug won't affect production data
- ✅ **Test new features** safely
- ✅ **Easy comparison** between versions
- ✅ **Automatic setup** - no complex configuration needed

## 🔄 Daily Development Workflow

```bash
# 1. Work on develop branch
git checkout develop

# 2. Make changes, add features, fix bugs
# Edit code...

# 3. Test with debug build (creates separate app)
flutter run

# 4. Commit changes
git add .
git commit -m "feat: add custom category colors"
git push origin develop

# 5. Production app remains unaffected!
```

## 🚀 Release Workflow

```bash
# When ready for release v1.1.0
git checkout main
git merge develop

# Build production APK
flutter build apk --release --split-per-abi

# Create GitHub Release
# Users can download and install over existing production app
```

## 📊 File Structure

```
android/app/src/
├── main/AndroidManifest.xml          # Base configuration
├── debug/AndroidManifest.xml         # DEV app name override
└── release/                          # (uses main configuration)
```

## 🎯 Key Configuration

### **build.gradle:**
```gradle
buildTypes {
    debug {
        applicationIdSuffix = ".debug"
        versionNameSuffix = "-debug"
        debuggable = true
    }
    release {
        // Production configuration
    }
}
```

### **debug/AndroidManifest.xml:**
```xml
<application
    android:label="Expense Tracker DEV"
    tools:replace="android:label" />
```

---
**Perfect for solo developer! Test safely without breaking production! 🎉**
