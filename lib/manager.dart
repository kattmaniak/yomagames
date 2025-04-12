// This is a skeleton for a game. It is not a complete game and will not run.
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:super_tooltip/super_tooltip.dart';

class ManagerGame extends StatefulWidget {
  const ManagerGame({super.key});

  @override
  State<ManagerGame> createState() => _ManagerGameState();
}

class _ManagerGameState extends State<ManagerGame> {
  int highScore = 0;
  final _controller = SuperTooltipController();

  _ManagerGameState() {
    // Load the high score from storage
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        highScore = prefs.getInt('highScoreManager') ?? 0;
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
                  'Welcome to Manager\'s Earnest Support!',
                ),
                GestureDetector(
                  onTap: () async {
                    await _controller.showTooltip();
                  },
                  child: SuperTooltip(
                    showBarrier: true,
                    controller: _controller,
                    content: const Text(
                      "This game is about making the right choices as a manager. Try to help your employees with their problems and earn points. The more scenarios you handle well, the better your score! Good luck!",
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
                  MaterialPageRoute(builder: (context) => const ManagerGameScreen()),
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

double wu = 1.0; // Global variable for width unit

class ManagerGameScreen extends StatelessWidget {
  const ManagerGameScreen({super.key});

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
                  const Text('Manager\'s Earnest Support'),
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
                  game: ManagerGameEngine(),
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

class Scenario {
  final String employeeName;
  final String problem;
  final List<String> options;
  final int correctOption;
  final List<String> outcomes;

  Scenario({
    required this.employeeName,
    required this.problem,
    required this.options,
    required this.correctOption,
    required this.outcomes,
  });
}

final List<Scenario> allScenarios = [
    Scenario(
      employeeName: 'Alex',
      problem: 'I\'m feeling overwhelmed with my current workload. What should I do?',
      options: [
        'Just work harder and longer hours',
        'Let\'s review your tasks and prioritize them together',
        'Maybe this job isn\'t for you',
      ],
      correctOption: 1,
      outcomes: [
        'Alex looks stressed and might burn out soon.',
        'Alex feels supported and manages to get back on track.',
        'Alex looks upset and starts job hunting.',
      ],
    ),
    Scenario(
      employeeName: 'Jordan',
      problem: 'I have a conflict with a teammate about our project direction. How should I handle it?',
      options: [
        'Just do it your way, you know best',
        'Avoid the conflict and work around them',
        'Schedule a meeting to discuss both perspectives professionally',
      ],
      correctOption: 2,
      outcomes: [
        'The conflict escalates and team morale drops.',
        'Communication breaks down and the project stalls.',
        'The team finds a compromise and works better together.',
      ],
    ),
    Scenario(
      employeeName: 'Taylor',
      problem: 'I made a mistake that might cost us a client. What should I do?',
      options: [
        'Hide it and hope no one notices',
        'Take responsibility and propose a solution',
        'Blame it on someone else',
      ],
      correctOption: 1,
      outcomes: [
        'The problem gets worse and the client leaves anyway.',
        'The client appreciates the honesty and gives us another chance.',
        'Team trust is damaged and the client still leaves.',
      ],
    ),
    Scenario(
      employeeName: 'Morgan',
      problem: 'I have a great idea for a new project, but I\'m not sure how to present it.',
      options: [
        'Just start working on it without approval',
        'Forget about it, we\'re too busy',
        'Prepare a brief proposal with potential benefits',
      ],
      correctOption: 2,
      outcomes: [
        'Resources are wasted on an unapproved project.',
        'Morgan feels discouraged and innovation suffers.',
        'The idea gets proper consideration and might be implemented.',
      ],
    ),
    Scenario(
      employeeName: 'Casey',
      problem: 'I\'m struggling to meet my deadline. What should I do?',
      options: [
        'Just submit whatever you have, quality doesn\'t matter',
        'Ask for more time and explain your challenges',
        'Work all night, sleep is for the weak',
      ],
      correctOption: 1,
      outcomes: [
        'The poor quality work has to be redone anyway.',
        'The deadline is adjusted and better work is produced.',
        'Casey burns out and calls in sick the next day.',
      ],
    ),
    Scenario(
      employeeName: 'Jamie',
      problem: 'I feel like my contributions are not valued. What should I do?',
      options: [
        'Keep quiet and hope things change',
        'Talk to your manager about your feelings',
        'Start looking for a new job',
      ],
      correctOption: 1,
      outcomes: [
        'Jamie feels resentful and disengaged.',
        'Jamie feels heard and appreciated.',
        'Jamie leaves the company, taking their skills elsewhere.',
      ],
    ),
    Scenario(
      employeeName: 'Riley',
      problem: 'I\'m not sure how to handle a difficult client. What should I do?',
      options: [
        'Ignore them and hope they go away',
        'Be rude back to them',
        'Listen to their concerns and try to find a solution',
      ],
      correctOption: 2,
      outcomes: [
        'The client escalates the issue and leaves.',
        'The situation worsens and the client complains.',
        'The client feels valued and stays with us.',
      ],
    ),
    Scenario(
      employeeName: 'Drew',
      problem: 'I\'m not sure how to approach a sensitive topic with a colleague. What should I do?',
      options: [
        'Avoid the conversation altogether',
        'Bring it up in front of others to embarrass them',
        'Have a private conversation and be respectful',
      ],
      correctOption: 2,
      outcomes: [
        'The issue festers and creates tension.',
        'The colleague feels humiliated and trust is broken.',
        'The colleague appreciates the respect and trust grows.',
      ],
    ),
    Scenario(
      employeeName: 'Skyler',
      problem: 'I\'m not sure how to handle a team member who is not pulling their weight. What should I do?',
      options: [
        'Ignore it and hope it gets better',
        'Talk to them directly and offer help',
        'Complain to your manager about them',
      ],
      correctOption: 1,
      outcomes: [
        'The issue continues and team morale drops.',
        'The team member appreciates the support and improves.',
        'The team member feels attacked and becomes defensive.',
      ],
    ),
    Scenario(
      employeeName: 'Finley',
      problem: 'I\'m not sure how to give constructive feedback. What should I do?',
      options: [
        'Just tell them they did a bad job',
        'Avoid giving feedback altogether',
        'Use the "sandwich" method: positive, negative, positive',
      ],
      correctOption: 2,
      outcomes: [
        'The team member feels demotivated and defensive.',
        'The team member feels confused and lost.',
        'The team member appreciates the feedback and improves.',
      ],
    ),
    Scenario(
      employeeName: 'Parker',
      problem: 'I\'m not sure how to handle a colleague who is always late. What should I do?',
      options: [
        'Ignore it and hope they change',
        'Talk to them about the impact of their lateness',
        'Complain to your manager about them',
      ],
      correctOption: 1,
      outcomes: [
        'The issue continues and team morale drops.',
        'The colleague appreciates the feedback and improves.',
        'The colleague feels attacked and becomes defensive.',
      ],
    ),
    Scenario(
      employeeName: 'Avery',
      problem: 'I\'m not sure how to handle a colleague who is always negative. What should I do?',
      options: [
        'Ignore them and hope they change',
        'Talk to them about their negativity',
        'Complain to your manager about them',
      ],
      correctOption: 1,
      outcomes: [
        'The issue continues and team morale drops.',
        'The colleague appreciates the feedback and improves.',
        'The colleague feels attacked and becomes defensive.',
      ],
    ),
    Scenario(
      employeeName: 'Rowan',
      problem: 'I\'m not sure how to handle a colleague who is always interrupting. What should I do?',
      options: [
        'Talk to them about their interruptions',
        'Ignore it and hope they change',
        'Complain to your manager about them',
      ],
      correctOption: 0,
      outcomes: [
        'The colleague appreciates the feedback and improves.',
        'The issue continues and team morale drops.',
        'The colleague feels attacked and becomes defensive.',
      ],
    ),
    Scenario(
      employeeName: 'Quinn',
      problem: 'I\'m not sure how to handle a colleague who is always gossiping. What should I do?',
      options: [
        'Ignore it and hope they change',
        'Talk to them about their gossiping',
        'Complain to your manager about them',
      ],
      correctOption: 1,
      outcomes: [
        'The issue continues and team morale drops.',
        'The colleague appreciates the feedback and improves.',
        'The colleague feels attacked and becomes defensive.',
      ],
    ),
    Scenario(
      employeeName: 'Sage',
      problem: 'I\'m not sure how to handle a colleague who is always taking credit for my work. What should I do?',
      options: [
        'Ignore it and hope they change',
        'Talk to them about their behavior',
        'Complain to your manager about them',
      ],
      correctOption: 1,
      outcomes: [
        'The issue continues and team morale drops.',
        'The colleague appreciates the feedback and improves.',
        'The colleague feels attacked and becomes defensive.',
      ],
    ),
    Scenario(
      employeeName: 'Charlie',
      problem: 'I\'m not sure how to handle a colleague who is always asking for help. What should I do?',
      options: [
        'Help them when you can, but set boundaries',
        'Ignore them and hope they figure it out',
        'Complain to your manager about them',
      ],
      correctOption: 0,
      outcomes: [
        'The colleague appreciates the help and becomes more independent.',
        'The issue continues and team morale drops.',
        'The colleague feels attacked and becomes defensive.',
      ],
    ),
    Scenario(
      employeeName: 'Taylor',
      problem: 'I\'m not sure how to handle a colleague who is always taking long breaks. What should I do?',
      options: [
        'Ignore it and hope they change',
        'Talk to them about their breaks',
        'Complain to your manager about them',
      ],
      correctOption: 1,
      outcomes: [
        'The issue continues and team morale drops.',
        'The colleague appreciates the feedback and improves.',
        'The colleague feels attacked and becomes defensive.',
      ],
    ),
    Scenario(
      employeeName: 'Emery',
      problem: 'I\'m not sure how to handle a colleague who is always making excuses. What should I do?',
      options: [
        'Ignore it and hope they change',
        'Complain to your manager about them',
        'Talk to them about their excuses',
      ],
      correctOption: 2,
      outcomes: [
        'The issue continues and team morale drops.',
        'The colleague feels attacked and becomes defensive.',
        'The colleague appreciates the feedback and improves.',
      ],
    ),
    Scenario(
      employeeName: 'Jordan',
      problem: 'I\'m not sure how to handle a colleague who is always asking for favors. What should I do?',
      options: [
        'Ignore them and hope they stop',
        'Help them when you can, but set boundaries',
        'Complain to your manager about them',
      ],
      correctOption: 1,
      outcomes: [
        'The issue continues and team morale drops.',
        'The colleague appreciates the help and becomes more independent.',
        'The colleague feels attacked and becomes defensive.',
      ],
    ),
    Scenario(
      employeeName: 'Elliot',
      problem: 'I feel underutilized and bored with my current assignments. How can I bring more value?',
      options: [
        'Maybe you just need to try harder.',
        'It might be best to stick with what you know.',
        'Let\'s discuss your strengths and assign you to a more challenging project.',
      ],
      correctOption: 2,
      outcomes: [
        'Elliot remains disengaged and unmotivated.',
        'Elliot continues to feel unchallenged and uninspired.',
        'Elliot feels valued and begins to thrive in new tasks.',
      ],
    ),
    Scenario(
      employeeName: 'Sienna',
      problem: 'I made a mistake that cost us an important client last week. What should I do?',
      options: [
        'Own up to it, learn from it, and propose a corrective plan.',
        'Dismiss the mistake as a one-time error.',
        'Blame external factors to avoid taking responsibility.'
      ],
      correctOption: 0,
      outcomes: [
        'Sienna gains trust through accountability.',
        'Sienna\'s inaction further erodes client confidence.',
        'Shifting blame only deepens the underlying issues.',
      ],
    ),
    Scenario(
      employeeName: 'Harper',
      problem: 'There is constant tension within the team that is affecting productivity. How should we address it?',
      options: [
        'Ignore the tension and hope it resolves itself.',
        'Organize a team meeting to address the issues and mediate conflicts.',
        'Advise individuals privately without tackling the group dynamic.',
      ],
      correctOption: 1,
      outcomes: [
        'Ignoring the issue causes the tension to worsen.',
        'The team feels heard and begins to resolve their differences.',
        'Private advice fails to mend the collective discord.',
      ],
    ),
    Scenario(
      employeeName: 'Kai',
      problem: 'I\'m overwhelmed by the increasing workload. Should I ask for help?',
      options: [
        'Take it all on, as it shows your commitment.',
        'Let\'s look at reassigning some tasks to ease your burden.',
        'Push through without changing your routine.'
      ],
      correctOption: 1,
      outcomes: [
        'Kai continues to struggle and risks burnout.',
        'Kai gains necessary support and improves productivity.',
        'The unsustainable pressure eventually takes its toll.',
      ],
    ),
    Scenario(
      employeeName: 'Cameron',
      problem: 'I have a new innovative idea, but I\'m hesitant about presenting it to senior management. What should I do?',
      options: [
        'Wait until you have every detail ironed out.',
        'Share it casually with peers before going higher up.',
        'Prepare a concise proposal and seek feedback to refine it further.',
      ],
      correctOption: 2,
      outcomes: [
        'Delaying too long might make you miss the opportunity.',
        'Casual sharing fails to make the necessary impact.',
        'Cameron\'s well-prepared proposal gains attention and sparks interest.',
      ],
    ),
    Scenario(
      employeeName: 'Morgan',
      problem: 'I found a significant error in last quarter\'s financial report that our VP already presented to the board. Should I bring it up now?',
      options: [
      'Transparently report the error through proper channels immediately',
      'Keep quiet - exposing it now might damage our department\'s reputation',
      'Discreetly fix it without drawing attention to the mistake',
      ],
      correctOption: 0,
      outcomes: [
      'While there\'s short-term embarrassment, your transparency builds long-term trust.',
      'The error eventually surfaces during an audit, causing much bigger problems.',
      'The inconsistency creates confusion in future reporting and raises questions about data integrity.',
      ],
    ),
    Scenario(
      employeeName: 'Dana',
      problem: 'My project deadline conflicts with my child\'s important surgery. My backup colleague would get overtime pay we can\'t afford in our budget.',
      options: [
      'Approve the necessary overtime despite budget constraints',
      'Find a compromise by partially delegating and working remotely during recovery',
      'Postpone the surgery to meet the work deadline',
      ],
      correctOption: 1,
      outcomes: [
      'The budget overrun triggers an audit and questions about your financial management.',
      'The balanced approach shows empathy while still meeting business needs.',
      'Dana\'s personal sacrifice creates resentment and affects future performance.',
      ],
    ),
    Scenario(
      employeeName: 'Jae',
      problem: 'I believe our new product has a potential safety issue, but raising it will delay launch and affect our quarterly targets.',
      options: [
      'Quietly document the concern but proceed with launch to meet targets',
      'Delay the launch until the issue is properly investigated',
      'Launch on schedule - the issue is probably minor and can be fixed in an update',
      ],
      correctOption: 1,
      outcomes: [
      'The documented concern becomes evidence of negligence when problems arise.',
      'While targets are missed, you avoid a potentially costly recall and litigation.',
      'The safety issue causes product failures and potential legal liability.',
      ],
    ),
    Scenario(
      employeeName: 'Riley',
      problem: 'I discovered a colleague is using company resources for their side business. They\'re going through financial hardship after medical issues.',
      options: [
      'Have a private conversation about proper boundaries and alternatives',
      'Report them immediately according to company policy',
      'Look the other way - everyone deserves a second chance',
      ],
      correctOption: 0,
      outcomes: [
      'The colleague appreciates the chance to correct their behavior without severe consequences.',
      'The colleague is terminated and the team becomes fearful of making any mistakes.',
      'The behavior escalates and is discovered by compliance, implicating you for not reporting it.',
      ],
    ),
    Scenario(
      employeeName: 'Blake',
      problem: 'My innovative solution could save the company millions, but it would automate away the jobs of several loyal employees.',
      options: [
      'Withhold the idea to protect people\'s jobs',
      'Present the solution with a transition plan to retrain affected employees',
      'Implement the solution - business efficiency must come first',
      ],
      correctOption: 1,
      outcomes: [
      'A competitor implements a similar solution, putting even more jobs at risk.',
      'The company benefits from innovation while demonstrating commitment to its people.',
      'The efficiency gains are overshadowed by plummeting morale and increased turnover.',
      ],
    ),
    Scenario(
      employeeName: 'Sam',
      problem: 'I\'ve been offered my dream role at a competitor, but my departure would leave our understaffed team in crisis.',
      options: [
      'Ask them to decline the offer out of loyalty to the team',
      'Encourage them to take the opportunity immediately',
      'Work with them on a transition plan that considers both their career and the team\'s needs',
      ],
      correctOption: 2,
      outcomes: [
      'Sam stays but becomes resentful, eventually leaving without notice anyway.',
      'The sudden departure creates a productivity collapse your team can\'t recover from.',
      'The managed transition allows both Sam\'s growth and team continuity.',
      ],
    ),
    Scenario(
      employeeName: 'Avery',
      problem: 'I\'ve been asked to lead a project that I don\'t feel qualified for. What should I do?',
      options: [
        'Decline the offer and let someone else take it on',
        'Accept the challenge and seek mentorship from experienced colleagues',
        'Fake it till you make it - just go for it',
      ],
      correctOption: 1,
      outcomes: [
        'Avery misses a valuable growth opportunity.',
        'Avery learns and grows, gaining respect from peers.',
        'Avery struggles and the project suffers as a result.',
      ],
    ),  
    Scenario(
      employeeName: 'Jordan',
      problem: 'I\'ve been asked to work overtime on a project that I don\'t think is necessary. What should I do?',
      options: [
        'Refuse to work overtime and let the project fail',
        'Work overtime and hope it leads to a promotion',
        'Discuss the necessity of the project with your manager',
      ],
      correctOption: 2,
      outcomes: [
        'The project fails and Jordan is blamed.',
        'Jordan works hard but feels unappreciated.',
        'The project is reassessed and resources are allocated appropriately.',
      ],
    ),
    Scenario(
      employeeName: 'Taylor',
      problem: 'I\'ve been asked to mentor a new employee who is struggling. What should I do?',
      options: [
        'Ignore the request and let them figure it out',
        'Take the time to mentor them and help them succeed',
        'Complain about the extra work to your manager',
      ],
      correctOption: 1,
      outcomes: [
        'The new employee continues to struggle and morale drops.',
        'The new employee thrives and becomes a valuable team member.',
        'Taylor feels overwhelmed and unappreciated.',
      ],
    ),
    // Add more scenarios as needed
  ];

class ManagerGameEngine extends FlameGame with TapCallbacks {
  // Game state variables
  int score = 0;
  int scenariosHandled = 0;
  double timeRemaining = 60.0; // 60 seconds game time
  bool gameOver = false;
  Random random = Random();
  
  // UI Components
  late TextComponent scoreText;
  late TextComponent timerText;
  late TextComponent scenarioText;
  late TextComponent employeeNameText;
  late List<TextButtonComponent> optionButtons;
  late TextComponent outcomeText;
  
  // Current scenario
  Scenario? currentScenario;
  bool awaitingChoice = false;

  final List<Scenario> scenarios = [];

  @override
  Color backgroundColor() => const Color(0xFFEDF1F8);
  
  @override
  Future<void> onLoad() async {
    // Load scenarios
    scenarios.addAll(allScenarios);
    // Header
    add(RectangleComponent(
      position: Vector2(0, 0),
      size: Vector2(400*wu, 80*wu),
      paint: Paint()..color = const Color(0xFF2C3E50),
    ));
    
    add(TextComponent(
      text: 'Manager\'s Earnest Support',
      position: Vector2(200*wu, 40*wu),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 24,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        )
      ),
      anchor: Anchor.center,
    ));
    
    // Score display
    scoreText = TextComponent(
      text: 'Score: 0',
      position: Vector2(20*wu, 100*wu),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 20,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        )
      ),
    );
    add(scoreText);
    
    // Timer display
    timerText = TextComponent(
      text: 'Time: 60s',
      position: Vector2(300*wu, 100*wu),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 20,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        )
      ),
    );
    add(timerText);
    
    // Employee name
    employeeNameText = TextComponent(
      text: '',
      position: Vector2(200*wu, 150*wu),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 22,
          color: Colors.blue,
          fontWeight: FontWeight.bold,
        )
      ),
      anchor: Anchor.center,
    );
    add(employeeNameText);
    
    // Scenario text
    scenarioText = TextComponent(
      text: '',
      position: Vector2(200*wu, 250*wu),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 18,
          color: Colors.black,
        )
      ),
      anchor: Anchor.center,
    );
    add(scenarioText);
    
    // Option buttons
    optionButtons = [];
    for (int i = 0; i < 3; i++) {
      final button = TextButtonComponent(
        text: '',
        position: Vector2(200*wu, (400 + i * 80)*wu),
        buttonColor: const Color(0xFF3498DB),
        onPressed: () => selectOption(i),
      );
      optionButtons.add(button);
      add(button);
    }
    
    // Outcome text
    outcomeText = TextComponent(
      text: '',
      position: Vector2(200*wu, 650*wu),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 18,
          color: Colors.green,
          fontWeight: FontWeight.bold,
        )
      ),
      anchor: Anchor.center,
    );
    add(outcomeText);
    
    // Start the first scenario
    nextScenario();
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (!gameOver) {
      timeRemaining -= dt;
      timerText.text = 'Time: ${timeRemaining.toInt()}s';
      
      if (timeRemaining <= 0) {
        endGame();
      }
    }
  }
  
  void nextScenario() {
    if (scenarios.isEmpty) {
      // If we've gone through all scenarios, end the game
      endGame();
      return;
    }
    
    // Select random scenario
    int index = random.nextInt(scenarios.length);
    currentScenario = scenarios[index];
    scenarios.removeAt(index); // Remove so we don't repeat
    
    // Update UI
    employeeNameText.text = currentScenario!.employeeName;
    scenarioText.text = wrapText(currentScenario!.problem);
    
    for (int i = 0; i < optionButtons.length; i++) {
      optionButtons[i].text = currentScenario!.options[i];
      optionButtons[i].visible = true;
    }
    
    outcomeText.text = '';
    awaitingChoice = true;
  }
  
  void selectOption(int option) {
    if (!awaitingChoice || gameOver) return;
    
    awaitingChoice = false;
    
    // Display outcome
    outcomeText.text = wrapText(currentScenario!.outcomes[option]);

    if (option == currentScenario!.correctOption) {
      score++;
      scoreText.text = 'Score: $score';
      outcomeText.textRenderer = TextPaint(
        style: const TextStyle(
          fontSize: 18,
          color: Colors.green,
          fontWeight: FontWeight.bold,
        )
      );
    } else {
      outcomeText.textRenderer = TextPaint(
        style: const TextStyle(
          fontSize: 18,
          color: Colors.red,
          fontWeight: FontWeight.bold,
        )
      );
    }
    
    // Hide buttons temporarily
    for (var button in optionButtons) {
      button.visible = false;
    }
    
    scenariosHandled++;
    
    // Show next scenario after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (!gameOver) {
        nextScenario();
      }
    });
  }
  
  void endGame() {
    gameOver = true;
    
    // Clear the screen for final score
    removeAll(children.where((component) => 
      component != scoreText && 
      component != timerText
    ).toList());
    
    // Show final score
    final gameOverText = TextComponent(
      text: 'Game Over!',
      position: Vector2(200*wu, 300*wu),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 36,
          color: Colors.red,
          fontWeight: FontWeight.bold,
        )
      ),
      anchor: Anchor.center,
    );
    add(gameOverText);
    
    final finalScoreText = TextComponent(
      text: 'Final Score: $score',
      position: Vector2(200*wu, 360*wu),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 28,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        )
      ),
      anchor: Anchor.center,
    );
    add(finalScoreText);
    
    final scenariosText = TextComponent(
      text: 'Scenarios Handled: $scenariosHandled',
      position: Vector2(200*wu, 400*wu),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 20,
          color: Colors.black,
        )
      ),
      anchor: Anchor.center,
    );
    add(scenariosText);
    
    // Play again button
    final playAgainButton = TextButtonComponent(
      text: 'Play Again',
      position: Vector2(200*wu, 500*wu),
      buttonColor: const Color(0xFF2ECC71),
      onPressed: resetGame,
    );
    add(playAgainButton);
    
    // Update high score
    SharedPreferences.getInstance().then((prefs) {
      int highScore = prefs.getInt('highScoreManager') ?? 0;
      if (score > highScore) {
        prefs.setInt('highScoreManager', score);
      }
    });
  }
  
  void resetGame() {
    removeAll(children);
    score = 0;
    scenariosHandled = 0;
    timeRemaining = 60.0;
    gameOver = false;
    
    // Replenish scenarios
    scenarios.clear();
    scenarios.addAll(allScenarios);
    
    onLoad();
  }
}

class TextButtonComponent extends PositionComponent with TapCallbacks {
  String text;
  final Color buttonColor;
  final VoidCallback onPressed;
  final TextPaint textPaint;
  bool visible = true;
  
  TextButtonComponent({
    required this.text,
    required Vector2 position,
    required this.buttonColor,
    required this.onPressed,
    Color textColor = Colors.white,
  }) : textPaint = TextPaint(
    style: TextStyle(
      fontSize: 16,
      color: textColor,
      fontWeight: FontWeight.bold,
    ),
  ), super(
    position: position,
    size: Vector2(350*wu, 60*wu),
    anchor: Anchor.center,
  );
  
  @override
  void render(Canvas canvas) {
    if (!visible) return;
    
    // Draw button background
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(10*wu)),
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