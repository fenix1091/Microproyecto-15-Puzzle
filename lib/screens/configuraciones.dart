import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  int? _boardSize;
  String _themeMode = 'automatico';
  String _pieceStyle = 'clasico';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _boardSize = prefs.containsKey('boardSize')
          ? prefs.getInt('boardSize')
          : null;
      _themeMode = prefs.getString('themeMode') ?? 'automatico';
      _pieceStyle = prefs.getString('pieceStyle') ?? 'clasico';
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (_boardSize != null) {
      await prefs.setInt('boardSize', _boardSize!);
    } else {
      await prefs.remove('boardSize');
    }
    await prefs.setString('themeMode', _themeMode);
    await prefs.setString('pieceStyle', _pieceStyle);

    bool isDark =
        _themeMode == 'oscuro' ||
        (_themeMode == 'automatico' &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);
    await prefs.setBool('isDarkMode', isDark);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuración guardada en persistencia local'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark =
        _themeMode == 'oscuro' ||
        (_themeMode == 'automatico' &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    final backgroundColor = isDark
        ? const Color(0xFF141A16)
        : const Color(0xFFF4F6F4);
    final cardColor = isDark ? const Color(0xFF1E2620) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF222825);
    final subtitleColor = isDark ? Colors.white70 : Colors.black54;
    final primaryColor = const Color(0xFF3B7A57);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Configuración',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            // Tamaño de Tablero
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tamaño del Tablero por Defecto',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                if (_boardSize != null)
                  TextButton(
                    onPressed: () => setState(() => _boardSize = null),
                    child: const Text(
                      'Preguntar al iniciar',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            SegmentedButton<int?>(
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: primaryColor.withValues(alpha: 0.2),
                selectedForegroundColor: textColor,
                foregroundColor: subtitleColor,
                side: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
              ),
              segments: const [
                ButtonSegment(
                  value: 3,
                  label: Text('3x3 (Fácil)'),
                  icon: Icon(Icons.grid_3x3),
                ),
                ButtonSegment(
                  value: 4,
                  label: Text('4x4 (Medio)'),
                  icon: Icon(Icons.grid_view),
                ),
                ButtonSegment(
                  value: 5,
                  label: Text('5x5 (Difícil)'),
                  icon: Icon(Icons.apps),
                ),
              ],
              selected: {_boardSize},
              onSelectionChanged: (Set<int?> newSelection) {
                setState(() => _boardSize = newSelection.first);
              },
            ),
            const SizedBox(height: 24),

            Text(
              'Tema Visual',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),
            SegmentedButton<String>(
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: primaryColor.withValues(alpha: 0.2),
                selectedForegroundColor: textColor,
                foregroundColor: subtitleColor,
                side: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
              ),
              segments: const [
                ButtonSegment(
                  value: 'claro',
                  label: Text('Claro'),
                  icon: Icon(Icons.light_mode),
                ),
                ButtonSegment(
                  value: 'oscuro',
                  label: Text('Oscuro'),
                  icon: Icon(Icons.dark_mode),
                ),
                ButtonSegment(
                  value: 'automatico',
                  label: Text('Auto'),
                  icon: Icon(Icons.brightness_auto),
                ),
              ],
              selected: {_themeMode},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() => _themeMode = newSelection.first);
              },
            ),
            const SizedBox(height: 24),

            // Estilos de visualización de las piezas
            Text(
              'Estilo de las Piezas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),
            SegmentedButton<String>(
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: primaryColor.withValues(alpha: 0.2),
                selectedForegroundColor: textColor,
                foregroundColor: subtitleColor,
                side: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
              ),
              segments: const [
                ButtonSegment(value: 'clasico', label: Text('Clásico')),
                ButtonSegment(
                  value: 'colorido',
                  label: Text('Colorido (Retro)'),
                ),
                ButtonSegment(value: 'imagen', label: Text('Imagen')),
              ],
              selected: {_pieceStyle},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() => _pieceStyle = newSelection.first);
              },
            ),
            const SizedBox(height: 40),

            SizedBox(
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
                onPressed: _savePreferences,
                icon: const Icon(Icons.save_rounded),
                label: const Text(
                  'Guardar Ajustes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
