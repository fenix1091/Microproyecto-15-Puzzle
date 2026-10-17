import 'package:flutter/material.dart';

class MenuPrincipal extends StatelessWidget {
  const MenuPrincipal({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.extension,
                  size: 80,
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 16),
                const Text(
                  '15-PUZZLE',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 40),
                _buildMenuButton(
                  context,
                  label: 'Jugar',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () {
                    // Aquí enlazaremos la Parte 5 (Juego)
                  },
                ),
                const SizedBox(height: 16),
                _buildMenuButton(
                  context,
                  label: 'Marcadores',
                  icon: Icons.leaderboard_rounded,
                  onPressed: () {
                    // Aquí enlazaremos la Parte 3 (Marcadores)
                  },
                ),
                const SizedBox(height: 16),
                _buildMenuButton(
                  context,
                  label: 'Configuración',
                  icon: Icons.settings_rounded,
                  onPressed: () {
                    // Aquí enlazaremos la Parte 3.2 (Configuración)
                  },
                ),
                const SizedBox(height: 16),
                _buildMenuButton(
                  context,
                  label: 'Instrucciones',
                  icon: Icons.help_outline_rounded,
                  onPressed: () {
                    // Aquí enlazaremos la Parte 3.4 (Instrucciones)
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 28),
        label: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}