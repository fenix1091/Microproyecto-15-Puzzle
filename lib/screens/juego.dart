import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JuegoScreen extends StatefulWidget {
  final int? forcedBoardSize;
  const JuegoScreen({super.key, this.forcedBoardSize});

  @override
  State<JuegoScreen> createState() => _JuegoScreenState();
}

class _JuegoScreenState extends State<JuegoScreen> {
  int _boardSize = 4;
  List<int> _board = [];
  int _moves = 0;
  bool _isDarkMode = false;
  String _pieceStyle = 'clasico';
  bool _isWon = false;

  // Imagen de ejemplo para el modo imagen
  final String _sampleImageUrl = 'https://picsum.photos/id/1015/600/600';

  Timer? _timer;
  int _secondsElapsed = 0;
  bool _timerRunning = false;

  @override
  void initState() {
    super.initState();
    _loadSettingsAndInitGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadSettingsAndInitGame() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (widget.forcedBoardSize != null) {
        _boardSize = widget.forcedBoardSize!;
      } else {
        _boardSize = prefs.getInt('boardSize') ?? 4;
      }

      String themeMode = prefs.getString('themeMode') ?? 'automatico';
      _isDarkMode =
          themeMode == 'oscuro' ||
          (themeMode == 'automatico' &&
              WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                  Brightness.dark);

      _pieceStyle = prefs.getString('pieceStyle') ?? 'clasico';
    });
    _initializeBoard();
  }

  void _initializeBoard() {
    int totalTiles = _boardSize * _boardSize;
    _board = List.generate(totalTiles, (index) => (index + 1) % totalTiles);
    _moves = 0;
    _isWon = false;
    _secondsElapsed = 0;
    _timer?.cancel();
    _timerRunning = false;

    _shuffleBoard();
    setState(() {});
  }

  void _shuffleBoard() {
    int emptyIndex = _board.indexOf(0);
    int shuffleSteps = _boardSize * 50;

    for (int i = 0; i < shuffleSteps; i++) {
      List<int> validMoves = _getValidMoves(emptyIndex);
      int randomMove =
          validMoves[(DateTime.now().millisecondsSinceEpoch) %
              validMoves.length];

      _board[emptyIndex] = _board[randomMove];
      _board[randomMove] = 0;
      emptyIndex = randomMove;
    }
  }

  List<int> _getValidMoves(int emptyIndex) {
    List<int> valid = [];
    int row = emptyIndex ~/ _boardSize;
    int col = emptyIndex % _boardSize;

    if (row > 0) valid.add(emptyIndex - _boardSize);
    if (row < _boardSize - 1) valid.add(emptyIndex + _boardSize);
    if (col > 0) valid.add(emptyIndex - 1);
    if (col < _boardSize - 1) valid.add(emptyIndex + 1);

    return valid;
  }

  void _startTimer() {
    if (_timerRunning) return;
    _timerRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _secondsElapsed++);
    });
  }

  void _onTileTap(int index) {
    if (_isWon) return;

    int emptyIndex = _board.indexOf(0);
    if (_getValidMoves(emptyIndex).contains(index)) {
      if (!_timerRunning) _startTimer();

      setState(() {
        _board[emptyIndex] = _board[index];
        _board[index] = 0;
        _moves++;
        _checkWinCondition();
      });
    }
  }

  Future<void> _checkWinCondition() async {
    for (int i = 0; i < _board.length - 1; i++) {
      if (_board[i] != i + 1) return;
    }

    _isWon = true;
    _timer?.cancel();
    _timerRunning = false;

    final prefs = await SharedPreferences.getInstance();
    String difficultyKey = _boardSize == 3
        ? 'facil'
        : (_boardSize == 4 ? 'medio' : 'dificil');
    String dateStr =
        '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';

    await prefs.setString(
      '${difficultyKey}_time',
      _formatTime(_secondsElapsed),
    );
    await prefs.setInt('${difficultyKey}_moves', _moves);
    await prefs.setString('${difficultyKey}_date', dateStr);

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('¡Felicidades! 🎉'),
        content: Text(
          'Has completado el puzzle ($_boardSize x $_boardSize):\n\n⏱️ Tiempo: ${_formatTime(_secondsElapsed)}\n🔢 Movimientos: $_moves\n💾 ¡Guardado en marcadores!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initializeBoard();
            },
            child: const Text('Jugar de nuevo'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Menú Principal'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // Renderiza el fragmento de la imagen recortado correctamente
  Widget _buildImageTile(int tileValue, Color primaryColor) {
    int correctIndex = tileValue - 1;
    int row = correctIndex ~/ _boardSize;
    int col = correctIndex % _boardSize;

    double alignX = -1.0 + (col / (_boardSize - 1)) * 2.0;
    double alignY = -1.0 + (row / (_boardSize - 1)) * 2.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          FractionallySizedBox(
            widthFactor: _boardSize.toDouble(),
            heightFactor: _boardSize.toDouble(),
            child: AlignmentTemplate(
              alignX: alignX,
              alignY: alignY,
              child: Image.network(
                _sampleImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: primaryColor,
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$tileValue',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _isDarkMode
        ? const Color(0xFF141A16)
        : const Color(0xFFF4F6F4);
    final textColor = _isDarkMode ? Colors.white : const Color(0xFF222825);
    final primaryColor = const Color(0xFF3B7A57);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Puzzle (${_boardSize}x$_boardSize)',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reiniciar',
            onPressed: _initializeBoard,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  '⏱️ Tiempo',
                  _formatTime(_secondsElapsed),
                  textColor,
                  primaryColor,
                ),
                _buildStatCard(
                  '🔢 Movimientos',
                  '$_moves',
                  textColor,
                  primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _boardSize,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                      ),
                      itemCount: _board.length,
                      itemBuilder: (context, index) {
                        int tileValue = _board[index];
                        if (tileValue == 0) {
                          return Container(
                            decoration: const BoxDecoration(
                              color: Colors.transparent,
                            ),
                          );
                        }

                        if (_pieceStyle == 'imagen') {
                          return GestureDetector(
                            onTap: () => _onTileTap(index),
                            child: _buildImageTile(tileValue, primaryColor),
                          );
                        }

                        Color tileColor = primaryColor;
                        if (_pieceStyle == 'colorido') {
                          List<Color> retroColors = [
                            Colors.teal,
                            Colors.indigo,
                            Colors.deepOrange,
                            Colors.brown,
                            Colors.purple,
                            Colors.blueGrey,
                            Colors.pink,
                          ];
                          tileColor =
                              retroColors[tileValue % retroColors.length];
                        }

                        return GestureDetector(
                          onTap: () => _onTileTap(index),
                          child: Container(
                            decoration: BoxDecoration(
                              color: tileColor,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '$tileValue',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color textColor,
    Color primaryColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1E2620) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: _isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class AlignmentTemplate extends StatelessWidget {
  final double alignX;
  final double alignY;
  final Widget child;

  const AlignmentTemplate({
    super.key,
    required this.alignX,
    required this.alignY,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Align(alignment: Alignment(alignX, alignY), child: child);
  }
}
