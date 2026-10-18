import 'package:flutter/material.dart';

import 'juego.dart';

class SeleccionarDificultadScreen extends StatelessWidget {
  final bool isDarkMode;
  const SeleccionarDificultadScreen({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDarkMode
        ? const Color(0xFF141A16)
        : const Color(0xFFF4F6F4);
    final textColor = isDarkMode ? Colors.white : const Color(0xFF222825);
    final primaryColor = const Color(0xFF3B7A57);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Seleccionar Dificultad',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_esports_rounded, size: 70, color: primaryColor),
            const SizedBox(height: 16),
            Text(
              '¿Cómo quieres jugar?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Elige el tamaño del tablero para tu partida',
              style: TextStyle(
                fontSize: 15,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 40),
            _buildDifficultyButton(
              context,
              title: 'Fácil (3 x 3)',
              subtitle: 'Ideal para partidas rápidas',
              size: 3,
              primaryColor: primaryColor,
              isDark: isDarkMode,
            ),
            const SizedBox(height: 16),
            _buildDifficultyButton(
              context,
              title: 'Medio (4 x 4)',
              subtitle: 'El clásico 15-Puzzle',
              size: 4,
              primaryColor: primaryColor,
              isDark: isDarkMode,
            ),
            const SizedBox(height: 16),
            _buildDifficultyButton(
              context,
              title: 'Difícil (5 x 5)',
              subtitle: 'Para todo un reto mental',
              size: 5,
              primaryColor: primaryColor,
              isDark: isDarkMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required int size,
    required Color primaryColor,
    required bool isDark,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 70,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? const Color(0xFF1E2620) : Colors.white,
          foregroundColor: primaryColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
          ),
        ),
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => JuegoScreen(forcedBoardSize: size),
            ),
          );
        },
        child: Row(
          children: [
            Icon(Icons.grid_view_rounded, size: 30, color: primaryColor),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
