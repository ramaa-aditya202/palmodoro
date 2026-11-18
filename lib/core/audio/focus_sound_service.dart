import 'package:audioplayers/audioplayers.dart';

import 'package:pomodoro_app/features/focus/models/focus_models.dart';

abstract class FocusSoundService {
  Future<void> play(FocusSoundSet soundSet, FocusSoundCue cue);
}

class AudioPlayersFocusSoundService implements FocusSoundService {
  AudioPlayersFocusSoundService();

  final AudioPlayer _player = AudioPlayer();

  @override
  Future<void> play(FocusSoundSet soundSet, FocusSoundCue cue) async {
    try {
      await _player.stop();
      await _player.play(
        AssetSource('sounds/${soundSet.storageValue}/${cue.fileName}'),
      );
    } catch (_) {
      // Audio playback errors on emulators without audio sinks are ignored.
    }
  }
}

class FakeFocusSoundService implements FocusSoundService {
  final List<FocusSoundCue> playedCues = [];
  final List<FocusSoundSet> playedSets = [];

  @override
  Future<void> play(FocusSoundSet soundSet, FocusSoundCue cue) async {
    playedSets.add(soundSet);
    playedCues.add(cue);
  }
}
