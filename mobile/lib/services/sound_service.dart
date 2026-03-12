import 'package:audioplayers/audioplayers.dart';

/// Manages all sound effects and ambient audio for StudentTrack Pro.
/// Uses bundled assets in assets/sounds/ for fully offline playback.
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final AudioPlayer _alarmPlayer = AudioPlayer();
  final AudioPlayer _ambientPlayer = AudioPlayer();
  bool _ambientPlaying = false;

  // Available ambient sounds — all bundled as assets (offline-first)
  static const ambientSounds = <String, String?>{
    'none': null,
    '🌧️ Rain': 'sounds/rain.mp3',
    '🌊 Ocean Breeze': 'sounds/ocean.mp3',
    '🔥 Fireplace': 'sounds/fireplace.mp3',
    '🌿 Forest': 'sounds/forest.mp3',
    '🎵 Lo-fi Guitar': 'sounds/lofi.mp3',
    '🐦 Birds': 'sounds/birds.mp3',
  };

  String _currentAmbient = 'none';
  String get currentAmbient => _currentAmbient;

  /// Play alarm sound when timer completes (uses gentle rain clip)
  Future<void> playAlarm() async {
    try {
      await _alarmPlayer.setReleaseMode(ReleaseMode.stop);
      await _alarmPlayer.play(AssetSource('sounds/alarm.mp3'), volume: 0.7);
      // Stop after 5 seconds (it's a long track, we just want a snippet)
      Future.delayed(const Duration(seconds: 5), () {
        _alarmPlayer.stop();
      });
    } catch (_) {
      // Graceful fail — user still gets haptic + notification
    }
  }

  /// Play a subtle tick sound (short snippet of fireplace)
  Future<void> playTick() async {
    try {
      await _alarmPlayer.setReleaseMode(ReleaseMode.stop);
      await _alarmPlayer.play(AssetSource('sounds/fireplace.mp3'), volume: 0.05);
      Future.delayed(const Duration(milliseconds: 200), () {
        _alarmPlayer.stop();
      });
    } catch (_) {}
  }

  /// Start ambient background sound (local asset, looped)
  Future<void> startAmbient(String name) async {
    _currentAmbient = name;
    await stopAmbient();
    final assetPath = ambientSounds[name];
    if (assetPath == null) return;
    try {
      await _ambientPlayer.setReleaseMode(ReleaseMode.loop);
      await _ambientPlayer.setVolume(0.3);
      await _ambientPlayer.play(AssetSource(assetPath));
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
