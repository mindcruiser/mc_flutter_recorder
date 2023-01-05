class RecorderInfo {
  final Duration duration;
  final double db;
  RecorderInfo(this.duration, this.db);

  @override
  String toString() => "duration: $duration, db: $db";
}