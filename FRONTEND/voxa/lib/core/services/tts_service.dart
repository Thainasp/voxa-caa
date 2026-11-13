import 'package:flutter_tts/flutter_tts.dart';

/// Síntese de voz nativa (RF01). Usa o motor de TTS do Android/iOS em pt-BR.
class TtsService {
  TtsService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  Future<void>? _setup;

  Future<void> _ensureSetup() => _setup ??= () async {
    await _tts.setLanguage('pt-BR');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }();

  /// Fala o texto, interrompendo a fala anterior (toques rápidos não
  /// acumulam uma fila de áudio).
  Future<void> speak(String text) async {
    final phrase = text.trim();
    if (phrase.isEmpty) return;
    await _ensureSetup();
    await _tts.stop();
    await _tts.speak(phrase);
  }

  Future<void> stop() => _tts.stop();
}
