# Google Sign-In Configuration Guide

## Error yang terjadi:
```
I/flutter (28483): Error signing in to Google: PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10: , null, null)
```

Error code 10 biasanya menunjukkan masalah konfigurasi Google Sign-In.

## Langkah-langkah Perbaikan:

### 1. Setup Google Cloud Console Project

1. **Buka Google Cloud Console**
   - Go to https://console.cloud.google.com/
   - Create new project atau pilih existing project

2. **Enable APIs**
   - Go to "APIs & Services" > "Library"
   - Enable these APIs:
     - Google Drive API
     - Google Sign-In API
     - Identity and Access Management (IAM) API

### 2. Create OAuth 2.0 Credentials

1. **Go to Credentials**
   - APIs & Services > Credentials
   - Click "Create Credentials" > "OAuth 2.0 Client ID"

2. **Configure OAuth Consent Screen** (if prompted)
   - User Type: External
   - App name: "Expense Tracker"
   - User support email: your email
   - Developer contact: your email

3. **Create Android OAuth Client**
   - Application type: Android
   - Name: "Expense Tracker Android"
   - Package name: `com.example.expense_tracker_app`
   - SHA-1 certificate fingerprint: [Run get_sha1.bat to get this]

4. **Create Web OAuth Client** (for backend)
   - Application type: Web application
   - Name: "Expense Tracker Web"
   - No authorized URLs needed for this case

### 3. Get SHA-1 Fingerprint

Run the provided script:
```bash
# Windows
get_sha1.bat

# Or manually:
cd %USERPROFILE%\.android
keytool -list -v -keystore debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Copy the SHA1 fingerprint and add it to your Android OAuth client in Google Cloud Console.

### 4. Download google-services.json

1. **In Google Cloud Console:**
   - Go to Project Settings (gear icon)
   - Your apps > Android app
   - Download `google-services.json`

2. **Replace the template file:**
   - Replace `android/app/google-services.json` with the downloaded file

### 5. Update Package Name (Optional)

If you want to use a custom package name instead of `com.example.expense_tracker_app`:

1. **Update android/app/build.gradle:**
   ```gradle
   defaultConfig {
       applicationId "your.custom.package.name"
       // ...
   }
   ```

2. **Update OAuth clients in Google Cloud Console with new package name**

3. **Update google-services.json with new package name**

### 6. Test the Configuration

1. **Clean and rebuild:**
   ```bash
   flutter clean
   flutter pub get
   cd android
   ./gradlew clean
   cd ..
   flutter run
   ```

2. **Test Google Sign-In:**
   - Open app
   - Go to Settings
   - Tap "Login ke Google Drive"
   - Should open Google Sign-In flow

### Troubleshooting

If still getting errors:

1. **Check package name consistency:**
   - android/app/build.gradle
   - google-services.json
   - Google Cloud Console OAuth clients

2. **Verify SHA-1 fingerprint:**
   - Make sure it's added to Android OAuth client
   - For release builds, you'll need release keystore SHA-1

3. **Check API enablement:**
   - Google Drive API
   - Google Sign-In API

4. **Verify google-services.json:**
   - Must be in android/app/ directory
   - Must match your project and package name

## Common Error Codes:

- **10**: Configuration error (SHA-1/package name mismatch)
- **12500**: Internal error (try clearing app data)
- **7**: Network error
- **8**: Internal error
