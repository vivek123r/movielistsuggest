# Firebase Setup Instructions

## Prerequisites
1. Install Flutter SDK
2. Install Firebase CLI: `npm install -g firebase-tools`
3. Login to Firebase: `firebase login`

## Step 1: Install Dependencies
```bash
flutter pub get
```

## Step 2: Install FlutterFire CLI
```bash
dart pub global activate flutterfire_cli
```

## Step 3: Configure Firebase for Your Project
Run this command in your project root:
```bash
flutterfire configure
```

This will:
- Ask you to select or create a Firebase project
- Automatically register your app with Firebase
- Download configuration files
- Generate `lib/firebase_options.dart`

**Important:** Select these options when prompted:
- ✅ Android
- ✅ iOS (if needed)
- ✅ Web (if needed)

## Step 4: Enable Authentication Methods in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Authentication** → **Sign-in method**
4. Enable these providers:
   - ✅ **Email/Password**
   - ✅ **Google** (optional but recommended)

### For Google Sign-In (Optional):
1. In Firebase Console, enable Google sign-in
2. Add your SHA-1 certificate fingerprint (for Android):
   ```bash
   cd android
   ./gradlew signingReport
   ```
3. Copy the SHA-1 from the debug variant
4. Add it in Firebase Console: Project Settings → Your apps → Android app

## Step 5: Update Android Configuration (if using Google Sign-In)

Add this to `android/app/build.gradle`:
```gradle
dependencies {
    // ... other dependencies
    implementation 'com.google.android.gms:play-services-auth:20.7.0'
}
```

## Step 6: Run the App
```bash
flutter run
```

## Features Included

### Authentication
- ✅ Email/Password login
- ✅ Email/Password signup
- ✅ Google Sign-In
- ✅ Password reset via email
- ✅ Auto logout/login with Firebase auth state
- ✅ User profile display (email, photo)

### UI Features
- 🎨 Beautiful gradient login page
- 🎨 Clean card-based form design
- 🎨 Show/hide password toggle
- 🎨 Loading indicators
- 🎨 Error messages with snackbars
- 🎨 User avatar in home page header
- 🎨 One-click logout

## File Structure
```
lib/
  ├── pages/
  │   ├── LoginPage.dart          # Login/Signup UI
  │   ├── AuthWrapper.dart        # Authentication state handler
  │   └── HomePage.dart           # Main app (updated with logout)
  ├── services/
  │   └── auth_service.dart       # Firebase Auth logic
  └── main.dart                   # App entry (Firebase initialized)
```

## Troubleshooting

### Error: "No Firebase App"
- Make sure you ran `flutterfire configure`
- Check that `firebase_options.dart` exists in `lib/`

### Google Sign-In not working
- Add SHA-1 fingerprint to Firebase Console
- Enable Google sign-in in Firebase Console
- Re-download `google-services.json` (Android) after adding SHA-1

### iOS build issues
- Run `cd ios && pod install`
- Make sure `GoogleService-Info.plist` is in `ios/Runner/`

## Next Steps
1. Customize the login page colors/design
2. Add user profiles
3. Sync watchlists with Firebase Firestore
4. Add social features

## Support
For Firebase documentation: https://firebase.google.com/docs/flutter/setup
