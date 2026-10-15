import 'dart:math';
import 'package:flutter/foundation.dart';

/// Utilitas media yang aman untuk Flutter Web & mobile (tanpa dart:io).
class MediaUtils {
  /// Membungkus data PCM 16-bit little-endian menjadi file WAV valid
  /// agar dapat dibaca librosa / soundfile di server AI Python.
  static Uint8List pcm16ToWav(
    Uint8List pcm, {
    int sampleRate = 16000,
    int channels = 1,
  }) {
    final int byteRate = sampleRate * channels * 2;
    final int dataSize = pcm.length;
    final ByteData header = ByteData(44);

    void writeAscii(int offset, String text) {
      for (int i = 0; i < text.length; i++) {
        header.setUint8(offset + i, text.codeUnitAt(i));
      }
    }

    writeAscii(0, 'RIFF');
    header.setUint32(4, 36 + dataSize, Endian.little);
    writeAscii(8, 'WAVE');
    writeAscii(12, 'fmt ');
    header.setUint32(16, 16, Endian.little); // ukuran subchunk fmt
    header.setUint16(20, 1, Endian.little); // PCM
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, channels * 2, Endian.little); // block align
    header.setUint16(34, 16, Endian.little); // bit per sampel
    writeAscii(36, 'data');
    header.setUint32(40, dataSize, Endian.little);

    final out = Uint8List(44 + dataSize);
    out.setRange(0, 44, header.buffer.asUint8List());
    out.setRange(44, 44 + dataSize, pcm);
    return out;
  }

  /// WAV sintetis (nada ~200 Hz) sebagai pengganti bila mikrofon tidak tersedia,
  /// sehingga server AI tetap menerima berkas audio yang valid.
  static Uint8List generateSyntheticWav({
    int sampleRate = 16000,
    double durationSeconds = 1.5,
  }) {
    final int numSamples = (sampleRate * durationSeconds).toInt();
    final ByteData pcm = ByteData(numSamples * 2);
    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      final double wave = 0.3 * sin(2 * pi * 200 * t) + 0.15 * sin(2 * pi * 400 * t);
      pcm.setInt16(i * 2, (wave * 32767).toInt().clamp(-32768, 32767), Endian.little);
    }
    return pcm16ToWav(pcm.buffer.asUint8List(), sampleRate: sampleRate);
  }
}
