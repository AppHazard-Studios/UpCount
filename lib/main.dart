import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

//import 'package:wakelock/wakelock.dart';
import 'package:audioplayers/audioplayers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //Wakelock.enable();
  await preloadClickSound();
  // Force landscape orientation
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(MyApp());
  });
}

final AudioPlayer _clickPlayer = AudioPlayer();

void playClick() {
  _clickPlayer.play(AssetSource('sounds/click.mp3'));
}

Future<void> preloadClickSound() async {
  AudioPlayer preloadPlayer = AudioPlayer();
  // Load the sound by setting its source
  await preloadPlayer.setSource(AssetSource('sounds/click.mp3'));
  preloadPlayer.dispose();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UpCount',
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class ClickSoundPlayer {
  final List<AudioPlayer> _players = [];
  int _currentIndex = 0;

  ClickSoundPlayer({int poolSize = 9}) {
    // Create a pool of AudioPlayers
    for (int i = 0; i < poolSize; i++) {
      _players.add(AudioPlayer());
    }
  }

  Future<void> play() async {
    final player = _players[_currentIndex];
    _currentIndex = (_currentIndex + 1) % _players.length;
    await player.play(AssetSource('sounds/click.mp3'));
  }

  void dispose() {
    for (final player in _players) {
      player.dispose();
    }
  }
}

// -----------------------------------------------------------------------------
//  HOME SCREEN
// -----------------------------------------------------------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 7 squares, initially show U P C O U N T
  List<String> homeSquares = 'UPCOUNT'.split('');
  bool animating = false;
  final ClickSoundPlayer clickSoundPlayer = ClickSoundPlayer(poolSize: 9);

  // AudioPlayer for clicks when animating squares
  //playClick();
  //final AudioCache _clickCache = AudioCache(prefix: 'sounds/click.mp3');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Mark the layout as ready after the first frame
    });
    //_clickCache.load('click.mp3');
    // Always reset to 'UPCOUNT' each time we arrive
    homeSquares = 'UPCOUNT'.split('');
  }

  /// Animate from current letters to [word], then run [onComplete].
  /// Each letter changes after 150ms; total 7 letters => ~1s total.
  Future<void> animateSquares(String word, VoidCallback onComplete) async {
    if (animating) return;
    animating = true;

    final newLetters = word.split(''); // 7 letters
    // For each letter...
    for (int i = 0; i < newLetters.length; i++) {
      // 1) Update the UI
      setState(() {
        homeSquares[i] = newLetters[i];
      });

      // 2) Play click sound (stop any previous click if overlapping)

      clickSoundPlayer.play();

      // 3) Optionally add haptic feedback here for each letter:
      // HapticFeedback.mediumImpact();

      // 4) Wait 150 ms before moving on to the next letter
      await Future.delayed(Duration(milliseconds: 150));
    }

    // Wait an extra 300 ms, then call onComplete
    await Future.delayed(Duration(milliseconds: 300));
    animating = false;
    onComplete();
  }

  /// Navigate to a round page and reset squares to 'UPCOUNT' after returning
  void _goToRound(String newWord, Widget page) {
    if (animating) return;
    animateSquares(newWord, () async {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      setState(() {
        homeSquares = 'UPCOUNT'.split('');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Transparent app bar, no text
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: null,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Yellow-ish background
          Container(color: const Color(0xFFFFE8A8)),

          // Main content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Round:',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 24),
                // 7 squares
                FixedSelectionBoard(totalBoxes: 7, items: homeSquares),
                SizedBox(height: 30),
                // Row of buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      onPressed:
                          () => _goToRound('LETTERS', LettersRoundPage()),
                      style: _outlinedStyle(),
                      child: Text(
                        'Letters Round',
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                    SizedBox(width: 20),
                    OutlinedButton(
                      onPressed:
                          () => _goToRound('NUMBERS', NumbersRoundPage()),
                      style: _outlinedStyle(),
                      child: Text(
                        'Numbers Round',
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                    SizedBox(width: 20),
                    OutlinedButton(
                      onPressed:
                          () => _goToRound('CONDRUM', ConundrumRoundPage()),
                      style: _outlinedStyle(),
                      child: Text(
                        'Conundrum Round',
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
//  LETTERS ROUND
// -----------------------------------------------------------------------------
class LettersRoundPage extends StatefulWidget {
  const LettersRoundPage({super.key});

  @override
  State<LettersRoundPage> createState() => _LettersRoundPageState();
}

class _LettersRoundPageState extends State<LettersRoundPage>
    with SingleTickerProviderStateMixin {
  final Random random = Random();
  final List<String> vowels = ['A', 'E', 'I', 'O', 'U'];
  final List<String> consonants = [
    'B',
    'C',
    'D',
    'F',
    'G',
    'H',
    'J',
    'K',
    'L',
    'M',
    'N',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'V',
    'W',
    'X',
    'Y',
    'Z',
  ];

  List<String> selectedLetters = [];

  late AnimationController _controller;

  bool get isRunning => _controller.isAnimating;

  // End-of-timer flash
  bool flashOn = false;
  Timer? flashTimer;
  int flashCount = 0;
  bool showProgress = true;

  // 1) Audio players: one for clicks, one for timer
  final AudioPlayer _clickPlayer = AudioPlayer();
  final AudioPlayer _timerPlayer = AudioPlayer();

  //playClick();

  @override
  void initState() {
    super.initState();
    initializeLetterBags();
    selectedLetters.clear();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 30),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Vibration.vibrate(pattern: [0, 300, 300, 300]); // Vibrate for 3 seconds
        _startFlashing();
      }
    });
  }

  // New state variable to track how many times a letter has been drawn
  Map<String, int> drawnCounts = {};

  // Existing state variables for the bags (make sure these are declared in the class)
  List<String> vowelBag = [];
  List<String> consonantBag = [];

  void initializeLetterBags() {
    // Reset drawn counts each round
    drawnCounts = {};

    final Map<String, int> vowelDistribution = {
      'A': 15,
      'E': 21,
      'I': 13,
      'O': 13,
      'U': 5,
    };
    final Map<String, int> consonantDistribution = {
      'B': 2,
      'C': 3,
      'D': 6,
      'F': 2,
      'G': 3,
      'H': 2,
      'J': 1,
      'K': 1,
      'L': 5,
      'M': 4,
      'N': 8,
      'P': 4,
      'Q': 1,
      'R': 9,
      'S': 9,
      'T': 9,
      'V': 1,
      'W': 1,
      'X': 1,
      'Y': 1,
      'Z': 1,
    };

    // Build the bags from the distributions
    vowelBag =
        vowelDistribution.entries
            .expand((entry) => List.filled(entry.value, entry.key))
            .toList();
    consonantBag =
        consonantDistribution.entries
            .expand((entry) => List.filled(entry.value, entry.key))
            .toList();

    // Shuffle to randomize initial order
    vowelBag.shuffle(random);
    consonantBag.shuffle(random);
  }

  Widget _buildBackArrow(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back_ios_new, size: 34, color: Colors.black),
      onPressed: () => Navigator.pop(context),
    );
  }

  void _startFlashing() {
    flashCount = 0;
    flashTimer?.cancel();
    flashTimer = Timer.periodic(Duration(milliseconds: 300), (timer) {
      setState(() => flashOn = !flashOn);
      flashCount++;
      if (flashCount >= 8) {
        timer.cancel();
        setState(() {
          flashOn = false;
          _controller.reset();
        });
      }
    });
  }

  // Letters logic
  final ClickSoundPlayer clickSoundPlayer = ClickSoundPlayer(poolSize: 9);

  void addLetter(String type) {
    if (selectedLetters.length >= 9) return;
    String newLetter;
    if (type == 'vowel') {
      if (vowelBag.isEmpty) return; // No vowels available
      int index = random.nextInt(vowelBag.length);
      newLetter = vowelBag[index];

      // Update the drawn count for this letter
      drawnCounts[newLetter] = (drawnCounts[newLetter] ?? 0) + 1;

      // If drawn once, reduce its probability by leaving only one copy in the bag.
      if ((drawnCounts[newLetter] ?? 0) == 1) {
        // Remove all copies then add back a single copy.
        vowelBag.removeWhere((letter) => letter == newLetter);
        vowelBag.add(newLetter);
      } else if ((drawnCounts[newLetter] ?? 0) >= 2) {
        // After two appearances, remove it entirely from the bag.
        vowelBag.removeWhere((letter) => letter == newLetter);
      }
    } else {
      if (consonantBag.isEmpty) return; // No consonants available
      int index = random.nextInt(consonantBag.length);
      newLetter = consonantBag[index];

      drawnCounts[newLetter] = (drawnCounts[newLetter] ?? 0) + 1;

      if ((drawnCounts[newLetter] ?? 0) == 1) {
        consonantBag.removeWhere((letter) => letter == newLetter);
        consonantBag.add(newLetter);
      } else if ((drawnCounts[newLetter] ?? 0) >= 2) {
        consonantBag.removeWhere((letter) => letter == newLetter);
      }
    }

    setState(() {
      selectedLetters.add(newLetter);
    });

    clickSoundPlayer.play();
  }

  void startTimer() {
    if (selectedLetters.length < 9) return;
    if (isRunning) return;
    flashTimer?.cancel();
    flashOn = false;
    showProgress = true;
    //stopVibrationPattern();

    // 3) Start the 30s timer sound

    _timerPlayer.play(AssetSource('sounds/timer.mp3'));

    _controller.reset();
    _controller.forward();
    //_startVibrationPattern();
  }

  Widget _buildLettersContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Select Letters:',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 24),
        FixedSelectionBoard(totalBoxes: 9, items: selectedLetters),
        SizedBox(height: 30),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton(
              onPressed: () => addLetter('vowel'),
              style: _outlinedStyle(),
              child: Text('Vowel', style: TextStyle(fontSize: 24)),
            ),
            SizedBox(width: 20),
            OutlinedButton(
              onPressed: () => addLetter('consonant'),
              style: _outlinedStyle(),
              child: Text('Consonant', style: TextStyle(fontSize: 24)),
            ),
            SizedBox(width: 20),
            OutlinedButton(
              onPressed: isRunning ? null : startTimer,
              style: _outlinedStyle(),
              child: Text('Start Timer', style: TextStyle(fontSize: 24)),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    flashTimer?.cancel();

    ///stopVibrationPattern();
    // Stop any playing audio
    _clickPlayer.dispose();
    _timerPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: null,
        automaticallyImplyLeading: false,
        leading: _buildBackArrow(context),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          if (showProgress)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final progress = _controller.value;
                final screenWidth = MediaQuery.of(context).size.width;
                return Row(
                  children: [
                    Container(
                      width: screenWidth * progress,
                      color: const Color(0xFFEEC477),
                    ),
                    Expanded(child: Container(color: const Color(0xFFFFE8A8))),
                  ],
                );
              },
            ),
          if (flashOn)
            Positioned.fill(child: Container(color: const Color(0xFFFFE8A8))),
          Center(child: _buildLettersContent()),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
//  NUMBERS ROUND
// -----------------------------------------------------------------------------
class NumbersRoundPage extends StatefulWidget {
  const NumbersRoundPage({super.key});

  @override
  State<NumbersRoundPage> createState() => _NumbersRoundPageState();
}

class _NumbersRoundPageState extends State<NumbersRoundPage>
    with SingleTickerProviderStateMixin {
  final Random random = Random();
  final List<int> largeNumbers = [25, 50, 75, 100];
  List<int> selectedNumbers = [];
  int? target;

  late AnimationController _controller;

  bool get isRunning => _controller.isAnimating;

  bool flashOn = false;
  Timer? flashTimer;
  int flashCount = 0;
  bool showProgress = true;

  // 1) Audio players for click + timer
  final AudioPlayer _clickPlayer = AudioPlayer();
  final AudioPlayer _timerPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    selectedNumbers.clear();
    target = null;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 30),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Vibration.vibrate(pattern: [0, 300, 300, 300]); // Vibrate for 3 seconds
        _startFlashing();
      }
    });

    // Timer can be normal
  }

  Widget _buildBackArrow(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back_ios_new, size: 34, color: Colors.black),
      onPressed: () => Navigator.pop(context),
    );
  }

  void _startFlashing() {
    flashCount = 0;
    flashTimer?.cancel();
    flashTimer = Timer.periodic(Duration(milliseconds: 300), (timer) {
      setState(() => flashOn = !flashOn);
      flashCount++;
      if (flashCount >= 8) {
        timer.cancel();
        setState(() {
          flashOn = false;
          _controller.reset();
        });
      }
    });
  }

  // 2) Each time we add a number, play click
  void addNumber(String type) {
    if (selectedNumbers.length >= 6) return;
    int number =
        (type == 'small')
            ? random.nextInt(10) + 1
            : largeNumbers[random.nextInt(largeNumbers.length)];
    setState(() {
      selectedNumbers.add(number);
      if (selectedNumbers.length == 6 && target == null) {
        generateTarget();
      }
    });
    final ClickSoundPlayer clickSoundPlayer = ClickSoundPlayer(poolSize: 9);

    clickSoundPlayer.play();
  }

  void generateTarget() {
    setState(() {
      target = 100 + random.nextInt(900);
    });
    // Could also play a click if you want
    _controller.reset();
    _timerPlayer.stop();
    final ClickSoundPlayer clickSoundPlayer = ClickSoundPlayer(poolSize: 9);

    clickSoundPlayer.play();
  }

  // 3) Start the 30s timer sound
  void startTimer() {
    if (selectedNumbers.length < 6 || target == null) return;
    if (isRunning) return;
    flashTimer?.cancel();
    flashOn = false;
    showProgress = true;
    //stopVibrationPattern();

    _timerPlayer.play(AssetSource('sounds/timer.mp3'));

    _controller.reset();
    _controller.forward();
  }

  Widget _buildNumbersContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Number Target: ${target ?? "--"}',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 24),
        FixedSelectionBoard(
          totalBoxes: 6,
          items: selectedNumbers.map((n) => n.toString()).toList(),
        ),
        SizedBox(height: 30),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton(
              onPressed: () => addNumber('small'),
              style: _outlinedStyle(),
              child: Text('Small', style: TextStyle(fontSize: 24)),
            ),
            SizedBox(width: 20),
            OutlinedButton(
              onPressed: () => addNumber('large'),
              style: _outlinedStyle(),
              child: Text('Large', style: TextStyle(fontSize: 24)),
            ),
            SizedBox(width: 20),
            OutlinedButton(
              onPressed: (selectedNumbers.length == 6) ? generateTarget : null,
              style: _outlinedStyle(),
              child: Text('Generate Target', style: TextStyle(fontSize: 24)),
            ),
            SizedBox(width: 20),
            OutlinedButton(
              onPressed:
                  (selectedNumbers.length == 6 && target != null && !isRunning)
                      ? startTimer
                      : null,
              style: _outlinedStyle(),
              child: Text('Start Timer', style: TextStyle(fontSize: 24)),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    flashTimer?.cancel();
    //stopVibrationPattern();
    // Stop any playing audio
    _clickPlayer.dispose();
    _timerPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: null,
        automaticallyImplyLeading: false,
        leading: _buildBackArrow(context),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          if (showProgress)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final progress = _controller.value;
                final screenWidth = MediaQuery.of(context).size.width;
                return Row(
                  children: [
                    Container(
                      width: screenWidth * progress,
                      color: const Color(0xFFEEC477),
                    ),
                    Expanded(child: Container(color: const Color(0xFFFFE8A8))),
                  ],
                );
              },
            ),
          if (flashOn)
            Positioned.fill(child: Container(color: const Color(0xFFFFE8A8))),
          Center(child: _buildNumbersContent()),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
//  CONUNDRUM ROUND
// -----------------------------------------------------------------------------
class ConundrumRoundPage extends StatefulWidget {
  const ConundrumRoundPage({super.key});

  @override
  State<ConundrumRoundPage> createState() => _ConundrumRoundPageState();
}

class _ConundrumRoundPageState extends State<ConundrumRoundPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  bool get isRunning => _controller.isAnimating;

  bool flashOn = false;
  Timer? flashTimer;
  int flashCount = 0;
  bool showProgress = true;
  bool _anagramSolved = false;

  final Random random = Random();
  final List<String> nineLetterWords = [
    // ... your conundrum words ...
    'ADVANCING',
    'CHALLENGE',
    'DEDICATED',
    'EDUCATION',
    'FORTUNATE',
    'GATHERING',
    'INSPIRING',
    'LIFESTYLE',
    'MARKETING',
    'NAVIGATOR',
    'OBJECTIVE',
    'PASSWORDS',
    'QUALIFIED',
    'SCULPTURE',
    'TECHNICAL',
    'WAREHOUSE',
    'XYLOPHONE',
    'YARDSTICK',
    'ZEALOUSLY',
    'ABANDONED',
    'BALANCING',
    'CARETAKER',
    'DELIGHTED',
    'ELEVATING',
    'FISHERMAN',
    'HAPPINESS',
    'IMPORTANT',
    'KNOWLEDGE',
    'LANDSCAPE',
    'MECHANICS',
    'NOTIFYING',
    'OPERATION',
    'PARAGRAPH',
    'QUALIFIED',
    'RADIATION',
    'SECONDARY',
    'TRAVELLER',
    'UNDERPAID',
    'VIGILANCE',
    'WONDERING',
    'YEARNINGS',
    'ABUNDANCE',
    'CELEBRATE',
    'DEPRESSED',
    'ENLIGHTEN',
    'FASCINATE',
    'GLORIFIED',
    'HARMONIES',
    'INCLUSIVE',
    'JOURNEYED',
    'KILOGRAMS',
    'MEMORIZED',
    'NURTURING',
    'OPPONENTS',
    'PERCEIVER',
    'QUADRANTS',
    'REPEATING',
    'STRUGGLED',
    'TOLERANCE',
    'UNIVERSAL',
    'VOLUNTEER',
    'WHISPERED',
    'XENOPHOBE',
    'YOUNGSTER',
    'ZEALOTISM',
    'ARROGANCE',
    'BREAKDOWN',
    'CHEMISTRY',
    'DYNAMICAL',
    'EFFECTIVE',
    'GOVERNING',
    'HISTORIAN',
    'INVENTION',
    'JUXTAPOSE',
    'KNEEBOARD',
    'LANDOWNER',
    'MYSTERIES',
    'NEGLECTED',
    'OFFENSIVE',
    'POLITICAL',
    'QUICKNESS',
    'RECEPTORS',
    'SATISFIED',
    'TEAMWORKS',
    'UNDERGRAD',
    'VIBRATION',
    'WANDERERS',
    'YESTERDAY',
    'ZEALOTISM',
    'ALIGNMENT',
    'BRILLIANT',
    'CROSSROAD',
    'DELIRIOUS',
    'EQUIPMENT',
    'FABRICATE',
    'GONDOLIER',
    'HEARTBEAT',
  ];

  late String originalConundrumWord;
  List<String> displayedLetters = [];

  // 1) Audio players for click + timer
  final AudioPlayer _clickPlayer = AudioPlayer();
  final AudioPlayer _timerPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _pickAndScrambleWord();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 30),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Vibration.vibrate(pattern: [0, 300, 300, 300]); // Vibrate for 3 seconds
        _startFlashing();
      }
    });

    // Timer can be normal
  }

  Widget _buildBackArrow(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back_ios_new, size: 34, color: Colors.black),
      onPressed: () => Navigator.pop(context),
    );
  }

  void _pickAndScrambleWord() {
    originalConundrumWord =
        nineLetterWords[random.nextInt(nineLetterWords.length)];
    displayedLetters = originalConundrumWord.split('')..shuffle();
  }

  void _startFlashing() {
    flashCount = 0;
    flashTimer?.cancel();
    flashTimer = Timer.periodic(Duration(milliseconds: 300), (timer) {
      setState(() => flashOn = !flashOn);
      flashCount++;
      if (flashCount >= 8) {
        timer.cancel();
        setState(() {
          flashOn = false;
          _controller.reset();
        });
      }
    });
  }

  void startTimer() {
    if (isRunning) return;
    flashTimer?.cancel();
    flashOn = false;
    showProgress = true;

    // 2) Start the 30s timer sound
    _timerPlayer.play(AssetSource('sounds/timer.mp3'));

    _controller.reset();
    _controller.forward();
  }

  Future<void> solveAnagram() async {
    // Reset the progress bar animation
    _controller.reset();

    // Animate each square changing one by one
    List<String> newLetters = originalConundrumWord.split('');
    for (int i = 0; i < newLetters.length; i++) {
      setState(() {
        displayedLetters[i] = newLetters[i];
        _anagramSolved = true;
      });
      playClick(); // Plays the click sound for each tile change
      await Future.delayed(Duration(milliseconds: 150));
    }
  }

  Widget _buildConundrumContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Solve the Anagram:',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 24),
        FixedSelectionBoard(totalBoxes: 9, items: displayedLetters),
        SizedBox(height: 30),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton(
              onPressed: (isRunning || _anagramSolved) ? null : startTimer,
              style: _outlinedStyle(),
              child: Text('Start Timer', style: TextStyle(fontSize: 24)),
            ),
            SizedBox(width: 20),
            OutlinedButton(
              onPressed: _anagramSolved ? () {} : solveAnagram,
              style: _outlinedStyle(),
              child: Text('Solve Anagram', style: TextStyle(fontSize: 24)),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    flashTimer?.cancel();
    // Stop any playing audio
    _clickPlayer.dispose();
    _timerPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: null,
        automaticallyImplyLeading: false,
        leading: _buildBackArrow(context),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          if (showProgress)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final progress = _controller.value;
                final screenWidth = MediaQuery.of(context).size.width;
                return Row(
                  children: [
                    Container(
                      width: screenWidth * progress,
                      color: const Color(0xFFEEC477),
                    ),
                    Expanded(child: Container(color: const Color(0xFFFFE8A8))),
                  ],
                );
              },
            ),
          if (flashOn)
            Positioned.fill(child: Container(color: const Color(0xFFFFE8A8))),
          Center(child: _buildConundrumContent()),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
//  FIXED SELECTION BOARD
// -----------------------------------------------------------------------------
class FixedSelectionBoard extends StatelessWidget {
  final int totalBoxes;
  final List<String> items;

  const FixedSelectionBoard({
    super.key,
    required this.totalBoxes,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(totalBoxes, (index) {
        String text = index < items.length ? items[index] : '';
        return Container(
          width: 80,
          height: 80,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }),
    );
  }
}

// -----------------------------------------------------------------------------
//  HELPER: OutlinedButton Style
// -----------------------------------------------------------------------------
ButtonStyle _outlinedStyle() {
  return ButtonStyle(
    side: WidgetStateProperty.all(BorderSide(color: Colors.black, width: 2.5)),
    animationDuration: Duration.zero,
    // instant press/release
    foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.pressed)) {
        return Colors.white; // pressed = white text
      }
      return Colors.black; // default = black text
    }),
    backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.pressed)) {
        return Colors.black; // pressed = black background
      }
      return Colors.transparent; // default = transparent
    }),
    overlayColor: WidgetStateProperty.all(Colors.transparent),
    elevation: WidgetStateProperty.all(0),
  );
}
