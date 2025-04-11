
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:scrabble_word_checker/scrabble_word_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_tooltip/super_tooltip.dart';

class WordsGame extends StatefulWidget {
  const WordsGame({super.key});

  @override
  State<WordsGame> createState() => _WordsGameState();
}

class _WordsGameState extends State<WordsGame> {
  int highScore = 0;
  final _controller = SuperTooltipController();

  _WordsGameState() {
    // Load the high score from storage
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        highScore = prefs.getInt('highScoreWords') ?? 0;
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
                  'Welcome to Rhetorician\'s Exciting Scramble!',
                ),
                GestureDetector(
                  onTap: () async {
                    await _controller.showTooltip();
                  },
                  child: SuperTooltip(
                    showBarrier: true,
                    controller: _controller,
                    content: const Text(
                      "This is a word game where you can form words from the letters provided. The game ends when the time runs out. Try to get the highest score possible!",
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
                  MaterialPageRoute(builder: (context) => const WordsGameScreen()),
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

class WordsGameScreen extends StatelessWidget {
  const WordsGameScreen({super.key});

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
                const Text('Rhetorician\'s Exciting Scramble'),
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
                game: WordsGameEngine(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WordsGameEngine extends FlameGame with TapCallbacks {
  // Game variables
  final ScrabbleWordChecker wordChecker = ScrabbleWordChecker(language: ScrabbleLanguage.english);
  final List<String> availableLetters = [];
  final List<LetterTile> selectedLetters = [];
  final List<LetterTile> letterTiles = [];
  String currentWord = '';
  int score = 0;
  int timeLeft = 60; // 60 seconds per game
  bool gameOver = false;
  
  // UI Components
  late TextComponent scoreText;
  late TextComponent timerText;
  late TextComponent wordText;
  late TextComponent messageText;
  
  // Game constants
  static const List<String> alphabet = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
  ];
  
  static const List<int> letterFrequencies = [
    9, 2, 2, 4, 12, 2, 3, 2, 9, 1, 1, 4, 2,
    6, 8, 2, 1, 6, 4, 6, 4, 2, 2, 1, 2, 1
  ];
  
  @override
  Color backgroundColor() => const Color(0xFFF5F5DC); // Beige background
  
  @override
  Future<void> onLoad() async {
    // Initialize letters
    generateLetters();
    
    // Create letter tiles
    createLetterTiles();
    
    // Add UI components
    scoreText = TextComponent(
      text: 'Score: 0',
      position: Vector2(25, 40),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 24,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    
    timerText = TextComponent(
      text: 'Time: 60',
      position: Vector2(375, 40),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 24,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      anchor: Anchor.topRight,
    );
    
    wordText = TextComponent(
      text: '',
      position: Vector2(200, 100),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 32,
          color: Colors.blue,
          fontWeight: FontWeight.bold,
        ),
      ),
      anchor: Anchor.center,
    );
    
    messageText = TextComponent(
      text: 'Form words from the letters below!',
      position: Vector2(200, 150),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 18,
          color: Colors.black54,
        ),
      ),
      anchor: Anchor.center,
    );
    
    add(scoreText);
    add(timerText);
    add(wordText);
    add(messageText);
    
    // Add submit and clear buttons
    final submitButton = RoundedButton(
      text: 'Submit',
      position: Vector2(25, 600),
      onTap: submitWord,
      color: Colors.green,
    )..anchor = Anchor.centerLeft;
    
    final clearButton = RoundedButton(
      text: 'Clear',
      position: Vector2(375, 600),
      onTap: clearSelection,
      color: Colors.red,
    )..anchor = Anchor.centerRight;
    
    add(submitButton);
    add(clearButton);
    
    // Start game timer
    final gametimer = TimerComponent(
      period: 1.0,
      onTick:() {
        if (!gameOver) {
          timeLeft--;
          timerText.text = 'Time: $timeLeft';
          
          if (timeLeft <= 0) {
            endGame();
          }
        }
      },
      repeat: true,
    );
    add(gametimer);
  }
  
  void generateLetters() {
    availableLetters.clear();
    
    // Create letter distribution based on frequencies
    for (int i = 0; i < alphabet.length; i++) {
      for (int j = 0; j < letterFrequencies[i]; j++) {
        availableLetters.add(alphabet[i]);
      }
    }
    
    // Shuffle letters
    availableLetters.shuffle();
  }
  
  void createLetterTiles() {
    // Clear existing tiles
    for (final tile in letterTiles) {
      remove(tile);
    }
    letterTiles.clear();
    
    // Create new tiles
    const int tilesPerRow = 6;
    const double tileSize = 50.0;
    const double startX = 25.0;
    const double startY = 300.0;
    const double padding = 10.0;
    
    for (int i = 0; i < 18; i++) {
      if (i >= availableLetters.length) break;
      
      int row = i ~/ tilesPerRow;
      int col = i % tilesPerRow;
      
      final letter = availableLetters[i];
      late LetterTile tile;
      tile = LetterTile(
        letter: letter,
        position: Vector2(
          startX + col * (tileSize + padding),
          startY + row * (tileSize + padding),
        ),
        tilesize: Vector2(tileSize, tileSize),
        onTap: () => toggleLetterSelection(tile),
      );
      
      letterTiles.add(tile);
      add(tile);
    }
  }
  
  void toggleLetterSelection(LetterTile tile) {
    if (gameOver) return;
    
    if (tile.isSelected) {
      // Deselect
      tile.isSelected = false;
      selectedLetters.remove(tile);
    } else {
      // Select
      tile.isSelected = true;
      selectedLetters.add(tile);
    }
    
    // Update current word
    currentWord = selectedLetters.map((tile) => tile.letter).join();
    wordText.text = currentWord;
  }
  
  void submitWord() {
    if (gameOver || currentWord.isEmpty) return;
    
    if (currentWord.length < 3) {
      messageText.text = 'Word too short! Try again.';
      return;
    }
    
    if (wordChecker.isValidWord(currentWord.toLowerCase())) {
      // Valid word
      int wordScore = wordChecker.getWordValue(currentWord.toLowerCase());
      score += wordScore;
      scoreText.text = 'Score: $score';
      
      messageText.text = 'Great! +$wordScore points';
      
      // Remove used letters and add new ones
      for (final tile in selectedLetters) {
        remove(tile);
        letterTiles.remove(tile);
      }
      
      // Replenish letters
      int lettersToAdd = selectedLetters.length;
      selectedLetters.clear();
      
      // Add new letters
      for (int i = 0; i < lettersToAdd; i++) {
        if (availableLetters.isNotEmpty) {
          availableLetters.shuffle();
          availableLetters.removeLast();
        }
      }
      
      createLetterTiles();
      currentWord = '';
      wordText.text = '';
    } else {
      // Invalid word
      messageText.text = 'Not a valid word! Try again.';
      clearSelection();
    }
  }
  
  void clearSelection() {
    for (final tile in selectedLetters) {
      tile.isSelected = false;
    }
    selectedLetters.clear();
    currentWord = '';
    wordText.text = '';
  }
  
  void endGame() {
    gameOver = true;
    messageText.text = 'Game Over! Final Score: $score';
    
    // Check for high score
    SharedPreferences.getInstance().then((prefs) {
      int highScore = prefs.getInt('highScoreWords') ?? 0;
      if (score > highScore) {
        prefs.setInt('highScoreWords', score);
        messageText.text = 'New High Score! $score';
      }
    });
    
    // Add play again button
    final playAgainButton = RoundedButton(
      text: 'Play Again',
      position: Vector2(200, 525),
      onTap: resetGame,
      color: Colors.blue,
    )..anchor = Anchor.center;
    add(playAgainButton);
  }
  
  void resetGame() {
    // Remove all components
    removeAll(children);
    
    // Reset game state
    score = 0;
    timeLeft = 60;
    gameOver = false;
    currentWord = '';
    selectedLetters.clear();
    letterTiles.clear();
    
    // Reload game
    onLoad();
  }
}

class LetterTile extends PositionComponent with TapCallbacks {
  final String letter;
  final Vector2 tilesize;
  final Function() onTap;
  bool isSelected = false;
  
  LetterTile({
    required this.letter,
    required Vector2 position,
    required this.tilesize,
    required this.onTap,
  }) : super(position: position, size: tilesize);
  
  @override
  void render(Canvas canvas) {
    // Draw tile background
    final Paint paint = Paint()
      ..color = isSelected ? Colors.orange : Colors.amber
      ..style = PaintingStyle.fill;
    
    final Paint borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));
    
    canvas.drawRRect(rrect, paint);
    canvas.drawRRect(rrect, borderPaint);
    
    // Draw letter
    final textPainter = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          color: Colors.black,
          fontSize: size.x * 0.6,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.x - textPainter.width) / 2,
        (size.y - textPainter.height) / 2,
      ),
    );
  }
  
  @override
  void onTapDown(TapDownEvent event) {
    onTap();
  }
}

class RoundedButton extends PositionComponent with TapCallbacks {
  final String text;
  final Function() onTap;
  final Color color;
  
  RoundedButton({
    required this.text,
    required Vector2 position,
    required this.onTap,
    required this.color,
  }) : super(position: position, size: Vector2(120, 50));
  
  @override
  void render(Canvas canvas) {
    // Draw button background
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(15));
    
    canvas.drawRRect(rrect, paint);
    
    // Draw text
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.x - textPainter.width) / 2,
        (size.y - textPainter.height) / 2,
      ),
    );
  }
  
  @override
  void onTapDown(TapDownEvent event) {
    onTap();
  }
}