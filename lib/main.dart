import 'package:flutter/material.dart';
import 'package:movielistsuggest/pages/HomePage.dart';
import 'package:movielistsuggest/pages/Suggetion.dart';
import 'package:movielistsuggest/pages/watchList.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainPage(),
      navigatorObservers: [HeroController()],
      routes: {
        '/home': (context) => const MyHomePage(),
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
        margin: EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(50)),
          child: BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: indexPage,
            type: BottomNavigationBarType.fixed,
            backgroundColor: const Color.fromARGB(255, 164, 193, 216),
            selectedItemColor: const Color.fromARGB(255, 179, 45, 45),
            unselectedItemColor: Colors.white70,
            iconSize: 20,
            selectedFontSize: 17,
            unselectedFontSize: 13,
            elevation: 15,
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
            ],
          ),
        ),
      ),
    );
  }
}
