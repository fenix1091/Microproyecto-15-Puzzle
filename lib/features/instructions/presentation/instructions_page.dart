import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/tokens.dart';

/// Instructions page detailing game rules, difficulty levels table, and adaptive engine.
class InstructionsPage extends StatelessWidget {
  const InstructionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Instrucciones'),
        leading: Semantics(
          label: 'Volver',
          button: true,
          excludeSemantics: true,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go(AppRoutes.menu),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.spaceMedium,
            vertical: AppTokens.spaceSmall,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // How to play card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTokens.spaceMedium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.sports_esports_outlined,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: AppTokens.spaceSmall),
                              Text(
                                '¿Cómo jugar?',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTokens.spaceSmall),
                          Text(
                            'El objetivo es ordenar las fichas en orden numérico ascendente (de izquierda a derecha y de arriba a abajo), dejando la casilla vacía en la esquina inferior derecha.',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: AppTokens.spaceSmall),
                          Text(
                            '• Toca una ficha adyacente al hueco para moverla.\n'
                            '• Toca una ficha en la misma fila o columna que el hueco para deslizar varias fichas a la vez en un solo movimiento.\n'
                            '• También puedes deslizar (swipe) con tu dedo hacia el hueco.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppTokens.spaceMedium),

                  // Levels Table Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTokens.spaceMedium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.format_list_numbered_rounded,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: AppTokens.spaceSmall),
                              Text(
                                'Niveles de dificultad',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTokens.spaceMedium),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columnSpacing: 16,
                              headingRowHeight: 40,
                              dataRowMinHeight: 36,
                              dataRowMaxHeight: 44,
                              columns: const [
                                DataColumn(label: Text('Nivel')),
                                DataColumn(label: Text('Tablero')),
                                DataColumn(label: Text('Mezcla')),
                                DataColumn(label: Text('Tiempo límite')),
                              ],
                              rows: const [
                                DataRow(
                                  cells: [
                                    DataCell(Text('Fácil')),
                                    DataCell(Text('3×3')),
                                    DataCell(Text('40 movs')),
                                    DataCell(Text('5 min')),
                                  ],
                                ),
                                DataRow(
                                  cells: [
                                    DataCell(Text('Medio')),
                                    DataCell(Text('4×4')),
                                    DataCell(Text('100 movs')),
                                    DataCell(Text('6 min')),
                                  ],
                                ),
                                DataRow(
                                  cells: [
                                    DataCell(Text('Difícil')),
                                    DataCell(Text('4×4')),
                                    DataCell(Text('200 movs')),
                                    DataCell(Text('4 min')),
                                  ],
                                ),
                                DataRow(
                                  cells: [
                                    DataCell(Text('Experto')),
                                    DataCell(Text('5×5')),
                                    DataCell(Text('400 movs')),
                                    DataCell(Text('8 min')),
                                  ],
                                ),
                                DataRow(
                                  cells: [
                                    DataCell(Text('Maestro')),
                                    DataCell(Text('6×6')),
                                    DataCell(Text('800 movs')),
                                    DataCell(Text('12 min')),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppTokens.spaceMedium),

                  // Adaptive Difficulty Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTokens.spaceMedium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: AppTokens.spaceSmall),
                              Text(
                                'Dificultad adaptativa',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTokens.spaceSmall),
                          Text(
                            'El motor inteligente de dificultad evalúa tus últimas 10 partidas:\n'
                            '• Si ganas 3 o más partidas seguidas con rapidez, subes al siguiente nivel.\n'
                            '• Si pierdes o abandonas 2 o más partidas consecutivas, el nivel baja para ayudarte a retomar el ritmo.\n'
                            '• Además, ajusta finamente el tiempo y la complejidad de la mezcla dentro de cada nivel según tu destreza.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
