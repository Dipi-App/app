import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../features/settings/state/settings_providers.dart';

/// Thin wrapper around the device text-to-speech engine.
///
/// Persian works only when the phone has a Persian voice installed. When it
/// does not, [available] resolves to false and every speaker button silently
/// disappears, so the app never shows a button that does nothing.
abstract final class VoiceHints {
  static final FlutterTts _tts = FlutterTts();
  static bool? _available;
  static bool _configured = false;

  static Future<bool> available() async {
    if (_available != null) return _available!;
    try {
      final languages = await _tts.getLanguages;
      final hasPersian = languages is List &&
          languages.any(
            (language) => language.toString().toLowerCase().startsWith('fa'),
          );
      if (!hasPersian) {
        _available = false;
        return false;
      }
      if (!_configured) {
        await _tts.setLanguage('fa-IR');
        await _tts.setSpeechRate(0.42);
        await _tts.setPitch(1.0);
        _configured = true;
      }
      _available = true;
    } catch (_) {
      _available = false;
    }
    return _available!;
  }

  static Future<void> speak(String text) async {
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {
      // Best effort only.
    }
  }

  static Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {
      // Best effort only.
    }
  }
}

/// A small speaker button that reads [text] aloud in Persian. Hidden when the
/// user turned voice hints off or when the device has no Persian voice.
class VoiceHintButton extends ConsumerStatefulWidget {
  const VoiceHintButton({
    super.key,
    required this.text,
    this.tooltip = 'خواندن با صدا',
    this.compact = false,
  });

  final String text;
  final String tooltip;
  final bool compact;

  @override
  ConsumerState<VoiceHintButton> createState() => _VoiceHintButtonState();
}

class _VoiceHintButtonState extends ConsumerState<VoiceHintButton> {
  bool _speaking = false;

  @override
  void dispose() {
    VoiceHints.stop();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_speaking) {
      await VoiceHints.stop();
      if (mounted) setState(() => _speaking = false);
      return;
    }
    setState(() => _speaking = true);
    await VoiceHints.speak(widget.text);
    if (mounted) setState(() => _speaking = false);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(
      settingsControllerProvider.select(
        (settings) => settings.value?.voiceHintsEnabled ?? true,
      ),
    );
    if (!enabled) return const SizedBox.shrink();

    return FutureBuilder<bool>(
      future: VoiceHints.available(),
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();
        return IconButton(
          tooltip: _speaking ? 'توقف' : widget.tooltip,
          onPressed: _toggle,
          visualDensity: widget.compact
              ? VisualDensity.compact
              : VisualDensity.standard,
          icon: Icon(
            _speaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
          ),
        );
      },
    );
  }
}
