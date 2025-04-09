import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flame/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:flame/game.dart';
import 'package:yomagames/haggling.dart';

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
              height: 700,
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

  int rotating = 0; // 0 none, 1 up, -1 down

  final List<String> _commands = ["L","R","U","D"]; // todo change to left, right, up, down when icons are added
  late TextComponent _commandText;
  List<int> commands = [];
  List<int> playerCommands = [];
  double commandTime = 0;

  late SpriteButtonComponent _leftButton;
  late SpriteButtonComponent _rightButton;
  late SpriteButtonComponent _upButton;
  late SpriteButtonComponent _downButton;

  @override
  Color backgroundColor() => Colors.lightBlue;
  
  int gameState = 0; // 0 sending player commands, 1 displaying commands, 2 listening to player commands, 3 over

  int score = 0;
  late TextComponent _scoreText;

  @override
  Future<void> onLoad() async {
    _spriteSheet = SpriteSheet(image: await Flame.images.load('plane.png'), srcSize: Vector2(32,32));
    _plane = SpriteAnimationComponent(
      animation: _spriteSheet.createAnimation(row: 0, stepTime: 0.2),
      position: Vector2(136, 186),
      size: Vector2.all(128),
      playing: false
    );

    _plane.decorator.addLast(Decorator());

    add(_plane);

    _scoreText = TextComponent(
      text: "Score: $score",
      position: Vector2(200, 700-8),
      scale: Vector2(2,2),
      anchor: Anchor.bottomCenter,
    );
    add(_scoreText);

    _leftButton = SpriteButtonComponent(
      position: Vector2(68, 700-72-64-64),
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
      ),
      anchor: Anchor.center,
    );

    _rightButton = SpriteButtonComponent(
      position: Vector2(400-68, 700-72-64-64),
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
      ),
      anchor: Anchor.center,
    );

    _upButton = SpriteButtonComponent(
      position: Vector2(200, 700-68-8-128-64),
      size: Vector2.all(128),
      onPressed: handleUp,
      button: Sprite(
        await Flame.images.load('right.png'),
        srcSize: Vector2(32,32),
        srcPosition: Vector2(0, 0)
      ),
      buttonDown: Sprite(
        await Flame.images.load('right.png'),
        srcSize: Vector2(32,32),
        srcPosition: Vector2(32, 0)
      ),
      anchor: Anchor.center,
      angle: -3.14159 / 2,
    );

    _downButton = SpriteButtonComponent(
      position: Vector2(200, 700-72-64),
      size: Vector2.all(128),
      onPressed: handleDown,
      button: Sprite(
        await Flame.images.load('right.png'),
        srcSize: Vector2(32,32),
        srcPosition: Vector2(0, 0)
      ),
      buttonDown: Sprite(
        await Flame.images.load('right.png'),
        srcSize: Vector2(32,32),
        srcPosition: Vector2(32, 0)
      ),
      anchor: Anchor.center,
      angle: 3.14159 / 2,
    );

    add(_leftButton);
    add(_rightButton);
    add(_upButton);
    add(_downButton);
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
      if(rotating == 1) {
        double remainingTime = _elapsedAnimationTime / 0.9;
        double angle = 0;
        if(remainingTime > 0.5) {
          angle = -1.5*remainingTime + 1.5;
        } else {
          angle = 1.5*remainingTime;
        }
        Rotate3DDecorator rotate = Rotate3DDecorator(
          center: Vector2.all(64),
          angleX: angle,
          perspective: 0.002,
        );
        _plane.decorator.replaceLast(rotate);
      } else if(rotating == -1) {
        double remainingTime = _elapsedAnimationTime / 0.9;
        double angle = 0;
        if(remainingTime > 0.5) {
          angle = -1.5*remainingTime + 1.5;
        } else {
          angle = 1.5*remainingTime;
        }
        Rotate3DDecorator rotate = Rotate3DDecorator(
          center: Vector2.all(64),
          angleX: -angle,
          perspective: 0.002,
        );
        _plane.decorator.replaceLast(rotate);
      }
    }
    _plane.update(dt);

    if(gameState == 0) {
      commands = [];
      playerCommands = [];
      for(int i = 0; i < 2+score/2; i++) {
        commands.add(Random().nextInt(4)); // todo change to 4 when buttons and animations are added
      }
      _commandText = TextComponent(
        text: commands.map((e) => _commands[e]).join(" "),
        position: Vector2(200, 150),
        scale: Vector2(2,2),
        anchor: Anchor.bottomCenter,
      );
      _commandText.text += " ";
      for(int i = 11; i < _commandText.text.length; i+=12) {
        _commandText.text = "${_commandText.text.substring(0, i)}\n${_commandText.text.substring(i+1)}";
      }
      add(_commandText);
      gameState = 1;
      commandTime = 2;
      remove(_leftButton);
      remove(_rightButton);
      remove(_upButton);
      remove(_downButton);
    } else if (gameState == 1) {
      commandTime -= dt;
      if(commandTime <= 0) {
        remove(_commandText);
        commandTime = 0;
        gameState = 2;
        add(_leftButton);
        add(_rightButton);
        add(_upButton);
        add(_downButton);
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

          SharedPreferences.getInstance().then((prefs) {
            int highScore = prefs.getInt('highScorePlanes') ?? 0;
            if (score > highScore) {
              prefs.setInt('highScorePlanes', score);
            }
          });

          late TextButtonComponent retryButton;
          retryButton = TextButtonComponent(
            text: "Retry",
            buttonColor: Colors.blueGrey,
            onPressed: () {
              remove(_commandText);
              remove(retryButton);
              gameState = 0;
              playerCommands.clear();
              commands.clear();
              score = 0;
            },
          )..position = Vector2(200, 250)
            ..anchor = Anchor.center
            ..scale = Vector2(2,2);
          add(retryButton);
          break;
        }
      }
      if(!fail && playerCommands.length == commands.length) {
        gameState = 0;
        score++;
        _scoreText.text = "Score: $score";
      }
    }
  }

  void handleUp() {
    if(_elapsedAnimationTime > 0 || gameState != 2) {
      return;
    }
    _elapsedAnimationTime = 0.9;
    rotating = 1;
    stopRotate();
    playerCommands.add(2);
  }

  void handleDown() {
    if(_elapsedAnimationTime > 0 || gameState != 2) {
      return;
    }
    _elapsedAnimationTime = 0.9;
    rotating = -1;
    stopRotate();
    playerCommands.add(3);
  }

  Future<void> stopRotate() async {
    await Future.delayed(const Duration(milliseconds: 900));
    _elapsedAnimationTime = 0;
    rotating = 0;
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