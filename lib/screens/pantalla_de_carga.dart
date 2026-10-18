import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'menu_principal.dart';

class PantallaDeCarga extends StatefulWidget {
  const PantallaDeCarga({super.key});

  @override
  State<PantallaDeCarga> createState() => _PantallaDeCargaState();
}

class _PantallaDeCargaState extends State<PantallaDeCarga>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();

    _loadThemePreference();

    // Animación fluida de entrada para el logo e identificador
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    // Transición automática al Menú Principal tras 3.5 segundos
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MenuPrincipalScreen()),
      );
    });
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    String themeMode = prefs.getString('themeMode') ?? 'automatico';
    setState(() {
      _isDarkMode =
          themeMode == 'oscuro' ||
          (themeMode == 'automatico' &&
              WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                  Brightness.dark);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _isDarkMode
        ? const Color(0xFF141A16)
        : const Color(0xFFF4F6F4);
    final textColor = _isDarkMode ? Colors.white : const Color(0xFF222825);
    final subtitleColor = _isDarkMode ? Colors.white70 : Colors.black54;
    final primaryColor = const Color(0xFF3B7A57);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Contenedor estético del icono principal
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.extension_rounded,
                    size: 84,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  '15-Puzzle',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Desafía tu mente',
                  style: TextStyle(
                    fontSize: 16,
                    letterSpacing: 0.5,
                    color: subtitleColor,
                  ),
                ),
                const SizedBox(height: 50),
                // Indicador de carga estilizado en tonos esmeralda
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    strokeWidth: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
