import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yomagames/manager.dart';

class ReadingGame extends StatefulWidget {
  const ReadingGame({super.key});

  @override
  State<ReadingGame> createState() => _ReadingGameState();
}

class _ReadingGameState extends State<ReadingGame> {
  int highScore = 0;

  _ReadingGameState() {
    // Load the high score from storage
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        highScore = prefs.getInt('highScoreReading') ?? 0;
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
              'Welcome to Diviner\'s Occult Reading!',
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReadingGameScreen()),
                );
              },
              child: const Text('Play'),
            ),
            Text('Highest Streak: $highScore'),
          ],
        ),
      ),
    );
  }
}

class ReadingGameScreen extends StatelessWidget {
  const ReadingGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Diviner\'s Occult Reading'),
            SizedBox(
              height: 700,
              width: 400,
              child: GameWidget(
                game: ReadingGameEngine(),
              ),
            ),
          ],
        ),
      ),
      
    );
  }
}

class TarotCard {
  final String name;
  final String imagePath;
  final String description;
  final Alignment prediction; // Positive, Negative, or Neutral

  TarotCard({
    required this.name,
    required this.imagePath,
    required this.description,
    required this.prediction,
  });
}

class Prediction {
  final String text;
  final Alignment alignment;

  Prediction({
    required this.text,
    required this.alignment,
  });
}

enum Alignment {
  positive,
  negative,
  neutral
}

class ReadingGameEngine extends FlameGame with TapCallbacks {
  // Game state
  int score = 0;
  int currentRound = 0;
  bool gameOver = false;
  late Random random;
  
  // UI Components
  late TextComponent scoreText;
  late TextComponent instructionText;
  late TextComponent resultText;
  late SpriteComponent magicBall;
  late ButtonComponent revealButton;
  late ButtonComponent positiveButton;
  late ButtonComponent neutralButton;
  late ButtonComponent negativeButton;
  
  // Game elements
  List<TarotCard> tarotDeck = [];
  List<TarotCard> currentHand = [];
  late Prediction currentPrediction;
  List<Prediction> predictions = [];
  
  // Player's prediction
  Alignment? playerPrediction;
  
  @override
  Color backgroundColor() => const Color(0xFF1A237E); // Deep indigo for mystical feel
  
  @override
  Future<void> onLoad() async {
    random = Random();
    
    // Initialize the tarot deck
    initTarotDeck();
    
    // Initialize predictions
    initPredictions();
    
    // Add background
    final background = SpriteComponent()
      ..sprite = await Sprite.load('divination_table.png')
      ..size = Vector2(400, 700)
      ..position = Vector2(0, 0);
    add(background);
    
    // Add score display
    scoreText = TextComponent(
      text: 'Streak: 0',
      position: Vector2(200, 50),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 24,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      anchor: Anchor.center,
    );
    add(scoreText);
    
    // Add instruction text
    instructionText = TextComponent(
      text: 'Read your tarot cards and predict the magic ball outcome!',
      position: Vector2(200, 100),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white70,
        ),
      ),
      anchor: Anchor.center,
    );
    add(instructionText);
    
    // Add magic 8-ball (initially showing back)
    magicBall = SpriteComponent()
      ..sprite = await Sprite.load('magic_ball_back.png')
      ..size = Vector2(120, 120)
      ..position = Vector2(200, 200)
      ..anchor = Anchor.center;
    add(magicBall);
    
    // Add prediction buttons
    positiveButton = ButtonComponent(
      button: SpriteComponent(
        sprite: await Sprite.load('positive_button.png'),
        size: Vector2(100, 50),
      ),
      buttonDown: SpriteComponent(
        sprite: await Sprite.load('positive_button_down.png'),
        size: Vector2(100, 50),
      ),
      position: Vector2(40, 600),
      onPressed: () => makePrediction(Alignment.positive),
    );
    
    neutralButton = ButtonComponent(
      button: SpriteComponent(
        sprite: await Sprite.load('neutral_button.png'),
        size: Vector2(100, 50),
      ),
      buttonDown: SpriteComponent(
        sprite: await Sprite.load('neutral_button_down.png'),
        size: Vector2(100, 50),
      ),
      position: Vector2(150, 600),
      onPressed: () => makePrediction(Alignment.neutral),
    );
    
    negativeButton = ButtonComponent(
      button: SpriteComponent(
        sprite: await Sprite.load('negative_button.png'),
        size: Vector2(100, 50),
      ),
      buttonDown: SpriteComponent(
        sprite: await Sprite.load('negative_button_down.png'),
        size: Vector2(100, 50),
      ),
      position: Vector2(260, 600),
      onPressed: () => makePrediction(Alignment.negative),
    );
    
    add(positiveButton);
    add(neutralButton);
    add(negativeButton);
    
    // Add reveal button (initially hidden)
    revealButton = ButtonComponent(
      button: SpriteComponent(
        sprite: await Sprite.load('reveal_button.png'),
        size: Vector2(180, 60),
      ),
      buttonDown: SpriteComponent(
        sprite: await Sprite.load('reveal_button_down.png'),
        size: Vector2(180, 60),
      ),
      position: Vector2(200, 650),
      onPressed: revealOutcome,
    )..anchor = Anchor.center
    ;// Initially hidden
    
    // Result text (initially hidden)
    resultText = TextComponent(
      text: '',
      position: Vector2(200, 200),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 20,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      anchor: Anchor.center,
    )
    ;// Initially hidden
    
    // Start first round
    startNewRound();
  }
  
  void initTarotDeck() {
    // Initialize with some sample tarot cards
    tarotDeck = [
      TarotCard(
        name: 'The Fool',
        imagePath: 'tarot_fool.jpg',
        description: 'New beginnings, spontaneity',
        prediction: Alignment.positive,
      ),
      TarotCard(
        name: 'Death',
        imagePath: 'tarot_death.jpg',
        description: 'Endings, transformation',
        prediction: Alignment.negative,
      ),
      TarotCard(
        name: 'The Lovers',
        imagePath: 'tarot_lovers.jpg',
        description: 'Love, harmony, relationships',
        prediction: Alignment.positive,
      ),
      TarotCard(
        name: 'The Tower',
        imagePath: 'tarot_tower.jpg',
        description: 'Disaster, upheaval, change',
        prediction: Alignment.negative,
      ),
      TarotCard(
        name: 'The Star',
        imagePath: 'tarot_star.jpg',
        description: 'Hope, faith, rejuvenation',
        prediction: Alignment.positive,
      ),
      TarotCard(
        name: 'The Moon',
        imagePath: 'tarot_moon.jpg',
        description: 'Illusion, fear, anxiety',
        prediction: Alignment.negative,
      ),
      TarotCard(
        name: 'The Sun',
        imagePath: 'tarot_sun.jpg',
        description: 'Success, joy, celebration',
        prediction: Alignment.positive,
      ),
      TarotCard(
        name: 'The Magician',
        imagePath: 'tarot_magician.jpg',
        description: 'Power, skill, concentration',
        prediction: Alignment.positive,
      ),
      TarotCard(
        name: 'The Hanged Man',
        imagePath: 'tarot_hanged_man.jpg',
        description: 'Surrender, letting go, sacrifice',
        prediction: Alignment.neutral,
      ),
      TarotCard(
        name: 'Temperance',
        imagePath: 'tarot_temperance.jpg',
        description: 'Balance, moderation, patience',
        prediction: Alignment.neutral,
      ),
      TarotCard(
        name: 'Wheel of Fortune',
        imagePath: 'tarot_wheel.jpg',
        description: 'Change, cycles, destiny',
        prediction: Alignment.neutral,
      ),
      TarotCard(
        name: 'Justice',
        imagePath: 'tarot_justice.jpg',
        description: 'Fairness, truth, law',
        prediction: Alignment.neutral,
      ),
    ];
  }
  
  void initPredictions() {
    predictions = [
      // Positive predictions
      Prediction(text: 'It is certain', alignment: Alignment.positive),
      Prediction(text: 'Without a doubt', alignment: Alignment.positive),
      Prediction(text: 'Yes definitely', alignment: Alignment.positive),
      Prediction(text: 'Signs point to yes', alignment: Alignment.positive),
      Prediction(text: 'Most likely', alignment: Alignment.positive),
      
      // Neutral predictions
      Prediction(text: 'Reply hazy, try again', alignment: Alignment.neutral),
      Prediction(text: 'Ask again later', alignment: Alignment.neutral),
      Prediction(text: 'Better not tell you now', alignment: Alignment.neutral),
      Prediction(text: 'Cannot predict now', alignment: Alignment.neutral),
      Prediction(text: 'Concentrate and ask again', alignment: Alignment.neutral),
      
      // Negative predictions
      Prediction(text: 'Don\'t count on it', alignment: Alignment.negative),
      Prediction(text: 'My reply is no', alignment: Alignment.negative),
      Prediction(text: 'My sources say no', alignment: Alignment.negative),
      Prediction(text: 'Outlook not so good', alignment: Alignment.negative),
      Prediction(text: 'Very doubtful', alignment: Alignment.negative),
    ];
  }
  
  Future<void> startNewRound() async {
    // Reset
    playerPrediction = null;
    currentRound++;
    
    // Show buttons
    add(positiveButton);
    add(neutralButton);
    add(negativeButton);
    if(children.contains(revealButton)) {
      remove(revealButton);
    }
    if(children.contains(resultText)) {
      remove(resultText);
    }
    
    // Reset magic ball
    magicBall.sprite = await Sprite.load('magic_ball_back.png');
    
    // Draw 3 random tarot cards
    tarotDeck.shuffle(random);
    currentHand = tarotDeck.take(3).toList();
    
    // Determine the next magic 8 ball prediction
    // Make it slightly biased toward the tarot cards' alignment
    int positiveCards = currentHand.where((card) => card.prediction == Alignment.positive).length;
    int negativeCards = currentHand.where((card) => card.prediction == Alignment.negative).length;
    int neutralCards = currentHand.where((card) => card.prediction == Alignment.neutral).length;
    
    // Weight the selection based on cards
    List<Alignment> weightedPool = [];
    
    // Add each card's alignment to the pool twice
    for (var card in currentHand) {
      weightedPool.add(card.prediction);
      weightedPool.add(card.prediction);
      weightedPool.add(card.prediction);
    }
    
    // Add some randomness (add each possible alignment once)
    weightedPool.add(Alignment.positive);
    weightedPool.add(Alignment.neutral);
    weightedPool.add(Alignment.negative);
    
    // Choose a random alignment from the weighted pool
    Alignment selectedAlignment = weightedPool[random.nextInt(weightedPool.length)];
    
    // Select a prediction with that alignment
    List<Prediction> alignedPredictions = predictions.where((p) => p.alignment == selectedAlignment).toList();
    currentPrediction = alignedPredictions[random.nextInt(alignedPredictions.length)];
    
    // Update instruction
    instructionText.text = 'Read the cards and divine the outcome!';
    
    // Display tarot cards
    displayTarotCards();
  }
  
  Future<void> displayTarotCards() async {
    // Remove old cards first
    removeWhere((component) => component is TarotCardComponent);
    
    // Add new tarot cards
    double cardWidth = 100;
    double spacing = 10;
    double totalWidth = (cardWidth * 3) + (spacing * 2);
    double startX = (size.x - totalWidth) / 2;
    
    for (int i = 0; i < currentHand.length; i++) {
      TarotCard card = currentHand[i];
      final cardComponent = TarotCardComponent(
        card: card,
        position: Vector2(startX + (i * (cardWidth + spacing)), 420),
        size: Vector2(cardWidth, 160),
      );
      add(cardComponent);
    }
  }
  
  void makePrediction(Alignment prediction) {
    if (gameOver || playerPrediction != null) return;
    
    playerPrediction = prediction;
    
    // Hide prediction buttons and show reveal button
    remove(positiveButton);
    remove(neutralButton);
    remove(negativeButton);
    add(revealButton);
    
    // Update instruction
    instructionText.text = 'Your prediction is made. Reveal the answer!';
  }
  
  Future<void> revealOutcome() async {
    if (gameOver || playerPrediction == null) return;
    
    // Show the magic 8-ball result
    magicBall.sprite = await Sprite.load('magic_ball_front.png');
    
    // Show the prediction text
    resultText.text = currentPrediction.text;
    add(resultText);
    
    // Check if the prediction matches
    bool correct = playerPrediction == currentPrediction.alignment;
    
    if (correct) {
      // Success!
      score++;
      scoreText.text = 'Streak: $score';
      
      // Add success effect
      add(SuccessMagicEffect()..position = Vector2(200, 350));
      
      // Update high score if needed
      SharedPreferences.getInstance().then((prefs) {
        int highScore = prefs.getInt('highScoreReading') ?? 0;
        if (score > highScore) {
          prefs.setInt('highScoreReading', score);
        }
      });
      
      // Add delay before next round
      Future.delayed(const Duration(seconds: 2), () {
        if (!gameOver) startNewRound();
      });
    } else {
      // Failure!
      gameOver = true;
      add(FailureMagicEffect()..position = Vector2(200, 350));
      
      // Show game over message
      instructionText.text = 'Game Over! Your final streak: $score';

      remove(revealButton);
      
      // Add play again button
      TextButtonComponent playAgainButton = TextButtonComponent(
        text: 'Play Again',
        position: Vector2(200, 650),
        onPressed: _resetGame,
        buttonColor: Colors.blueGrey,
      );

      add(playAgainButton);
    }
  }
  
  void _resetGame() {
    // Reset game state
    score = 0;
    currentRound = 0;
    gameOver = false;

    removeWhere((component) => component is TextButtonComponent);

    scoreText.text = 'Streak: 0';
    
    // Restart the game
    startNewRound();
  }
}

class TarotCardComponent extends PositionComponent with TapCallbacks {
  final TarotCard card;
  late SpriteComponent cardSprite;
  bool flipped = false;
  
  TarotCardComponent({
    required this.card,
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size);
  
  @override
  Future<void> onLoad() async {
    cardSprite = SpriteComponent()
      ..sprite = await Sprite.load(card.imagePath)
      ..size = size
      ..anchor = Anchor.center
      ..position = size / 2;
    add(cardSprite);
    
    // Add name text
    final nameText = TextComponent(
      text: card.name,
      position: Vector2(size.x / 2, 10),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      anchor: Anchor.bottomCenter,
    );
    add(nameText);
    
    return super.onLoad();
  }
  
  @override
  void onTapDown(TapDownEvent event) {
    // Show card details when tapped
    ReadingGameEngine game = findGame() as ReadingGameEngine;
    game.instructionText.text = '${card.name}: ${card.description}';
  }
}

class SuccessMagicEffect extends SpriteAnimationComponent {
  SuccessMagicEffect()
      : super(
          size: Vector2(150, 150),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    animation = await SpriteAnimation.load(
      'success_effect.png',
      SpriteAnimationData.sequenced(
        amount: 6,
        stepTime: 0.2,
        textureSize: Vector2.all(150),
        loop: false,
      ),
    );
    
    // Remove after animation completes
    animationTicker?.completed.then((_) => removeFromParent());
    return super.onLoad();
  }
}

class FailureMagicEffect extends SpriteAnimationComponent {
  FailureMagicEffect()
      : super(
          size: Vector2(150, 150),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    animation = await SpriteAnimation.load(
      'failure_effect.png',
      SpriteAnimationData.sequenced(
        amount: 6,
        stepTime: 0.1,
        textureSize: Vector2.all(150),
        loop: false,
      ),
    );
    
    // Remove after animation completes
    animationTicker?.completed.then((_) => removeFromParent());
    return super.onLoad();
  }
}