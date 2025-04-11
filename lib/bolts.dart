// This is a skeleton for a game. It is not a complete game and will not run.
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:math';
import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:super_tooltip/super_tooltip.dart';

class BoltsGame extends StatefulWidget {
  const BoltsGame({super.key});

  @override
  State<BoltsGame> createState() => _BoltsGameState();
}

class _BoltsGameState extends State<BoltsGame> {
  int highScore = 0;
  final _controller = SuperTooltipController();

  _BoltsGameState() {
    // Load the high score from storage
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        highScore = prefs.getInt('highScoreBolts') ?? 0;
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
                  'Welcome to Mechanic\'s Messy Machines!',
                ),
                GestureDetector(
                  onTap: () async {
                    await _controller.showTooltip();
                  },
                  child: SuperTooltip(
                    showBarrier: true,
                    controller: _controller,
                    content: const Text(
                      "This is a game where you tap on bolts to score points. The bolts will appear at random positions and you have to tap them before they disappear. The game gets faster as you progress. Try to get the highest score possible!",
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
                  MaterialPageRoute(builder: (context) => const BoltsGameScreen()),
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

class BoltsGameScreen extends StatelessWidget {
  const BoltsGameScreen({super.key});

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
                const Text('Mechanic\'s Messy Machines'),
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
                game: BoltsGameEngine(),
              ),
            ),
          ],
        ),
      ),
      
    );
  }
}

class BoltsGameEngine extends FlameGame with TapCallbacks {
  // Game variables
  final List<Bolt> bolts = [];
  final Random random = Random();
  double spawnTimer = 0;
  double boltInterval = 2.0; // Time between bolts in seconds
  int score = 0;
  int combo = 0;
  bool gameOver = false;
  
  // UI components
  late TextComponent scoreText;
  late TextComponent comboText;
  late SpriteComponent background;
  
  // Rhythm variables
  final double beatInterval = 1.0; // 1 second per beat
  double beatTimer = 0;
  bool onBeat = false;
  final double hitWindow = 0.33; // Time window to hit a bolt (in seconds)
  
  @override
  Color backgroundColor() => const Color(0xff666666);
  
  @override
  Future<void> onLoad() async {
    // Load background
    background = SpriteComponent()
      ..sprite = await Sprite.load('metal_panel.png')
      ..size = Vector2(400, 700)
      ..position = Vector2(0, 0);
    add(background);
    
    // Add score text
    scoreText = TextComponent(
      text: 'Score: 0',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white, 
          fontSize: 24,
        ),
      ),
      position: Vector2(20, 20),
    );
    add(scoreText);
    
    // Add combo text
    comboText = TextComponent(
      text: 'Combo: 0',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.yellow, 
          fontSize: 20,
        ),
      ),
      position: Vector2(20, 50),
    );
    add(comboText);
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (gameOver) return;
    
    // Update beat timer
    beatTimer += dt;
    if (beatTimer >= beatInterval) {
      beatTimer = 0;
      onBeat = true;

      // Audio cue for beat
      FlameAudio.play('beat.wav');
      
      // Visual cue for beat
      add(BeatIndicator()..position = Vector2(200, 50));
    } else {
      onBeat = false;
    }
    
    // Spawn new bolts
    spawnTimer += dt;
    if (spawnTimer >= boltInterval) {
      spawnTimer = 0;
      spawnBolt();
      
      // Make the game more challenging over time
      if (boltInterval > 0.5) {
        boltInterval *= 0.98;
      }
    }
    
    // Update all bolts
    for (var bolt in [...bolts]) {
      bolt.remainingTime -= dt;
      
      // If bolt timer ran out, it's a miss
      if (bolt.remainingTime <= 0) {
        removeBolt(bolt, false);
        
        // Check for game over
        if (--combo < -5) {
          endGame();
        }
        
        comboText.text = 'Combo: $combo';
      }
    }
  }
  
  void spawnBolt() {
    // Create a new bolt at a random position
    final x = 50 + random.nextDouble() * 300;
    final y = 100 + random.nextDouble() * 550;
    
    final bolt = Bolt()
      ..position = Vector2(x, y)
      ..remainingTime = 3.0; // 3 seconds to tap the bolt
    
    bolts.add(bolt);
    add(bolt);
  }
  
  void removeBolt(Bolt bolt, bool success) {
    bolts.remove(bolt);
    remove(bolt);
    
    if (success) {
      // Add visual feedback
      add(SuccessEffect()..position = bolt.position.clone());
      
      // Update score
      score++;
      combo++;
      scoreText.text = 'Score: $score';
      comboText.text = 'Combo: $combo';
    } else {
      // Add failure visual
      add(FailureEffect()..position = bolt.position.clone());
    }
  }
  
  @override
  void onTapDown(TapDownEvent event) {
    if (gameOver) {
      resetGame();
      return;
    }
    
    // Check if tap is on beat
    bool hitOnBeat = beatTimer < hitWindow || beatTimer > beatInterval - hitWindow;
    
    // Check if tap hits any bolt
    bool hitAny = false;
    for (var bolt in [...bolts]) {
      if (_pointInCircle(bolt.position, 30, event.localPosition)) {
        removeBolt(bolt, hitOnBeat);
        hitAny = true;
        break;
      }
    }
    
    // If tapped but didn't hit any bolt or not on beat
    if (!hitAny || !hitOnBeat) {
      combo--;
      comboText.text = 'Combo: $combo';
      
      // Check for game over
      if (combo < -5) {
        endGame();
      }
    }
  }
  
  bool _pointInCircle(Vector2 center, double radius, Vector2 point) {
    return (center - point).length <= radius;
  }
  
  void endGame() {
    gameOver = true;
    
    // Show game over text
    add(TextComponent(
      text: 'Game Over!',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.red, 
          fontSize: 40,
        ),
      ),
      position: Vector2(200, 400),
      anchor: Anchor.center,
    ));
    
    add(TextComponent(
      text: 'Final Score: $score',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white, 
          fontSize: 30,
        ),
      ),
      position: Vector2(200, 450),
      anchor: Anchor.center,
    ));
    
    add(TextComponent(
      text: 'Tap to play again',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white, 
          fontSize: 20,
        ),
      ),
      position: Vector2(200, 500),
      anchor: Anchor.center,
    ));
    
    // Update high score if needed
    SharedPreferences.getInstance().then((prefs) {
      int highScore = prefs.getInt('highScoreBolts') ?? 0;
      if (score > highScore) {
        prefs.setInt('highScoreBolts', score);
      }
    });
  }
  
  void resetGame() {
    // Remove all components
    removeAll(children);
    
    // Reset game variables
    bolts.clear();
    score = 0;
    combo = 0;
    gameOver = false;
    spawnTimer = 0;
    boltInterval = 2.0;
    beatTimer = 0;
    
    // Reload initial components
    onLoad();
  }
}

class Bolt extends SpriteComponent {
  Bolt() : super(size: Vector2(60, 60), anchor: Anchor.center);
  
  double remainingTime = 3.0;
  
  @override
  FutureOr<void> onLoad() async {
    sprite = await Sprite.load('bolt.png');
    return super.onLoad();
  }
  
  @override
  void render(Canvas canvas) {
    // Render with rotation based on remaining time
    angle = (3.0 - remainingTime) * 1.5;
    super.render(canvas);
  }
}

class BeatIndicator extends CircleComponent {
  BeatIndicator() : super(
    radius: 10,
    paint: Paint()..color = Colors.white,
    anchor: Anchor.center,
  );
  
  double lifeTime = 0.4;
  
  @override
  void update(double dt) {
    super.update(dt);
    
    lifeTime -= dt;
    if (lifeTime <= 0) {
      removeFromParent();
    }
    
    radius += dt * 30;
    paint.color = paint.color.withValues(alpha: lifeTime / 0.4);
  }
}

class SuccessEffect extends SpriteAnimationComponent {
  SuccessEffect() : super(size: Vector2(80, 80), anchor: Anchor.center);
  
  @override
  FutureOr<void> onLoad() async {
    final spriteSheet = await Flame.images.load('screw_success.png');
    animation = SpriteAnimation.fromFrameData(
      spriteSheet,
      SpriteAnimationData.sequenced(
        amount: 5,
        textureSize: Vector2(32, 32),
        stepTime: 0.1,
        loop: false,
      ),
    );

    removeAfter();

    return super.onLoad();
  }

  void removeAfter() async {
    await Future.delayed(const Duration(seconds: 2));
    // Fade out effect
    final effect = OpacityEffect.to(
      0.0, 
      EffectController(duration: 1.0)
    );
    add(effect);
    await Future.delayed(const Duration(seconds: 1));

    removeFromParent();
  }
}

class FailureEffect extends SpriteAnimationComponent {
  FailureEffect() : super(size: Vector2(80, 80), anchor: Anchor.center);
  
  @override
  FutureOr<void> onLoad() async {
    final spriteSheet = await Flame.images.load('screw_failure.png');
    animation = SpriteAnimation.fromFrameData(
      spriteSheet,
      SpriteAnimationData.sequenced(
        amount: 5,
        textureSize: Vector2(32, 32),
        stepTime: 0.1,
        loop: false,
      ),
    );

    removeAfter();

    return super.onLoad();
  }

  void removeAfter() async {
    await Future.delayed(const Duration(seconds: 2));
    // Fade out effect
    final effect = OpacityEffect.to(
      0.0, 
      EffectController(duration: 1.0)
    );
    add(effect);
    await Future.delayed(const Duration(seconds: 1));

    removeFromParent();
  }
}