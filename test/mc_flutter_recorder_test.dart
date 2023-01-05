import 'package:flutter_test/flutter_test.dart';
import 'package:mc_flutter_recorder/mc_flutter_recorder_platform_interface.dart';
import 'package:mc_flutter_recorder/mc_flutter_recorder_method_channel.dart';
import 'package:mc_flutter_recorder/recorder_config.dart';
import 'package:mc_flutter_recorder/recorder_exception.dart';
import 'package:mc_flutter_recorder/recorder_info.dart';
import 'package:mc_flutter_recorder/recorder_state.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockMcFlutterRecorderPlatform 
    with MockPlatformInterfaceMixin
    implements McFlutterRecorderPlatform {

  @override
  Future<void> close() {
    // TODO: implement close
    throw UnimplementedError();
  }

  @override
  Future<RecorderState> getState() {
    // TODO: implement getState
    throw UnimplementedError();
  }

  @override
  Future<void> init(RecorderConfig config) {
    // TODO: implement init
    throw UnimplementedError();
  }

  @override
  Future<void> pause() {
    // TODO: implement pause
    throw UnimplementedError();
  }

  @override
  // TODO: implement recordErrorStream
  Stream<RecorderException> get recordErrorStream => throw UnimplementedError();

  @override
  // TODO: implement recordInfoStream
  Stream<RecorderInfo> get recordInfoStream => throw UnimplementedError();

  @override
  // TODO: implement recordStateStream
  Stream<RecorderState> get recordStateStream => throw UnimplementedError();

  @override
  Future<void> resume() {
    // TODO: implement resume
    throw UnimplementedError();
  }

  @override
  Future<void> start() {
    // TODO: implement start
    throw UnimplementedError();
  }

  @override
  Future<void> stop() {
    // TODO: implement stop
    throw UnimplementedError();
  }

  @override
  void updateRecordError(Map<String, dynamic> data) {
    // TODO: implement updateRecordError
  }

  @override
  void updateRecordInfo(Map<String, dynamic> data) {
    // TODO: implement updateRecordInfo
  }

  @override
  void updateRecordState(Map<String, dynamic> data) {
    // TODO: implement updateRecordState
  }
}

void main() {
  final McFlutterRecorderPlatform initialPlatform = McFlutterRecorderPlatform.instance;

  test('$MethodChannelMcFlutterRecorder is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelMcFlutterRecorder>());
  });
}
