import 'package:flutter/material.dart';

import 'configuraciones.dart';

class MenuPrincipal extends StatelessWidget {
  const MenuPrincipal({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightGreen.shade50,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.extension, size: 80, color: Colors.lightGreen),
                const SizedBox(height: 16),
                const Text(
                  '15-Puzzle',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.lightGreen,
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
                  onPressed: () {},
                ),
                const SizedBox(height: 16),
                _buildMenuButton(
                  context,
                  label: 'Configuración',
                  icon: Icons.settings_rounded,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ConfiguracionScreen()),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildMenuButton(
                  context,
                  label: 'Instrucciones',
                  icon: Icons.help_outline_rounded,
                  onPressed: () {},
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
          backgroundColor: Colors.green,
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
