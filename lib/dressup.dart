// This is a skeleton for a game. It is not a complete game and will not run.
import 'dart:async';
import 'dart:collection';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
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
            const Text('Mortician\'s Deadly Dressup'),
            SizedBox(
              height: 900,
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
  final double width;
  final double height;
  final ClothingType type;
  final ClothingStyle style;
  final int score;

  PieceData({
    required this.imagePath,
    required this.width,
    required this.height,
    required this.type,
    required this.style,
    required this.score,
  });
}

List<PieceData> piecesData = [
  PieceData(
    imagePath: 'hat.png',
    width: 150,
    height: 100,
    type: ClothingType.hat,
    style: ClothingStyle.goth,
    score: 10,
  ),
  PieceData(
    imagePath: 'shirt.png',
    width: 200,
    height: 250,
    type: ClothingType.shirt,
    style: ClothingStyle.punk,
    score: 20,
  ),
  PieceData(
    imagePath: 'pants.png',
    width: 200,
    height: 350,
    type: ClothingType.pants,
    style: ClothingStyle.casual,
    score: 30,
  ),
];

Future<ClothingPiece> loadClothingPiece(String imagePath) async {
  for (var pieceData in piecesData) {
    if (pieceData.imagePath == imagePath) {
      return ClothingPiece(
        sprite: Sprite(await Flame.images.load(pieceData.imagePath), srcSize: Vector2(pieceData.width, pieceData.height), srcPosition: Vector2.zero()),
        width: pieceData.width,
        height: pieceData.height,
        type: pieceData.type,
        style: pieceData.style,
        score: pieceData.score,
      );
    }
  }
  throw Exception('Clothing piece not found');
}

class DressUpGameEngine extends FlameGame {
  // variables
  late SpriteComponent body;
  List<ClothingPiece> clothes = [];

  bool finished = false;

  HashMap<ClothingType, ClothingPiece> selectedClothes = HashMap<ClothingType, ClothingPiece>();

  int score = 0;

  static DressUpGameEngine? instance;

  @override
  Future<void> onLoad() async {
    instance = this;
    // load assets
    body = SpriteComponent()
      ..sprite = Sprite(await Flame.images.load('body.png'), srcSize: Vector2(400, 700), srcPosition: Vector2.zero())
      ..size = Vector2(300, 700)
      ..anchor = Anchor.center
      ..position = Vector2(200, 400);

    add(body);

    //todo load random pieces?

    clothes.add(await loadClothingPiece('hat.png')..position = Vector2(50, 50));

    clothes.add(await loadClothingPiece('shirt.png')..position = Vector2(200, 200));

    clothes.add(await loadClothingPiece('pants.png')..position = Vector2(200, 500));

    clothes.forEach(add);
    
    ButtonComponent finalizeButton = ButtonComponent(
      button: SpriteComponent(
        sprite: Sprite(await Flame.images.load('finalize.png'), srcSize: Vector2(200, 50), srcPosition: Vector2.zero()),
        size: Vector2(200, 50),
      ),
      buttonDown: SpriteComponent(
        sprite: Sprite(await Flame.images.load('finalize.png'), srcSize: Vector2(200, 50), srcPosition: Vector2(0, 50)),
        size: Vector2(200, 50),
      ),
      size: Vector2(200, 50),
      position: Vector2(100, 850),
      onPressed: calculateScore,
    );
    add(finalizeButton);
  }

  void calculateScore() {
    // calculate score
    score = 0;
    HashMap<ClothingStyle, int> clothingScores = HashMap<ClothingStyle, int>();

    List<ClothingPiece> pieces = List.empty(growable: true);

    if(selectedClothes.containsKey(ClothingType.hat)) pieces.add(selectedClothes[ClothingType.hat]!);
    if(selectedClothes.containsKey(ClothingType.shirt)) pieces.add(selectedClothes[ClothingType.shirt]!);
    if(selectedClothes.containsKey(ClothingType.pants)) pieces.add(selectedClothes[ClothingType.pants]!);

    for (var clothingPiece in pieces) {
      if(clothingScores.containsKey(clothingPiece.style)) {
        clothingScores[clothingPiece.style] = clothingScores[clothingPiece.style]! * clothingPiece.score;
      } else {
        clothingScores[clothingPiece.style] = clothingPiece.score;
      }
    }

    for (var style in clothingScores.keys) {
      score += clothingScores[style]!;
    }

    TextComponent scoreText = TextComponent(
      text: 'Score: $score',
      position: Vector2(200, 800),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 24,
          color: Colors.white,
        ),
      ),
      anchor: Anchor.center,
    );
    add(scoreText);
    finished = true;

    for (var clothingPiece in clothes) {
      clothingPiece.canDrag = false;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
  
    // update game state
  }
  
  void handleDragEnd(ClothingPiece clothingPiece) {
    if (clothingPiece.position.x > 200 - clothingPiece.width*0.75) {
      if (selectedClothes.containsKey(clothingPiece.type)) {
        selectedClothes[clothingPiece.type]?.isSelected = false;
      }
      selectedClothes[clothingPiece.type] = clothingPiece;
      clothingPiece.isSelected = true;
    } else {
      if (selectedClothes.containsKey(clothingPiece.type)) {
        selectedClothes[clothingPiece.type]?.isSelected = false;
        selectedClothes.remove(clothingPiece.type);
      }
    }
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
  casual,
}

class ClothingPiece extends SpriteComponent with DragCallbacks {
  ClothingPiece({
    required this.sprite,
    required this.width,
    required this.height,
    required this.type,
    required this.style,
    required this.score,
  }) : super(
    sprite: sprite,
    size: Vector2(width, height),
  );

  @override
  FutureOr<void> onLoad() {
    opacity = 0.5;
    return super.onLoad();
  }

  final Sprite sprite;
  final double width;
  final double height;
  final ClothingType type;
  final ClothingStyle style;
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
    if(newPosition.x < 0) {
      newPosition.x = 0;
    } else if(newPosition.x + width > 400) {
      newPosition.x = 400 - width;
    }
    if(newPosition.y < 0) {
      newPosition.y = 0;
    } else if(newPosition.y + height > 900) {
      newPosition.y = 900 - height;
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