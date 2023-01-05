package com.mindcruiser.mc_flutter_recorder

import android.Manifest
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.NonNull
import androidx.core.content.PermissionChecker.PERMISSION_GRANTED
import androidx.core.content.PermissionChecker.checkSelfPermission
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.log10


/** McFlutterRecorderPlugin */
class McFlutterRecorderPlugin : FlutterPlugin, MethodCallHandler, IMcFlutterRecorderPlugin {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel: MethodChannel

  private lateinit var applicationContext: Context

  private val mainHandler = Handler(Looper.getMainLooper())

  private var dataLength = 0L

  private var recorder: McRecorder? = null

  private var recorderConfig: RecorderConfig? = null

  private val recorderCallback = object : RecorderCallback {
    override fun onRecordData(data: ByteArray) {
      dataLength += data.size
      recorderConfig?.let {

        // calculate duration
        val duration =
          dataLength * 1000 / (it.sampleRate * it.channelConfig.channelCount * it.recordFormat.bitRate / 8)

        // calculate dB
        // rms = √((x1^2 + x2^2 + x3^2 + ... + xn^2) / n)
        // refs = 2^(bitRate - 1)
        // dBFS = 20 * log10(rms/refs)
        // make dBFS to positive so
        // dB = 20 * log10(rms) and maximum is refs
        val db = when (it.recordFormat) {
          RecordFormat.PCM_16BIT -> {
            val sa = ShortArray(data.size / 2)
            val byteBuffer = ByteBuffer.wrap(data)
            byteBuffer.order(ByteOrder.LITTLE_ENDIAN).asShortBuffer().get(sa)

            val rmsSum = sa
              .map { it.toLong() * it.toLong() }
              .fold(0L) { a, b -> a + b }
            if (rmsSum <= 1 || sa.isEmpty()) {
              0.0
            } else {
              10 * log10(rmsSum / sa.size.toDouble())
            }
          }
          RecordFormat.PCM_8BIT -> {
            val rmsSum = data
              .map { it.toLong() * it.toLong() }
              .fold(0L) { a, b -> a + b }
            if (rmsSum <= 1 || data.isEmpty()) {
              0.0
            } else {
              10 * log10(rmsSum / data.size.toDouble())
            }
          }
        }

        mainHandler.post {
          updateRecordInfo(RecorderInfo(duration, db))
          recorderConfig?.maxDuration?.let {
            if (duration > it) {
              recorderConfig?.callback?.onRecordError(RecorderException(ErrorType.DURATION_EXCEEDED, "duration too long: $it"))
              recorder?.stop()
            }
          }
        }
      }
    }

    override fun onRecordError(exception: RecorderException) {
      mainHandler.post {
        updateRecordError(exception)
      }
    }

    override fun onRecordStateChange(state: RecorderState) {
      mainHandler.post {
        updateRecordState(state)
      }
    }

  }

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    applicationContext = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "mc_flutter_recorder")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "init" -> {
        val args = call.arguments as Map<*, *>
        val path = args["filePath"] as String
        val sampleRate = (args["sampleRate"] as Int?) ?: 16000
        val bitRate = when (args["pcmBitRate"] as String?) {
          "pcm8Bit" -> RecordFormat.PCM_8BIT
          "pcm16Bit" -> RecordFormat.PCM_16BIT
          else -> RecordFormat.PCM_16BIT
        }
        val channel = when (args["channel"] as String?) {
          "mono" -> ChannelConfig.MONO
          "stereo" -> ChannelConfig.STEREO
          else -> ChannelConfig.MONO
        }
        val period = args["period"] as Int? ?: 50
        val interruptedBehavior = when (args["interruptedBehavior"] as String?) {
          "stop" -> InterruptedBehavior.STOP
          "pause" -> InterruptedBehavior.PAUSE
          else -> InterruptedBehavior.STOP
        }
        val maxDuration = args["maxDuration"] as Int?
        val freeDisk = args["freeDisk"] as Int? ?: 100
        recorderConfig = RecorderConfig(
          path,
          recorderCallback,
          sampleRate,
          channel,
          bitRate,
          period,
          interruptedBehavior,
          maxDuration,
          freeDisk * 1024 * 1024
        ).also {
          result.success(init(it))
        }
      }
      "start" -> result.success(start())
      "resume" -> result.success(resume())
      "pause" -> result.success(pause())
      "stop" -> result.success(stop())
      "close" -> result.success(close())
      "getState" -> result.success(getState())
      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun init(config: RecorderConfig): Boolean {


    val permission = Manifest.permission.RECORD_AUDIO

    val hasPermission =
      checkSelfPermission(applicationContext, permission) == PERMISSION_GRANTED

    if (!hasPermission) {
      updateRecordError(
        RecorderException(
          ErrorType.NO_PERMISSION,
          "must to request record audio permission"
        )
      )
      return false
    }

    if (recorder != null) {
      updateRecordError(
        RecorderException(
          ErrorType.ILLEGAL_STATE,
          "recorder has been init"
        )
      )
      return false
    }

    recorder = recorder ?: McRecorder(applicationContext, config).let {
      if (it.init()) it else null
    }
    return true
  }

  override fun start(): Boolean {
    return if (recorder?.currentState == RecorderState.INITIALIZED) {
      recorder?.start()
      true
    } else {
      updateRecordError(
        RecorderException(
          ErrorType.ILLEGAL_STATE,
          recorder?.currentState?.let {
            "current state is {${it.name}}, only ${RecorderState.INITIALIZED.name} can start recorder"
          } ?: "the recorder has been closed",
        ))
      false
    }
  }

  override fun pause(): Boolean {
    return if (recorder?.currentState == RecorderState.RECORDING) {
      recorder?.pause()
      true
    } else {
      updateRecordError(
        RecorderException(
          ErrorType.ILLEGAL_STATE,
          recorder?.currentState?.let {
            "current state is {${it.name}}, only ${RecorderState.RECORDING.name} can pause recorder"
          } ?: "the recorder has been closed",
        ))
      false
    }
  }

  override fun resume(): Boolean {
    return if (recorder?.currentState == RecorderState.PAUSING) {
      recorder?.resume()
      true
    } else {
      updateRecordError(
        RecorderException(
          ErrorType.ILLEGAL_STATE,
          recorder?.currentState?.let {
            "current state is {${it.name}}, only ${RecorderState.PAUSING.name} can resume recorder"
          } ?: "the recorder has been closed",
        ))
      false
    }
  }

  override fun stop(): Boolean {
    return if (recorder?.currentState == RecorderState.PAUSING || recorder?.currentState == RecorderState.RECORDING) {
      recorder?.stop()
      true
    } else {
      updateRecordError(
        RecorderException(
          ErrorType.ILLEGAL_STATE,
          recorder?.currentState?.let {
            "current state is {${it.name}}, only ${RecorderState.PAUSING.name} can resume recorder"
          } ?: "the recorder has been closed",
        ))
      false
    }
  }

  override fun close(): Boolean {
    recorder?.close()
    dataLength = 0L
    recorder = null
    recorderConfig = null
    return true
  }

  override fun getState(): String {
    return when (recorder?.currentState ?: RecorderState.NOT_INITIALIZED) {
      RecorderState.NOT_INITIALIZED -> "notInitialized"
      RecorderState.INITIALIZED -> "initialized"
      RecorderState.RECORDING -> "recording"
      RecorderState.PAUSING -> "pausing"
      RecorderState.STOPPED -> "stopped"
      RecorderState.FINALIZED -> "finalized"
    }
  }

  override fun updateRecordInfo(info: RecorderInfo) {
    channel.invokeMethod(
      "updateRecordInfo", mapOf(
        "duration" to info.duration,
        "db" to info.db
      )
    )
  }

  override fun updateRecordState(state: RecorderState) {
    channel.invokeMethod(
      "updateRecordState", mapOf(
        "state" to when (state) {
          RecorderState.NOT_INITIALIZED -> "notInitialized"
          RecorderState.INITIALIZED -> "initialized"
          RecorderState.RECORDING -> "recording"
          RecorderState.PAUSING -> "pausing"
          RecorderState.STOPPED -> "stopped"
          RecorderState.FINALIZED -> "finalized"
        }
      )
    )
  }

  override fun updateRecordError(exception: RecorderException) {
    channel.invokeMethod(
      "updateRecordError", mapOf(
        "errorType" to when (exception.err) {
          ErrorType.ILLEGAL_ARGUMENT -> "illegalArgument"
          ErrorType.ILLEGAL_STATE -> "illegalState"
          ErrorType.NO_PERMISSION -> "noPermission"
          ErrorType.NO_SPACE -> "noSpace"
          ErrorType.INTERRUPTED -> "interrupted"
          ErrorType.UNKNOWN -> "unknown"
          ErrorType.DURATION_EXCEEDED -> "durationExceeded"
        },
        "message" to exception.message
      )
    )
  }
}
