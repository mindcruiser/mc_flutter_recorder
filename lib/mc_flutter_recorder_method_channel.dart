import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mc_flutter_recorder/recorder_config.dart';
import 'package:mc_flutter_recorder/recorder_exception.dart';
import 'package:mc_flutter_recorder/recorder_info.dart';
import 'package:mc_flutter_recorder/recorder_state.dart';

import 'mc_flutter_recorder_platform_interface.dart';

/// An implementation of [McFlutterRecorderPlatform] that uses method channels.
class MethodChannelMcFlutterRecorder extends McFlutterRecorderPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('mc_flutter_recorder');

  final StreamController<RecorderState> _recordStateController = StreamController.broadcast();
  final StreamController<RecorderException> _recordErrorController = StreamController.broadcast();
  final StreamController<RecorderInfo> _recordInfoController = StreamController.broadcast();

  StreamSink<RecorderInfo> get _recordInfoSink => _recordInfoController.sink;

  StreamSink<RecorderState> get _recordStateSink => _recordStateController.sink;

  StreamSink<RecorderException> get _recordErrorSink => _recordErrorController.sink;

  @override
  Stream<RecorderState> get recordStateStream => _recordStateController.stream;

  @override
  Stream<RecorderInfo> get recordInfoStream => _recordInfoController.stream;

  @override
  Stream<RecorderException> get recordErrorStream => _recordErrorController.stream;

  MethodChannelMcFlutterRecorder() {
    methodChannel.setMethodCallHandler(handleMethod);
  }

  Future<dynamic> handleMethod(MethodCall call) async {
    try {
      switch (call.method) {
        case "updateRecordInfo":
          updateRecordInfo(Map.from(call.arguments));
          break;
        case "updateRecordError":
          updateRecordError(Map.from(call.arguments));
          break;
        case "updateRecordState":
          updateRecordState(Map.from(call.arguments));
          break;
        default:
          throw UnsupportedError("method not supported ${call.method} ${call.arguments}");
      }
    } catch (e) {
      print(e);
      rethrow;
    }

  }


  @override
  Future<void> init(RecorderConfig config) async {
    await methodChannel.invokeMethod<void>("init", config.toData());
  }

  @override
  Future<void> start() async {
    await methodChannel.invokeMethod<void>("start");
  }

  @override
  Future<void> pause() async {
    await methodChannel.invokeMethod<void>("pause");
  }

  @override
  Future<void> resume() async {
    await methodChannel.invokeMethod<void>("resume");
  }

  @override
  Future<void> stop() async {
    await methodChannel.invokeMethod<void>("stop");
  }

  @override
  Future<void> close() async {
    await methodChannel.invokeMethod<void>("close");
  }


  @override
  Future<RecorderState> getState() async {
    final state = await methodChannel.invokeMethod<String>("getState");
    switch (state) {
      case "notInitialized":
        return RecorderState.notInitialized;
      case "initialized":
        return RecorderState.initialized;
      case "recording":
        return RecorderState.recording;
      case "pausing":
        return RecorderState.pausing;
      case "stopped":
        return RecorderState.stopped;
      case "finalized":
        return RecorderState.finalized;
      default:
        throw PlatformException(code: 'getState', message: "unknown state: $state");
    }
  }

  @override
  void updateRecordState(Map<String, dynamic> data) async {
    final RecorderState state;
    switch (data['state']) {
      case "notInitialized":
        state = RecorderState.notInitialized;
        break;
      case "initialized":
        state = RecorderState.initialized;
        break;
      case "recording":
        state = RecorderState.recording;
        break;
      case "pausing":
        state = RecorderState.pausing;
        break;
      case "stopped":
        state = RecorderState.stopped;
        break;
      case "finalized":
        state = RecorderState.finalized;
        break;
      default:
        throw PlatformException(code: 'getState', message: "unknown state: ${data['state']}");
    }
    _recordStateSink.add(state);
  }

  @override
  void updateRecordError(Map<String, dynamic> data) async {
    final errorType;
    switch(data['errorType']) {
      case "illegalArgument":
        errorType = ErrorType.illegalArgument;
        break;
      case "illegalState":
        errorType = ErrorType.illegalState;
        break;
      case "noPermission":
        errorType = ErrorType.noPermission;
        break;
      case "noSpace":
        errorType = ErrorType.noSpace;
        break;
      case "interrupted":
        errorType = ErrorType.interrupted;
        break;
      case "unknown":
        errorType = ErrorType.unknown;
        break;
      case "durationExceeded":
        errorType = ErrorType.durationExceeded;
        break;
      default:
        throw PlatformException(code: 'updateRecordError', message: "unknown errorType: ${data['errorType']}");
    }

    _recordErrorSink.add(RecorderException(errorType, "${data['message']}"));
  }

  @override
  void updateRecordInfo(Map<String, dynamic> data) async {
    _recordInfoSink.add(RecorderInfo(Duration(milliseconds: data['duration']), data['db']));
  }
}
