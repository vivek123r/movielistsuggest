# Firebase Firestore Setup Guide

## What Has Been Implemented

I've successfully integrated Firebase Firestore for cloud data storage in your movie app. Here's what was done:

### 1. **Added Firestore Dependency** ✅
- Added `cloud_firestore: ^5.4.4` to `pubspec.yaml`
- Successfully installed with `flutter pub get`

### 2. **Created FirestoreService** ✅
**File:** `lib/services/firestore_service.dart`

A singleton service that handles all cloud data operations:

**Firestore Structure:**
```
users/
  {userId}/
    data/
      - watchlist (document)
      - movie_lists (document)
      - ratings (document)
```

**Available Methods:**
- `saveWatchlist(List<Movie>)` - Save watchlist to cloud
- `loadWatchlist()` - Load watchlist from cloud
- `saveMovieLists(Map)` - Save custom movie lists
- `loadMovieLists()` - Load custom movie lists
- `saveRatings(Map<int, double>)` - Save user ratings
- `loadRatings()` - Load user ratings
- `saveUserProfile(Map)` - Save profile data
- `loadUserProfile()` - Load profile data
- `clearUserData()` - Delete all user data (batch operation)
- `syncAllData()` - Sync all data to cloud in one call

### 3. **Updated WatchListService** ✅
**File:** `lib/services/watch_list_service.dart`

**Changes:**
- `addMovie()` now syncs to Firestore after adding
- `removeMovie()` now syncs to Firestore after removing
- `loadWatchList()` tries Firestore first, falls back to local storage
- Automatically migrates local data to Firestore on first load

### 4. **Updated MovieListService** ✅
**File:** `lib/services/movie_list_service.dart`

**Changes:**
- `_loadFromStorage()` tries Firestore first for lists and ratings
- `_saveToStorage()` syncs both lists and ratings to Firestore
- Automatically migrates local data to Firestore on first load
- All create/delete/rename operations sync to cloud

### 5. **Updated AuthService** ✅
**File:** `lib/services/auth_service.dart`

**Changes:**
- `signInWithEmail()` loads user data from Firestore after login
- `signUpWithEmail()` loads user data from Firestore after signup
- `signInWithGoogle()` loads user data from Firestore after login
- Added `_loadUserData()` helper method to load all user data on authentication

## How It Works

### Data Sync Strategy
1. **On App Launch:** Services load from Firestore first, fall back to local storage
2. **On Data Change:** Immediately sync to both local storage and Firestore
3. **On Login:** Load all user data from Firestore
4. **On Logout:** Local data is kept cached (will reload from Firestore on next login)

### Offline Support
- All data is still saved locally with SharedPreferences
- App works offline with cached data
- When online, data syncs automatically
- Firestore handles sync conflicts automatically

### User Isolation
- Each user's data is stored under `users/{userId}/data/`
- Users can only access their own data (enforced by Firestore security rules)
- No data sharing between accounts

## Required: Enable Firestore in Firebase Console

⚠️ **IMPORTANT:** You need to enable Firestore in your Firebase project:

### Steps:

1. **Go to Firebase Console**
   - Visit: https://console.firebase.google.com
   - Select your project

2. **Enable Firestore Database**
   - Click "Build" in left sidebar
   - Click "Firestore Database"
   - Click "Create database"

3. **Choose Mode**
   - **For Development:** Select "Test mode" (allows read/write for 30 days)
   - **For Production:** Select "Production mode" (recommended)

4. **Select Region**
   - Choose the region closest to your users
   - Example: `us-central1`, `europe-west1`, `asia-south1`

5. **Set Security Rules** (REQUIRED for production)

Click "Rules" tab and use these security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow users to read/write only their own data
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

**What these rules do:**
- Users must be authenticated to access data
- Users can only access data under `users/{their_userId}/`
- Prevents unauthorized access to other users' data

## Testing Your Integration

### Test Locally:

1. **Sign in to the app**
2. **Add movies to your watchlist**
3. **Create a custom list**
4. **Rate some movies**
5. **Sign out**
6. **Sign back in**
7. **Verify all your data is still there**

### Verify in Firebase Console:

1. Go to Firestore Database in Firebase Console
2. You should see a `users` collection
3. Click on your user ID
4. You should see documents for `watchlist`, `movie_lists`, and `ratings`

### Check Logs:

The app prints helpful logs:
- `📂 Loaded X lists from Firestore` - Successful cloud load
- `📥 Loading user data from Firestore...` - Loading on login
- `💾 Saved X lists and Y ratings to storage` - Successful sync
- `⚠️ Could not load from Firestore, falling back to local` - Offline or Firestore not enabled

## Benefits of This Implementation

✅ **Cloud Backup** - Your data is safe even if you uninstall the app
✅ **Multi-Device Sync** - Use the app on multiple devices with same account
✅ **No Data Loss** - Data persists across logout/login
✅ **Offline Support** - App works offline with local cache
✅ **Automatic Migration** - Existing local data is automatically uploaded to Firestore
✅ **User Privacy** - Each user's data is isolated with security rules
✅ **Scalable** - Firestore handles millions of users

## Data Structure Examples

### Watchlist Document
```json
{
  "movies": [
    {
      "id": 123,
      "title": "Inception",
      "overview": "...",
      "posterPath": "/...",
      "voteAverage": 8.8
    }
  ],
  "updatedAt": "2025-01-08T10:30:00Z"
}
```

### Movie Lists Document
```json
{
  "watchlist": {
    "id": "watchlist",
    "name": "My Watch List",
    "movies": [...],
    "createdAt": "...",
    "isDefault": true
  },
  "list_1234567890": {
    "id": "list_1234567890",
    "name": "Favorites",
    "movies": [...],
    "createdAt": "...",
    "isDefault": false
  },
  "updatedAt": "2025-01-08T10:30:00Z"
}
```

### Ratings Document
```json
{
  "ratings": {
    "123": 9.0,
    "456": 7.5,
    "789": 8.5
  },
  "updatedAt": "2025-01-08T10:30:00Z"
}
```

## Troubleshooting

### "Permission denied" errors:
- Make sure Firestore is enabled in Firebase Console
- Check security rules allow authenticated users
- Verify user is signed in

### Data not syncing:
- Check internet connection
- Look for error logs in console
- Verify Firebase project is configured correctly

### "User not found" errors:
- User must be signed in to access Firestore
- Check `FirebaseAuth.instance.currentUser` is not null

## Next Steps

1. ✅ **Enable Firestore** in Firebase Console (required)
2. ✅ **Set security rules** for production
3. ✅ **Test the integration** with your account
4. ✅ **Monitor usage** in Firebase Console

## Cost Considerations

Firestore Free Tier (per day):
- 50,000 document reads
- 20,000 document writes
- 20,000 document deletes
- 1 GB storage

For a typical user:
- Login: ~3 reads (watchlist, lists, ratings)
- Add movie: 1 write
- Remove movie: 1 write
- Create list: 1 write

This is very generous for small to medium apps!

## Support

If you encounter any issues:
1. Check the logs in your terminal
2. Verify Firestore is enabled in Firebase Console
3. Ensure security rules are set correctly
4. Test with a fresh account to rule out data corruption

---

**Your app now has enterprise-grade cloud data storage! 🎉**
