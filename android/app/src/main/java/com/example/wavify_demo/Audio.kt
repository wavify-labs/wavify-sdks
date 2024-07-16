package com.example.wavify_demo

import android.annotation.SuppressLint
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.util.Log
import java.io.File
import java.io.RandomAccessFile
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.atomic.AtomicBoolean

class Audio {
    companion object {
        private const val sampleRate = 16000
        private const val maxAudioLengthInSeconds = 30

        // TODO: assumes file is 16bit encoded PCM
        fun fromWavFile(wavFile: File): FloatArray {
            val randomAccessFile = RandomAccessFile(wavFile, "r")
            // Skip the WAV file header
            randomAccessFile.seek(44)
            val bytes = ByteArray(2)
            val floatList = mutableListOf<Float>()

            while (randomAccessFile.read(bytes) != -1) {
                val short = ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN).short
                floatList.add(short.toFloat() / Short.MAX_VALUE)
            }

            randomAccessFile.close()

            return floatList.toFloatArray()
        }

        @SuppressLint("MissingPermission")
        fun fromRecording(stopRecordingFlag: AtomicBoolean): FloatArray {
            val recordingChunkLengthInSeconds = 1

            val minBufferSize = maxOf(
                AudioRecord.getMinBufferSize(
                    sampleRate,
                    AudioFormat.CHANNEL_IN_MONO,
                    AudioFormat.ENCODING_PCM_16BIT
                ),
                2 * recordingChunkLengthInSeconds * sampleRate
            )

            val audioRecord = AudioRecord.Builder()
                .setAudioSource(MediaRecorder.AudioSource.MIC)
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setSampleRate(sampleRate)
                        .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                        .setChannelMask(AudioFormat.CHANNEL_IN_MONO)
                        .build()
                )
                .setBufferSizeInBytes(minBufferSize)
                .build()

            try {
                val pcmAudioData = ShortArray(maxAudioLengthInSeconds * sampleRate) { 0 }
                var pcmAudioDataOffset = 0

                audioRecord.startRecording()

                while (!stopRecordingFlag.get() && pcmAudioDataOffset < pcmAudioData.size) {
                    val numFloatsToRead = minOf(
                        recordingChunkLengthInSeconds * sampleRate,
                        pcmAudioData.size - pcmAudioDataOffset
                    )

                    val readResult = audioRecord.read(
                        pcmAudioData, pcmAudioDataOffset, numFloatsToRead,
                        AudioRecord.READ_BLOCKING
                    )

                    Log.d(MainActivity.TAG, "AudioRecord.read(int[], ...) returned $readResult")

                    if (readResult >= 0) {
                        pcmAudioDataOffset += readResult
                    } else {
                        throw RuntimeException("AudioRecord.read() returned error code $readResult")
                    }
                }

                audioRecord.stop()

                return pcmAudioData.map { it.toFloat() / Short.MAX_VALUE }.toFloatArray()

            } finally {
                if (audioRecord.recordingState == AudioRecord.RECORDSTATE_RECORDING) {
                    audioRecord.stop()
                }
                audioRecord.release()
            }
        }
    }

}