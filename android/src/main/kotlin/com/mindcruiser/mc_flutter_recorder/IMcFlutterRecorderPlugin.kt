package com.mindcruiser.mc_flutter_recorder

interface IMcFlutterRecorderPlugin {
    fun init(config: RecorderConfig): Boolean
    fun start(): Boolean
    fun pause(): Boolean
    fun resume(): Boolean
    fun stop(): Boolean
    fun close(): Boolean
    fun getState(): String

    fun updateRecordInfo(info: RecorderInfo)
    fun updateRecordState(state: RecorderState)
    fun updateRecordError(exception: RecorderException)
}

