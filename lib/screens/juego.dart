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
  int _boardSize = 4; // Por defecto 4x4 (15-puzzle)
  List<int> _board = [];
  int _moves = 0;
  bool _isDarkMode = false;
  bool _isWon = false;

  // Cronómetro
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
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      if (widget.forcedBoardSize != null) {
        _boardSize = widget.forcedBoardSize!;
      } else {
        _boardSize = prefs.getInt('boardSize') ?? 4;
      }
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
    // Hacemos N * 30 movimientos aleatorios válidos
    int emptyIndex = _board.indexOf(0);
    int shuffleSteps = _boardSize * 50;

    for (int i = 0; i < shuffleSteps; i++) {
      List<int> validMoves = _getValidMoves(emptyIndex);
      // Elegir un movimiento aleatorio válido
      int randomMove =
          validMoves[(DateTime.now().millisecondsSinceEpoch) %
              validMoves.length];

      // Intercambiar
      _board[emptyIndex] = _board[randomMove];
      _board[randomMove] = 0;
      emptyIndex = randomMove;
    }
  }

  // Obtiene los índices adyacentes que se pueden mover al espacio vacío
  List<int> _getValidMoves(int emptyIndex) {
    List<int> valid = [];
    int row = emptyIndex ~/ _boardSize;
    int col = emptyIndex % _boardSize;

    if (row > 0) valid.add(emptyIndex - _boardSize); // Arriba
    if (row < _boardSize - 1) valid.add(emptyIndex + _boardSize); // Abajo
    if (col > 0) valid.add(emptyIndex - 1); // Izquierda
    if (col < _boardSize - 1) valid.add(emptyIndex + 1); // Derecha

    return valid;
  }

  void _startTimer() {
    if (_timerRunning) return;
    _timerRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  // Lógica al tocar una ficha
  void _onTileTap(int index) {
    if (_isWon) return;

    int emptyIndex = _board.indexOf(0);
    if (_getValidMoves(emptyIndex).contains(index)) {
      if (!_timerRunning) {
        _startTimer();
      }

      setState(() {
        // Intercambiar la ficha seleccionada con el espacio vacío
        _board[emptyIndex] = _board[index];
        _board[index] = 0;
        _moves++;

        // Verificar si ganó
        _checkWinCondition();
      });
    }
  }

  // Condición de victoria: ordenada de 1 a N*N-1 y el 0 al final
  void _checkWinCondition() {
    for (int i = 0; i < _board.length - 1; i++) {
      if (_board[i] != i + 1) return;
    }

    // Si llega aquí, ¡ganó!
    _isWon = true;
    _timer?.cancel();
    _timerRunning = false;

    // Mostrar diálogo de victoria
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('¡Felicidades! 🎉'),
        content: Text(
          'Has completado el puzzle en:\n\n⏱️ Tiempo: ${_formatTime(_secondsElapsed)}\n🔢 Movimientos: $_moves',
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
              Navigator.pop(context); // Volver al menú
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
            // Panel de estadísticas (Tiempo y Movimientos)
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

            // Tablero del Puzzle
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
                          // Espacio vacío
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          );
                        }

                        return GestureDetector(
                          onTap: () => _onTileTap(index),
                          child: Container(
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
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
                                  fontSize: 22,
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
