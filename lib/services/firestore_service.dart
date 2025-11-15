import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:movielistsuggest/models/movie.dart';
import 'dart:convert';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  // Save watchlist to Firestore
  Future<void> saveWatchlist(List<Movie> movies) async {
    if (_userId == null) {
      print('⚠️ No user ID, cannot save watchlist to Firestore');
      return;
    }
    
    try {
      print('💾 Saving ${movies.length} movies to Firestore for user: $_userId');
      final movieData = movies.map((m) => m.toJson()).toList();
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('data')
          .doc('watchlist')
          .set({
        'movies': movieData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Watchlist saved to Firestore successfully');
    } catch (e) {
      print('❌ Error saving watchlist to Firestore: $e');
    }
  }

  // Load watchlist from Firestore
  Future<List<Movie>> loadWatchlist() async {
    if (_userId == null) {
      print('⚠️ No user ID, cannot load watchlist from Firestore');
      return [];
    }
    
    try {
      print('🔍 Attempting to load watchlist from Firestore for user: $_userId');
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('data')
          .doc('watchlist')
          .get();
      
      print('📄 Firestore document exists: ${doc.exists}');
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        print('📦 Firestore data keys: ${data.keys.toList()}');
        
        if (data['movies'] != null) {
          final List<dynamic> movieList = data['movies'];
          print('✅ Found ${movieList.length} movies in Firestore');
          return movieList.map((m) => Movie.fromJson(m)).toList();
        } else {
          print('⚠️ No movies field in Firestore document');
        }
      } else {
        print('⚠️ Firestore watchlist document does not exist or is empty');
      }
      return [];
    } catch (e) {
      print('❌ Error loading watchlist from Firestore: $e');
      return [];
    }
  }

  // Save custom movie lists to Firestore
  Future<void> saveMovieLists(Map<String, dynamic> listsData) async {
    if (_userId == null) {
      print('⚠️ No user ID, cannot save movie lists to Firestore');
      return;
    }
    
    try {
      print('💾 Saving ${listsData.length} lists to Firestore for user: $_userId');
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('data')
          .doc('movie_lists')
          .set({
        'lists': listsData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Movie lists saved to Firestore successfully');
    } catch (e) {
      print('❌ Error saving movie lists to Firestore: $e');
    }
  }

  // Load custom movie lists from Firestore
  Future<Map<String, dynamic>?> loadMovieLists() async {
    if (_userId == null) {
      print('⚠️ No user ID, cannot load movie lists from Firestore');
      return null;
    }
    
    try {
      print('🔍 Attempting to load movie lists from Firestore for user: $_userId');
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('data')
          .doc('movie_lists')
          .get();
      
      print('📄 Firestore movie_lists document exists: ${doc.exists}');
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        print('📦 Firestore data keys: ${data.keys.toList()}');
        
        if (data['lists'] != null) {
          final lists = data['lists'] as Map<String, dynamic>;
          print('✅ Found ${lists.length} lists in Firestore');
          return lists;
        } else {
          print('⚠️ No lists field in Firestore document');
        }
      } else {
        print('⚠️ Firestore movie_lists document does not exist or is empty');
      }
      return null;
    } catch (e) {
      print('❌ Error loading movie lists from Firestore: $e');
      return null;
    }
  }

  // Save movie ratings to Firestore
  Future<void> saveRatings(Map<int, double> ratings) async {
    if (_userId == null) {
      print('⚠️ No user ID, cannot save ratings to Firestore');
      return;
    }
    
    try {
      print('💾 Saving ${ratings.length} ratings to Firestore for user: $_userId');
      // Convert int keys to strings for Firestore
      final ratingsData = ratings.map((key, value) => MapEntry(key.toString(), value));
      
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('data')
          .doc('ratings')
          .set({
        'ratings': ratingsData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Ratings saved to Firestore successfully');
    } catch (e) {
      print('❌ Error saving ratings to Firestore: $e');
    }
  }

  // Load movie ratings from Firestore
  Future<Map<int, double>> loadRatings() async {
    if (_userId == null) {
      print('⚠️ No user ID, cannot load ratings from Firestore');
      return {};
    }
    
    try {
      print('🔍 Attempting to load ratings from Firestore for user: $_userId');
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('data')
          .doc('ratings')
          .get();
      
      print('📄 Firestore ratings document exists: ${doc.exists}');
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        print('📦 Firestore data keys: ${data.keys.toList()}');
        
        if (data['ratings'] != null) {
          final ratingsData = data['ratings'] as Map<String, dynamic>;
          print('✅ Found ${ratingsData.length} ratings in Firestore');
          // Convert string keys back to int
          return ratingsData.map((key, value) => MapEntry(int.parse(key), value as double));
        } else {
          print('⚠️ No ratings field in Firestore document');
        }
      } else {
        print('⚠️ Firestore ratings document does not exist or is empty');
      }
      return {};
    } catch (e) {
      print('❌ Error loading ratings from Firestore: $e');
      return {};
    }
  }

  // Save user profile data
  Future<void> saveUserProfile(Map<String, dynamic> profileData) async {
    if (_userId == null) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .set(profileData, SetOptions(merge: true));
      print('User profile saved to Firestore');
    } catch (e) {
      print('Error saving user profile: $e');
    }
  }

  // Load user profile data
  Future<Map<String, dynamic>?> loadUserProfile() async {
    if (_userId == null) return null;
    
    try {
      final doc = await _firestore.collection('users').doc(_userId).get();
      return doc.data();
    } catch (e) {
      print('Error loading user profile: $e');
      return null;
    }
  }

  // Clear all user data (for logout/delete account)
  Future<void> clearUserData() async {
    if (_userId == null) return;
    
    try {
      final batch = _firestore.batch();
      
      // Delete watchlist
      batch.delete(_firestore
          .collection('users')
          .doc(_userId)
          .collection('data')
          .doc('watchlist'));
      
      // Delete movie lists
      batch.delete(_firestore
          .collection('users')
          .doc(_userId)
          .collection('data')
          .doc('movie_lists'));
      
      // Delete ratings
      batch.delete(_firestore
          .collection('users')
          .doc(_userId)
          .collection('data')
          .doc('ratings'));
      
      await batch.commit();
      print('User data cleared from Firestore');
    } catch (e) {
      print('Error clearing user data: $e');
    }
  }

  // Sync local data to Firestore (call this periodically or on app close)
  Future<void> syncAllData({
    List<Movie>? watchlist,
    Map<String, dynamic>? movieLists,
    Map<int, double>? ratings,
  }) async {
    if (_userId == null) return;
    
    try {
      if (watchlist != null) await saveWatchlist(watchlist);
      if (movieLists != null) await saveMovieLists(movieLists);
      if (ratings != null) await saveRatings(ratings);
      print('All data synced to Firestore');
    } catch (e) {
      print('Error syncing data: $e');
    }
  }
}
