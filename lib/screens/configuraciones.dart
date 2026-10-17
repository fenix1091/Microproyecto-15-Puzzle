import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  int _boardSize = 4;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _boardSize = prefs.getInt('boardSize') ?? 4;
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('boardSize', _boardSize);
    await prefs.setBool('isDarkMode', _isDarkMode);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuración guardada correctamente'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _isDarkMode
        ? const Color(0xFF141A16)
        : const Color(0xFFF4F6F4);
    final cardColor = _isDarkMode ? const Color(0xFF1E2620) : Colors.white;
    final textColor = _isDarkMode ? Colors.white : const Color(0xFF222825);
    final subtitleColor = _isDarkMode ? Colors.white70 : Colors.black54;
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tamaño del Tablero',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: primaryColor.withValues(alpha: 0.2),
                  selectedForegroundColor: textColor,
                  foregroundColor: subtitleColor,
                  side: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
                ),
                segments: const [
                  ButtonSegment(
                    value: 3,
                    label: Text('3 x 3'),
                    icon: Icon(Icons.grid_3x3),
                  ),
                  ButtonSegment(
                    value: 4,
                    label: Text('4 x 4'),
                    icon: Icon(Icons.grid_view),
                  ),
                  ButtonSegment(
                    value: 5,
                    label: Text('5 x 5'),
                    icon: Icon(Icons.apps),
                  ),
                ],
                selected: {_boardSize},
                onSelectionChanged: (Set<int> newSelection) {
                  setState(() {
                    _boardSize = newSelection.first;
                  });
                },
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Ajustes Visuales',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              color: cardColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: primaryColor.withValues(alpha: 0.2)),
              ),
              child: SwitchListTile(
                title: Text(
                  'Modo Oscuro',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                secondary: Icon(Icons.dark_mode, color: primaryColor),
                activeThumbColor: primaryColor,
                value: _isDarkMode,
                onChanged: (value) {
                  setState(() => _isDarkMode = value);
                },
              ),
            ),
            const Spacer(),
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
