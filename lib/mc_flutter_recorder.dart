
import 'package:mc_flutter_recorder/recorder_config.dart';
import 'package:mc_flutter_recorder/recorder_exception.dart';
import 'package:mc_flutter_recorder/recorder_info.dart';
import 'package:mc_flutter_recorder/recorder_state.dart';

import 'mc_flutter_recorder_platform_interface.dart';

/// MCFlutterRecorder is a Flutter plugin for recording audio.
/// Not only does it support basic recording functions,
/// but it also supports audio interruption policy control and other exception handling.
/// Only support wav format for now.
class MCFlutterRecorder {

  /// Get the current state of the recorder.
  Future<RecorderState> get currentState => McFlutterRecorderPlatform.instance.getState();

  /// Initialize the recorder with the given [RecorderConfig].
  Future<void> init(RecorderConfig config) {
    return McFlutterRecorderPlatform.instance.init(config);
  }

  /// Start recording.
  Future<void> start() {
    return McFlutterRecorderPlatform.instance.start();
  }

  /// Resume recording.
  Future<void> resume() {
    return McFlutterRecorderPlatform.instance.resume();
  }

  /// Pause recording.
  Future<void> pause() {
    return McFlutterRecorderPlatform.instance.pause();
  }

  /// Stop recording.
  Future<void> stop() {
    return McFlutterRecorderPlatform.instance.stop();
  }

  /// Finalize the recording.
  Future<void> close() {
    return McFlutterRecorderPlatform.instance.close();
  }

  /// Stream of [RecorderInfo]s.
  Stream<RecorderInfo> recorderInfoStream() async* {
    yield* McFlutterRecorderPlatform.instance.recordInfoStream;
  }

  /// Stream of [RecorderException]s.
  Stream<RecorderException> recorderErrorStream() async* {
    yield* McFlutterRecorderPlatform.instance.recordErrorStream;

  }

  /// Stream of [RecorderState]s.
  Stream<RecorderState> recorderStateStream() async* {
    yield await McFlutterRecorderPlatform.instance.getState();
    yield* McFlutterRecorderPlatform.instance.recordStateStream;
  }
}
