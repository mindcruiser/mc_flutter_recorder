import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_flutter_recorder/mc_flutter_recorder_method_channel.dart';

void main() {
  MethodChannelMcFlutterRecorder platform = MethodChannelMcFlutterRecorder();
  const MethodChannel channel = MethodChannel('mc_flutter_recorder');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });
}
