@echo off
echo Getting SHA-1 fingerprint for Android Debug keystore...
echo.

cd /d "%USERPROFILE%\.android"

if exist debug.keystore (
    echo Debug keystore found. Getting SHA-1 fingerprint...
    echo.
    keytool -list -v -keystore debug.keystore -alias androiddebugkey -storepass android -keypass android | findstr "SHA1:"
    echo.
    echo Copy the SHA1 fingerprint above and add it to your Google Cloud Console:
    echo 1. Go to Google Cloud Console
    echo 2. Select your project
    echo 3. Go to APIs & Services ^> Credentials
    echo 4. Edit your OAuth 2.0 client ID
    echo 5. Add the SHA-1 fingerprint under "Signing-certificate fingerprints"
) else (
    echo Debug keystore not found. Creating one...
    keytool -genkey -v -keystore debug.keystore -alias androiddebugkey -keyalg RSA -keysize 2048 -validity 10000 -storepass android -keypass android -dname "CN=Android Debug,O=Android,C=US"
    echo.
    echo Debug keystore created. Getting SHA-1 fingerprint...
    keytool -list -v -keystore debug.keystore -alias androiddebugkey -storepass android -keypass android | findstr "SHA1:"
)

echo.
pause
