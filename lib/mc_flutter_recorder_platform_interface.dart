import 'package:mc_flutter_recorder/recorder_config.dart';
import 'package:mc_flutter_recorder/recorder_exception.dart';
import 'package:mc_flutter_recorder/recorder_info.dart';
import 'package:mc_flutter_recorder/recorder_state.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'mc_flutter_recorder_method_channel.dart';

abstract class McFlutterRecorderPlatform extends PlatformInterface {
  /// Constructs a McFlutterRecorderPlatform.
  McFlutterRecorderPlatform() : super(token: _token);

  static final Object _token = Object();

  static McFlutterRecorderPlatform _instance = MethodChannelMcFlutterRecorder();

  /// The default instance of [McFlutterRecorderPlatform] to use.
  ///
  /// Defaults to [MethodChannelMcFlutterRecorder].
  static McFlutterRecorderPlatform get instance => _instance;
  
  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [McFlutterRecorderPlatform] when
  /// they register themselves.
  static set instance(McFlutterRecorderPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Stream<RecorderState> get recordStateStream => throw UnimplementedError('recordStateStream has not been implemented.');
  Stream<RecorderInfo> get recordInfoStream => throw UnimplementedError('recordInfoStream has not been implemented.');
  Stream<RecorderException> get recordErrorStream => throw UnimplementedError('_recordErrorStream has not been implemented.');

  Future<void> init(RecorderConfig config) {
    throw UnimplementedError('init() has not been implemented.');
  }

  Future<void> start() {
    throw UnimplementedError('start() has not been implemented.');
  }

  Future<void> resume() {
    throw UnimplementedError('resume() has not been implemented.');
  }

  Future<void> pause() {
    throw UnimplementedError('pause() has not been implemented.');
  }

  Future<void> stop() {
    throw UnimplementedError('stop() has not been implemented.');
  }

  Future<void> close() {
    throw UnimplementedError('close() has not been implemented.');
  }

  Future<RecorderState> getState() {
    throw UnimplementedError('getState() has not been implemented.');
  }

  void updateRecordInfo(Map<String, dynamic> data) {
    throw UnimplementedError('updateRecordInfo() has not been implemented.');
  }

  void updateRecordError(Map<String, dynamic> data) {
    throw UnimplementedError('updateRecordError() has not been implemented.');
  }

  void updateRecordState(Map<String, dynamic> data) {
    throw UnimplementedError('updateRecordState() has not been implemented.');
  }
}
