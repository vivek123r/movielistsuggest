import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:movielistsuggest/pages/HomePage.dart';
import 'package:movielistsuggest/pages/Suggetion.dart';
import 'package:movielistsuggest/pages/watchList.dart';
import 'package:movielistsuggest/pages/StreamingPage.dart';
import 'package:movielistsuggest/pages/AuthWrapper.dart';
import 'package:movielistsuggest/services/movie_list_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Movie List Service at app startup
  final movieListService = MovieListService();
  await movieListService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movie List Suggest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[700],
          elevation: 0,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1E1E1E),
          selectedItemColor: Colors.tealAccent,
          unselectedItemColor: Colors.grey[700],
        ),
        colorScheme: const ColorScheme.dark(
          primary: Colors.tealAccent,
          secondary: Colors.tealAccent,
          surface: Color(0xFF1E1E1E),
          background: Colors.black,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: const AuthWrapper(),
      navigatorObservers: [HeroController()],
      routes: {
        '/home': (context) => const MyHomePage(),
        '/main': (context) => const MainPage(),
        '/suggestion': (context) => const SuggestionPage(),
        '/watchlist': (context) => const WatchListPage(),

      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int selectedIndex = 0;

  List<Widget> pages = [
    const MyHomePage(),
    const SuggestionPage(),
    const WatchListPage(),
    const StreamingPage(),
  ];
  void indexPage(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: pages),
      
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(50)),
          child: BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: indexPage,
            type: BottomNavigationBarType.fixed,
            backgroundColor: const Color(0xFF1E1E1E),
            selectedItemColor: Colors.tealAccent,
            unselectedItemColor: Colors.grey,
            iconSize: 20,
            selectedFontSize: 17,
            unselectedFontSize: 13,
            elevation: 8,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                icon: Icon(Icons.lightbulb),
                label: 'Suggestion',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bookmark),
                label: 'WatchList',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.play_circle_outline),
                label: 'Streaming',
              ),
            ],
          ),
        ),
      ),
    );
  }
}