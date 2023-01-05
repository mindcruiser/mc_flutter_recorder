class RecorderConfig {
  /// The path to save the audio.
  final String filePath;

  /// The sample rate of the recording, in hertz. The default value is 16000.
  final int sampleRate;

  /// The channel of the recording. The default value is [RecorderChannel.mono].
  final RecorderChannel channel;

  /// The bit rate of the recording. The default value is [PcmBitRate.pcm16Bit].
  final PcmBitRate pcmBitRate;

  /// The period of the recorderInfoStream callback. The default value is 100 milliseconds.
  final Duration period;

  /// The maximum duration of the recording. The default value is 5 hours, if the value is null, the recording will not be limited.
  final Duration? maxDuration;

  /// The behavior when the recording is interrupted. The default value is [InterruptedBehavior.pause].
  final InterruptedBehavior interruptedBehavior;

  /// The minimum free disk space in MB. The default value is 100.
  final int freeDisk;

  RecorderConfig({
    required this.filePath,
    this.sampleRate = 16000,
    this.channel = RecorderChannel.mono,
    this.pcmBitRate = PcmBitRate.pcm16Bit,
    this.period = const Duration(milliseconds: 100),
    this.maxDuration = const Duration(hours: 5),
    this.freeDisk = 100,
    this.interruptedBehavior = InterruptedBehavior.pause
  }): assert(period.inMilliseconds > 50);

  Map<String, dynamic> toData() => <String, dynamic>{
    "filePath": filePath,
    "sampleRate": sampleRate,
    "channel": channel.name,
    "pcmBitRate": pcmBitRate.name,
    "period": period.inMilliseconds,
    "maxDuration": maxDuration?.inMilliseconds,
    "freeDisk": freeDisk,
    "interruptedBehavior": interruptedBehavior.name
  };
}

enum RecorderChannel {
  /// Mono channel
  mono,

  /// Stereo channel
  stereo;

  int get channelCount {
    switch (this) {
      case RecorderChannel.mono:
        return 1;
      case RecorderChannel.stereo:
        return 2;
    }
  }
}

enum PcmBitRate {
  /// 8-bit PCM
  pcm8Bit,

  /// 16-bit PCM
  pcm16Bit;

  int get bitRate {
    switch (this) {
      case PcmBitRate.pcm8Bit:
        return 8;
      case PcmBitRate.pcm16Bit:
        return 16;
    }
  }
}

enum InterruptedBehavior {
  /// Pause the recording when the recording is interrupted.
  pause,

  /// Stop the recording when the recording is interrupted.
  stop
}
