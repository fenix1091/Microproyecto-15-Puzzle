import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

void main() {
  final outDir = Directory('assets/sounds');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  File('assets/sounds/move.wav').writeAsBytesSync(
    _generateWav(
      durationSeconds: 0.08,
      generator: (t, duration) {
        // Short wooden click / pluck sound: 520 Hz fading fast
        final env = math.exp(-t * 35.0);
        return math.sin(2 * math.pi * 520 * t) * env;
      },
    ),
  );

  File('assets/sounds/invalid.wav').writeAsBytesSync(
    _generateWav(
      durationSeconds: 0.12,
      generator: (t, duration) {
        // Low dull thud / buzz: 160 Hz square-ish wave decaying
        final env = math.exp(-t * 20.0);
        final sine = math.sin(2 * math.pi * 160 * t);
        return (sine > 0 ? 0.8 : -0.8) * env;
      },
    ),
  );

  File('assets/sounds/win.wav').writeAsBytesSync(
    _generateWav(
      durationSeconds: 0.5,
      generator: (t, duration) {
        // Rising major chord arpeggio: C5 (523), E5 (659), G5 (784), C6 (1046)
        final noteIndex = (t / 0.1).floor().clamp(0, 3);
        final freqs = [523.25, 659.25, 783.99, 1046.50];
        final f = freqs[noteIndex];
        final noteT = t - (noteIndex * 0.1);
        final env = math.exp(-noteT * 10.0);
        return math.sin(2 * math.pi * f * t) * env * 0.8;
      },
    ),
  );

  File('assets/sounds/lose.wav').writeAsBytesSync(
    _generateWav(
      durationSeconds: 0.4,
      generator: (t, duration) {
        // Descending sad tone: 320 Hz down to 140 Hz
        final f = 320.0 - (180.0 * (t / duration));
        final env = 1.0 - (t / duration);
        return math.sin(2 * math.pi * f * t) * env * 0.8;
      },
    ),
  );

  // ignore: avoid_print
  print('Synthesized 4 WAV sound files in assets/sounds/');
}

Uint8List _generateWav({
  required double durationSeconds,
  required double Function(double t, double duration) generator,
  int sampleRate = 22050,
}) {
  final numSamples = (sampleRate * durationSeconds).round();
  final dataSize = numSamples * 2; // 16-bit mono
  final fileSize = 36 + dataSize;

  final bytes = ByteData(44 + dataSize);

  // RIFF header
  bytes.setUint8(0, 0x52); // R
  bytes.setUint8(1, 0x49); // I
  bytes.setUint8(2, 0x46); // F
  bytes.setUint8(3, 0x46); // F
  bytes.setUint32(4, fileSize, Endian.little);
  bytes.setUint8(8, 0x57); // W
  bytes.setUint8(9, 0x41); // A
  bytes.setUint8(10, 0x56); // V
  bytes.setUint8(11, 0x45); // E

  // 'fmt ' chunk
  bytes.setUint8(12, 0x66); // f
  bytes.setUint8(13, 0x6D); // m
  bytes.setUint8(14, 0x74); // t
  bytes.setUint8(15, 0x20); // ' '
  bytes.setUint32(16, 16, Endian.little); // SubChunk1Size (16 for PCM)
  bytes.setUint16(20, 1, Endian.little); // AudioFormat (1 = PCM)
  bytes.setUint16(22, 1, Endian.little); // NumChannels (1 = Mono)
  bytes.setUint32(24, sampleRate, Endian.little); // SampleRate
  bytes.setUint32(28, sampleRate * 2, Endian.little); // ByteRate (SampleRate * 1 * 16/8)
  bytes.setUint16(32, 2, Endian.little); // BlockAlign (1 * 16/8)
  bytes.setUint16(34, 16, Endian.little); // BitsPerSample

  // 'data' chunk
  bytes.setUint8(36, 0x64); // d
  bytes.setUint8(37, 0x61); // a
  bytes.setUint8(38, 0x74); // t
  bytes.setUint8(39, 0x61); // a
  bytes.setUint32(40, dataSize, Endian.little);

  for (var i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final sampleValue = generator(t, durationSeconds).clamp(-1.0, 1.0);
    final intSample = (sampleValue * 32767).round().clamp(-32768, 32767);
    bytes.setInt16(44 + (i * 2), intSample, Endian.little);
  }

  return bytes.buffer.asUint8List();
}
