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
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  void _confirmarBorrarMarcadores() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDark = _isDarkMode;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E2620) : Colors.white,
          title: Text('Borrar Marcadores', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          content: Text(
            '¿Estás seguro de que deseas eliminar todo el historial de puntuaciones?',
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                setState(() {
                  _scoreFacil = null;
                  _scoreMedio = null;
                  _scoreDificil = null;
                });
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Marcadores borrados con éxito')),
                  );
                }
              },
              child: const Text('Borrar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _isDarkMode ? const Color(0xFF141A16) : const Color(0xFFF4F6F4);
    final textColor = _isDarkMode ? Colors.white : const Color(0xFF222825);
    final primaryColor = const Color(0xFF3B7A57);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Text('Tabla de Marcadores', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
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
            _buildScoreView(_scoreFacil, 'Fácil'),
            _buildScoreView(_scoreMedio, 'Medio'),
            _buildScoreView(_scoreDificil, 'Difícil'),
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
              Icon(Icons.emoji_events_outlined, size: 80, color: primaryColor.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                'Sin registros en dificultad $dificultad',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 8),
              Text(
                '¡Juega una partida para registrar tu mejor tiempo y movimientos aquí!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: _isDarkMode ? Colors.white60 : Colors.black54),
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
            child: ListTile(
              leading: const Icon(Icons.star_rounded, color: Colors.amber, size: 40),
              title: Text('Mejor Partida ($dificultad)', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text('⏱️ Mejor Tiempo: ${scoreData['tiempo']}', style: TextStyle(color: textColor)),
                  Text('🔢 Menor Movimientos: ${scoreData['movimientos']}', style: TextStyle(color: textColor)),
                  Text('📅 Fecha: ${scoreData['fecha']}', style: TextStyle(color: textColor)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}