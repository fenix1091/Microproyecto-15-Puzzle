import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MarcadoresScreen extends StatefulWidget {
  const MarcadoresScreen({super.key});

  @override
  State<MarcadoresScreen> createState() => _MarcadoresScreenState();
}

class _MarcadoresScreenState extends State<MarcadoresScreen> {
  bool _isDarkMode = false;
  Map<String, dynamic>? _scoreFacil;
  Map<String, dynamic>? _scoreMedio;
  Map<String, dynamic>? _scoreDificil;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      String themeMode = prefs.getString('themeMode') ?? 'automatico';
      _isDarkMode =
          themeMode == 'oscuro' ||
          (themeMode == 'automatico' &&
              WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                  Brightness.dark);

      // Cargar Fácil (3x3)
      if (prefs.containsKey('facil_time')) {
        _scoreFacil = {
          'tiempo': prefs.getString('facil_time'),
          'movimientos': prefs.getInt('facil_moves'),
          'fecha': prefs.getString('facil_date'),
        };
      } else {
        _scoreFacil = null;
      }

      // Cargar Medio (4x4)
      if (prefs.containsKey('medio_time')) {
        _scoreMedio = {
          'tiempo': prefs.getString('medio_time'),
          'movimientos': prefs.getInt('medio_moves'),
          'fecha': prefs.getString('medio_date'),
        };
      } else {
        _scoreMedio = null;
      }

      // Cargar Difícil (5x5)
      if (prefs.containsKey('dificil_time')) {
        _scoreDificil = {
          'tiempo': prefs.getString('dificil_time'),
          'movimientos': prefs.getInt('dificil_moves'),
          'fecha': prefs.getString('dificil_date'),
        };
      } else {
        _scoreDificil = null;
      }
    });
  }

  void _confirmarBorrarMarcadores() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDark = _isDarkMode;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E2620) : Colors.white,
          title: Text(
            'Borrar Marcadores',
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
          content: Text(
            '¿Estás seguro de que deseas eliminar todo el historial de puntuaciones guardadas?',
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('facil_time');
                await prefs.remove('facil_moves');
                await prefs.remove('facil_date');
                await prefs.remove('medio_time');
                await prefs.remove('medio_moves');
                await prefs.remove('medio_date');
                await prefs.remove('dificil_time');
                await prefs.remove('dificil_moves');
                await prefs.remove('dificil_date');

                setState(() {
                  _scoreFacil = null;
                  _scoreMedio = null;
                  _scoreDificil = null;
                });

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Marcadores borrados con éxito'),
                    ),
                  );
                }
              },
              child: const Text(
                'Borrar',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _isDarkMode
        ? const Color(0xFF141A16)
        : const Color(0xFFF4F6F4);
    final textColor = _isDarkMode ? Colors.white : const Color(0xFF222825);
    final primaryColor = const Color(0xFF3B7A57);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Text(
            'Tabla de Marcadores',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: textColor),
          bottom: TabBar(
            labelColor: primaryColor,
            unselectedLabelColor: _isDarkMode ? Colors.white60 : Colors.black54,
            indicatorColor: primaryColor,
            tabs: const [
              Tab(text: 'Fácil (3x3)'),
              Tab(text: 'Medio (4x4)'),
              Tab(text: 'Difícil (5x5)'),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.delete_sweep_rounded, color: textColor),
              tooltip: 'Borrar Marcadores',
              onPressed: _confirmarBorrarMarcadores,
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildScoreView(_scoreFacil, 'Fácil (3x3)'),
            _buildScoreView(_scoreMedio, 'Medio (4x4)'),
            _buildScoreView(_scoreDificil, 'Difícil (5x5)'),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreView(Map<String, dynamic>? scoreData, String dificultad) {
    final textColor = _isDarkMode ? Colors.white : const Color(0xFF222825);
    final cardColor = _isDarkMode ? const Color(0xFF1E2620) : Colors.white;
    final primaryColor = const Color(0xFF3B7A57);

    if (scoreData == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 80,
                color: primaryColor.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Sin registros en $dificultad',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '¡Juega una partida y acá verás registrado tu mejor tiempo y movimientos!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: _isDarkMode ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: ListView(
        children: [
          Card(
            color: cardColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: primaryColor.withValues(alpha: 0.2)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListTile(
                leading: const Icon(
                  Icons.star_rounded,
                  color: Colors.amber,
                  size: 44,
                ),
                title: Text(
                  'Mejor Récord ($dificultad)',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          '⏱️ Tiempo: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${scoreData['tiempo']}',
                          style: TextStyle(color: textColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text(
                          '🔢 Movimientos: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${scoreData['movimientos']}',
                          style: TextStyle(color: textColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text(
                          '📅 Fecha: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${scoreData['fecha']}',
                          style: TextStyle(color: textColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
