// This is a skeleton for a game. It is not a complete game and will not run.
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart';
import 'package:super_tooltip/super_tooltip.dart';


class CarvingGame extends StatefulWidget {
  const CarvingGame({super.key});

  @override
  State<CarvingGame> createState() => _CarvingGameState();
}

class _CarvingGameState extends State<CarvingGame> {
  int highScore = 0;
  final _controller = SuperTooltipController();

  _CarvingGameState() {
    // Load the high score from storage
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        highScore = prefs.getInt('highScoreCarving') ?? 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Welcome to Ice Sculptor\'s Daring Creation!',
                ),
                GestureDetector(
                  onTap: () async {
                    await _controller.showTooltip();
                  },
                  child: SuperTooltip(
                    showBarrier: true,
                    controller: _controller,
                    content: const Text(
                      "This game is about carving ice sculptures. Tap to carve the ice, but be careful not to tap too fast or the ice will crack! The goal is to carve the sculpture as quickly as possible without breaking it.",
                      softWrap: true,
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    ),
                    child: Container(
                      width: 40.0,
                      height: 40.0,
                      child: const Icon(
                        Icons.info,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Text('High score: $highScore'),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CarvingGameScreen()),
                );
              },
              child: const Text('Play'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}

class CarvingGameScreen extends StatelessWidget {
  const CarvingGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text('Ice Sculptor\'s Daring Creation'),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Back'),
                ),
              ],
            ),
            SizedBox(
              height: 700,
              width: 400,
              child: GameWidget(
                game: CarvingGameEngine(),
              ),
            ),
          ],
        ),
      ),
      
    );
  }
}

class CarvingGameEngine extends FlameGame with TapCallbacks {
  // Game variables
  late SpriteComponent iceBlock;
  late SpriteComponent sculpture;
  late TextComponent speedText;
  late TextComponent scoreText;
  late TextComponent instructionText;
  
  // Carving variables
  double carvingProgress = 0;
  double carvingSpeed = 0;
  double maxSafeSpeed = 5.1; // Maximum safe taps per second
  double carvingDecayRate = 0.5; // How quickly carving speed decreases
  double lastTapTime = 0;
  
  // Game state
  bool gameStarted = false;
  bool gameOver = false;
  double gameTime = 0;
  int score = 0;
  
  final Random random = Random();
  
  @override
  Color backgroundColor() => const Color(0xFFE3F2FD); // Light blue background
  
  @override
  Future<void> onLoad() async {
    // Load sculpture sprite (initially invisible)
    sculpture = SpriteComponent()
      ..sprite = await Sprite.load('ice_sculpture.png')
      ..size = Vector2(300, 400)
      ..position = Vector2(200, 250)
      ..anchor = Anchor.topCenter;
    
    // Load ice block sprite
    iceBlock = SpriteComponent()
      ..sprite = await Sprite.load('ice_block.png')
      ..size = Vector2(300, 400)
      ..position = Vector2(200, 650)
      ..anchor = Anchor.bottomCenter;
    
    // Add speed meter
    speedText = TextComponent(
      text: 'Carving Speed: 0',
      position: Vector2(200, 220),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 24,
          color: Colors.blue,
          fontWeight: FontWeight.bold,
        )
      ),
      anchor: Anchor.center,
    );
    
    // Add score text
    scoreText = TextComponent(
      text: 'Time: 0.0s',
      position: Vector2(200, 185),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 20,
          color: Colors.black,
        )
      ),
      anchor: Anchor.center,
    );
    
    // Add instruction text
    instructionText = TextComponent(
      text: 'Tap to start carving!\nDon\'t tap too quickly or the ice will crack!',
      position: Vector2(200, 50),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 20,
          color: Colors.black54,
        )
      ),
      anchor: Anchor.center,
    );
    
    add(sculpture);
    add(iceBlock);
    add(speedText);
    add(scoreText);
    add(instructionText);
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (!gameStarted || gameOver) return;
    
    // Update game time
    gameTime += dt;
    scoreText.text = 'Time: ${gameTime.toStringAsFixed(1)}s';
    
    // Decay carving speed over time
    carvingSpeed = max(0, carvingSpeed - (carvingDecayRate * dt));
    speedText.text = 'Carving Speed: ${carvingSpeed.toStringAsFixed(1)}';
    
    // Update colors based on speed
    if (carvingSpeed > maxSafeSpeed * 0.8) {
      speedText.textRenderer = TextPaint(
        style: const TextStyle(
          fontSize: 24,
          color: Colors.red,
          fontWeight: FontWeight.bold,
        )
      );
    } else {
      speedText.textRenderer = TextPaint(
        style: const TextStyle(
          fontSize: 24,
          color: Colors.blue,
          fontWeight: FontWeight.bold,
        )
      );
    }
    
    // Update carving progress based on speed
    double progressIncrement = carvingSpeed * dt * 0.1;
    carvingProgress += progressIncrement;
    
    // Scale ice block down as it's carved
    double scaleBlock = 1.0 - carvingProgress/5.0;
    iceBlock.scale = Vector2(1.0, scaleBlock);
    
    // Check for completion
    if (carvingProgress >= 5.0) {
      completeGame();
    }
  }
  
  @override
  void onTapDown(TapDownEvent event) {
    if (gameOver) {
      resetGame();
      return;
    }
    
    if (!gameStarted) {
      gameStarted = true;
      instructionText.text = 'Carve carefully!';
    }
    
    // Calculate tap speed
    double now = gameTime;
    double timeSinceLastTap = now - lastTapTime;
    lastTapTime = now;
    
    if (timeSinceLastTap > 0.1) {
      // Increase carving speed based on tap frequency
      carvingSpeed += (1.0 / timeSinceLastTap) * 0.5;
      
      // Add visual feedback for tapping
      final tapEffect = CircleComponent(
        radius: 20,
        paint: Paint()..color = Colors.white.withValues(alpha: 0.5),
        position: event.localPosition,
        anchor: Anchor.center,
      );
      
      tapEffect.add(
        ScaleEffect.by(
          Vector2.all(3),
          EffectController(duration: 0.5),
          onComplete: () => tapEffect.removeFromParent(),
        ),
      );
      
      add(tapEffect);
      
      // Check if tapping too fast
      if (carvingSpeed > maxSafeSpeed) {
        speedText.textRenderer = TextPaint(
          style: const TextStyle(
            fontSize: 24,
            color: Colors.red,
            fontWeight: FontWeight.bold,
          )
        );
        speedText.text = 'Carving Speed: ${carvingSpeed.toStringAsFixed(1)}';
        breakIce();
      }
    }
  }
  
  void breakIce() {
    gameOver = true;
    
    // Visual effect for breaking
    sculpture.add(
      SequenceEffect([
        ScaleEffect.by(
          Vector2.all(1.2),
          EffectController(duration: 0.2),
        ),
        OpacityEffect.to(
          0,
          EffectController(duration: 0.3),
        ),
      ]),
    );
    
    // Show game over message
    final gameOverText = TextComponent(
      text: 'Oh no! The ice cracked!',
      position: Vector2(200, 100),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 30,
          color: Colors.red,
          fontWeight: FontWeight.bold,
        )
      ),
      anchor: Anchor.center,
    );
    
    final retryText = TextComponent(
      text: 'Tap to try again',
      position: Vector2(200, 150),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 20,
          color: Colors.black,
        )
      ),
      anchor: Anchor.center,
    );
    
    add(gameOverText);
    add(retryText);
  }
  
  void completeGame() {
    gameOver = true;
    
    // Calculate score based on time (faster is better)
    score = max(0, 110 - (gameTime).round());
    
    // Show completion message
    final successText = TextComponent(
      text: 'Masterpiece Complete!',
      position: Vector2(200, 100),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 30,
          color: Colors.green,
          fontWeight: FontWeight.bold,
        )
      ),
      anchor: Anchor.center,
    );
    
    final finalScoreText = TextComponent(
      text: 'Final Score: $score',
      position: Vector2(200, 50),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 24,
          color: Colors.black,
        )
      ),
      anchor: Anchor.center,
    );
    
    final retryText = TextComponent(
      text: 'Tap to play again',
      position: Vector2(200, 150),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 20,
          color: Colors.black54,
        )
      ),
      anchor: Anchor.center,
    );
    
    remove(instructionText);
    add(successText);
    add(finalScoreText);
    add(retryText);
    
    // Update high score if needed
    SharedPreferences.getInstance().then((prefs) {
      int highScore = prefs.getInt('highScoreCarving') ?? 0;
      if (score > highScore) {
        prefs.setInt('highScoreCarving', score);
      }
    });
  }
  
  void resetGame() {
    remove(iceBlock);
    remove(sculpture);
    remove(speedText);
    remove(scoreText);
    removeAll(children.whereType<TextComponent>());
    
    gameStarted = false;
    gameOver = false;
    carvingProgress = 0;
    carvingSpeed = 0;
    gameTime = 0;
    score = 0;
    lastTapTime = 0;
    
    onLoad();
  }
}