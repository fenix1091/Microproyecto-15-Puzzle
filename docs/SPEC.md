# Sliding Puzzle — Especificación técnica

> Versión 1.0 · 2026-10-17 · Flutter 3.47.7 (stable) · Dart 3.13.5
> Inspirado en las mecánicas de [AChep/15puzzle](https://github.com/AChep/15puzzle). Implementación original: no se reutiliza código.

## 1. Objetivo

Juego de rompecabezas deslizante (3×3 a 6×6) moderno, accesible y desafiante, con dificultad adaptativa, récords locales y una arquitectura limpia, testeable y escalable.

**Prioridades:** rendimiento → mantenibilidad → escalabilidad → experiencia de juego.

## 2. Entorno y convenciones

| Tema | Decisión |
|---|---|
| Plataformas | Web (verificada localmente), Android, iOS, Windows (requieren SDK/VS) |
| Ruta de trabajo | **Ejecutar Flutter desde `D:\dev\sliding_puzzle`** (junction). La ruta real contiene "ó" y rompe `flutter analyze` / `flutter build`. |
| Estado / DI | `flutter_riverpod` 3 (Notifier / AsyncNotifier, sin codegen) |
| Navegación | `go_router` 18 |
| Persistencia | `hive_ce` (historial, mapas planos sin adapters) + `shared_preferences` (ajustes) |
| Audio / háptica | `audioplayers` + `HapticFeedback` (ambos opcionales) |
| Igualdad | `equatable` |
| Tests | `flutter_test`, `mocktail`, `integration_test`, Playwright (e2e web) |
| Lints | `flutter_lints` + `strict-casts`, `strict-raw-types` y reglas extra (`analysis_options.yaml`) |
| Idioma UI | Español |

## 3. Arquitectura

Clean Architecture por feature. Dependencias **solo hacia dentro**:

```
presentation ──► application ──► domain ◄── data
      │                              ▲
      └──────── app/di (composition root) ┘
```

- **domain**: entidades inmutables, servicios puros (algoritmos), interfaces de repositorio, casos de uso. Sin Flutter (excepto `equatable`).
- **data**: implementaciones de repositorios (Hive, SharedPreferences), DTOs.
- **application**: controladores Riverpod (`Notifier`) que orquestan casos de uso y exponen estado.
- **presentation**: widgets y páginas. Solo leen providers de `application` y `app/di`. **Nunca** importan `data/`.
- **app/di/providers.dart**: único lugar donde se instancian implementaciones (DIP). Tests usan `ProviderScope(overrides:)`.

SOLID: cada caso de uso es una clase con `call()` (SRP); repositorios como `interface` (DIP/ISP); nuevas fuentes de datos se agregan sin tocar el dominio (OCP).

Errores esperados → `Result<T>` (`Ok` / `Err(Failure)`); excepciones solo para errores de programación.

## 4. Árbol de directorios

```
lib/
  main.dart                       # semántica web en QA, ProviderScope
  app/
    app.dart                      # MaterialApp.router, temas
    router.dart                   # AppRoutes + routerProvider
    di/bootstrap.dart             # abre Hive + SharedPreferences
    di/providers.dart             # composition root
    theme/                        # app_theme.dart, tokens (colores, radios, duraciones)
  core/
    config/app_env.dart           # --dart-define QA, QA_SEED, QA_TIME_LIMIT, QA_SHUFFLE_MOVES
    errors/failure.dart
    result.dart
    services/feedback_service.dart
    utils/clock.dart, random_source.dart
  shared/
    services/audio_feedback_service.dart
    widgets/                      # botones, chips de estadística, logo animado, diálogos
  features/
    splash/presentation/
    menu/presentation/
    game/
      domain/entities/            # board, difficulty_level, difficulty_config, difficulty_decision,
                                  # game_session, game_result, player_stats
      domain/services/            # shuffler, solvability, heuristics, difficulty_engine
      domain/repositories/        # game_history_repository
      domain/usecases/            # start_game, game_actions, finish_game, stats_usecases
      data/                       # dto + hive_game_history_repository
      application/                # game_state, game_controller
      presentation/               # game_page, result_page, widgets/
    leaderboard/
      domain/ (entities, repositories, usecases)
      data/repositories/history_leaderboard_repository.dart
      application/leaderboard_providers.dart
      presentation/
    settings/
      domain/ (user_settings, settings_repository, usecases)
      data/repositories/prefs_settings_repository.dart
      application/settings_controller.dart
      presentation/
    instructions/presentation/
assets/sounds/                    # move.wav, invalid.wav, win.wav, lose.wav
test/unit/  test/widget/  integration_test/  test_driver/
tests/                            # Playwright e2e
docs/                             # SPEC.md, REVIEW.md, QA_REPORT.md, ui/
```

## 5. Modelos de dominio

| Entidad | Campos clave | Notas |
|---|---|---|
| `Board` | `size`, `tiles` (fila mayor, `0` = hueco), `emptyIndex` | Inmutable. `canMove`, `slideGroup`, `move`, `isSolved`, `isTileHome`, `neighborsOfEmpty`. Tocar una ficha en la fila/columna del hueco desliza todas las intermedias (1 movimiento). |
| `DifficultyLevel` | `easy, medium, hard, expert, master` | `next`, `previous`, `key` estable para persistencia |
| `DifficultyConfig` | `boardSize`, `shuffleMoves`, `timeLimit?`, `minSolutionDepth` | `DifficultyConfig.base(level)` = tabla §7 |
| `DifficultyDecision` | `level`, `trend`, `shuffleMultiplier`, `timeMultiplier` | Salida del motor adaptativo |
| `GameSession` | `initialBoard`, `board`, `config`, `moves`, `elapsed`, `status` | `ready → playing ⇄ paused → won/lost`; `remaining` |
| `GameResult` | `level`, `boardSize`, `moves`, `duration`, `outcome`, `minSolutionDepth`, `playedAt`, `timeLimit`, `isPersonalBest` | `won / lost / abandoned` |
| `PlayerStats` | `gamesPlayed`, `wins`, promedios, rachas | Abandono = derrota |
| `LeaderboardEntry` | `rank`, `level`, `boardSize`, `duration`, `moves`, `playedAt` | Orden: tiempo ↑, movimientos ↑ |
| `UserSettings` | `themeMode`, `soundEnabled`, `vibrationEnabled`, `adaptiveDifficulty`, `manualLevel`, `reduceMotion`, `currentLevel` | |

## 6. Casos de uso

| Caso de uso | Firma | Reglas |
|---|---|---|
| `StartGame` | `({currentLevel, manualLevel?}) → Future<Result<GameSetup>>` | Manual: config base. Adaptativo: `DifficultyEngine.evaluate(history)` → `configFor`. Aplica overrides QA. |
| `MoveTile` | `(session, index) → Result<GameSession>` | `ready` pasa a `playing` en el primer movimiento válido; tablero resuelto → `won`. |
| `TickGame` | `(session, delta) → GameSession` | Solo `playing`; al superar `timeLimit` → `lost`. |
| `PauseGame` / `ResumeGame` | `(session) → Result<GameSession>` | `playing ⇄ paused` |
| `RestartGame` | `(session) → GameSession` | Mismo `initialBoard`, contadores en 0, `ready` |
| `FinishGame` | `(session, outcome) → Future<Result<GameResult>>` | Guarda historial; si ganó, envía al ranking y marca `isPersonalBest` |
| `ComputeNextDifficulty` | `(current) → Future<Result<DifficultyDecision>>` | Vista previa en el menú |
| `GetPlayerStats` | `() → Future<Result<PlayerStats>>` | |
| `GetLeaderboard` / `GetPersonalBest` | `(level) → …` | Top 10 por nivel |
| `LoadSettings` / `UpdateSettings` | | Valores por defecto si no hay datos |

## 7. Sistema de dificultad

### 7.1 Tabla base

| Nivel | Tablero | Mezcla (movs) | Tiempo límite | Profundidad mín. |
|---|---|---|---|---|
| Fácil | 3×3 | 40 | 5 min | 10 |
| Medio | 4×4 | 100 | 6 min | 25 |
| Difícil | 4×4 | 200 | 4 min | 40 |
| Experto | 5×5 | 400 | 8 min | 70 |
| Maestro | 6×6 | 800 | 12 min | 110 |

### 7.2 Motor adaptativo (`DifficultyEngine`, función pura)

Entrada: últimas 10 partidas (más reciente primero) y nivel actual.

- `ratioTiempo = duración / timeLimit`, `ratioMovs = movimientos / minSolutionDepth`.
- **Sube** si `rachaVictorias ≥ 3` y el promedio de `ratioTiempo` en victorias es `< 0.6`.
- **Baja** si `rachaDerrotas ≥ 2` o el promedio de `ratioTiempo` es `> 0.95`.
- **Se mantiene** en otro caso, con ajuste fino:
  - `shuffleMultiplier` y `timeMultiplier` ∈ [0.8, 1.2].
  - Jugador rápido y eficiente (`ratioTiempo < 0.75` y `ratioMovs < 2.5`): mezcla ×1.1–1.2 y tiempo ×0.9–0.8.
  - Jugador lento (`ratioTiempo > 0.85`): mezcla ×0.9–0.8 y tiempo ×1.1–1.2.
- Abandonos cuentan como derrotas. Sin historial → nivel actual sin cambios.
- El nivel resultante se guarda en `UserSettings.currentLevel`.

La dificultad modifica: **tamaño del tablero** (por nivel), **complejidad de mezcla** (`shuffleMoves`), **tiempo límite** y **profundidad requerida** (`minSolutionDepth`).

## 8. Algoritmos

- **Mezcla resoluble por construcción:** paseo aleatorio de movimientos legales desde el tablero resuelto, sin deshacer el paso anterior. Después sigue mezclando hasta que `Heuristics.lowerBound ≥ minSolutionDepth`, con un tope de 4× `shuffleMoves`. Nunca devuelve un tablero resuelto. Objetivo: menos de 50 ms en 6×6.
- **Verificación:** `isSolvable` por paridad de inversiones. Ancho impar: inversiones pares. Ancho par: `inversiones + filaDelHuecoDesdeAbajo` impar.
- **Profundidad:** Manhattan + Linear Conflict (cota admisible). Para 3×3 se puede calcular IDA* exacto en `compute()` (roadmap: pistas).
- **Ranking:** derivado del historial (única fuente de verdad); top 10 por nivel.

## 9. Flujo de navegación

```
/splash ──(precarga OK)──► /menu
/menu ──► /game ──(ganar/perder/abandonar)──► /result ──► /game (jugar de nuevo) | /menu
/menu ──► /leaderboard | /settings | /instructions
```

- Si `appDependenciesProvider` no terminó (recarga web o deep link), cualquier ruta redirige a `/splash`. `/result` sin `extra` redirige a `/menu`.
- Pausa: overlay sobre `/game`. Salir: diálogo de confirmación (botón y `PopScope`). Ir a segundo plano → pausa automática (`AppLifecycleListener`).

## 10. Diseño UI

- **Material 3**, `ColorScheme.fromSeed`, temas claro, oscuro y sistema. Tokens en `app/theme/`.
- **Splash:** las fichas del logo aparecen con escala y desvanecimiento escalonados mientras se precargan Hive, ajustes y sonidos (mínimo ~1.2 s). Transición fade-through al menú.
- **Menú:** título, nivel actual con su tendencia, y botones Jugar, Marcadores, Configuración e Instrucciones.
- **Juego:** HUD con temporizador (cuenta regresiva si hay límite; en rojo y con pulso en los últimos 10 s), movimientos y nivel/tamaño. Botones Pausa, Reiniciar y Salir. Tablero cuadrado.
  - Fichas con `AnimatedPositioned` (140 ms, `easeOutCubic`). Sacudida si el movimiento es inválido. Resaltado sutil si la ficha está en su posición. Pulso o confeti al ganar.
  - Entrada por toque y por deslizamiento (swipe). `RepaintBoundary` por ficha.
- **Resultado:** victoria o derrota, tiempo, movimientos, eficiencia (`movimientos / profundidad`), insignia de récord personal, y botones Jugar de nuevo y Menú.
- **Responsive:** `LayoutBuilder`; lado del tablero = `min(ancho, alto) × 0.9`, como máximo 560 px. En horizontal o escritorio el HUD va al lado. Sin overflow entre 320×568 y 2560×1440.
- **Accesibilidad:** `Semantics` en cada ficha ("Ficha 5, fila 2, columna 1, movible") y botones con etiqueta. Contraste AA. Se respeta `MediaQuery.disableAnimations` y `UserSettings.reduceMotion`. Soporta escalado de texto hasta 200 %. Áreas táctiles de al menos 48 px.

## 11. Plan de implementación (orquestación Orca)

| Oleada | Responsable | Entregable | Aceptación |
|---|---|---|---|
| 1 | Coordinador (Claude Opus) | Proyecto, dependencias, contratos (este código base), SPEC | `flutter analyze` limpio, `flutter build web` OK |
| 2A | Backend (Codex · GPT-6-Luna) | core, dominio, datos, controladores, unit tests | `flutter test test/unit` verde, cobertura de dominio ≥ 90 % |
| 2B | Frontend (Antigravity · Gemini 3.8) | tema, router, pantallas, animaciones, accesibilidad, widget tests | `flutter test test/widget` verde, sin overflow |
| 3 | Mediador (Claude Sonnet 5.5) | `docs/REVIEW.md` | Consistencia de capas; conflictos escalados al coordinador |
| 4 | Coordinador | integración, `integration_test`, CI | todo verde |
| 5 | QA (Codex · GPT-6-Luna) | Playwright + `docs/QA_REPORT.md` | bugs clasificados; críticos y altos corregidos |

**Propiedad de archivos:** el backend es dueño de `lib/core/**`, `lib/features/*/{domain,data,application}/**`, `test/unit/**`. El frontend es dueño de `lib/app/{app.dart,router.dart,theme/**}`, `lib/shared/**`, `lib/features/*/presentation/**`, `assets/**`, `test/widget/**`. El coordinador es dueño de `pubspec.yaml`, `lib/main.dart`, `lib/app/di/**`, CI y `docs/SPEC.md`. Cambiar un contrato (firma pública del dominio o la aplicación) requiere aprobación del coordinador.

## 12. Estrategia de testing

| Nivel | Alcance | Herramientas |
|---|---|---|
| Unit | Board (movimientos simples y múltiples, bordes), solvability (casos conocidos), heuristics (valores a mano), shuffler (1000 semillas → siempre resoluble y nunca resuelto; profundidad ≥ mínima; rendimiento 6×6), DifficultyEngine (tabla de escenarios), casos de uso con fakes/mocktail, repositorios (Hive en directorio temporal, `SharedPreferences.setMockInitialValues`) | `flutter_test`, `mocktail` |
| Widget | BoardView (tap mueve, semántica), HUD, overlay de pausa, resultado, ajustes, temas, layouts 360×640 y 1440×900 | `flutter_test`, overrides de providers |
| Integración | Flujo completo con semilla y `QA_SHUFFLE_MOVES` bajo: splash → menú → ganar → récord persistido | `integration_test` + `flutter drive` + chromedriver |
| E2E | Build web QA con semántica: navegación, partida, pausa, reinicio, salir, derrota por tiempo, ajustes persistidos, tema, viewports móvil y escritorio, tiempos de carga | Playwright (chromium, firefox, webkit, Pixel 5, iPhone 12) |

Comandos (desde `D:\dev\sliding_puzzle`):

```
flutter analyze
flutter test --coverage
chromedriver --port=4444
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart -d web-server
flutter build web --dart-define=QA=true --dart-define=QA_SEED=42
npx playwright test
```

## 13. Riesgos técnicos

| # | Riesgo | Impacto | Mitigación |
|---|---|---|---|
| 1 | Ruta con caracteres no ASCII rompe el tooling | Alto | Junction `D:\dev\sliding_puzzle` |
| 2 | Sin Android SDK ni Visual Studio | Medio | Verificar web en local; las demás plataformas en CI |
| 3 | Flutter web dibuja en canvas | Alto para QA | Activar el árbol de semántica con `--dart-define=QA=true`; etiquetas estables |
| 4 | Varios agentes en el mismo worktree | Medio | Propiedad de archivos estricta; contratos congelados |
| 5 | Rendimiento 6×6 | Medio | Heurística O(n²) solo al generar; `RepaintBoundary`; animaciones implícitas |
| 6 | Esquema de Hive cambia | Bajo | DTO con `schemaVersion`; si no se puede leer, se descarta el registro |
| 7 | Audio en web sin gesto previo del usuario | Bajo | Reproducir solo después de la primera interacción; los fallos de audio son silenciosos |
| 8 | IDs de modelo no disponibles en Orca | Bajo | Revisar `launch.effective`; usar el modelo por defecto del agente |

## 14. Roadmap

- **v1.0** — MVP de este documento.
- **v1.1** — pistas (IDA* en 3×3 y 4×4, un movimiento sugerido), modo imagen.
- **v1.2** — logros, estadísticas con gráficos, exportar historial.
- **v1.3** — desafío diario con semilla compartida y ranking online opcional.
- **v2.0** — multijugador por turnos o carrera en tiempo real.

## 15. Formato de reporte QA

Cada bug en `docs/QA_REPORT.md`:

```
### QA-### · <título>
- Severidad: Crítico | Alto | Medio | Bajo
- Área: funcional | UI | UX | rendimiento | responsive | accesibilidad
- Descripción:
- Pasos para reproducir:
- Resultado esperado / obtenido:
- Causa probable:
- Solución recomendada:
- Evidencia: (captura / trace de Playwright)
```

Criterio de severidad: **Crítico** = bloquea jugar o pierde datos. **Alto** = una función principal está rota o es inaccesible. **Medio** = comportamiento incorrecto que se puede evitar. **Bajo** = detalle visual o de texto.
