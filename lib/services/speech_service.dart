import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Thin wrapper around the platform speech recognizer, forced to English.
class SpeechService {
  final SpeechToText _speech = SpeechToText();
  String? _localeId;

  void Function(String status)? _onStatus;
  void Function(String message)? _onError;

  /// Returns false if the permission is denied or no recognizer is installed.
  Future<bool> initialize() async {
    final available = await _speech.initialize(
      onStatus: (status) => _onStatus?.call(status),
      onError: (error) => _onError?.call(error.errorMsg),
    );
    if (available) _localeId ??= await _englishLocale();
    return available;
  }

  Future<String> _englishLocale() async {
    final locales = await _speech.locales();
    String normalized(String id) => id.replaceAll('_', '-').toLowerCase();
    for (final locale in locales) {
      if (normalized(locale.localeId) == 'en-us') return locale.localeId;
    }
    for (final locale in locales) {
      if (normalized(locale.localeId).startsWith('en')) return locale.localeId;
    }
    return 'en_US';
  }

  Future<void> listen({
    required void Function(SpeechRecognitionResult result) onResult,
    required void Function(String status) onStatus,
    required void Function(String message) onError,
  }) async {
    _onStatus = onStatus;
    _onError = onError;
    await _speech.listen(
      onResult: onResult,
      listenOptions: SpeechListenOptions(
        localeId: _localeId,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
        listenMode: ListenMode.dictation,
        partialResults: true,
        cancelOnError: true,
      ),
    );
  }

  Future<void> stop() => _speech.stop();

  Future<void> cancel() => _speech.cancel();
}
