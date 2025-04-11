
import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:super_tooltip/super_tooltip.dart';

class CinemaGame extends StatefulWidget {
  const CinemaGame({super.key});

  @override
  State<CinemaGame> createState() => _CinemaGameState();
}

class _CinemaGameState extends State<CinemaGame> {
  int highScore = 0;
  final _controller = SuperTooltipController();

  _CinemaGameState() {
    // Load the high score from storage
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        highScore = prefs.getInt('highScoreCinema') ?? 0;
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
                  'Welcome to Cinema\'s Script Procurement!',
                ),
                GestureDetector(
                  onTap: () async {
                    await _controller.showTooltip();
                  },
                  child: SuperTooltip(
                    showBarrier: true,
                    controller: _controller,
                    content: const Text(
                      "This game is a fun and interactive way to create a story. The game will guide you through different moods and story segments, allowing you to craft a unique narrative. Choose wisely and enjoy the process!",
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
                  MaterialPageRoute(builder: (context) => const CinemaGameScreen()),
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

class CinemaGameScreen extends StatelessWidget {
  const CinemaGameScreen({super.key});

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
                const Text('Cinema\'s Script Procurement'),
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
                game: CinemaGameEngine(),
              ),
            ),
          ],
        ),
      ),
      
    );
  }
}

enum StorySection {
  beginning,
  middle,
  end
}

enum StoryMood {
  dramatic,
  comedic,
  scary
}

class Character {
  final String name;
  final String description;
  final Map<StoryMood, double> moodAffinities;

  Character({
    required this.name, 
    required this.description, 
    required this.moodAffinities,
  });
}

class StorySegment {
  final String content;
  final StoryMood mood;
  final StorySection section;

  StorySegment({
    required this.content,
    required this.mood,
    required this.section,
  });
}

class CinemaGameEngine extends FlameGame with TapCallbacks {
  // Game variables
  int score = 0;
  int currentRound = 0;
  int maxRounds = 3;
  bool gameOver = false;
  
  Character? currentCharacter;
  StoryMood? lastSelectedMood;
  List<StorySegment> selectedSegments = [];
  
  late TextComponent scoreText;
  late TextComponent roundText;
  late TextComponent characterText;
  late TextComponent storyText;
  late TextComponent feedbackText;
  
  // UI Components
  List<TextButtonComponent> moodButtons = [];
  late TextButtonComponent nextButton;
  late TextButtonComponent playAgainButton;
  
  // Story data
  final List<Character> characters = [
    Character(
      name: 'Kenny Tanaka, Ult. Salesman',
      description: 'A smooth-talking salesman with a heart of gold',
      moodAffinities: {
        StoryMood.dramatic: 1.5,
        StoryMood.scary: 0.5,
        StoryMood.comedic: 2.0,
      },
    ),
    Character(
      name: 'Job Deniur, Ult. Mortician',
      description: 'A quirky mortician with a dark sense of humor',
      moodAffinities: {
        StoryMood.dramatic: 0.5,
        StoryMood.scary: 2.0,
        StoryMood.comedic: 1.5,
      },
    ),
    Character(
      name: 'Emilia Caraballo, Ult. Rhetorician',
      description: 'A master of wordplay with a flair for the dramatic',
      moodAffinities: {
        StoryMood.dramatic: 2.0,
        StoryMood.scary: 1.5,
        StoryMood.comedic: 0.5,
      },
    ),
    Character(
      name: 'Cyra Frolain, Ult. Ice Sculptor',
      description: 'An artist who carves beauty from ice and chaos',
      moodAffinities: {
        StoryMood.dramatic: 1.5,
        StoryMood.scary: 1.5,
        StoryMood.comedic: 1.0,
      },
    ),
    Character(
      name: 'Elliot Foster, Ult. Cinema',
      description: 'A film buff with a passion for storytelling',
      moodAffinities: {
        StoryMood.dramatic: 1.0,
        StoryMood.scary: 1.25,
        StoryMood.comedic: 2.0,
      },
    ),
    Character(
      name: 'Howard Kent, Ult. Branch Manager',
      description: 'A no-nonsense manager with a love for order',
      moodAffinities: {
        StoryMood.dramatic: 2.0,
        StoryMood.scary: 1.0,
        StoryMood.comedic: 1.25,
      },
    ),
    Character(
      name: 'Sasha Wolfe, Ult. Diviner',
      description: 'A mysterious figure with a knack for the occult',
      moodAffinities: {
        StoryMood.dramatic: 1.25,
        StoryMood.scary: 2.0,
        StoryMood.comedic: 1.0,
      },
    ),
    Character(
      name: 'Ronnie Pietri, Ult. Mechanic',
      description: 'A mechanic with a knack for all moving parts',
      moodAffinities: {
        StoryMood.dramatic: 1.0,
        StoryMood.scary: 1.5,
        StoryMood.comedic: 2.0,
      },
    ),
    Character(
      name: 'Scott Jacobs, Ult. Pilot',
      description: 'A pilot with a love for adventure and the skies',
      moodAffinities: {
        StoryMood.dramatic: 1.5,
        StoryMood.scary: 2.0,
        StoryMood.comedic: 1.0,
      },
    ),
  ];
  
  final Map<StorySection, Map<StoryMood, List<String>>> storySegments = {
    StorySection.beginning: {
      StoryMood.dramatic: [
        "The rain poured down as they stood at the crossroads of their destiny.",
        "With trembling hands, they opened the letter that would change everything.",
        "The city lights dimmed as memories of the past came flooding back.",
        "A shadowy figure appeared in the distance, beckoning them closer.",
        "The clock struck midnight, and the world around them began to unravel.",
        "Cherry blossoms swirled as the ancient sword was drawn from its scabbard.",
        "Their eyes met across the crowded mecha hangar, destiny calling them both.",
        "The pendant glowed with an otherworldly light as the prophecy began to unfold.",
        "The student council president declared war, their eyes blazing with determination.",
        "As the train departed, they knew this journey would transform them forever.",
      ],
      StoryMood.comedic: [
        "It was the kind of morning where the coffee machine explodes and the cat brings in a dead rat.",
        "If there's one thing life taught them, it's that pants are not optional for job interviews.",
        "Three weddings, two funerals, and a partridge in a pear tree - this day couldn't get any weirder.",
        "They tripped over their own shoelaces while trying to impress the new neighbor.",
        "When they tried to cook breakfast, the fire department showed up.",
        "Their tsundere roommate had accidentally washed all their white clothes with a red sock again.",
        "The magical girl transformation sequence was interrupted by an unfortunately timed phone call.",
        "They had somehow been reincarnated as a vending machine in another world.",
        "The cat wasn't supposed to talk, yet here they were, discussing philosophy at 3 AM.",
        "Their attempt at summoning a demon resulted in a confused accountant named Dave.",
      ],
      StoryMood.scary: [
        "The shadows in the corner of the room seemed to move of their own accord.",
        "The phone call came at midnight, nothing but breathing on the other end.",
        "The abandoned house had stood empty for decades, until tonight.",
        "A cold breeze swept through the room, carrying whispers of the past.",
        "The lights flickered, and for a moment, they could see the figure standing behind them.",
        "The cursed video ended with a message: 'Seven days, unless you forward this to five friends.'",
        "The abandoned school corridor echoed with the sound of children's laughter at midnight.",
        "Their reflection in the mirror smiled back, though they were not smiling.",
        "The old well in the forest had been sealed for a reason, they discovered too late.",
        "Every photo they took showed the same stranger standing behind them, getting closer each time.",
      ],
    },
    StorySection.middle: {
      StoryMood.dramatic: [
        "Tears streamed down their face as the truth was finally revealed.",
        "The betrayal cut deeper than any knife ever could.",
        "In that moment, everything they believed in came crashing down.",
        "They stood on the edge of the cliff, contemplating the leap into the unknown.",
        "The silence was deafening as they waited for the answer that would change everything.",
        "Their true power awakened as the villain threatened those they loved most.",
        "The rival extended a hand in friendship after years of bitter conflict.",
        "Under the moonlight, they made a promise that would echo across lifetimes.",
        "The mecha's systems failed as they entered the final battle, leaving only their resolve.",
        "Rain mixed with tears as they confessed feelings that had been hidden for years.",
      ],
      StoryMood.comedic: [
        "As if on cue, the sprinkler system went off during the most important speech of their life.",
        "The dog ate not just the homework, but apparently the entire kitchen table too.",
        "Their blind date turned out to be their high school nemesis. Awkward doesn't begin to cover it.",
        "They accidentally sent a text meant for their best friend to their boss instead.",
        "The cake was a lie, but the frosting was real - and delicious.",
        "The beach episode took an unexpected turn when the giant squid showed up.",
        "Their power level was over 9000, but their social skills remained at -3.",
        "The ninja training montage was interrupted by an ice cream truck jingle.",
        "They discovered their pet hamster was secretly the reincarnation of a feudal lord.",
        "Their attempt at cooking curry ended with a new color being invented.",
      ],
      StoryMood.scary: [
        "The footsteps grew louder despite no one else being in the house.",
        "The mirror reflected a face that wasn't their own.",
        "Blood dripped from the ceiling, one slow drop at a time.",
        "The door creaked open, revealing a dark figure standing in the shadows.",
        "They could hear the whispers of the dead, begging for release.",
        "The cursed doll's eyes followed them across the room, blinking when no one was watching.",
        "Every night at 3:33, the music box would play itself, growing louder each time.",
        "The text message contained coordinates to where their body would be found tomorrow.",
        "The urban legend about the bathroom mirror ritual turned out to be horrifyingly real.",
        "The school after hours transformed into a labyrinth filled with shadows of former students.",
      ],
    },
    StorySection.end: {
      StoryMood.dramatic: [
        "And in the end, they realized that love was the answer all along.",
        "With one final look back, they walked away from everything they had ever known.",
        "Some wounds never heal, but perhaps that's what makes us human.",
        "As the sun set, they knew that this was just the beginning of a new chapter.",
        "The final piece of the puzzle fell into place, revealing a truth they never expected.",
        "The cherry blossoms fell as they parted ways, promising to meet again in another life.",
        "Their rival smiled as they both reached for the stars, no longer alone in their journey.",
        "The mecha powered down for the last time, its purpose finally fulfilled.",
        "They graduated not just from school, but from the people they once were.",
        "As the sakura petals danced in the wind, they found the courage to say goodbye.",
      ],
      StoryMood.comedic: [
        "And that's why you should never bring a llama to a wedding reception.",
        "In conclusion: three stars, would accidentally set fire to again.",
        "All's well that ends well, except for that unfortunate mustache incident.",
        "They finally understood that the secret to happiness was a good pair of socks.",
        "As they walked away, they couldn't help but laugh at the absurdity of it all.",
        "The tournament ended with everyone covered in pudding, but friendship was the real prize.",
        "Their final form turned out to be suspiciously similar to a rubber duck.",
        "The world was saved thanks to the power of awkward dancing and bad puns.",
        "In the end, the real treasure was the weird memes they made along the way.",
        "They finally mastered the legendary technique of getting up before noon on weekends.",
      ],
      StoryMood.scary: [
        "The door slammed shut, trapping them inside forever.",
        "As the credits rolled, they realized the horror movie was actually based on their own life.",
        "The last text message simply read: 'I'm standing right behind you.'",
        "The darkness closed in around them, and they knew they were not alone.",
        "And as the clock broke into pieces, they vanished without a trace.",
        "The ritual was complete, and what emerged was no longer human.",
        "The diary's final entry promised they would return every blood moon to claim another victim.",
        "The last photo on the camera revealed what had been following them all along.",
        "They smiled at their reflection, unaware it would continue smiling even after they turned away.",
        "The curse would continue, passing from one unwitting soul to the next for eternity.",
      ],
    }
  };
  
  // Mood transition multipliers (mood after -> mood before)
  final Map<StoryMood, Map<StoryMood, double>> moodTransitions = {
    StoryMood.dramatic: {
      StoryMood.dramatic: 1.0,
      StoryMood.comedic: 1.5, // Dramatic after comedy is interesting
      StoryMood.scary: 1.2,
    },
    StoryMood.comedic: {
      StoryMood.dramatic: 1.3, // Comedy after drama is refreshing
      StoryMood.comedic: 0.8, // Too much comedy gets old
      StoryMood.scary: 1.8, // Comedy after scary is a great relief
    },
    StoryMood.scary: {
      StoryMood.dramatic: 1.4, // Scary after dramatic builds tension
      StoryMood.comedic: 2.0, // Scary after comedy is shocking
      StoryMood.scary: 0.9, // Too much scary gets predictable
    },
  };

  @override
  Color backgroundColor() => const Color(0xFF2C3E50); // Dark blue background
  
  @override
  Future<void> onLoad() async {
    // Initialize UI components
    scoreText = TextComponent(
      text: 'Score: 0',
      position: Vector2(200, 30),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 24,
          color: Colors.white,
        ),
      ),
      anchor: Anchor.center,
    );
    
    roundText = TextComponent(
      text: 'Story 1 of $maxRounds... Starring:',
      position: Vector2(200, 60),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 20,
          color: Colors.white,
        ),
      ),
      anchor: Anchor.center,
    );
    
    characterText = TextComponent(
      text: '',
      position: Vector2(200, 100),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 22,
          color: Colors.yellow,
          fontWeight: FontWeight.bold,
        ),
      ),
      anchor: Anchor.center,
    );
    
    storyText = TextComponent(
      text: 'Select mood for the beginning of your story',
      position: Vector2(200, 350),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      anchor: Anchor.center,
    );
    
    feedbackText = TextComponent(
      text: '',
      position: Vector2(200, 150),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 16,
          color: Colors.lightBlueAccent,
        ),
      ),
      anchor: Anchor.center,
    );
    
    // Create mood buttons
    final dramaticButton = TextButtonComponent(
      text: 'Dramatic',
      position: Vector2(90, 600),
      buttonColor: Colors.red,
      onPressed: () => selectMood(StoryMood.dramatic),
      buttonSize: Vector2(100, 50),
    );

    // final dramaticButton = ColoredButtonComponent(
    //   button: RectangleComponent(
    //     size: Vector2(100, 50),
    //     paint: Paint()..color = Colors.red.shade800,
    //   ),
    //   position: Vector2(100, 600),
    //   onPressed: () => selectMood(StoryMood.dramatic),
    //   text: "Dramatic",
      
    // )..anchor = Anchor.center;
    
    final comedicButton = TextButtonComponent(
      text: 'Comedic',
      position: Vector2(200, 600),
      buttonColor: Colors.green,
      onPressed: () => selectMood(StoryMood.comedic),
      buttonSize: Vector2(100, 50),
    );

    // final comedicButton = ButtonComponent(
    //   button: RectangleComponent(
    //     size: Vector2(100, 50),
    //     paint: Paint()..color = Colors.green.shade800,
    //   ),
    //   position: Vector2(200, 600),
    //   onPressed: () => selectMood(StoryMood.comedic),
    //   children: [
    //     TextComponent(
    //       text: 'Comedic',
    //       anchor: Anchor.center,
    //       position: Vector2(50, 25),
    //       textRenderer: TextPaint(
    //         style: const TextStyle(fontSize: 16, color: Colors.white),
    //       ),
    //     ),
    //   ],
    // )..anchor = Anchor.center;
    
    final scaryButton = TextButtonComponent(
      text: 'Scary',
      position: Vector2(310, 600),
      buttonColor: Colors.purple,
      onPressed: () => selectMood(StoryMood.scary),
      buttonSize: Vector2(100, 50),
    );

    // final scaryButton = ButtonComponent(
    //   button: RectangleComponent(
    //     size: Vector2(100, 50),
    //     paint: Paint()..color = Colors.purple.shade800,
    //   ),
    //   position: Vector2(300, 600),
    //   onPressed: () => selectMood(StoryMood.scary),
    //   children: [
    //     TextComponent(
    //       text: 'Scary',
    //       anchor: Anchor.center,
    //       position: Vector2(50, 25),
    //       textRenderer: TextPaint(
    //         style: const TextStyle(fontSize: 16, color: Colors.white),
    //       ),
    //     ),
    //   ],
    // )..anchor = Anchor.center;
    
    moodButtons = [dramaticButton, comedicButton, scaryButton];
    
    // Create next button (initially hidden)

    nextButton = TextButtonComponent(
      text: 'Next',
      position: Vector2(200, 540),
      buttonColor: Colors.blue,
      onPressed: nextSection,
      buttonSize: Vector2(150, 50),
    );

    // nextButton = ButtonComponent(
    //   button: RectangleComponent(
    //     size: Vector2(150, 50),
    //     paint: Paint()..color = Colors.blue,
    //   ),
    //   position: Vector2(200, 550),
    //   onPressed: nextSection,
    //   children: [
    //     TextComponent(
    //       text: 'Next',
    //       anchor: Anchor.center,
    //       position: Vector2(75, 25),
    //       textRenderer: TextPaint(
    //         style: const TextStyle(fontSize: 18, color: Colors.white),
    //       ),
    //     ),
    //   ],
    // )..anchor = Anchor.center;
    
    // Add components
    add(scoreText);
    add(roundText);
    add(characterText);
    add(storyText);
    add(feedbackText);
    
    for (final button in moodButtons) {
      add(button);
    }
    
    // Start the first round
    startNewStory();
  }
  
  void startNewStory() {
    currentRound++;
    roundText.text = 'Story $currentRound of $maxRounds... Starring:';
    
    // Select random character
    currentCharacter = characters[Random().nextInt(characters.length)];
    characterText.text = currentCharacter!.name;
    
    selectedSegments = [];
    lastSelectedMood = null;
    
    // Update instructions
    storyText.text = 'Select mood for the beginning of your story';
    feedbackText.text = currentCharacter!.description;
  }
  
  void selectMood(StoryMood mood) {
    if (gameOver) return;
    
    StorySection currentSection;
    if (selectedSegments.isEmpty) {
      currentSection = StorySection.beginning;
    } else if (selectedSegments.length == 1) {
      currentSection = StorySection.middle;
    } else {
      currentSection = StorySection.end;
    }
    
    // Get random story segment for selected mood and section
    final segments = storySegments[currentSection]![mood]!;
    final segment = segments[Random().nextInt(segments.length)];
    
    // Add segment to story
    selectedSegments.add(StorySegment(
      content: segment,
      mood: mood,
      section: currentSection,
    ));
    
    // Display current story
    updateStoryDisplay();
    
    // Calculate score for this segment
    if (lastSelectedMood != null) {
      double multiplier = moodTransitions[mood]![lastSelectedMood]!;
      double characterMultiplier = currentCharacter!.moodAffinities[mood]!;
      int segmentScore = (10 * multiplier * characterMultiplier).round();
      
      score += segmentScore;
      scoreText.text = 'Score: $score';
      
      // Feedback on score
      feedbackText.text = 'Mood transition: x${multiplier.toStringAsFixed(1)}\n'
          'Character affinity: x${characterMultiplier.toStringAsFixed(1)}\n'
          'Points: +$segmentScore';
    }
    
    lastSelectedMood = mood;
    
    // Show next button after selection
    if (!children.contains(nextButton)) {
      add(nextButton);
    }
    // Remove mood buttons
    for (final button in moodButtons) {
      remove(button);
    }
  }

  
  
  void updateStoryDisplay() {
    String storyDisplay = '';
    for (final segment in selectedSegments) {
      String segTextWrapped = wrapText(segment.content);
      storyDisplay += '$segTextWrapped\n\n';
      //storyDisplay += '${segment.content}\n\n';
    }
    storyText.text = storyDisplay;
  }
  
  void nextSection() {
    // Remove next button
    if (children.contains(nextButton)) {
      remove(nextButton);
    }
    // Add mood buttons back
    for (final button in moodButtons) {
      add(button);
    }
    
    if (selectedSegments.length >= 3) {
      // Story is complete
      if (currentRound >= maxRounds) {
        endGame();
      } else {
        // Start next story
        startNewStory();
      }
    } else {
      // Move to next section
      String sectionName;
      if (selectedSegments.length == 1) {
        sectionName = 'middle';
      } else {
        sectionName = 'ending';
      }
      
      feedbackText.text = 'Now select the $sectionName of your story';
    }
  }
  
  void endGame() {
    gameOver = true;
    
    // Remove mood buttons
    for (final button in moodButtons) {
      remove(button);
    }
    
    // Final score message
    feedbackText.text = 'Game Over! Final Score: $score';
    
    // Add play again button

    playAgainButton = TextButtonComponent(
      text: 'Play Again',
      position: Vector2(200, 550),
      buttonColor: Colors.green,
      onPressed: resetGame,
      buttonSize: Vector2(150, 50),
    );

    // playAgainButton = ButtonComponent(
    //   button: RectangleComponent(
    //     size: Vector2(200, 60),
    //     paint: Paint()..color = Colors.green,
    //   ),
    //   position: Vector2(200, 450),
    //   onPressed: resetGame,
    //   children: [
    //     TextComponent(
    //       text: 'Play Again',
    //       anchor: Anchor.center,
    //       position: Vector2(100, 30),
    //       textRenderer: TextPaint(
    //         style: const TextStyle(fontSize: 20, color: Colors.white),
    //       ),
    //     ),
    //   ],
    // );
    add(playAgainButton);
    
    // Save high score
    SharedPreferences.getInstance().then((prefs) {
      int highScore = prefs.getInt('highScoreCinema') ?? 0;
      if (score > highScore) {
        prefs.setInt('highScoreCinema', score);
      }
    });
  }
  
  void resetGame() {
    // Reset game state
    score = 0;
    currentRound = 0;
    gameOver = false;
    selectedSegments = [];
    
    // Update UI
    scoreText.text = 'Score: 0';
    
    // Remove play again button
    remove(playAgainButton);
    
    // Add mood buttons back
    for (final button in moodButtons) {
      add(button);
    }
    
    // Start new game
    startNewStory();
  }
}

class TextButtonComponent extends PositionComponent with TapCallbacks {
  String text;
  final Color buttonColor;
  final VoidCallback onPressed;
  final TextPaint textPaint;
  final Vector2 buttonSize;
  bool visible = true;
  
  TextButtonComponent({
    required this.text,
    required Vector2 position,
    required this.buttonColor,
    required this.onPressed,
    required this.buttonSize,
    Color textColor = Colors.white,
  }) : textPaint = TextPaint(
    style: TextStyle(
      fontSize: 16,
      color: textColor,
      fontWeight: FontWeight.bold,
    ),
  ), super(
    position: position,
    size: buttonSize,
    anchor: Anchor.center,
  );
  
  @override
  void render(Canvas canvas) {
    if (!visible) return;
    
    // Draw button background
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      Paint()..color = buttonColor
    );

    text = wrapText(text);
    
    // Draw text centered
    textPaint.render(
      canvas, 
      text,
      Vector2(size.x / 2, size.y / 2),
      anchor: Anchor.center
    );
  }
  
  @override
  void onTapDown(TapDownEvent event) {
    if (visible) {
      onPressed();
    }
  }
}

String wrapText(String text) {

  // Add newlines to wrap text that is too long
  const int maxLineLength = 45;
  List<String> lines = text.split('\n');
  
  for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
    String line = lines[lineIndex];
    if (line.length <= maxLineLength) continue;
    
    int lastSpace = -1;
    for (int i = 1; i < line.length; i++) {
      if (line[i] == ' ') {
        lastSpace = i;
      }
      
      if (i > maxLineLength && lastSpace != -1) {
        // Insert newline at the last space
        String firstPart = line.substring(0, lastSpace);
        String secondPart = line.substring(lastSpace + 1);
        lines[lineIndex] = firstPart;
        lines.insert(lineIndex + 1, secondPart);
        break;
      }
    }
  }
  
  return lines.join('\n');
} 