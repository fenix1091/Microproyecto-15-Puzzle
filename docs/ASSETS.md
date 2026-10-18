# Assets del proyecto

> Cómo están implementados los assets (sonidos, iconos, fuentes) y cómo se comportan dentro de `lib/`.
> Verificado contra el código y la build web del commit actual. Android, iOS y Windows no se pudieron probar en esta máquina (ver [§9](#9-limitaciones-conocidas)).

## 1. Resumen

El proyecto solo tiene **un tipo de asset propio: 4 sonidos cortos**. Todo lo demás se resuelve por código.

| Asset | Dónde vive | Quién lo usa |
|---|---|---|
| 4 sonidos `.wav` (48.7 KB en total) | `assets/sounds/` | `lib/shared/services/audio_feedback_service.dart` |
| Iconos de la interfaz | fuente **Material Icons** que trae Flutter (`Icons.*`) | todas las páginas de `lib/features/*/presentation/` |
| Logo animado | **no es una imagen**: está dibujado con widgets | `lib/shared/widgets/animated_logo.dart` |
| Íconos de la app (launcher, favicon) | `web/`, `android/…/mipmap-*`, `ios/…/AppIcon.appiconset` | el sistema operativo o el navegador, fuera de `lib/` |
| Colores y tipografía | tokens en código (`ColorScheme.fromSeed`), sin fuentes propias | `lib/app/theme/` |

No hay imágenes (`.png`, `.svg`), ni fuentes personalizadas, ni animaciones Lottie en el proyecto.

## 2. Los sonidos

| Archivo | Evento | Duración | Tamaño | Cómo suena |
|---|---|---|---|---|
| `move.wav` | una ficha se mueve | 0.08 s | 3.5 KB | clic corto de 520 Hz que se apaga rápido |
| `invalid.wav` | toque sobre una ficha que no se puede mover | 0.12 s | 5.2 KB | golpe grave de 160 Hz (onda cuadrada) |
| `win.wav` | el tablero queda resuelto | 0.50 s | 21.6 KB | arpegio ascendente do-mi-sol-do (523, 659, 784, 1046 Hz) |
| `lose.wav` | se acaba el tiempo | 0.40 s | 17.3 KB | tono descendente de 320 a 140 Hz |

Formato de todos: **WAV PCM, mono, 16 bits, 22 050 Hz**. Son sintéticos: no hay grabaciones ni audio con licencia de terceros.

### Cómo se generaron

`tool/gen_sounds.dart` calcula cada onda (seno con envolvente exponencial) y escribe el archivo WAV a mano, con la cabecera RIFF incluida. No usa ninguna dependencia. Para regenerarlos, desde la raíz del proyecto:

```powershell
cd D:\dev\sliding_puzzle
dart run tool/gen_sounds.dart
```

Importante: la ruta de salida `assets/sounds` es **relativa**, así que el comando solo funciona desde la raíz. Sobrescribe los cuatro archivos.

## 3. Cómo llegan a la app

### Declaración

En `pubspec.yaml`:

```yaml
flutter:
  uses-material-design: true      # incluye la fuente Material Icons
  assets:
    - assets/sounds/              # toda la carpeta, sin subcarpetas
```

Declarar una carpeta incluye todos sus archivos, pero **no sus subcarpetas**: si algún día se crea `assets/sounds/ui/`, hay que añadirla como otra línea.

### Empaquetado

`flutter build` copia los archivos y los lista en `AssetManifest.bin`. En la build web quedan en:

```
build/web/assets/assets/sounds/move.wav
                              invalid.wav
                              win.wav
                              lose.wav
```

El `assets/` doble es normal: el primero es la carpeta de assets de Flutter y el segundo es la ruta declarada en el pubspec.

### Resolución de rutas

El código nunca escribe `assets/sounds/move.wav`, sino `'sounds/move.wav'`. El paquete `audioplayers` antepone solo el prefijo `assets/` (`AudioCache.prefix`, valor por defecto). Por eso:

- Se puede mover la carpeta sin tocar las rutas, siempre que el prefijo siga siendo `assets/`.
- Una ruta mal escrita **no rompe la app**: el servicio atrapa el error y el sonido simplemente no suena (ver [§5](#5-reglas-de-comportamiento)).

## 4. Dónde intervienen en `lib/`

```
lib/
├─ main.dart                                    ← registra el servicio real
├─ core/services/feedback_service.dart          ← contrato + versión "muda" (Noop)
├─ shared/services/audio_feedback_service.dart  ← implementación real (sonido + vibración)
├─ app/di/providers.dart                        ← feedbackServiceProvider (por defecto: Noop)
├─ app/app.dart                                 ← detecta el primer gesto del usuario (web)
├─ features/splash/…/splash_page.dart           ← precarga los sonidos
├─ features/settings/application/settings_controller.dart  ← aplica sonido/vibración activados
├─ features/settings/presentation/settings_page.dart       ← los interruptores
└─ features/game/application/game_controller.dart          ← dispara los eventos
```

### El patrón

Se aplica el mismo patrón que a los repositorios: **la lógica depende de una interfaz, no del paquete de audio**.

```
GameController / SettingsController / SplashPage
            │  usan
            ▼
   FeedbackService  (interfaz en core/)          ← ningún import de audioplayers aquí
      ▲                         ▲
      │                         │
NoopFeedbackService      AudioFeedbackService    ← audioplayers + HapticFeedback
(por defecto, no hace nada)  (la inyecta main.dart)
```

- `feedbackServiceProvider` devuelve `NoopFeedbackService` por defecto.
- `main.dart` lo sustituye por `AudioFeedbackService()` con `overrideWithValue`.
- Los tests no tocan `main.dart`, así que **nunca cargan audio**: usan el Noop o un falso propio.

La interfaz tiene seis métodos: `preload()`, `configure(sound:, vibration:)`, `tileMoved()`, `invalidMove()`, `gameWon()` y `gameLost()`.

## 5. Reglas de comportamiento

### Línea de tiempo

1. **Arranque.** `main()` crea `AudioFeedbackService()`. Todavía no se crea ningún reproductor ni se carga ningún archivo.
2. **Splash.** `SplashPage` ejecuta `Future.wait([settings, feedback.preload()])`. Si la precarga falla, el error se ignora y el splash continúa. Se espera como mínimo `splashMinDuration` (~1.2 s).
3. **Ajustes.** Al cargar los ajustes, `SettingsController.build()` llama a `configure(sound, vibration)`. Cada vez que el usuario cambia un interruptor, `change()` vuelve a llamarlo **antes** de guardar en disco, así que el efecto es inmediato.
4. **Partida.** `GameController` pide el efecto en cada evento.

### Evento → sonido y vibración

| Evento (`GameController`) | Método | Sonido | Vibración (`HapticFeedback`) |
|---|---|---|---|
| ficha movida | `tileMoved()` | `move.wav` | `lightImpact()` |
| toque inválido | `invalidMove()` | `invalid.wav` | `heavyImpact()` |
| tablero resuelto | `gameWon()` | `win.wav` | `vibrate()` |
| tiempo agotado | `gameLost()` | `lose.wav` | `mediumImpact()` |

Los tres primeros los dispara el toque del jugador. `gameLost()` lo dispara el **temporizador**, no un gesto.

### Reglas

| Regla | Detalle |
|---|---|
| **Sonido y vibración son independientes** | `sound: false` no apaga la vibración, ni al revés. Los dos valores se guardan en `SharedPreferences` (`settings.soundEnabled`, `settings.vibrationEnabled`). |
| **Nunca lanza excepciones** | Cada llamada a audio y a vibración está en un `try/catch`. El audio es opcional: si falla, el juego sigue. |
| **Un solo reproductor** | Se crea una vez (perezosamente) y se reutiliza. Antes de cada sonido hace `stop()` y luego `play()`, así que **un sonido nuevo corta al anterior**. |
| **Modo `lowLatency`** | Se pide para sonidos cortos. Según la documentación de `audioplayers`, en este modo no se disparan eventos de fin ni de posición, y el código es responsable de detener el reproductor. Por eso se hace `stop()` antes de cada reproducción. |
| **Autoplay en web** | Los navegadores bloquean el audio hasta que el usuario interactúa. El servicio arranca con `_hasUserGesture = !kIsWeb` (verdadero fuera de la web). En la web, `app.dart` envuelve la app en un `Listener.onPointerDown` que llama a `recordUserGesture()`. Mientras no haya un primer toque, `_playSound` no hace nada. |
| **`gameLost()` no cuenta como gesto** | A diferencia de los otros tres, no marca `_hasUserGesture = true`, porque lo dispara un temporizador y no el usuario. |

## 6. Diferencias por plataforma

| | Web | Android / iOS | Escritorio (Windows) |
|---|---|---|---|
| **Precarga** | `preload()` **no hace nada**; el navegador descarga cada WAV la primera vez que suena | `AudioCache.loadAll` copia los 4 archivos a un directorio temporal, para que el reproductor nativo los lea como archivos locales | igual que móvil |
| **Primer sonido** | puede tener un pequeño retraso (descarga + decodificación) | inmediato | inmediato |
| **Autoplay** | bloqueado hasta el primer toque | sin restricción | sin restricción |
| **Vibración** | sin efecto | sí, vía `HapticFeedback` | sin efecto |
| **Ruta del archivo** | `assets/assets/sounds/*.wav` (URL relativa) | dentro del paquete de la app | dentro de `data/flutter_assets/` |

## 7. Iconos, fuentes y logo

### Iconos de la interfaz

Todos son `Icons.*` (Material Icons). No hay ningún `.svg` ni `.png` en la UI. El compilador hace **tree-shaking** de la fuente: en la build actual `MaterialIcons-Regular.otf` pesa **12.8 KB** en lugar de ~1.6 MB, porque solo conserva los glifos usados.

`cupertino_icons` está en el `pubspec.yaml` pero **ninguna parte de `lib/` lo usa**; el tree-shaking lo reduce a 1.4 KB, así que su costo es mínimo. Se puede quitar sin consecuencias.

### Logo animado

`AnimatedLogo` no carga ninguna imagen. Dibuja una cuadrícula de 2×2 con tres fichas (`1`, `5`, `★`) y un hueco, usando contenedores con colores del `ColorScheme`. Por eso:

- se adapta solo a los temas claro y oscuro;
- escala a cualquier tamaño (`size`) sin perder nitidez;
- no añade peso a la build;
- respeta `reduceMotion` y `MediaQuery.disableAnimations`: sin animación, aparece ya completo.

### Iconos de la aplicación

Son los del sistema operativo o el navegador, fuera de `lib/`:

| Plataforma | Archivos |
|---|---|
| Web | `web/favicon.png`, `web/icons/Icon-192.png`, `Icon-512.png`, `Icon-maskable-192.png`, `Icon-maskable-512.png` |
| Android | `android/app/src/main/res/mipmap-*/` |
| iOS | `ios/Runner/Assets.xcassets/AppIcon.appiconset` |

**Siguen siendo los de la plantilla de `flutter create`**: git no registra ningún cambio en ellos desde el primer commit. Lo único personalizado es `web/manifest.json` (nombre "Sliding Puzzle", colores `#2563EB` y descripción) y `web/index.html` (título y descripción).

## 8. Tests

| Nivel | Qué hace con los assets |
|---|---|
| Unitarios y de widgets | Usan `NoopFeedbackService` o un falso que registra las llamadas. **No cargan ni reproducen audio.** Comprueban que cada evento llama al método correcto y que `configure` recibe los valores de los ajustes. |
| Integración (`flutter drive`) | Monta `SlidingPuzzleApp` sin el override de `main.dart`, así que usa el Noop. |
| Playwright (e2e) | Ejecuta la app real, con `AudioFeedbackService`. Solo verifica que el interruptor de sonido se guarda y persiste tras recargar; **no comprueba que suene algo**. |

Hoy no hay ninguna prueba que reproduzca realmente un sonido.

## 9. Limitaciones conocidas

1. **Un sonido corta al anterior.** Con un solo reproductor, el último en pedirse gana. Caso real: el movimiento que resuelve el tablero llama a `tileMoved()` y enseguida a `gameWon()`, así que `move.wav` se corta casi de inmediato o no llega a oírse. Es fácil de arreglar con un `AudioPool` o un reproductor por sonido.
2. **Primer sonido con retraso en web**, porque `preload()` no hace nada allí.
3. **Sin sonido hasta el primer toque en web**, por la política de autoplay. Si el usuario navega solo con teclado, el servicio no lo detecta como gesto hasta el primer movimiento de ficha.
4. **Vibración en Android sin verificar.** `AndroidManifest.xml` no declara el permiso `VIBRATE` y no se pudo probar en un dispositivo. Los métodos de `HapticFeedback` usan la retroalimentación háptica del sistema, que normalmente no lo requiere, pero hay que confirmarlo.
5. **Android, iOS y Windows no se compilaron** (faltan el Android SDK y Visual Studio). El comportamiento de la [§6](#6-diferencias-por-plataforma) para esas plataformas sale de leer el código de `audioplayers`, no de ejecutarlo.
6. **Iconos de la app sin personalizar** (ver [§7](#iconos-de-la-aplicación)).

## 10. Cómo añadir o cambiar un asset

### Un sonido nuevo

1. Colocar el `.wav` en `assets/sounds/` (o añadirlo a `tool/gen_sounds.dart` y regenerar). Debe ser corto, mono y de ~22 kHz.
2. No hace falta tocar el `pubspec.yaml`: la carpeta ya está declarada.
3. Añadir un método a `FeedbackService` (`core/services/feedback_service.dart`) y a `NoopFeedbackService`.
4. Implementarlo en `AudioFeedbackService` llamando a `_playSound('sounds/nuevo.wav')`, y añadir la ruta a la lista de `preload()`.
5. Llamarlo desde el controlador que corresponda. Si el método es de la interfaz, los tests con falsos dejan de compilar hasta que añadan el método: es la señal para actualizarlos.

### Una imagen o una fuente

1. Crear la carpeta (`assets/images/`, `assets/fonts/`) y declararla en `pubspec.yaml` bajo `flutter: assets:` (las fuentes van bajo `fonts:`).
2. Cargar con `Image.asset('assets/images/x.png')`. Aquí la ruta sí lleva `assets/`, porque no hay prefijo automático como en `audioplayers`.
3. Si es una fuente, referenciarla en `ThemeData(fontFamily: …)` dentro de `lib/app/theme/app_theme.dart`.
4. Si la imagen aparece en un widget que se prueba, usar un `AssetBundle` falso en el test para no depender del archivo.

### Cambiar los iconos de la app

Generar los PNG con una herramienta como `flutter_launcher_icons` y sustituir los archivos de la tabla de la [§7](#iconos-de-la-aplicación). Es un cambio solo de plataforma: no toca `lib/`.
