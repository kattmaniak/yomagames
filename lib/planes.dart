import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/input.dart';
import 'package:flame/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:flame/game.dart';
import 'package:super_tooltip/super_tooltip.dart';

class PlanesGame extends StatefulWidget {
  const PlanesGame({super.key});

  @override
  State<PlanesGame> createState() => _PlanesGameState();
}

class _PlanesGameState extends State<PlanesGame> {
  int highScore = 0;
  final _controller = SuperTooltipController();

  _PlanesGameState() {
    // Load the high score from storage
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        highScore = prefs.getInt('highScorePlanes') ?? 0;
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
                  'Welcome to Pilot\'s Aerobatic Adventure!',
                ),
                const Text(
                  'Hidden text \u{2190} \u{2192} \u{2191} \u{2193}',
                  style: TextStyle(
                    fontSize: 0,
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    await _controller.showTooltip();
                  },
                  child: SuperTooltip(
                    showBarrier: true,
                    controller: _controller,
                    content: const Text(
                      "This is a game where you control a plane and perform aerobatic maneuvers. The goal is to follow the commands (\u{2190} \u{2192} \u{2191} \u{2193}) displayed on the screen. Use the buttons or arrow keys to control the plane's movements. Good luck!",
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
                  MaterialPageRoute(builder: (context) => const PlanesGameScreen()),
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

double wu = 1.0; // width unit, used to scale the game to fit the screen

class PlanesGameScreen extends StatelessWidget {
  const PlanesGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double deviceWidth = MediaQuery.of(context).size.width;
    if(deviceWidth > 400) {
      deviceWidth = 400;
    }
    wu = deviceWidth / 400;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text('Pilot\'s Aerobatic Adventure'),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Back'),
                  ),
                ],
              ),
              SizedBox(
                height: 700*wu,
                width: 400*wu,
                child: GameWidget(
                  game: PlanesGameEngine(),
                ),
              ),
              SizedBox(
                height: 400*wu,
                width: 700*wu,
              ),
            ],
          ),
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

  final List<String> _commands = ["\u{2190}","\u{2192}","\u{2191}","\u{2193}"]; // todo change to left, right, up, down when icons are added
  
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
      position: Vector2(136*wu, 186*wu),
      size: Vector2.all(128*wu),
      playing: false
    );

    _plane.decorator.addLast(Decorator());

    add(_plane);

    final TextComponent unicodeIconLoadBodge = TextComponent(
      text: "L\u{2190}",
      position: Vector2(-200*wu, -150*wu),
      scale: Vector2(2,2),
      anchor: Anchor.bottomCenter,
    );
    add(unicodeIconLoadBodge);

    _scoreText = TextComponent(
      text: "Score: $score",
      position: Vector2(200*wu, (700-8)*wu),
      scale: Vector2(2,2),
      anchor: Anchor.bottomCenter,
    );
    add(_scoreText);

    _leftButton = SpriteButtonComponent(
      position: Vector2(68*wu, (700-72-64-64)*wu),
      size: Vector2.all(128*wu),
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
      position: Vector2((400-68)*wu, (700-72-64-64)*wu),
      size: Vector2.all(128*wu),
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
      position: Vector2(200*wu, (700-68-8-128-64)*wu),
      size: Vector2.all(128*wu),
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
      position: Vector2(200*wu, (700-72-64)*wu),
      size: Vector2.all(128*wu),
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
          center: Vector2.all(64*wu),
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
          center: Vector2.all(64*wu),
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
        position: Vector2(200*wu, 140*wu),
        scale: Vector2(2,2),
        anchor: Anchor.center,
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
            position: Vector2(200*wu, 200*wu),
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
          )..position = Vector2(200*wu, 250*wu)
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


class TextButtonComponent extends TextComponent with TapCallbacks {
  @override
  final String text;
  final Color buttonColor;
  final VoidCallback onPressed;

  TextButtonComponent({
    required this.text,
    required this.buttonColor,
    required this.onPressed,
  }) : super (
    text: text,
    position: Vector2(0, 0),
    textRenderer: TextPaint(
      style: TextStyle(
        fontSize: 23,
        color: Colors.white,
        backgroundColor: buttonColor
      ),
    ),
  ) {
    anchor = Anchor.center;
  }

  @override
  bool onTapDown(TapDownEvent event) {
    onPressed();
    return true;
  }
}