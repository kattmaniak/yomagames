// This is a skeleton for a game. It is not a complete game and will not run.
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SkeletonGame extends StatelessWidget {
  const SkeletonGame({super.key});

  @override
  Widget build(BuildContext context) {
    int highScore = 0;
    SharedPreferences.getInstance().then((prefs) {
      highScore = prefs.getInt('highScoreSkeleton') ?? 0;
    });
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Welcome to //Skeleton Game Title//!',
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SkeletonGameScreen()),
                );
              },
              child: const Text('Play'),
            ),
            Text('High score: $highScore'),
          ],
        ),
      ),
    );
  }
}

class SkeletonGameScreen extends StatelessWidget {
  const SkeletonGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Skeleton Game Title'),
            SizedBox(
              height: 900,
              width: 400,
              child: GameWidget(
                game: SkeletonGameEngine(),
              ),
            ),
          ],
        ),
      ),
      
    );
  }
}

class SkeletonGameEngine extends FlameGame {
  // variables

  @override
  Future<void> onLoad() async {
    // load assets
  }

  @override
  void update(double dt) {
    super.update(dt);
  
    // update game state
  }
}