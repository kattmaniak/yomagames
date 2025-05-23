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
import 'package:super_tooltip/super_tooltip.dart';

class DressUpGame extends StatefulWidget {
  const DressUpGame({super.key});

  @override
  State<DressUpGame> createState() => _DressUpGameState();
}

class _DressUpGameState extends State<DressUpGame> {
  int highScore = 0;
  final _controller = SuperTooltipController();

  _DressUpGameState() {
    // Load the high score from storage
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        highScore = prefs.getInt('highScoreDressup') ?? 0;
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
                  'Welcome to Mortician\'s Deadly Dressup!',
                ),
                GestureDetector(
                  onTap: () async {
                    await _controller.showTooltip();
                  },
                  child: SuperTooltip(
                    showBarrier: true,
                    controller: _controller,
                    content: const Text(
                      "This is a dress-up game where you can select different clothing pieces to dress up a character. The goal is to create the best outfit possible and score points based on your choices. You can drag and drop clothing pieces onto the character, and once you're done, you can finalize your outfit to see your score.",
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
                  MaterialPageRoute(builder: (context) => const DressUpGameScreen()),
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

double wu = 1.0; // width unit for scaling

class DressUpGameScreen extends StatelessWidget {
  const DressUpGameScreen({super.key});

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
                height: 700*wu,
                width: 400*wu,
                child: GameWidget(
                  game: DressUpGameEngine(),
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
        width: sprite.originalSize.x*wu,
        height: sprite.originalSize.y*wu,
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
      ..size = Vector2(400*wu, 700*wu)
      ..anchor = Anchor.center
      ..position = Vector2(200*wu, 350*wu);
    add(background);

    // load assets
    body = SpriteComponent()
      ..sprite = Sprite(await Flame.images.load('body.png'), srcSize: Vector2(100, 250), srcPosition: Vector2.zero())
      ..size = Vector2(100*wu, 250*wu)
      ..anchor = Anchor.center
      ..position = Vector2(200*wu, 350*wu)
      ..scale = Vector2(2, 2);

    add(body);

    List<Vector2> positions = [
      Vector2(75*wu, 100*wu),
      Vector2(75*wu, 300*wu),
      Vector2(75*wu, 500*wu),
      Vector2(325*wu, 100*wu),
      Vector2(325*wu, 300*wu),
      Vector2(325*wu, 500*wu),
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
        size: Vector2(200*wu, 50*wu),
      ),
      buttonDown: SpriteComponent(
        sprite: Sprite(await Flame.images.load('finalize.png'), srcSize: Vector2(200, 50), srcPosition: Vector2(0, 50)),
        size: Vector2(200*wu, 50*wu),
      ),
      size: Vector2(200*wu, 50*wu),
      position: Vector2(100*wu, 640*wu),
      onPressed: calculateScore,
    );
    add(finalizeButton);

    replayButton = ButtonComponent(
      button: SpriteComponent(
        sprite: Sprite(await Flame.images.load('replay.png'), srcSize: Vector2(200, 50), srcPosition: Vector2.zero()),
        size: Vector2(200*wu, 50*wu),
      ),
      buttonDown: SpriteComponent(
        sprite: Sprite(await Flame.images.load('replay.png'), srcSize: Vector2(200, 50), srcPosition: Vector2(0, 50)),
        size: Vector2(200*wu, 50*wu),
      ),
      size: Vector2(200*wu, 50*wu),
      position: Vector2(100*wu, 640*wu),
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
      position: Vector2(200*wu, 50*wu),
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
    position: Vector2(200*wu,135*wu),
    size: Vector2(30*wu, 30*wu),
    anchor: Anchor.center,
    paint: Paint()..color = Colors.white.withAlpha(0),
  );

  RectangleComponent shirtHitbox = RectangleComponent(
    position: Vector2(200*wu,300*wu),
    size: Vector2(30*wu, 100*wu),
    anchor: Anchor.center,
    paint: Paint()..color = Colors.white.withAlpha(0),
  );

  RectangleComponent pantsHitbox = RectangleComponent(
    position: Vector2(200*wu,450*wu),
    size: Vector2(30*wu, 70*wu),
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
    } else if(newPosition.x + width > 400*wu) {
      newPosition.x = 400*wu - width;
    }
    if(newPosition.y - height < 0) {
      newPosition.y = height;
    } else if(newPosition.y + height > 700*wu) {
      newPosition.y = 700*wu - height;
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