import 'package:audioplayers/audioplayers.dart';

/// Manages all sound effects and ambient audio for StudentTrack Pro.
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final AudioPlayer _alarmPlayer = AudioPlayer();
  final AudioPlayer _ambientPlayer = AudioPlayer();
  bool _ambientPlaying = false;

  // Available ambient sounds (URL-based, royalty-free from Pixabay)
  static const ambientSounds = <String, String?>{
    'none': null,
    '🌧️ Rain': 'https://cdn.pixabay.com/audio/2022/05/13/audio_257112f4be.mp3',
    '🌊 Ocean': 'https://cdn.pixabay.com/audio/2024/11/04/audio_014024c7d0.mp3',
    '🔥 Fireplace': 'https://cdn.pixabay.com/audio/2024/09/24/audio_f2b2dbdb38.mp3',
    '🌿 Forest': 'https://cdn.pixabay.com/audio/2022/03/10/audio_3258a498a0.mp3',
    '☕ Café': 'https://cdn.pixabay.com/audio/2024/06/11/audio_3bab10ca38.mp3',
  };

  // Alarm sounds (URL-based so no local asset files needed)
  static const _alarmUrl = 'https://cdn.pixabay.com/audio/2024/02/19/audio_e4043e6d8f.mp3';
  static const _tickUrl = 'https://cdn.pixabay.com/audio/2022/03/24/audio_78d2e2b77c.mp3';

  String _currentAmbient = 'none';
  String get currentAmbient => _currentAmbient;

  /// Play alarm sound when timer completes
  Future<void> playAlarm() async {
    try {
      await _alarmPlayer.setReleaseMode(ReleaseMode.stop);
      await _alarmPlayer.play(UrlSource(_alarmUrl), volume: 0.7);
    } catch (_) {
      // Graceful fail — user still gets haptic + notification
    }
  }

  /// Play a subtle tick sound
  Future<void> playTick() async {
    try {
      await _alarmPlayer.setReleaseMode(ReleaseMode.stop);
      await _alarmPlayer.play(UrlSource(_tickUrl), volume: 0.08);
    } catch (_) {}
  }

  /// Start ambient background sound
  Future<void> startAmbient(String name) async {
    _currentAmbient = name;
    await stopAmbient();
    final url = ambientSounds[name];
    if (url == null) return;
    try {
      await _ambientPlayer.setReleaseMode(ReleaseMode.loop);
      await _ambientPlayer.setVolume(0.3);
      await _ambientPlayer.play(UrlSource(url));
      _ambientPlaying = true;
    } catch (_) {}
  }

  /// Stop ambient sound
  Future<void> stopAmbient() async {
    if (_ambientPlaying) {
      await _ambientPlayer.stop();
      _ambientPlaying = false;
    }
  }

  /// Set ambient volume (0.0 - 1.0)
  Future<void> setAmbientVolume(double vol) async {
    await _ambientPlayer.setVolume(vol);
  }

  bool get isAmbientPlaying => _ambientPlaying;

  Future<void> dispose() async {
    await _alarmPlayer.dispose();
    await _ambientPlayer.dispose();
  }
}
