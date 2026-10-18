import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InstruccionesScreen extends StatefulWidget {
  const InstruccionesScreen({super.key});

  @override
  State<InstruccionesScreen> createState() => _InstruccionesScreenState();
}

class _InstruccionesScreenState extends State<InstruccionesScreen> {
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
      appBar: AppBar(
        title: Text(
          'Instrucciones / Cómo Jugar',
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
            _buildInstructionTile(
              step: '1',
              title: 'Explicación breve',
              subtitle: '"Ordena las piezas en orden numérico (o forma la imagen correcta) utilizando el espacio vacío para deslizar las piezas adyacentes".',
              textColor: textColor,
              primaryColor: primaryColor,
            ),
            const Divider(height: 32),
            _buildInstructionTile(
              step: '2',
              title: 'Dinámica de la partida',
              subtitle: 'Al realizar el primer movimiento, comienza a descontarse el tiempo del cronómeto y se van sumndo los movimientos realizados. En caso de que el tiempo se agote y no se haya completado el puzzle, la partida acabara y perderás.',
              textColor: textColor,
              primaryColor: primaryColor,
            ),
            const Divider(height: 32),
            _buildInstructionTile(
              step: '3',
              title: '¿Cómo ganar?',
              subtitle: 'Se gana al ordernar todas las piezas correctamente de izquierda a derecha y de arriba hacia abajo dejando el espacio vacío al final.',
              textColor: textColor,
              primaryColor: primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionTile({
    required String step,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color primaryColor,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: primaryColor,
        child: Text(
          step,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6.0),
        child: Text(
          subtitle,
          style: TextStyle(
            color: _isDarkMode ? Colors.white70 : Colors.black87,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
