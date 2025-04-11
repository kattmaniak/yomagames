// This is a skeleton for a game. It is not a complete game and will not run.
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_tooltip/super_tooltip.dart';

class HagglingGame extends StatefulWidget {
  const HagglingGame({super.key});

  @override
  State<HagglingGame> createState() => _HagglingGameState();
}

class _HagglingGameState extends State<HagglingGame> {
  int highScore = 0;
  final _controller = SuperTooltipController();

  _HagglingGameState() {
    // Load the high score from storage
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        highScore = prefs.getInt('highScoreHaggling') ?? 0;
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
                  'Welcome to the Salesman\'s Tough Customer!',
                ),
                GestureDetector(
                  onTap: () async {
                    await _controller.showTooltip();
                  },
                  child: SuperTooltip(
                    showBarrier: true,
                    controller: _controller,
                    content: const Text(
                      "This is a game where you play as a salesman trying to haggle with a tough customer. Your goal is to sell items at the best price possible while keeping the customer interested. Use your negotiation skills to adjust the price and talk up the item to win over the customer. Good luck!",
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
                  MaterialPageRoute(builder: (context) => const HagglingGameScreen()),
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

class HagglingGameScreen extends StatelessWidget {
  const HagglingGameScreen({super.key});

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
                const Text('Salesman\'s Tough Customer'),
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
                game: HagglingGameEngine(),
              ),
            ),
          ],
        ),
      ),
      
    );
  }
}

// class HagglingGameEngine extends FlameGame {
//   // variables

//   @override
//   Future<void> onLoad() async {
//     // load assets
//   }

//   @override
//   void update(double dt) {
//     super.update(dt);
  
//     // update game state
//   }
// }
class Item {
  final String name;
  final double basePrice;
  final String description;
  final double maxMarkup;

  Item({
    required this.name,
    required this.basePrice,
    required this.description,
    required this.maxMarkup,
  });
}

class Customer {
  final String name;
  final double patience;
  final double stubbornness;
  
  Customer({
    required this.name,
    required this.patience,
    required this.stubbornness,
  });
}

class HagglingGameEngine extends FlameGame {
  // Game state
  late Item currentItem;
  late Customer currentCustomer;
  
  double currentPrice = 0;
  double startingPrice = 0;
  int patienceRemaining = 5;
  bool gameOver = false;
  int score = 0;
  
  late TextComponent itemNameText;
  late TextComponent itemDescText;
  late TextComponent priceText;
  late TextComponent patienceText;
  late TextComponent customerResponseText;
  late TextComponent talkUpText;
  
  final List<Item> availableItems = [
    Item(name: 'Antique Watch', basePrice: 50, description: 'A beautiful timepiece from the 1900s', maxMarkup: 2.5),
    Item(name: 'Vintage Lamp', basePrice: 75, description: 'A charming lamp with brass detailing', maxMarkup: 2.0),
    Item(name: 'Leather Boots', basePrice: 120, description: 'Handcrafted genuine leather boots', maxMarkup: 1.8),
  ];
  
  final List<Customer> customers = [
    Customer(name: 'Bargain Bear', patience: 6, stubbornness: 0.8),
    Customer(name: 'Wealthy Yoma', patience: 4, stubbornness: 0.5),
    Customer(name: 'Thrifty Kuma', patience: 8, stubbornness: 0.9),
  ];

  String patienceString(int patience) {
    if (patience > 5) {
      return 'Customer is very patient.';
    } else if (patience > 2) {
      return 'Customer is somewhat patient.';
    } else {
      return 'Customer is losing patience!';
    }
  }
  
  final Random random = Random();
  
  late TextButtonComponent talkUpButton;
  late TextButtonComponent finalizeButton;

  @override
  Color backgroundColor() => const Color(0xFFeeeeee);
  
  @override
  Future<void> onLoad() async {
    // Initialize a random item and customer
    currentItem = availableItems[random.nextInt(availableItems.length)];
    currentCustomer = customers[random.nextInt(customers.length)];
    
    // Calculate starting price
    startingPrice = currentItem.basePrice;
    currentPrice = startingPrice * 1.2; // Start with 20% markup
    patienceRemaining = currentCustomer.patience.toInt();
    
    // UI components
    itemNameText = TextComponent(
      text: currentItem.name,
      position: Vector2(200, 100),
      textRenderer: TextPaint(style: const TextStyle(fontSize: 24, color: Colors.black)),
      anchor: Anchor.center,
    );
    
    itemDescText = TextComponent(
      text: currentItem.description,
      position: Vector2(200, 140),
      textRenderer: TextPaint(style: const TextStyle(fontSize: 16, color: Colors.black54)),
      anchor: Anchor.center,
    );
    
    priceText = TextComponent(
      text: '\$${currentPrice.toStringAsFixed(2)}',
      position: Vector2(200, 200),
      textRenderer: TextPaint(style: const TextStyle(fontSize: 32, color: Colors.green)),
      anchor: Anchor.center,
    );
    
    patienceText = TextComponent(
      text: patienceString(patienceRemaining),
      position: Vector2(200, 250),
      textRenderer: TextPaint(style: const TextStyle(fontSize: 16, color: Colors.red)),
      anchor: Anchor.center,
    );
    
    customerResponseText = TextComponent(
      text: '${currentCustomer.name} is looking at the ${currentItem.name}...',
      position: Vector2(200, 300),
      textRenderer: TextPaint(style: const TextStyle(fontSize: 16, color: Colors.black)),
      anchor: Anchor.center,
    );
    

    talkUpText = TextComponent(
      text: '',
      position: Vector2(200, 550),
      textRenderer: TextPaint(style: const TextStyle(fontSize: 16, color: Colors.black)),
      anchor: Anchor.center,
    );
    add(talkUpText);

    // Price controls
    final increaseSmallButton = TextButtonComponent(
      text: '+\$5',
      buttonColor: const Color(0xFF4CAF50),
      onPressed: () => adjustPrice(5),
    )
    ..position = Vector2(150, 400);
    
    final increaseLargeButton = TextButtonComponent(
      text: '+\$20',
      buttonColor: const Color(0xFF4CAF50),
      onPressed: () => adjustPrice(20),
    )
    ..position = Vector2(250, 400);
    
    final decreaseSmallButton = TextButtonComponent(
      text: '-\$5',
      buttonColor: const Color(0xFFFF5722),
      onPressed: () => adjustPrice(-5),
    )
    ..position = Vector2(150, 460);
    
    final decreaseLargeButton = TextButtonComponent(
      text: '-\$20',
      buttonColor: const Color(0xFFFF5722),
      onPressed: () => adjustPrice(-20),
    )
    ..position = Vector2(250, 460);

    talkUpButton = TextButtonComponent(
      text: 'Talk Up Customer',
      buttonColor: const Color(0xFF2196F3),
      onPressed: talkUpCustomer,
    )..position = Vector2(200, 600);

    
    finalizeButton = TextButtonComponent(
      text: 'Make Final Offer',
      buttonColor: const Color(0xFF2196F3),
      onPressed: finalizeOffer,
    )
    ..position = Vector2(200, 650);
    
    add(itemNameText);
    add(itemDescText);
    add(priceText);
    add(patienceText);
    add(customerResponseText);
    add(increaseSmallButton);
    add(increaseLargeButton);
    add(decreaseSmallButton);
    add(decreaseLargeButton);
    add(talkUpButton);
    add(finalizeButton);
  }

  void talkUpCustomer() {
    if (gameOver) return;

    // Random talk up text and random chance of increasing patience based on stubbornness
    List<String> talkUpResponses = [
      "This is a rare find!",
      "You won't find a better deal anywhere else!",
      "This item has a great history!",
      "It's a collector's item!",
    ];
    String response = talkUpResponses[random.nextInt(talkUpResponses.length)];
    talkUpText.text = response;
    double chanceOfIncreasingPatience = currentCustomer.stubbornness * 0.5;
    double randomValue = random.nextDouble();

    if (randomValue < chanceOfIncreasingPatience) {
      patienceRemaining++;
      patienceText.text = patienceString(patienceRemaining);
      customerResponseText.text = "${currentCustomer.name} seems more interested!";
    } else if (randomValue < chanceOfIncreasingPatience + 0.3) {
      customerResponseText.text = "${currentCustomer.name} doesn't seem to budge...";
    } else {
      customerResponseText.text = "${currentCustomer.name} seems frustrated...";
      patienceRemaining--;
      patienceText.text = patienceString(patienceRemaining);
      if (patienceRemaining <= 0) {
        customerResponseText.text = "${currentCustomer.name} has lost patience and left!";
        gameOver = true;
        score = 0;
        showResult();
      }
    }
  }
  
  void adjustPrice(double amount) {
    if (gameOver) return;
    
    currentPrice += amount;
    if (currentPrice < startingPrice) {
      currentPrice = startingPrice;
    }
    
    priceText.text = '\$${currentPrice.toStringAsFixed(2)}';
    
    // Customer reaction
    patienceRemaining--;
    patienceText.text = patienceString(patienceRemaining);
    
    if (patienceRemaining <= 0) {
      customerResponseText.text = "${currentCustomer.name} has lost patience and left!";
      gameOver = true;
      score = 0;
      showResult();
    } else {
      double markup = currentPrice / startingPrice;
      double maxPossibleMarkup = currentItem.maxMarkup;
      double chanceOfLeaving = (markup / maxPossibleMarkup) * currentCustomer.stubbornness;
      
      if (random.nextDouble() < chanceOfLeaving) {
        customerResponseText.text = "That's too expensive for me!";
      } else if (markup > 1.5) {
        customerResponseText.text = "Hmm, that seems a bit high...";
      } else {
        customerResponseText.text = "I'm considering your offer...";
      }
    }
  }
  
  void finalizeOffer() {
    if (gameOver) return;
    
    double markup = currentPrice / startingPrice;
    double maxPossibleMarkup = currentItem.maxMarkup;
    double acceptanceThreshold = (maxPossibleMarkup - 1.0) * currentCustomer.stubbornness;
    
    if (markup - 1.0 > acceptanceThreshold) {
      customerResponseText.text = "That's too expensive! I'm leaving.";
      score = 0;
    } else {
      // Calculate score as percentage of max possible markup achieved
      double percentOfMaxMarkup = (markup - 1.0) / (maxPossibleMarkup - 1.0) * 100;
      score = percentOfMaxMarkup.toInt();
      
      customerResponseText.text = "Deal! I'll take it for \$${currentPrice.toStringAsFixed(2)}";
      
      // Update high score
      SharedPreferences.getInstance().then((prefs) {
        int highScore = prefs.getInt('highScoreHaggling') ?? 0;
        if (score > highScore) {
          prefs.setInt('highScoreHaggling', score);
        }
      });
    }
    
    gameOver = true;
    showResult();
  }
  
  void showResult() {
    final resultText = TextComponent(
      text: 'Score: $score',
      position: Vector2(200, 550),
      textRenderer: TextPaint(style: const TextStyle(fontSize: 32, color: Colors.blue)),
      anchor: Anchor.center,
    );
    
    final playAgainButton = TextButtonComponent(
      text: 'Play Again',
      buttonColor: const Color(0xFF4CAF50),
      onPressed: resetGame,
    )
    ..position = Vector2(200, 600);

    remove(talkUpButton);
    remove(talkUpText);
    remove(finalizeButton);

    add(resultText);
    add(playAgainButton);
  }
  
  void resetGame() {
    removeAll(children);
    gameOver = false;
    onLoad();
  }
  
  // @override
  // void update(double dt) {
  //   super.update(dt);
  // }
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