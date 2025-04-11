// This is a skeleton for a game. It is not a complete game and will not run.
import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/rendering.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DressUpGame extends StatefulWidget {
  const DressUpGame({super.key});

  @override
  State<DressUpGame> createState() => _DressUpGameState();
}

class _DressUpGameState extends State<DressUpGame> {
  int _highScore = 0;

  _DressUpGameState() {
    // Load the high score from storage
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _highScore = prefs.getInt('highScoreDressup') ?? 0;
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
              'Welcome to Mortician\'s Deadly Dressup!',
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DressUpGameScreen()),
                );
              },
              child: const Text('Play'),
            ),
            Text('High score: $_highScore'),
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

class DressUpGameScreen extends StatelessWidget {
  const DressUpGameScreen({super.key});

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
                const Text('Mortician\'s Deadly Dressup'),
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
                game: DressUpGameEngine(),
              ),
            ),
          ],
        ),
      ),
      
    );
  }
}

class PieceData {
  final String imagePath;
  final ClothingType type;
  final ClothingStyle style;
  final int score;

  PieceData({
    required this.imagePath,
    required this.type,
    required this.style,
    required this.score,
  });
}

List<PieceData> piecesData = [
  PieceData(
    imagePath: 'hat.png',
    type: ClothingType.hat,
    style: ClothingStyle.goth,
    score: 10,
  ),
  PieceData(
    imagePath: 'shirt.png',
    type: ClothingType.shirt,
    style: ClothingStyle.goth,
    score: 20,
  ),
  PieceData(
    imagePath: 'khakis.png',
    type: ClothingType.pants,
    style: ClothingStyle.goth,
    score: 30,
  ),
  PieceData(
    imagePath: 'pants.png',
    type: ClothingType.pants,
    style: ClothingStyle.punk,
    score: 30,
  ),
  PieceData(
    imagePath: 'beanie.png',
    type: ClothingType.hat,
    style: ClothingStyle.punk,
    score: 15,
  ),
  PieceData(
    imagePath: 'tiedye.png',
    type: ClothingType.shirt,
    style: ClothingStyle.punk,
    score: 25,
  ),
  PieceData(
    imagePath: 'funnyhat.png',
    type: ClothingType.hat,
    style: ClothingStyle.fine,
    score: 5,
  ),
  PieceData(
    imagePath: 'dress.png',
    type: ClothingType.shirt,
    style: ClothingStyle.fine,
    score: 50,
  ),
  PieceData(
    imagePath: 'stockings.png',
    type: ClothingType.pants,
    style: ClothingStyle.fine,
    score: 10,
  ),
];

Map<ClothingStyle, List> colorMap = {
  ClothingStyle.goth: [Colors.black, Colors.red, Colors.white, Colors.purple],
  ClothingStyle.punk: [Colors.white, Colors.blue, Colors.red, Colors.yellow],
  ClothingStyle.fine: [Colors.purple, Colors.yellow, Colors.blue, Colors.black],
};

Future<ClothingPiece> loadClothingPiece(String imagePath) async {
  for (var pieceData in piecesData) {
    if (pieceData.imagePath == imagePath) {
      final sprite = Sprite(await Flame.images.load(pieceData.imagePath));
      final color = colorMap[pieceData.style]![Random().nextInt(colorMap[pieceData.style]!.length)];
      return ClothingPiece(
        sprite: sprite,
        width: sprite.originalSize.x,
        height: sprite.originalSize.y,
        type: pieceData.type,
        style: pieceData.style,
        color: color,
        score: pieceData.score + Random().nextInt(5),
      )..anchor = Anchor.center;
    }
  }
  throw Exception('Clothing piece not found');
}

class DressUpGameEngine extends FlameGame {
  // variables
  late SpriteComponent body;
  List<ClothingPiece> clothes = [];

  bool finished = false;
  late ButtonComponent finalizeButton;
  late ButtonComponent replayButton;

  HashMap<ClothingType, ClothingPiece> selectedClothes = HashMap<ClothingType, ClothingPiece>();

  int score = 0;

  static DressUpGameEngine? instance;

  @override
  Color backgroundColor() => Colors.grey;

  @override
  Future<void> onLoad() async {
    instance = this;
    add(hatHitbox);
    add(shirtHitbox);
    add(pantsHitbox);

    final background = SpriteComponent()
      ..sprite = Sprite(await Flame.images.load('morgue.png'), srcSize: Vector2(400, 700), srcPosition: Vector2.zero())
      ..size = Vector2(400, 700)
      ..anchor = Anchor.center
      ..position = Vector2(200, 350);
    add(background);

    // load assets
    body = SpriteComponent()
      ..sprite = Sprite(await Flame.images.load('body.png'), srcSize: Vector2(100, 250), srcPosition: Vector2.zero())
      ..size = Vector2(100, 250)
      ..anchor = Anchor.center
      ..position = Vector2(200, 350)
      ..scale = Vector2(2, 2);

    add(body);

    List<Vector2> positions = [
      Vector2(75, 100),
      Vector2(75, 300),
      Vector2(75, 500),
      Vector2(325, 100),
      Vector2(325, 300),
      Vector2(325, 500),
    ];

    //todo load random pieces?

    final piecesCopy = List<PieceData>.from(piecesData);

    for (var pos in positions) {
      if (piecesCopy.isEmpty) break;
      int randomIndex = Random().nextInt(piecesCopy.length);
      PieceData pieceData = piecesCopy[randomIndex];
      piecesCopy.removeAt(randomIndex);

      ClothingPiece clothingPiece = await loadClothingPiece(pieceData.imagePath);
      clothingPiece.position = pos;
      clothes.add(clothingPiece);
    }    

    // clothes.add(await loadClothingPiece('hat.png')..position = Vector2(50, 50));

    // clothes.add(await loadClothingPiece('shirt.png')..position = Vector2(200, 200));

    // clothes.add(await loadClothingPiece('pants.png')..position = Vector2(200, 500));

    clothes.forEach(add);
    
    finalizeButton = ButtonComponent(
      button: SpriteComponent(
        sprite: Sprite(await Flame.images.load('finalize.png'), srcSize: Vector2(200, 50), srcPosition: Vector2.zero()),
        size: Vector2(200, 50),
      ),
      buttonDown: SpriteComponent(
        sprite: Sprite(await Flame.images.load('finalize.png'), srcSize: Vector2(200, 50), srcPosition: Vector2(0, 50)),
        size: Vector2(200, 50),
      ),
      size: Vector2(200, 50),
      position: Vector2(100, 640),
      onPressed: calculateScore,
    );
    add(finalizeButton);

    replayButton = ButtonComponent(
      button: SpriteComponent(
        sprite: Sprite(await Flame.images.load('replay.png'), srcSize: Vector2(200, 50), srcPosition: Vector2.zero()),
        size: Vector2(200, 50),
      ),
      buttonDown: SpriteComponent(
        sprite: Sprite(await Flame.images.load('replay.png'), srcSize: Vector2(200, 50), srcPosition: Vector2(0, 50)),
        size: Vector2(200, 50),
      ),
      size: Vector2(200, 50),
      position: Vector2(100, 640),
      onPressed: playAgain,
    );
  }

  void calculateScore() {

    removeWhere((c) => c is ClothingPiece && !selectedClothes.containsValue(c));


    // calculate score
    score = 0;
    HashMap<ClothingStyle, int> clothingScores = HashMap<ClothingStyle, int>();
    HashMap<Color, int> colorScores = HashMap<Color, int>();

    List<ClothingPiece> pieces = List.empty(growable: true);

    if(selectedClothes.containsKey(ClothingType.hat)) pieces.add(selectedClothes[ClothingType.hat]!);
    if(selectedClothes.containsKey(ClothingType.shirt)) pieces.add(selectedClothes[ClothingType.shirt]!);
    if(selectedClothes.containsKey(ClothingType.pants)) pieces.add(selectedClothes[ClothingType.pants]!);

    for (var clothingPiece in pieces) {
      score += clothingPiece.score;
      if(clothingScores.containsKey(clothingPiece.style)) {
        score += clothingPiece.score * clothingScores[clothingPiece.style]!;
        clothingScores[clothingPiece.style] = clothingScores[clothingPiece.style]! + 1;
      } else {
        clothingScores[clothingPiece.style] = 1;
      }
      if(colorScores.containsKey(clothingPiece.color)) {
        score += clothingPiece.score * colorScores[clothingPiece.color]!;
        colorScores[clothingPiece.color] = colorScores[clothingPiece.color]! + 1;
      } else {
        colorScores[clothingPiece.color] = 1;
      }
    }

    TextComponent scoreText = TextComponent(
      text: 'Score: $score',
      position: Vector2(200, 50),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 24,
          color: Colors.black,
        ),
      ),
      anchor: Anchor.center,
    );
    add(scoreText);
    finished = true;

    remove(finalizeButton);
    add(replayButton);

    //check score for high score and update if necessary
    SharedPreferences.getInstance().then((prefs) {
      int highScore = prefs.getInt('highScoreDressup') ?? 0;
      if (score > highScore) {
        prefs.setInt('highScoreDressup', score);
      }
    });

    for (var clothingPiece in clothes) {
      clothingPiece.canDrag = false;
    }
  }

  @override
  // ignore: unnecessary_overrides
  void update(double dt) {
    super.update(dt);
  
    // update game state
  }

  RectangleComponent hatHitbox = RectangleComponent(
    position: Vector2(200,135),
    size: Vector2(30, 30),
    anchor: Anchor.center,
    paint: Paint()..color = Colors.white.withAlpha(0),
  );

  RectangleComponent shirtHitbox = RectangleComponent(
    position: Vector2(200,300),
    size: Vector2(30, 100),
    anchor: Anchor.center,
    paint: Paint()..color = Colors.white.withAlpha(0),
  );

  RectangleComponent pantsHitbox = RectangleComponent(
    position: Vector2(200,450),
    size: Vector2(30, 70),
    anchor: Anchor.center,
    paint: Paint()..color = Colors.white.withAlpha(0),
  );
  
  void handleDragEnd(ClothingPiece clothingPiece) {

    switch (clothingPiece.type) {
      case ClothingType.hat:
        if(hatHitbox.containsPoint(clothingPiece.position)) {
          clothingPiece.isSelected = true;
          selectedClothes[clothingPiece.type] = clothingPiece;
          remove(clothingPiece);
          add(clothingPiece);
        } else {
          clothingPiece.isSelected = false;
          selectedClothes.remove(clothingPiece.type);
        }
        break;
      case ClothingType.shirt:
        if(shirtHitbox.containsPoint(clothingPiece.position)) {
          clothingPiece.isSelected = true;
          selectedClothes[clothingPiece.type] = clothingPiece;
          remove(clothingPiece);
          add(clothingPiece);
        } else {
          clothingPiece.isSelected = false;
          selectedClothes.remove(clothingPiece.type);
        }
        break;
      case ClothingType.pants:
        if(pantsHitbox.containsPoint(clothingPiece.position)) {
          clothingPiece.isSelected = true;
          selectedClothes[clothingPiece.type] = clothingPiece;
          remove(clothingPiece);
          add(clothingPiece);
        } else {
          clothingPiece.isSelected = false;
          selectedClothes.remove(clothingPiece.type);
        }
        break;
    }

    // if (clothingPiece.position.x > 200 - clothingPiece.width*0.75) {
    //   if (selectedClothes.containsKey(clothingPiece.type)) {
    //     selectedClothes[clothingPiece.type]?.isSelected = false;
    //   }
    //   selectedClothes[clothingPiece.type] = clothingPiece;
    //   clothingPiece.isSelected = true;
    // } else {
    //   if (selectedClothes.containsKey(clothingPiece.type)) {
    //     selectedClothes[clothingPiece.type]?.isSelected = false;
    //     selectedClothes.remove(clothingPiece.type);
    //   }
    // }
  }

  void playAgain() {
    // reset game state
    score = 0;
    finished = false;
    selectedClothes.clear();
    clothes.clear();

    removeWhere((c) => c is ClothingPiece);
    remove(replayButton);
    removeWhere((c) => c is TextComponent);
    removeWhere((c) => c is ButtonComponent);
    removeWhere((c) => c is RectangleComponent);
    remove(body);

    onLoad();
  }
}

enum ClothingType {
  hat,
  shirt,
  pants,
}

enum ClothingStyle {
  goth,
  punk,
  fine,
}

class ClothingPiece extends SpriteComponent with DragCallbacks {
  ClothingPiece({
    required this.sprite,
    required this.width,
    required this.height,
    required this.type,
    required this.style,
    required this.color,
    required this.score,
  }) : super(
    sprite: sprite,
    size: Vector2(width, height)*2,
  );

  @override
  FutureOr<void> onLoad() {
    opacity = 0.5;

    //decorator.addLast(PaintDecorator.grayscale());
    decorator.addLast(PaintDecorator.tint(color.withAlpha(170)));

    return super.onLoad();
  }

  @override
  final Sprite sprite;
  @override
  final double width;
  @override
  final double height;
  final ClothingType type;
  final ClothingStyle style;
  final Color color;
  final int score;
  
  bool draggable = true;
  set canDrag(bool draggable) {
    this.draggable = draggable;
  }

  bool selected = false;
  bool get isSelected => selected;
  set isSelected(bool value) {
    selected = value;
    if (selected) {
      // handle selection
      opacity = 1;
    } else {
      // handle deselection
      opacity = 0.5;
    }
  }
  
  @override
  void onDragStart(DragStartEvent event) {
    if (!draggable) return;
    super.onDragStart(event);
    // handle drag start
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!draggable) return;
    super.onDragUpdate(event);
    // handle drag update
    Vector2 newPosition = position + event.localDelta;
    if(newPosition.x - width < 0) {
      newPosition.x = width;
    } else if(newPosition.x + width > 400) {
      newPosition.x = 400 - width;
    }
    if(newPosition.y - height < 0) {
      newPosition.y = height;
    } else if(newPosition.y + height > 700) {
      newPosition.y = 700 - height;
    }
    position = newPosition;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    if (!draggable) return;
    super.onDragEnd(event);
    // handle drag end
    DressUpGameEngine.instance?.handleDragEnd(this);
  }
}