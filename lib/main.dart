import 'package:flutter/material.dart';
import 'package:yomagames/bolts.dart';
import 'package:yomagames/carving.dart';
import 'package:yomagames/haggling.dart';
import 'package:yomagames/manager.dart';
import 'package:yomagames/reading.dart';
import 'package:yomagames/words.dart';
import 'dressup.dart';
import 'planes.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yoma Games',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Yoma Games'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Select a game:',
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PlanesGame()),
                );
              },
              child: const Text('Pilot\'s Aerobatic Adventure'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DressUpGame()),
                );
              },
              child: const Text('Mortician\'s Deadly Dressup'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HagglingGame()),
                );
              },
              child: const Text('Salesman\'s Tough Customer'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BoltsGame()),
                );
              },
              child: const Text('Mechanic\'s Messy Machines'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CarvingGame()),
                );
              },
              child: const Text('Ice Sculptor\'s Daring Creation'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManagerGame()),
                );
              },
              child: const Text('Manager\'s Earnest Support'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WordsGame()),
                );
              },
              child: const Text('Rhetorician\'s Exciting Scramble'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReadingGame()),
                );
              },
              child: const Text('Diviner\'s Occult Reading'),
            ),
          ],
        ),
      ),
    );
  }
}
