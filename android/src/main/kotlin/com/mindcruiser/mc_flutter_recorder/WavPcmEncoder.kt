package com.mindcruiser.mc_flutter_recorder

import android.os.Environment
import android.os.StatFs
import java.io.File
import java.io.FileOutputStream
import java.io.RandomAccessFile


class WavPcmEncoder(val config: RecorderConfig) {

    companion object {
        val WRITE_HEADER_PERIOD = 10
    }

    private var addHeader = false
    private var fileOutputStream: FileOutputStream? = null
    //    private var randomAccessFile: RandomAccessFile? = null
    private var writeHeader = 0


    fun init() {
        val outputFile = File(config.filePath)

        if (!outputFile.parentFile!!.exists()) {
            outputFile.parentFile!!.mkdirs()
        }

        if (outputFile.exists()) {
            outputFile.delete()
        }

        if (!outputFile.exists()) {
            outputFile.createNewFile()

            fileOutputStream = FileOutputStream(outputFile)
//            randomAccessFile = RandomAccessFile(outputFile, "rw")
        }
    }

    fun getAvailableInternalMemorySize(): Long {
        val path = Environment.getDataDirectory()
        val stat = StatFs(path.path)
        val blockSize = stat.blockSize.toLong()
        //获取可用区块数量
        val availableBlocks = stat.availableBlocks.toLong()
        return availableBlocks * blockSize
    }

    fun processAudioBytes(input: ByteArray, offset: Int, length: Int): ByteArray {

        return if (!addHeader) {
            addHeader = true

            val header = getWavHeader(
                0,
                0,
                config.sampleRate,
                config.channelConfig.channelCount,
                config.recordFormat.bitRate,
            )

            val output = ByteArray(header.size + length)

            header.copyInto(output, 0, 0, header.size)
            input.copyInto(output, header.size, 0, length)

            fileOutputStream?.write(output)
            output
        } else {
            val output = input.copyOfRange(offset, length + offset)

            fileOutputStream?.write(output)


            if (writeHeader % WRITE_HEADER_PERIOD == 0 && writeHeader > 0) {
                refreshHeader()
                writeHeader = 0
            } else {
                writeHeader++
            }

            output
        }

    }

    fun stop() {
        refreshHeader()
        fileOutputStream?.flush()
        fileOutputStream?.close()
        fileOutputStream = null
    }

    private fun refreshHeader() {
        val outputFile = File(config.filePath)
        val fileLength = outputFile.length()
        val audioLength = fileLength - 44
        val dataLength = fileLength - 8

        val wavHeader =
            getWavHeader(
                audioLength.toInt(),
                dataLength.toInt(),
                config.sampleRate,
                config.channelConfig.channelCount,
                config.recordFormat.bitRate,
            )

        RandomAccessFile(outputFile, "rw").use {
            it.write(wavHeader, 0, wavHeader.size)
        }
    }

    private fun getWavHeader(
        totalAudioLen: Int,
        totalDataLen: Int,
        sampleRate: Int,
        channels: Int,
        bitRate: Int,
    ): ByteArray {
        val blockAlign = (channels * bitRate / 8)
        val byteRate = sampleRate * blockAlign
        val header = ByteArray(44)
        // ChunkID "RIFF"
        header[0] = 'R'.code.toByte()
        header[1] = 'I'.code.toByte()
        header[2] = 'F'.code.toByte()
        header[3] = 'F'.code.toByte()
        // ChunkSize == FileLength - WAVHeaderLength littleEndian
        header[4] = (totalDataLen and 0xff).toByte()
        header[5] = (totalDataLen shr 8 and 0xff).toByte()
        header[6] = (totalDataLen shr 16 and 0xff).toByte()
        header[7] = (totalDataLen shr 24 and 0xff).toByte()
        // Format "WAVE"
        header[8] = 'W'.code.toByte()
        header[9] = 'A'.code.toByte()
        header[10] = 'V'.code.toByte()
        header[11] = 'E'.code.toByte()
        // SubChunk1ID "fmt "
        header[12] = 'f'.code.toByte()
        header[13] = 'm'.code.toByte()
        header[14] = 't'.code.toByte()
        header[15] = ' '.code.toByte()//过渡字节
        // SubChunk1Size 16 for PCM littleEndian
        header[16] = 16
        header[17] = 0
        header[18] = 0
        header[19] = 0
        // AudioFormat 1 for PCM littleEndian
        header[20] = 1
        header[21] = 0
        // NumChannels littleEndian
        header[22] = channels.toByte()
        header[23] = 0
        // SampleRate littleEndian
        header[24] = (sampleRate and 0xff).toByte()
        header[25] = (sampleRate shr 8 and 0xff).toByte()
        header[26] = (sampleRate shr 16 and 0xff).toByte()
        header[27] = (sampleRate shr 24 and 0xff).toByte()
        // ByteRate == SampleRate * BlockAlign littleEndian
        header[28] = (byteRate and 0xff).toByte()
        header[29] = (byteRate shr 8 and 0xff).toByte()
        header[30] = (byteRate shr 16 and 0xff).toByte()
        header[31] = (byteRate shr 24 and 0xff).toByte()
        // BlockAlign == NumChannels * BitsPerSample / 8 littleEndian
        header[32] = blockAlign.toByte()
        header[33] = 0
        // BitsPerSample littleEndian
        header[34] = bitRate.toByte()
        header[35] = 0
        // SubChunk2ID "data"
        header[36] = 'd'.code.toByte()
        header[37] = 'a'.code.toByte()
        header[38] = 't'.code.toByte()
        header[39] = 'a'.code.toByte()
        // SubChunk2Size == NumSamples * BlockAlign == FileLength - WAVHeaderLength littleEndian
        header[40] = (totalAudioLen and 0xff).toByte()
        header[41] = (totalAudioLen shr 8 and 0xff).toByte()
        header[42] = (totalAudioLen shr 16 and 0xff).toByte()
        header[43] = (totalAudioLen shr 24 and 0xff).toByte()

        return header
    }
}