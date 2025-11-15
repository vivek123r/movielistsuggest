import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:movielistsuggest/services/firestore_service.dart';
import 'package:movielistsuggest/services/watch_list_service.dart';
import 'package:movielistsuggest/services/movie_list_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Load user data from Firestore after successful login
      await _loadUserData();
      
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Load user data from Firestore after successful signup
      await _loadUserData();
      
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return null; // User cancelled
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final result = await _auth.signInWithCredential(credential);
      
      // Load user data from Firestore after successful login
      await _loadUserData();
      
      return result;
    } catch (e) {
      throw 'Google Sign-In failed: ${e.toString()}';
    }
  }

  // Sign out
  Future<void> signOut() async {
    // Clear local data before signing out
    await _clearLocalData();
    
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
    
    print('🚪 Signed out and cleared local data');
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Load user data from Firestore
  Future<void> _loadUserData() async {
    try {
      print('📥 Loading user data from Firestore...');
      
      // Check if we need to clear local data (different user)
      await _checkAndClearIfDifferentUser();
      
      // Force reload watchlist
      await WatchListService().reloadWatchList();
      
      // Force reinitialize movie lists and ratings
      await MovieListService().reinitialize();
      
      print('✅ User data loaded successfully');
    } catch (e) {
      print('⚠️ Error loading user data: $e');
      // Continue even if there's an error - user can still use the app
    }
  }

  // Check if user changed and clear local data if needed
  Future<void> _checkAndClearIfDifferentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = _auth.currentUser?.uid;
      final savedUserId = prefs.getString('last_user_id');
      
      if (currentUserId != null && savedUserId != null && currentUserId != savedUserId) {
        // Different user - clear local data
        print('🔄 Different user detected, clearing local data...');
        await _clearLocalData();
      }
      
      // Save current user ID
      if (currentUserId != null) {
        await prefs.setString('last_user_id', currentUserId);
      }
    } catch (e) {
      print('⚠️ Error checking user: $e');
    }
  }

  // Clear local SharedPreferences data
  Future<void> _clearLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear all movie-related data
      await prefs.remove('watchList');
      await prefs.remove('all_movie_lists');
      await prefs.remove('movie_ratings');
      
      print('🧹 Cleared local SharedPreferences data');
    } catch (e) {
      print('⚠️ Error clearing local data: $e');
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }
}
