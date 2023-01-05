package com.mindcruiser.mc_flutter_recorder

import android.content.Context
import android.media.*
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import io.flutter.Log
import java.io.IOException
import java.util.concurrent.atomic.AtomicInteger


class McRecorder(private val appContext: Context, private val config: RecorderConfig) {

    companion object {
        private val TAG = "McRecorder"
    }

    private val audioManager = appContext.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private val recorderHandler = Handler(HandlerThread("McRecorder").apply { start() }.looper)
    private var recorder: AudioRecord? = null
    private val encoder = WavPcmEncoder(config)
    private val state: AtomicInteger = AtomicInteger(RecorderState.NOT_INITIALIZED.ordinal)
    private val bufferSize =
        config.period * (config.sampleRate * config.channelConfig.channelCount * config.recordFormat.bitRate / 8) / 1000

    private val audioRegisterCallback = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
        object : AudioManager.AudioRecordingCallback() {
            override fun onRecordingConfigChanged(configs: MutableList<AudioRecordingConfiguration>?) {
                if (configs.isNullOrEmpty()) {
                    // there is no app is recording
                    Log.d(TAG, "there is no app is recording")
                } else {
                    Log.d(
                        TAG, "recording config change: \n${
                            configs.map {
                                "\tclientAudioSource: ${it.clientAudioSource}\n" +
                                        "\tisClientSilenced: ${it.isClientSilenced}\n" +
                                        "\tclientAudioSessionId: ${it.clientAudioSessionId}\n" +
                                        "\tproductName: ${it.audioDevice?.productName}"
                            }
                        }"
                    )
                    configs.forEach {
                        when (it.clientAudioSource) {
                            MediaRecorder.AudioSource.MIC -> {
                                if (currentState == RecorderState.RECORDING && it.isClientSilenced) {
                                    config.callback.onRecordError(
                                        RecorderException(
                                            ErrorType.INTERRUPTED,
                                            "microphone is occupied when recording"
                                        )
                                    )
                                    when (config.interruptedBehavior) {
                                        InterruptedBehavior.STOP -> stop()
                                        InterruptedBehavior.PAUSE -> pause()
                                    }
                                }
                            }
                            else -> {
                                // ignore other case
                            }
                        }
                    }
                }
            }
        }
    } else {
        null
    }

    private val afChangeListener = AudioManager.OnAudioFocusChangeListener { focusChange ->
        when (focusChange) {
            AudioManager.AUDIOFOCUS_LOSS, AudioManager.AUDIOFOCUS_LOSS_TRANSIENT, AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                if (state.get() == RecorderState.RECORDING.ordinal) {
                    pause()
                }
            }
            AudioManager.AUDIOFOCUS_GAIN -> {
                // Your app has been granted audio focus again
                // Raise volume to normal, restart playback if necessary
            }
        }
    }

    private val audioFocus = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN).run {
            setAudioAttributes(AudioAttributes.Builder().run {
                setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
                setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                build()
            })
            setAcceptsDelayedFocusGain(true)
            setOnAudioFocusChangeListener(afChangeListener, Handler(Looper.getMainLooper()))
            build()
        }
    } else {
        null
    }

    private val recordTask = Runnable {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && audioManager.activeRecordingConfigurations.any {
                it.isClientSilenced
            }) {
            Log.d(TAG, "microphone is occupied when start")
            config.callback.onRecordError(
                RecorderException(
                    ErrorType.INTERRUPTED,
                    "microphone is occupied when start"
                )
            )
            when (config.interruptedBehavior) {
                InterruptedBehavior.STOP -> stop()
                InterruptedBehavior.PAUSE -> pause()
            }
            return@Runnable
        }

        try {
            recorder?.startRecording()
        } catch (e: Exception) {
            config.callback.onRecordError(
                RecorderException(
                    ErrorType.INTERRUPTED,
                    "microphone is occupied"
                )
            )
            when (config.interruptedBehavior) {
                InterruptedBehavior.STOP -> stop()
                InterruptedBehavior.PAUSE -> pause()
            }
            return@Runnable
        }
        Log.d(TAG, "recordTask start")
        var i = 0
        while (state.get() == RecorderState.RECORDING.ordinal) {
            if (recorder?.recordingState != AudioRecord.RECORDSTATE_RECORDING) {
                config.callback.onRecordError(
                    RecorderException(
                        ErrorType.INTERRUPTED,
                        "microphone is occupied"
                    )
                )
                when (config.interruptedBehavior) {
                    InterruptedBehavior.STOP -> stop()
                    InterruptedBehavior.PAUSE -> pause()
                }
                break
            }
            val bytes = ByteArray(bufferSize)
            val count = recorder?.read(bytes, 0, bufferSize)
            if (count != null && count > 0) {
                try {
                    if (i % 100 == 0) {
                        if (encoder.getAvailableInternalMemorySize() <= config.freeDisk) { // todo config
                            throw IOException("space less than 128MB")
                        }
                        if (i != 0) {
                            i = 0
                        }
                    } else {
                        i++
                    }

                    encoder.processAudioBytes(bytes, 0, bufferSize)
                } catch (e: IOException) {
                    config.callback.onRecordError(RecorderException(ErrorType.NO_SPACE, e.message))
                    stop()
                    break
                }
                config.callback.onRecordData(bytes)
            } else {
                when (count) {
                    AudioRecord.ERROR_INVALID_OPERATION -> config.callback.onRecordError(
                        RecorderException(ErrorType.UNKNOWN, "error code: ERROR_INVALID_OPERATION")
                    )
                    AudioRecord.ERROR_BAD_VALUE -> config.callback.onRecordError(
                        RecorderException(
                            ErrorType.UNKNOWN,
                            "Eerror code: RROR_BAD_VALUE"
                        )
                    )
                    AudioRecord.ERROR_DEAD_OBJECT -> config.callback.onRecordError(
                        RecorderException(
                            ErrorType.UNKNOWN,
                            "error code: ERROR_DEAD_OBJECT"
                        )
                    )
                    null -> config.callback.onRecordError(
                        RecorderException(
                            ErrorType.ILLEGAL_STATE,
                            "recorder need to init"
                        )
                    )
                    else -> config.callback.onRecordError(
                        RecorderException(
                            ErrorType.UNKNOWN,
                            "error code: $count"
                        )
                    )
                }
                break
            }
        }

        recorder?.stop()
        Log.d(TAG, "recordTask stop")
    }

    private val releaseTask = Runnable {
        encoder.stop()
        recorder?.release()
        recorder = null
        Log.d(TAG, "releaseTask finished")
    }

    val currentState
        get() = RecorderState.values()[state.get()]


    private fun registerCallback() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            recorder?.registerAudioRecordingCallback(
                appContext.mainExecutor,
                audioRegisterCallback!!
            )
        }
    }

    private fun unregisterCallback() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            recorder?.unregisterAudioRecordingCallback(audioRegisterCallback!!)
        }
    }

    private fun requestAudioFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioManager.requestAudioFocus(audioFocus!!)
        }
    }

    private fun abandonAudioFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioManager.abandonAudioFocusRequest(audioFocus!!)
        }
    }


    fun init(): Boolean {
        encoder.init()
        Log.d(TAG, "buffer size: $bufferSize")
        Log.d(TAG, "available size: ${encoder.getAvailableInternalMemorySize() / 1024.0}")
        recorder = AudioRecord(
            MediaRecorder.AudioSource.MIC,
            config.sampleRate,
            config.channelConfig.channel,
            config.recordFormat.format,
            bufferSize
        )
        registerCallback()
        state.set(RecorderState.INITIALIZED.ordinal)
        config.callback.onRecordStateChange(RecorderState.INITIALIZED)
        return true
    }

    fun start() {
        state.set(RecorderState.RECORDING.ordinal)
        requestAudioFocus()
        recorderHandler.post(recordTask)
        config.callback.onRecordStateChange(RecorderState.RECORDING)
    }

    fun pause() {
        state.set(RecorderState.PAUSING.ordinal)
        abandonAudioFocus()
        config.callback.onRecordStateChange(RecorderState.PAUSING)
    }

    fun resume() {
        state.set(RecorderState.RECORDING.ordinal)
        recorderHandler.removeCallbacks(recordTask)
        requestAudioFocus()
        recorderHandler.post(recordTask)
        config.callback.onRecordStateChange(RecorderState.RECORDING)
    }

    fun stop() {
        abandonAudioFocus()
        state.set(RecorderState.STOPPED.ordinal)
        config.callback.onRecordStateChange(RecorderState.STOPPED)
    }

    fun close() {
        state.set(RecorderState.FINALIZED.ordinal)
        unregisterCallback()
        recorderHandler.post(releaseTask)
        config.callback.onRecordStateChange(RecorderState.FINALIZED)
    }
}

data class RecorderConfig(
    val filePath: String,
    val callback: RecorderCallback,
    val sampleRate: Int = 16000,
    val channelConfig: ChannelConfig = ChannelConfig.MONO,
    val recordFormat: RecordFormat = RecordFormat.PCM_16BIT,
    val period: Int = 5,
    val interruptedBehavior: InterruptedBehavior = InterruptedBehavior.STOP,
    val maxDuration: Int? = null,
    val freeDisk: Int = 100 * 1024 * 1024,
)

enum class ChannelConfig(val channel: Int) {
    MONO(AudioFormat.CHANNEL_IN_MONO),
    STEREO(AudioFormat.CHANNEL_IN_STEREO);

    val channelCount
        get() = when (this) {
            MONO -> 1
            STEREO -> 2
        }
}

enum class RecordFormat(val format: Int) {
    PCM_16BIT(AudioFormat.ENCODING_PCM_16BIT),
    PCM_8BIT(AudioFormat.ENCODING_PCM_8BIT);

    val bitRate
        get() = when (this) {
            PCM_16BIT -> 16
            PCM_8BIT -> 8
        }
}

enum class RecorderState {
    NOT_INITIALIZED,
    INITIALIZED,
    RECORDING,
    PAUSING,
    STOPPED,
    FINALIZED
}

enum class InterruptedBehavior {
    STOP,
    PAUSE
}

interface RecorderCallback {
    fun onRecordData(data: ByteArray)
    fun onRecordError(exception: RecorderException)
    fun onRecordStateChange(state: RecorderState)
}