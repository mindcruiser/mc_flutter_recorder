package com.mindcruiser.mc_flutter_recorder

class RecorderException(val err: ErrorType, message: String?) : Exception(message)

enum class ErrorType {
    ILLEGAL_ARGUMENT,
    ILLEGAL_STATE,
    NO_PERMISSION,
    NO_SPACE,
    INTERRUPTED,
    UNKNOWN,
    DURATION_EXCEEDED,
}