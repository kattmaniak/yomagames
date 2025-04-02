import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:flame/game.dart';

class PlanesGame extends StatefulWidget {
  const PlanesGame({super.key});

  @override
  State<PlanesGame> createState() => _PlanesGameState();
}

class _PlanesGameState extends State<PlanesGame> {

  int _highScore = 0;

  _PlanesGameState() {
    // Load the high score from storage
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _highScore = prefs.getInt('highScorePlanes') ?? 0;
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
            const Text(
              'Welcome to the Pilot\'s Aerobatic Adventure!',
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PlanesGameScreen()),
                );
              },
              child: const Text('Play'),
            ),
            Text('High score: $_highScore'),
          ],
        ),
      ),
    );
  }
}

class PlanesGameScreen extends StatelessWidget {
  const PlanesGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Pilot\'s Aerobatic Adventure'),
            SizedBox(
              height: 900,
              width: 400,
              child: GameWidget(
                game: PlanesGameEngine(),
              ),
            ),
          ],
        ),
      ),
      
    );
  }
}

class PlanesGameEngine extends FlameGame with KeyboardEvents {
  late SpriteSheet _spriteSheet;
  late SpriteAnimationComponent _plane;
  double _elapsedAnimationTime = 0;

  final List<String> _commands = ["L","R","U","D"]; // todo change to left, right, up, down when icons are added
  late TextComponent _commandText;
  List<int> commands = [];
  List<int> playerCommands = [];
  double commandTime = 0;

  late SpriteButtonComponent _leftButton;
  late SpriteButtonComponent _rightButton;
  
  int gameState = 0; // 0 sending player commands, 1 displaying commands, 2 listening to player commands, 3 over

  @override
  Future<void> onLoad() async {
    _spriteSheet = SpriteSheet(image: await Flame.images.load('plane.png'), srcSize: Vector2(32,32));
    _plane = SpriteAnimationComponent(
      animation: _spriteSheet.createAnimation(row: 0, stepTime: 0.2),
      position: Vector2(136, 336),
      size: Vector2.all(128),
      playing: false
    );
    add(_plane);

    _leftButton = SpriteButtonComponent(
      position: Vector2(64, 900-256),
      size: Vector2.all(128),
      onPressed: handleLeft,
      button: Sprite(
        await Flame.images.load('left.png'),
        srcSize: Vector2(32,32),
        srcPosition: Vector2(0, 0)
      ),
      buttonDown: Sprite(
        await Flame.images.load('left.png'),
        srcSize: Vector2(32,32),
        srcPosition: Vector2(32, 0)
      )
    );

    _rightButton = SpriteButtonComponent(
      position: Vector2(400-128-64, 900-256),
      size: Vector2.all(128),
      onPressed: handleRight,
      button: Sprite(
        await Flame.images.load('right.png'),
        srcSize: Vector2(32,32),
        srcPosition: Vector2(0, 0)
      ),
      buttonDown: Sprite(
        await Flame.images.load('right.png'),
        srcSize: Vector2(32,32),
        srcPosition: Vector2(32, 0)
      )
    );

    add(_leftButton);
    add(_rightButton);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if(_elapsedAnimationTime > 0) {
      _elapsedAnimationTime -= dt;
      if(_elapsedAnimationTime <= 0) {
        _plane.playing = false;
        _elapsedAnimationTime = 0;
      }
    }
    _plane.update(dt);

    if(gameState == 0) {
      commands = [];
      playerCommands = [];
      for(int i = 0; i < 3; i++) {
        commands.add(Random().nextInt(2)); // todo change to 4 when buttons and animations are added
      }
      _commandText = TextComponent(
        text: commands.map((e) => _commands[e]).join(" "),
        position: Vector2(200, 200),
        scale: Vector2(2,2),
        anchor: Anchor.bottomCenter,
      );
      add(_commandText);
      gameState = 1;
      commandTime = 2;
    } else if (gameState == 1) {
      commandTime -= dt;
      if(commandTime <= 0) {
        remove(_commandText);
        commandTime = 0;
        gameState = 2;
      }
    } else if (gameState == 2) {
      bool fail = false;
      for(int commandIndex = 0; commandIndex < playerCommands.length; commandIndex++) {
        if(playerCommands[commandIndex] != commands[commandIndex]) {
          gameState = 3;
          fail = true;
          _commandText = TextComponent(
            text: "Game over!",
            position: Vector2(200, 200),
            scale: Vector2(2,2),
            anchor: Anchor.bottomCenter,
          );
          add(_commandText);
          break;
        }
      }
      if(!fail && playerCommands.length == commands.length) {
        gameState = 0;
      }
    }
  }

  void handleUp() {
    //todo
  }

  void handleDown() {
    //todo
  }

  void handleLeft() {
    if(_elapsedAnimationTime > 0 || gameState != 2) {
      return;
    }
    _plane.playing = true;
    _plane.animation = _spriteSheet.createAnimation(row: 0, stepTime: 0.2).reversed();
    _elapsedAnimationTime = 0.9;
    playerCommands.add(0);
  }

  void handleRight() {
    if(_elapsedAnimationTime > 0 || gameState != 2) {
      return;
    }
    _plane.playing = true;
    _plane.animation = _spriteSheet.createAnimation(row: 0, stepTime: 0.2);
    _elapsedAnimationTime = 0.9;
    playerCommands.add(1);
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        handleRight();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        handleLeft();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }
}