import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import '../../domain/exercises/exercise_catalog.dart';
import '../../domain/feedback/feedback_engine.dart';
import '../../domain/phoneme/arpabet.dart';
import '../../domain/phoneme/phoneme_dictionary.dart';
import '../../domain/phoneme/pronunciation_scorer.dart';
import '../../state/app_state.dart';
import '../widgets/result_panel.dart';

enum _Phase { idle, listening, scoring }

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key, required this.exercise});

  final Exercise exercise;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  late final AppState _app = context.read<AppState>();
  late final AppLifecycleListener _lifecycle;
  final Stopwatch _timer = Stopwatch();

  _Phase _phase = _Phase.idle;
  String _heard = '';
  double? _confidence;
  String? _message;
  bool _microphoneBlocked = false;
  int? _sessionId;
  PronunciationResult? _result;
  PronunciationFeedback? _feedback;

  @override
  void initState() {
    super.initState();
    _timer.start();
    // Time with the app in the background does not count as study time.
    _lifecycle = AppLifecycleListener(
      onPause: _timer.stop,
      onResume: _timer.start,
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _timer.stop();
    unawaited(_app.speech.cancel());
    unawaited(_closeSession());
    super.dispose();
  }

  Future<void> _closeSession() async {
    final session = _sessionId;
    if (session == null) return;
    await _app.practice.updateDuration(session, _timer.elapsed.inSeconds);
    await _app.refresh();
  }

  Future<void> _startListening() async {
    setState(() {
      _message = null;
      _microphoneBlocked = false;
      _heard = '';
      _confidence = null;
      _result = null;
      _feedback = null;
    });
    if (!await _app.speech.initialize()) {
      if (!mounted) return;
      final blocked = await Permission.microphone.isPermanentlyDenied;
      if (!mounted) return;
      setState(() {
        _microphoneBlocked = blocked;
        _message = blocked
            ? 'Micro đang bị chặn. Hãy bật quyền micro trong cài đặt của máy.'
            : 'Không dùng được nhận dạng giọng nói. Hãy cho phép dùng micro và '
                  'kiểm tra máy đã có dịch vụ nhận dạng giọng nói.';
      });
      return;
    }
    setState(() => _phase = _Phase.listening);
    await _app.speech.listen(
      onResult: _onResult,
      onStatus: _onStatus,
      onError: _onError,
    );
  }

  void _onResult(SpeechRecognitionResult result) {
    if (!mounted || _phase != _Phase.listening) return;
    setState(() {
      _heard = result.recognizedWords;
      if (result.hasConfidenceRating) _confidence = result.confidence;
    });
    if (result.finalResult) unawaited(_finish());
  }

  /// Some devices end without a final result; the delay gives one time to
  /// arrive before falling back to the last partial text.
  void _onStatus(String status) {
    if (status != 'done') return;
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (mounted && _phase == _Phase.listening) unawaited(_finish());
    });
  }

  void _onError(String code) {
    if (!mounted || _phase != _Phase.listening) return;
    setState(() {
      _phase = _Phase.idle;
      _message = switch (code) {
        'error_no_match' ||
        'error_speech_timeout' => 'Chưa nghe rõ. Hãy nói to hơn và thử lại.',
        'error_network' || 'error_network_timeout' || 'error_server' =>
          'Không kết nối được dịch vụ nhận dạng. Hãy kiểm tra Internet.',
        'error_audio_error' => 'Micro đang gặp lỗi. Hãy thử lại.',
        _ => 'Không nhận dạng được giọng nói ($code). Hãy thử lại.',
      };
    });
  }

  Future<void> _finish() async {
    if (_phase != _Phase.listening) return;
    if (_heard.trim().isEmpty) {
      setState(() {
        _phase = _Phase.idle;
        _message = 'Chưa nghe thấy gì. Hãy nhấn micro và đọc câu trên.';
      });
      return;
    }
    setState(() => _phase = _Phase.scoring);

    final result = _app.scorer.score(
      expectedText: widget.exercise.text,
      recognizedText: _heard,
      confidence: _confidence,
    );
    final session = _sessionId ??= await _app.practice.startSession(
      userId: _app.user!.id,
      exerciseId: widget.exercise.id,
    );
    await _app.practice.saveAttempt(session, result);
    await _app.practice.updateDuration(session, _timer.elapsed.inSeconds);
    await _app.refresh();

    if (!mounted) return;
    setState(() {
      _phase = _Phase.idle;
      _result = result;
      _feedback = buildFeedback(result, currentExerciseId: widget.exercise.id);
    });
  }

  String get _referenceIpa =>
      normalizeWords(widget.exercise.text)
          .map((word) => _app.dictionary.lookup(word).first.map(toIpa).join())
          .join(' ');

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final result = _result;
    final feedback = _feedback;
    return Scaffold(
      appBar: AppBar(title: Text(widget.exercise.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(widget.exercise.text, style: textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            '/$_referenceIpa/',
            style: textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: _MicButton(
              phase: _phase,
              onStart: _startListening,
              onStop: _app.speech.stop,
            ),
          ),
          const SizedBox(height: 12),
          if (_phase == _Phase.listening)
            Text(
              _heard.isEmpty ? 'Đang nghe, mời bạn đọc...' : _heard,
              textAlign: TextAlign.center,
            ),
          if (_message != null)
            Text(
              _message!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (_microphoneBlocked)
            const Center(
              child: TextButton(
                onPressed: openAppSettings,
                child: Text('Mở cài đặt'),
              ),
            ),
          if (result != null && feedback != null) ...[
            const SizedBox(height: 8),
            ResultPanel(
              result: result,
              feedback: feedback,
              onOpenExercise: (exercise) => Navigator.of(context)
                  .pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => PracticeScreen(exercise: exercise),
                    ),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({
    required this.phase,
    required this.onStart,
    required this.onStop,
  });

  final _Phase phase;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final listening = phase == _Phase.listening;
    if (phase == _Phase.scoring) {
      return const SizedBox(
        width: 88,
        height: 88,
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Column(
      children: [
        SizedBox(
          width: 88,
          height: 88,
          child: FilledButton(
            onPressed: listening ? onStop : onStart,
            style: FilledButton.styleFrom(
              shape: const CircleBorder(),
              padding: EdgeInsets.zero,
              backgroundColor: listening ? scheme.error : scheme.primary,
              foregroundColor: listening ? scheme.onError : scheme.onPrimary,
            ),
            child: Icon(listening ? Icons.stop : Icons.mic, size: 40),
          ),
        ),
        const SizedBox(height: 8),
        Text(listening ? 'Nhấn để dừng' : 'Nhấn để đọc'),
      ],
    );
  }
}
