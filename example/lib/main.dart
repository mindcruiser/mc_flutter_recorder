
import 'package:flutter/material.dart';
import 'package:mc_flutter_recorder/mc_flutter_recorder.dart';
import 'package:mc_flutter_recorder/recorder_config.dart';
import 'package:mc_flutter_recorder/recorder_exception.dart';
import 'dart:async';

import 'package:mc_flutter_recorder/recorder_info.dart';
import 'package:mc_flutter_recorder/recorder_state.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _mcRecorderPlugin = MCFlutterRecorder();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('MCFlutterRecorder'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder<RecorderInfo>(
                stream: _mcRecorderPlugin.recorderInfoStream(),
                builder: (context, snapshot) {
                  var db = snapshot.data?.db ?? 0;
                  return Text("duration: ${snapshot.data?.duration}\ndb: ${db.roundToDouble()}");
                },
              ),
              StreamBuilder<RecorderState>(
                stream: _mcRecorderPlugin.recorderStateStream(),
                builder: (context, snapshot) {
                  return Text("state: ${snapshot.data?.name}");
                },
              ),
              ErrorWidget(stream: _mcRecorderPlugin.recorderErrorStream()),
              Wrap(
                children: [
                  TextButton(
                      onPressed: () async {
                        final granted = await Permission.microphone.isGranted;
                        if (!granted) {
                          await Permission.microphone.request();
                        }
                      },
                      child: const Text("permission")),
                  TextButton(
                      onPressed: () async {
                        final dir = (await getApplicationDocumentsDirectory()).path;
                        final path = '$dir/example.wav';
                        setState(() {
                          _mcRecorderPlugin.init(RecorderConfig(
                            filePath: path,
                            sampleRate: 16000,
                            channel: RecorderChannel.mono,
                            pcmBitRate: PcmBitRate.pcm16Bit,
                            period: const Duration(milliseconds: 100),
                            interruptedBehavior: InterruptedBehavior.stop,
                            freeDisk: 100,
                          ));
                        });
                      },
                      child: const Text("init")),
                  TextButton(
                      onPressed: () {
                        setState(() {
                          _mcRecorderPlugin.start();
                        });
                      },
                      child: const Text("start")),
                  TextButton(
                      onPressed: () {
                        setState(() {
                          _mcRecorderPlugin.pause();
                        });
                      },
                      child: const Text("pause")),
                  TextButton(
                      onPressed: () {
                        setState(() {
                          _mcRecorderPlugin.resume();
                        });
                      },
                      child: const Text("resume")),
                  TextButton(
                      onPressed: () {
                        setState(() {
                          _mcRecorderPlugin.stop();
                        });
                      },
                      child: const Text("stop")),
                  TextButton(
                      onPressed: () {
                        setState(() {
                          _mcRecorderPlugin.close();
                        });
                      },
                      child: const Text("close")),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorWidget extends StatefulWidget {
  final Stream<RecorderException> stream;

  const ErrorWidget({Key? key, required this.stream}) : super(key: key);

  @override
  State<ErrorWidget> createState() => _ErrorWidgetState();
}

class _ErrorWidgetState extends State<ErrorWidget> {
  StreamSubscription? _streamSubscription;

  @override
  void initState() {
    super.initState();
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _streamSubscription = widget.stream.listen((event) {
      final msg = "error type: ${event.errorType}, message: ${event.message}";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
