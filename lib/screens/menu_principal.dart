import 'package:flutter/material.dart';
import 'package:micro_proyecto_sist/screens/dificultad.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'configuraciones.dart';
import 'marcadores.dart';
import 'instrucciones.dart';
import 'juego.dart';

class MenuPrincipalScreen extends StatefulWidget {
  const MenuPrincipalScreen({super.key});

  @override
  State<MenuPrincipalScreen> createState() => _MenuPrincipalScreenState();
}

class _MenuPrincipalScreenState extends State<MenuPrincipalScreen> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.extension_rounded, size: 80, color: primaryColor),
              const SizedBox(height: 16),
              Text(
                '15-Puzzle',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Desafía tu mente',
                style: TextStyle(
                  fontSize: 16,
                  color: _isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 48),
              _buildMenuButton(
                context,
                label: 'Jugar',
                icon: Icons.play_arrow_rounded,
                primaryColor: primaryColor,
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final hasPreference = prefs.containsKey('boardSize');
                  final isDark = prefs.getBool('isDarkMode') ?? false;

                  if (!context.mounted) return;

                  if (hasPreference) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => JuegoScreen()),
                    );
                  } else {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SeleccionarDificultadScreen(isDarkMode: isDark),
                      ),
                    );
                  }
                  _loadPreferences();
                },
              ),
              const SizedBox(height: 16),
              _buildMenuButton(
                context,
                label: 'Marcadores',
                icon: Icons.emoji_events_rounded,
                primaryColor: primaryColor,
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MarcadoresScreen(),
                    ),
                  );
                  _loadPreferences();
                },
              ),
              const SizedBox(height: 16),
              _buildMenuButton(
                context,
                label: 'Configuración',
                icon: Icons.settings_rounded,
                primaryColor: primaryColor,
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ConfiguracionScreen(),
                    ),
                  );
                  _loadPreferences();
                },
              ),
              const SizedBox(height: 16),
              _buildMenuButton(
                context,
                label: 'Instrucciones',
                icon: Icons.help_outline_rounded,
                primaryColor: primaryColor,
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InstruccionesScreen(),
                    ),
                  );
                  _loadPreferences();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color primaryColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
