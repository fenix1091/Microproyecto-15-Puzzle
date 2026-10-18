# Sliding Puzzle — Revisión técnica (Oleada 3, mediador)

> Revisión de los commits `7790c59` (contratos), `7590dde` (backend) y `dd395cc` (frontend) contra `docs/SPEC.md` y `docs/ui/DESIGN.md`.
> Fecha: 2026-10-17. Solo lectura: no se modificó ningún archivo salvo este documento. Rutas relativas a la raíz del repo; `lib/…` salvo indicación.

## 1. Resumen

El proyecto **compila, analiza limpio y pasa todos los tests** (64/64). La arquitectura por capas se respeta: no hay un solo import de `data/` desde presentación y el dominio solo depende de `equatable`. Las reglas de juego del SPEC §6–8 están implementadas correctamente (deslizamiento múltiple = 1 movimiento, `ready → playing` en el primer movimiento, temporizador solo en `playing`, derrota por límite, abandono = derrota, récord personal calculado antes de guardar, overrides QA).

Lo que **no** está bien está en la costura UI ↔ controlador, que los tests de widget no cubren porque sustituyen el controlador por un `FakeGameController`:

- **Sin bloqueantes (0 Críticos)**, pero hay **3 hallazgos Altos**: las fichas no exponen la acción `tap` en el árbol de semántica (verificado con `SemanticsData`), el layout horizontal en teléfonos desborda 23–55 px (verificado, 3 viewports) y un fallo de arranque del almacenamiento deja la app en un bucle splash→menú→splash sin mensaje.
- La navegación al terminar la partida es **ambigua entre documentos**: SPEC §9 dice `/game → /result` al abandonar; DESIGN §4.3 dice `/menu`. El código hace las dos cosas en carrera y la última gana (`/menu`; verificado).
- `GamePage` ignora `GameState.isStarting` y `GameState.failure`: spinner infinito o tablero obsoleto si `start()` o `FinishGame` fallan.
- Bug backend de dato visible: “Racha actual” del marcador se calcula desde la partida **más antigua**.
- Rendimiento: `GamePage` observa todo el `GameState`; cada tick de 1 s reconstruye HUD y las 35 fichas en 6×6. Aceptable hoy, fácil de acotar.

**Conteo por severidad:** Crítico 0 · Alto 3 · Medio 10 · Bajo 13 · **Total 26**.

## 2. Resultados de las verificaciones automáticas

Todo ejecutado desde la junction `D:\dev\sliding_puzzle` con Flutter 3.47.7 / Dart 3.13.5, en PowerShell.

| Comando | Resultado |
|---|---|
| `flutter analyze` | **No issues found!** (5.1 s) |
| `flutter test` (unit + widget) | **All tests passed!** — 64 tests |
| `flutter build web` | **√ Built build\web** (compilación 53.4 s; dry-run Wasm OK). `build/` está en `.gitignore`; `git status` limpio |
| `flutter test --coverage` | No ejecutado (el criterio ≥ 90 % de cobertura del dominio del SPEC §11 queda sin medir) |

Nota de entorno (MED-025): lanzados desde **Git Bash** los tres comandos fallan (`"D:\duo" no se reconoce…` en el hook de *native assets* de `objective_c` porque la ruta del SDK contiene un espacio, y el analysis server cae con `FormatException`). Con PowerShell funcionan. Quien ejecute CI/QA en Windows debe usar PowerShell.

Verificaciones adicionales hechas en una **copia desechable** (`D:\dev\review_copy`, fuera del repo) con tests de sondeo, para no tocar el proyecto: desborde en horizontal, flujo real de abandono con el controlador real, acciones de semántica de las fichas y nodos duplicados en pausa. Los resultados se citan en los hallazgos.

## 3. Capas (verificación con grep)

Comandos ejecutados desde `lib/`:

| Regla | Comando | Resultado |
|---|---|---|
| presentación/shared/app no importa `data/` | `grep -rn "/data/" features/*/presentation shared app/app.dart app/router.dart app/theme` | **0 coincidencias** ✔ |
| dominio sin Flutter ni infraestructura | `grep -rn "package:flutter\|dart:ui\|flutter_riverpod\|hive\|shared_preferences" features/*/domain core` | **0 coincidencias** ✔ |
| paquetes importados por dominio+core | `grep -rhn "import 'package:" features/*/domain core` | solo `package:equatable/equatable.dart` (10×) ✔ |
| application no importa `data/` | `grep -rn "/data/" features/*/application` | **0 coincidencias** ✔ |
| dominio no importa application/presentation/data | `grep -rn "application/\|presentation/\|/data/" features/*/domain` | **0 coincidencias** ✔ |
| quién usa `app/di` desde presentación | `grep -rn "app/di" features/*/presentation shared` | solo `splash_page.dart:6` (`appDependenciesProvider`, permitido por SPEC §3) ✔ |
| única composición de `data/` | `app/di/providers.dart:7,15,18` y `app/di/bootstrap.dart:4` | ✔ composition root |

Observaciones de capas (no violaciones): `application/*` importa `app/di/providers.dart` (`game_controller.dart:5`, `settings_controller.dart:3`, `leaderboard_providers.dart:3`) — el diagrama de SPEC §3 solo dibuja `presentation → app/di`; y la presentación importa `app/router.dart` para leer `AppRoutes`, mientras el router importa las páginas (ciclo de imports de solo constantes). Ver MED-024 y conflicto C6.

## 4. Verificación de contratos y reglas

### 4.1 Contrato UI ↔ controladores (tarea 2)

| Punto | Estado | Evidencia |
|---|---|---|
| `start()` al entrar, una sola vez | ✔ en `initState` vía `addPostFrameCallback`. Rebuilds no lo repiten. ⚠ ver MED-006 (sesión obsoleta visible mientras arranca) | `presentation/pages/game_page.dart:28-32` |
| `tap(index)` desde tablero | ✔ | `game_page.dart:138-140,167-169`; `board_view.dart:161-167` |
| `pause` / `resume` / `restart` | ✔ llamadas correctas. ⚠ `pause` en `ready` falla en silencio (MED-022) | `game_page.dart:122-127,181-187` |
| `abandon()` al salir | ✔ en diálogo de salida. ✘ no se llama en `dispose` ni al cambiar de ruta por otro medio (MED-015) | `game_page.dart:56-76` |
| Navegación a `/result` exactamente una vez | ✔ el `ref.listen` compara `previous?.result != result` y `start()` pone `result` a `null` antes de la nueva partida. ✘ en abandono se dispara además `go(/menu)` (MED-005) | `game_page.dart:81-88` |
| Auto-pausa en segundo plano | ✔ `AppLifecycleListener` `onInactive` y `onPause` solo si `playing`. (Pausa también al perder foco en escritorio/web: aceptable) | `game_page.dart:34-47` |
| Manejo de `isStarting` / `failure` / `session == null` | ✘ `session == null` → spinner; `isStarting` y `failure` **no se leen en ninguna parte de presentación** (`grep` sin coincidencias) | `game_page.dart:103-104`; MED-006, MED-010 |
| Ajustes por `settingsControllerProvider.notifier.change` | ✔ en las 6 opciones | `settings/presentation/settings_page.dart:56,…` |
| Invalidación de marcadores tras la partida | ✔ `leaderboardProvider(level)`, `personalBestProvider(level)`, `playerStatsProvider`, `nextDifficultyProvider(level)` se invalidan en `_finish` **antes** del siguiente frame | `application/game_controller.dart:76-79` |
| Nivel adaptativo persistido | ✔ `currentLevel = decision.level` (nivel jugado). ⚠ con `start(level:)` forzado también se persiste (conflicto C8) | `game_controller.dart:80-89` |

### 4.2 Reglas de juego (SPEC §6–8, tarea 3)

| Regla | Estado | Evidencia |
|---|---|---|
| Deslizamiento múltiple = 1 movimiento | ✔ | `domain/entities/board.dart:37-74`; `usecases/game_actions.dart:19-25` (`moves + 1`) |
| `ready → playing` al primer movimiento válido; `won` si resuelto | ✔ | `game_actions.dart:24` |
| Temporizador solo en `playing` | ✔ se arranca tras el 1.er movimiento, se cancela en pausa/fin/dispose | `game_controller.dart:43-66,133,157` |
| Derrota al superar el límite | ✔ `elapsed >= timeLimit` → `lost` → `FinishGame` | `game_actions.dart:35-46`; `game_controller.dart:60-64` |
| Abandono cuenta como derrota | ✔ en motor y estadísticas (`outcome != won`). ⚠ no se registra si `moves == 0` (conflicto C2) | `difficulty_engine.dart:44-57`; `game_controller.dart:189` |
| Reglas adaptativas y clamps | ✔ sube (`winRun ≥ 3` y media ratio victorias < 0.6), baja (`lossRun ≥ 2` o media > 0.95), multiplicadores con `clamp(.8, 1.2)`. ⚠ MED-009 y MED-016 | `difficulty_engine.dart:62-100` |
| Tabla base §7.1 | ✔ coincide fila por fila | `difficulty_config.dart:16-52` |
| Orden de récords: tiempo ↑, movimientos ↑ | ✔ | `history_leaderboard_repository.dart:56-59` |
| Récord personal calculado **antes** de guardar | ✔ `submit` (lee historial sin la partida actual) se ejecuta antes de `_history.save` | `finish_game.dart:36-41` |
| Mezcla resoluble y no resuelta | ✔ | `shuffler.dart:18-37` |
| QA: `QA`, `QA_SEED`, `QA_TIME_LIMIT`, `QA_SHUFFLE_MOVES` | ✔ las cuatro se leen: `main.dart:13` (semántica web), `providers.dart:37` (semilla), `start_game.dart:56-68` (límite y mezcla) | ver nota abajo |
| Historial máx. 500, más reciente primero | ✔ | `hive_game_history_repository.dart:24,44` |

Nota QA: `QA_SHUFFLE_MOVES` no baja `minSolutionDepth`, por lo que el mezclador camina hasta 4× el valor (tope) en vez de parar antes; sigue produciendo tableros casi resueltos y válidos. Sin impacto.

### 4.3 Contrato semántico / etiquetas QA (tarea 4)

| Etiqueta | Estado | Evidencia |
|---|---|---|
| Fichas `Ficha {n}, fila {r}, columna {c}[, movible]` (1-based) | ✔ texto exacto, verificado con el nodo real: `"Ficha 7, fila 3, columna 1, movible"`. ✘ **sin acción `tap`** (MED-001) | `widgets/tile_view.dart:105-130` |
| Menú: Jugar / Marcadores / Configuración / Instrucciones | ✔ | `menu/presentation/menu_page.dart:164,171,178,185` |
| Juego: Pausa / Reiniciar / Salir | ✔ (duplicados en pausa: MED-008) | `game_hud.dart:160-177` |
| Pausa: Reanudar | ✔ | `pause_overlay.dart:67-72` |
| Resultado: Jugar de nuevo / Menú | ✔ | `result_page.dart:190,197` |
| Volver (ajustes, marcadores, instrucciones, diálogo) | ✔ (posible etiqueta duplicada: MED-023) | `settings_page.dart:25-33`, `exit_confirmation_dialog.dart:29` |
| HUD `Tiempo mm:ss` / `Movimientos n` / `Nivel X` | ✔ | `game_hud.dart:100-135` |
| Nombres de nivel Fácil/Medio/Difícil/Experto/Maestro | ✔ | usados vía `displayName` |

## 5. Hallazgos

Severidad según SPEC §15: **Crítico** = bloquea jugar o pierde datos · **Alto** = función principal rota o inaccesible · **Medio** = comportamiento incorrecto evitable · **Bajo** = detalle.

| ID | Sev. | Dueño | Archivo:línea | Descripción | Corrección recomendada |
|---|---|---|---|---|---|
| MED-001 | Alto | frontend | `features/game/presentation/widgets/tile_view.dart:126-130` | `Semantics(button: true, excludeSemantics: true)` descarta los hijos, incluido el `InkWell`, y el propio nodo no declara `onTap`. Verificado: `getSemanticsData().hasAction(SemanticsAction.tap) == false` en la ficha “Ficha 7…movible”. TalkBack/VoiceOver y la activación por semántica (Playwright en el build QA) no pueden mover fichas; solo funciona el puntero directo. Incumple SPEC §10 (accesibilidad) y el contrato QA de DESIGN §5. | Añadir `onTap: widget.onTap` al `Semantics` (y `enabled: canMove` si se quiere distinguir). Añadir test con `tester.semantics.tap(find.semantics.byLabel(...))` y verificar que `tap(index)` se llama. |
| MED-002 | Alto | frontend + coordinador | `features/splash/presentation/splash_page.dart:30-48`; `app/router.dart:59-67` | Si `bootstrapDependencies()` falla (p. ej. IndexedDB bloqueado en navegación privada, disco lleno), `Future.wait` lanza y el `catch (_)` lo traga; la página hace `go(/menu)`, el `redirect` ve `!depsAsync.hasValue` y vuelve a `/splash`, que reinicia el preload. Bucle infinito cada ≥ 1,2 s, sin spinner de error ni reintento: la app queda inutilizable sin explicación. | En splash distinguir error de `appDependenciesProvider`: mostrar pantalla de error con “Reintentar” (`ref.invalidate(appDependenciesProvider)`) y no navegar. El `redirect` debería dejar pasar a `/menu` solo con `hasValue`. Test de widget con provider que lanza. |
| MED-003 | Medio | backend | `features/game/domain/usecases/stats_usecases.dart:43-59`; `test/unit/features/game/domain/usecases/usecases_test.dart:123` | El historial llega **más reciente primero** (`hive_game_history_repository.dart:44`) y el bucle lo recorre en ese orden, de modo que `winStreak`/`lossStreak` finales son las rachas de las partidas **más antiguas**, no la actual. Se muestra como “Racha actual” (`leaderboard_page.dart:120`). El test usa un `History` fake que añade en orden cronológico y solo aserta `bestWinStreak`, así que no lo detecta. | Calcular la racha actual contando desde `items.first` hasta el primer corte; `best` puede seguir con el recorrido completo. Corregir el fake para respetar el contrato (más reciente primero) y añadir aserciones de `winStreak`/`lossStreak`. |
| MED-004 | Alto | frontend | `features/game/presentation/pages/game_page.dart:109-130`; `widgets/game_hud.dart:180-198` | El layout horizontal (`ancho > alto`) pone un HUD de 280 px con `Column` + `Spacer` sin scroll; necesita ≈ 400 px de alto. Verificado con sondeo: **overflow de 55/40/38 px** (y 3 excepciones `RenderFlex`) a 568×320, 640×360 y 844×390; el botón “Salir” queda fuera de pantalla. Incumple SPEC §10 (“sin overflow”) y el propio test `responsive_overflow_test.dart:12-13`, que solo prueba 360×640 y 1440×900. 320×568, 360×640 con texto ×2 y 2560×1440 pasan. | Envolver el HUD horizontal en `SingleChildScrollView` o usar `LayoutBuilder` con tarjetas en rejilla compacta y botones en fila; reducir `padding`. Ampliar el test a 568×320, 640×360, 844×390, 320×568, texto ×2 y tablero 6×6. |
| MED-005 | Medio | frontend + coordinador | `features/game/presentation/pages/game_page.dart:56-76,81-88`; `application/game_controller.dart:91-93` | Al confirmar “Salir” con movimientos, `abandon()` publica `state.result`; el `ref.listen` hace `go(/result)` **y** `_handleExit` hace después `go(/menu)`. Verificado con el controlador real: termina en `/menu`, `/result` nunca se ve, el historial guarda 1 `abandoned`. Funciona por orden de ejecución, no por diseño, y contradice SPEC §9 (`/game → /result` “ganar/perder/abandonar”). | Decidir destino (ver C1) y hacerlo explícito: p. ej. el listener ignora `outcome == abandoned` y `_handleExit` navega a `/menu`; o `_handleExit` no navega y deja actuar al listener. Añadir test de integración con el controlador real. |
| MED-006 | Medio | frontend + backend | `features/game/presentation/pages/game_page.dart:90-104`; `application/game_controller.dart:99-122` | `GamePage` solo comprueba `session == null`. (a) `GameController` no es `autoDispose`, así que al reentrar (p. ej. “Jugar de nuevo”) se pinta la **sesión terminada anterior** hasta que `start()` termina; `start()` pone `isStarting: true` pero conserva la sesión. (b) Si `start()` falla (`failure`, `isStarting: false`, `session` sigue `null` en la primera partida) la pantalla es un spinner eterno. | Backend: en `start()` emitir `GameState(isStarting: true)` (descarta sesión y resultado). Frontend: si `isStarting` o `session == null` mostrar spinner; si `failure != null && session == null` mostrar error con “Reintentar” y “Volver”. |
| MED-007 | Medio | backend (+ frontend) | `application/game_controller.dart:131`; `application/game_state.dart:56`; `widgets/board_view.dart:155-160` | `state.copyWith(invalidTapIndex: null)` no limpia nada: `invalidTapIndex ?? this.invalidTapIndex` conserva el valor anterior. `BoardView` asigna `shakeTrigger = invalidTapCount` a la ficha que **ocupa ahora** ese índice; tras un toque inválido en el índice 5, cualquier movimiento válido que lleve otra ficha al índice 5 la hace sacudirse como si fuera inválida. | Usar un centinela de limpieza (`clearInvalidTap`) o convertir el par en un único valor `({int index, int seq})?`. Alternativa UI: disparar la sacudida desde un `ref.listen` sobre `invalidTapCount`. Añadir test del controlador. |
| MED-008 | Medio | frontend | `features/game/presentation/pages/game_page.dart:107-189`; `widgets/pause_overlay.dart:67-85`; `widgets/game_hud.dart:160-177` | En pausa el árbol de semántica contiene **dos** botones “Reiniciar” y **dos** “Salir” (HUD + overlay) — verificado: 2/2 nodos — y las 8 fichas siguen expuestas (`Ficha nodes while paused = 8`). El `getByRole('button', {name:'Reiniciar'})` de Playwright falla por modo estricto, y un lector de pantalla puede analizar el tablero durante la pausa, anulando la intención de “ocultar el tablero” (DESIGN §4.3). | Envolver el contenido de fondo en `ExcludeSemantics(excluding: paused)` o `Offstage`/`IgnorePointer`, y poner el overlay como `Semantics(scopesRoute/namesRoute, container: true)`. Alternativa: eliminar Reiniciar/Salir duplicados del overlay. |
| MED-009 | Medio | backend | `domain/services/difficulty_engine.dart:74-90` | El ajuste fino usa solo `recent.first`. Un **abandono** (o un abandono tras pocos movimientos) tiene `timeRatio ≈ 0` y `moveRatio ≈ 0`, y entra en la rama “rápido y eficiente” → mezcla ×1,1–1,2, tiempo ×0,9: el jugador que se rinde recibe una partida más difícil. SPEC §7.2: abandonos cuentan como derrotas. | Excluir de la rama “rápido y eficiente” las partidas no ganadas (`last.outcome != won`) y, para derrota/abandono, aplicar la rama “lento”. Test con historial `[abandoned]` y `[won, abandoned]`. |
| MED-010 | Medio | backend + frontend | `application/game_controller.dart:91-93`; `domain/usecases/finish_game.dart:37-42`; `game_page.dart:81-88` | Si `leaderboard.submit` o `history.save` devuelven `Err`, `_finish` solo asigna `state.failure`; `state.result` nunca se publica y la UI no lee `failure`. El usuario queda mirando un tablero terminado (`won/lost`) sin navegación ni mensaje; cada toque añade otro `GameStateFailure`. Se sale con “Salir” (el `abandon` retorna por `isFinished`). | Publicar un `GameResult` en memoria aunque falle el guardado (con `failure` informativo) para que la UI navegue; o que la UI muestre `SnackBar` + botón “Ver resultado”. Deshabilitar toques cuando la sesión está terminada. |
| MED-011 | Medio | backend | `features/settings/application/settings_controller.dart:40-42`; `application/game_controller.dart:105-106` | Si `UpdateSettings` falla, `change()` reemplaza el estado por `AsyncError(failure)`, perdiendo los valores ya aplicados de forma optimista: `app.dart:24` vuelve a `ThemeMode.system`, `SettingsPage` muestra solo el texto de error sin reintento y `GameController` cae a `const UserSettings()` (`.value` nulo). | Mantener `AsyncData(next)` y exponer el fallo por otro canal (p. ej. `AsyncValue.copyWithPrevious`/campo `lastFailure`), o revertir a `old`. |
| MED-012 | Medio | frontend | `game_page.dart:90`; `widgets/board_view.dart:73-175`; `widgets/tile_view.dart:86-197` | `GamePage` hace `ref.watch(gameControllerProvider)` completo: cada tick (1 s) reconstruye `LayoutBuilder`, HUD, `BoardView` y todas las `TileView` (35 en 6×6, cada una con `Theme.of`, sombras, `Ink`/`InkWell` y `indexOf`) además de 36 huecos estáticos, aunque el tablero no cambió. No hay `RepaintBoundary` en el HUD ni en el fondo de huecos. La pausa usa `BackdropFilter` blur a pantalla completa. | `ref.watch(gameControllerProvider.select(...))` por separado para `board`, `status/moves/elapsed` y `invalidTap`; hacer `BoardView` un widget que reciba `Board` (igualdad por valor) y `const`/cachear el fondo de huecos; `RepaintBoundary` al HUD. Medir en perfil con 6×6. |
| MED-013 | Medio | frontend | `test/widget/helpers/widget_test_helpers.dart:19-97`; `test/widget/game_page_test.dart:11-199`; `test/widget/responsive_overflow_test.dart:12-13` | Todos los tests de `GamePage` usan `FakeGameController` (override de `start/tap/pause/…`): no se prueba el listener de `/result`, el abandono real, el auto-pausado ni el ciclo de vida. El test de responsive no cubre horizontal, 320×568, escala de texto ni 6×6, por eso MED-004 pasó. | Añadir tests con el controlador real + repositorios en memoria y `GoRouter` (el sondeo de este informe sirve de base) y una matriz de viewports/escala de texto. |
| MED-014 | Bajo | backend | `domain/usecases/start_game.dart:43-46` | `StartGame` ignora un error de lectura del historial (`valueOrNull ?? const []`) y genera la partida como si no hubiera historial: el modo adaptativo se reinicia sin avisar. | Devolver `Err` o, mejor, degradar con un `decision` marcado (`trend: unchanged`) y registrar el fallo. Documentar la decisión. |
| MED-015 | Bajo | frontend | `game_page.dart:51-54`; `application/game_controller.dart:15,33` | `GamePage.dispose` no pausa ni abandona; `GameController` no es `autoDispose`. Si la ruta cambia por otra vía que el diálogo (deep link, `go()` externo), el `Timer` sigue corriendo, puede terminar la partida por tiempo y guardarla como derrota sin que nadie la vea. | En `dispose` (o `ref.onDispose` del listener) llamar `pause()` si `playing`; o `NotifierProvider.autoDispose` con `ref.keepAlive` solo mientras haya resultado. |
| MED-016 | Bajo | backend | `domain/services/difficulty_engine.dart:82-89,74-78` | (a) El multiplicador de tiempo del jugador rápido solo llega a ≈ 0,88 (`.9 - amount*.1`, `amount ≤ 0.2`), nunca a 0,8 como pide SPEC §7.2 “×0,9–0,8”. (b) `ratioTiempo`/`ratioMovs` del ajuste fino salen de la última partida, no de la ventana; SPEC no lo precisa. | Reescalar a `[0.9, 0.8]` linealmente; documentar (o cambiar) el uso de la última partida. |
| MED-017 | Bajo | frontend | `widgets/tile_view.dart:64-84`; `game_page.dart:67-72,84-86` | Código muerto/defensivo: `_isTileHome` y `_canMove` envuelven `Board.isTileHome/canMove` (que no lanzan) en `try/catch` con una copia de la lógica; `go()` dentro de `try/catch (_)` oculta errores reales de navegación. Señal de contrato mal conocido. | Eliminar los `try/catch` y la lógica duplicada; dejar que los errores de navegación se propaguen o registrar. |
| MED-018 | Bajo | backend | `domain/services/difficulty_engine.dart:41`; `shuffler.dart:11`; `history_leaderboard_repository.dart:12`; `hive_game_history_repository.dart:17`; `stats_usecases.dart:13,15,30`; `shared/services/audio_feedback_service.dart:22,100-101` | Código muerto y duplicado: `else {}` vacío; **7** `// ignore: unused_field` obsoletos sobre campos que sí se usan; cálculo de `ratioTiempo` duplicado (`:35-38` y `:75-78`) y tres bucles sobre `recent` que se pueden fundir; `recordUserGesture()` nunca se llama (y `gameLost()` marca el gesto como hecho, anulando la protección de autoplay de SPEC §13-7). | Limpiar; extraer `_timeRatio(GameResult)`; quitar los `ignore`; en `gameLost` no asumir gesto. |
| MED-019 | Bajo | frontend | `application/game_state.dart:23` (contrato); `result_page.dart:25-206` | `GameState.decision` (“¡Subiste de nivel!”, tendencia) no se lee en ninguna página: el SPEC §10 y el doc del estado lo prevén, pero el jugador no recibe ese feedback. | Mostrar chip de tendencia en HUD/resultado o aceptar formalmente que solo el menú muestra la tendencia. |
| MED-020 | Bajo | frontend | `app/theme/tokens.dart:11,18`; `app/router.dart:35-45`; `shared/widgets/animated_logo.dart:55` | Deriva respecto a la documentación: breakpoint 760 vs DESIGN §4.3 “≥ 720”; transición 250 ms vs DESIGN §3 “200 ms”; no hay pulso/confeti al ganar (SPEC §10; `grep -ri confeti lib` vacío); transiciones de página y logo usan solo `MediaQuery.disableAnimations`, ignorando `UserSettings.reduceMotion`. | Alinear tokens o documentos; pasar `reduceMotion` a `_buildFadePage` y a `AnimatedLogo`; decidir si el pulso al ganar entra en v1.0. |
| MED-021 | Bajo | frontend | `widgets/board_view.dart:26-69` | El gesto de deslizar solo se evalúa en `onDragEnd` con velocidad ≥ 120 px/s: un arrastre lento y deliberado se ignora, y no hay seguimiento del dedo. Además mueve solo la ficha adyacente al hueco. | Usar también distancia mínima (p. ej. 24 px) y documentar el comportamiento. |
| MED-022 | Bajo | frontend | `widgets/game_hud.dart:160-165,57-60`; `usecases/game_actions.dart:54-56` | “Pausa” está activo en estado `ready` (antes del primer movimiento): `PauseGame` devuelve `GameStateFailure` y el controlador lo guarda en `state.failure` sin feedback. Además el pulso rojo de los últimos 10 s sigue animando mientras el juego está en pausa. | Deshabilitar el botón salvo en `playing`; detener `_pulseController` si `status != playing`. |
| MED-023 | Bajo | frontend | `settings_page.dart:25-33`; `leaderboard_page.dart:52-60`; `instructions_page.dart:19-27`; `leaderboard_page.dart` (subtítulo de fecha) | `Semantics(label:'Volver', button:true)` envuelve un `IconButton` que ya tiene `tooltip:'Volver'` (semántica propia): riesgo de etiqueta duplicada “Volver / Volver” en el árbol; sin verificar en Playwright. La fecha se pinta `d/m/yyyy` sin cero a la izquierda ni localización. | Dejar solo el `tooltip` (o `Semantics` con `excludeSemantics`); usar `DateFormat` / padding. |
| MED-024 | Bajo | coordinador | `features/game/presentation/pages/game_page.dart:5`; `app/router.dart:5-12`; `application/game_controller.dart:5` | `AppRoutes` vive en `app/router.dart`, que importa todas las páginas; las páginas importan el router para leer las constantes (ciclo de imports). `application/` importa `app/di`, no contemplado explícitamente en el diagrama de SPEC §3. | Mover `AppRoutes` a un archivo hoja (`app/routes.dart`) y aclarar en SPEC §3 que `application → app/di` está permitido (o invertirlo). |
| MED-025 | Bajo | coordinador | entorno | Flutter desde Git Bash falla: hook de *native assets* de `objective_c` sin comillas en la ruta del SDK (`D:\duo dinamico\…`) y caída del analysis server (`FormatException` en `LspByteStreamServerChannel`). Con PowerShell todo funciona. La ruta del SDK también contiene un espacio, no solo la del proyecto. | Documentar en SPEC §2/§12 que CI y QA en Windows usan PowerShell, o mover el SDK a una ruta ASCII sin espacios. |
| MED-026 | Bajo | backend (decisión del coordinador) | `application/game_controller.dart:188-192` | `abandon()` no hace nada si `moves == 0`. La partida abandonada sin tocar una ficha no queda en el historial ni cuenta como derrota; el diálogo (`exit_confirmation_dialog.dart:24`) dice que “se registrará como abandono”. Ver C2. | Decidir y alinear texto y código. |

## 6. Conflictos entre agentes

Puntos donde backend y frontend (o sus documentos) discrepan sobre un contrato. Se propone una resolución; **decide el coordinador**.

| # | Conflicto | Posición backend / SPEC | Posición frontend / DESIGN | Resolución recomendada |
|---|---|---|---|---|
| C1 | **Destino tras abandonar** | SPEC §9: `/game ──(ganar/perder/abandonar)──► /result`. Doc del controlador: “la UI navega a la pantalla de resultado cuando `result` deja de ser nulo” (`game_state.dart:26-27`). | DESIGN §4.3: al confirmar, `abandon()` y navegar a `/menu`; `result_page.dart:62-64` sí maneja “Partida abandonada”. | Ir a **`/menu`** al abandonar (el usuario acaba de decidir salir; ver un “Derrota” es redundante). El `ref.listen` debe ignorar `GameOutcome.abandoned` y SPEC §9 y el doc de `GameState.result` se corrigen. Elimina la carrera de MED-005. |
| C2 | **Abandono sin movimientos** | `abandon()` ignora la partida si `moves == 0` (`game_controller.dart:189`). | El diálogo promete registrar siempre un abandono (derrota). | Mantener “no se registra si `moves == 0`” (evita penalizar al adaptativo por entrar y salir) y cambiar el texto a “…si ya moviste fichas se registrará como abandono”; o bien registrar siempre. Elegir una. |
| C3 | **Ciclo de vida del estado del juego** | `GameController` persiste entre partidas (no `autoDispose`); `start()` conserva la sesión previa (`isStarting: true` + `copyWith`). | `GamePage` asume “sesión nula = cargando” y no lee `isStarting`/`failure`. | El backend reinicia el estado (`GameState(isStarting: true)`) al empezar; el frontend dibuja spinner/error según `isStarting`/`failure`. Ver MED-006. |
| C4 | **Contrato de toque inválido** | `invalidTapIndex` + `invalidTapCount`; el índice nunca se limpia (MED-007). | `BoardView` compara el índice con la posición *actual* de cada ficha (`board_view.dart:155-160`). | Cambiar a un único evento `({int index, int seq})?` limpiado tras la animación, o que la UI reaccione solo a `invalidTapCount` con `ref.listen`. |
| C5 | **Pausa antes del primer movimiento** | `PauseGame` solo `playing → paused` (`game_actions.dart:54`). | HUD ofrece “Pausa” siempre (DESIGN §4.3 no limita). | Deshabilitar “Pausa” fuera de `playing` (frontend). No cambiar el dominio: sin temporizador no hay nada que pausar. |
| C6 | **Dirección de dependencias / rutas** | SPEC §3: `presentation → application → domain`, `presentation → app/di`; `application` importa `app/di`. | La presentación importa `app/router.dart` para `AppRoutes`. | Mover `AppRoutes` a `app/routes.dart` (hoja) y reflejar en SPEC §3 que `application → app/di` es aceptado. |
| C7 | **Tokens documentados vs código** | SPEC §10: tablero ≤ 560, ficha 140 ms ✔. | DESIGN §3/§4.3: transición 200 ms, horizontal ≥ 720; código: 250 ms y 760 (`tokens.dart:11,18`). | Alinear DESIGN al código (más simple) o el código a DESIGN; actualizar el doc con el valor final. |
| C8 | **Nivel adaptativo con partida forzada** | `GameController.start(level:)` permite forzar un nivel y, con modo adaptativo, `_finish` guarda `decision.level` como `currentLevel` (`game_controller.dart:80-89`). | La UI nunca llama `start(level:)`. | Dejar la API pero no persistir `currentLevel` cuando `level != null`; o eliminar el parámetro hasta que haga falta (menos superficie de contrato). |

## 7. Qué quedó sin comprobar

- Cobertura de tests (`--coverage`) y el objetivo ≥ 90 % del dominio.
- Rendimiento medido (perfil) en 6×6 y de la mezcla (< 50 ms): solo revisión estática. `shuffler_test.dart:33-40` aserta < 50 ms de media en 6×6/800 y pasó dentro de `flutter test`.
- Comportamiento real de Playwright sobre el build QA (MED-001, MED-008 y MED-023 son riesgos inferidos del árbol de semántica de Flutter, verificado en tests, no en un navegador).
- Plataformas Android/iOS/Windows (sin SDK/VS, SPEC §13-2).
- `integration_test/` y `test_driver/` no existen todavía (Oleada 4).
