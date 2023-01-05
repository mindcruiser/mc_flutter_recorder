class RecorderException implements Exception {
  final String message;
  final ErrorType errorType;

  RecorderException(this.errorType, [this.message = ""]);
}

enum ErrorType {
  illegalArgument,
  illegalState,
  noPermission,
  noSpace,
  interrupted,
  unknown,
  durationExceeded,
}
