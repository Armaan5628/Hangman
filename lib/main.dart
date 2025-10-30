import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

void main() {
  runApp(const HangmanApp());
}

class HangmanApp extends StatelessWidget {
  const HangmanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Guess the Word',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.indigo,
          textTheme: const TextTheme(
            headlineMedium: TextStyle(fontWeight: FontWeight.bold),
            titleLarge: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        home: const GameScreen(),
      ),
    );
  }
}

enum GameStatus { playing, won, lost }

class GameState extends ChangeNotifier {
  static const int maxWrong = 6; // 6 wrong guesses and the player loses

  // Provide a healthy list of words (UPPERCASE)
  final List<String> _allWords = [
    'FLUTTER', 'WIDGET', 'STATE', 'PROVIDER', 'DART', 'PACKAGE', 'ASYNC',
    'CONTEXT', 'BUILDER', 'SNIPPET', 'MATERIAL', 'NAVIGATOR', 'VARIABLE',
    'FUNCTION', 'COLLECTION', 'MONGODB', 'SECURITY', 'PROJECT', 'ELEGANT',
    'HAPPY', 'REFLECT', 'CAPTURE', 'NETWORK', 'RESPONSIVE', 'ANDROID', 'IOS',
    'WINDOWS', 'LINUX', 'MACOS'
  ];

  late final List<String> _wordQueue; // shuffled, cycles without repeat until exhausted
  int _queueIndex = 0;

  String _currentWord = '';
  final Set<String> _correct = <String>{};
  final Set<String> _wrong = <String>{};
  final List<String> _guessedInOrder = <String>[]; // to display letters guessed
  GameStatus _status = GameStatus.playing;

  GameState() {
    _wordQueue = List<String>.from(_allWords);
    _shuffleWords();
    _startNewGame(initial: true);
  }

  // Public getters
  String get currentWord => _currentWord;
  GameStatus get status => _status;
  int get wrongCount => _wrong.length;
  int get wrongLeft => GameState.maxWrong - wrongCount;
  List<String> get guessedLetters => List.unmodifiable(_guessedInOrder);

  String get maskedWord {
    // Show guessed letters in their positions, otherwise underscore
    final letters = _currentWord.split('');
    return letters
        .map((ch) => _correct.contains(ch) ? ch : '_')
        .join(' ');
  }

  void guessLetter(String raw) {
    if (_status != GameStatus.playing) return; // ignore if game ended
    final letter = raw.toUpperCase();
    if (_guessedInOrder.contains(letter)) return; // already guessed, no penalty

    _guessedInOrder.add(letter);

    if (_currentWord.contains(letter)) {
      _correct.add(letter);
      // Win if every unique letter in word has been guessed
      final uniqueLetters = _currentWord.split('').toSet();
      if (_correct.containsAll(uniqueLetters)) {
        _status = GameStatus.won;
      }
    } else {
      _wrong.add(letter);
      if (_wrong.length >= GameState.maxWrong) {
        _status = GameStatus.lost;
      }
    }
    notifyListeners();
  }

  void playAgain() {
    _startNewGame();
  }

  void _startNewGame({bool initial = false}) {
    // Ensure each play uses a different word until all words are used once
    if (!initial) {
      _queueIndex = (_queueIndex + 1) % _wordQueue.length;
      if (_queueIndex == 0) {
        // All words used once; reshuffle for a fresh round
        _shuffleWords();
      }
    }
    _currentWord = _wordQueue[_queueIndex];

    _correct
      ..clear();
    _wrong
      ..clear();
    _guessedInOrder
      ..clear();
    _status = GameStatus.playing;
    notifyListeners();
  }

  void _shuffleWords() {
    final random = Random();
    _wordQueue.shuffle(random);
    // Make sure the very first pick differs from previous last if possible
    // (not strictly necessary on app start, but keeps behavior consistent)
  }
}

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guess the Word (Hangman)'),
        actions: [
          IconButton(
            tooltip: 'New Word',
            onPressed: game.status == GameStatus.playing
                ? () => context.read<GameState>().playAgain()
                : null,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),

                  // Masked word display
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 24),
                      child: Column(
                        children: [
                          Text(
                            game.maskedWord,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(letterSpacing: 4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Wrong guesses: ${game.wrongCount}  •  Left: ${game.wrongLeft} (max ${GameState.maxWrong})',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Status banner (WON/LOST/PLAYING)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: switch (game.status) {
                        GameStatus.won => Colors.green.withOpacity(0.12),
                        GameStatus.lost => Colors.red.withOpacity(0.12),
                        GameStatus.playing => Colors.amber.withOpacity(0.08),
                      },
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          switch (game.status) {
                            GameStatus.won => Icons.emoji_events,
                            GameStatus.lost => Icons.sentiment_very_dissatisfied,
                            GameStatus.playing => Icons.psychology_alt,
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(
                          switch (game.status) {
                            GameStatus.won => 'You WON! 🎉',
                            GameStatus.lost => 'You LOST. 😵‍💫  Word: ${game.currentWord}',
                            GameStatus.playing => 'Guess letters to reveal the word',
                          },
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Alphabet keypad
                  Expanded(
                    child: Center(
                      child: _AlphabetGrid(
                        onTap: (letter) =>
                            context.read<GameState>().guessLetter(letter),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Already guessed letters
                  _GuessedLettersStrip(letters: game.guessedLetters),

                  const SizedBox(height: 12),

                  // Play Again button when game ends
                  if (game.status != GameStatus.playing)
                    FilledButton.icon(
                      onPressed: () => context.read<GameState>().playAgain(),
                      icon: const Icon(Icons.replay),
                      label: const Text('Play Again (New Word)'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AlphabetGrid extends StatelessWidget {
  _AlphabetGrid({required this.onTap});

  final void Function(String letter) onTap;

  final List<String> _alphabet =
      List<String>.generate(26, (i) => String.fromCharCode('A'.codeUnitAt(0) + i));

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.3,
      ),
      itemCount: _alphabet.length,
      itemBuilder: (context, index) {
        final letter = _alphabet[index];
        final isUsed = game.guessedLetters.contains(letter);
        final isCorrect = game.currentWord.contains(letter);
        final enabled = game.status == GameStatus.playing && !isUsed;

        return ElevatedButton(
          onPressed: enabled ? () => onTap(letter) : null,
          style: ElevatedButton.styleFrom(
            disabledBackgroundColor: isUsed
                ? (isCorrect ? Colors.green.shade200 : Colors.red.shade200)
                : null,
            disabledForegroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(letter, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        );
      },
    );
  }
}

class _GuessedLettersStrip extends StatelessWidget {
  const _GuessedLettersStrip({required this.letters});
  final List<String> letters;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Text('Guessed: ', style: Theme.of(context).textTheme.titleMedium),
            if (letters.isEmpty)
              const Text('(none)')
            else
              ...letters.map((l) => Chip(label: Text(l))).toList(),
          ],
        ),
      ),
    );
  }
}
