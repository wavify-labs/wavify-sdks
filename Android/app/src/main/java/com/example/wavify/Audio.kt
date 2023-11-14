package com.example.wavify

import android.annotation.SuppressLint
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.util.Log
import java.io.File
import java.io.RandomAccessFile
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer
import java.util.concurrent.atomic.AtomicBoolean

class Audio {
    companion object {
        private const val bytesPerFloat = 4
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
                    AudioFormat.ENCODING_PCM_FLOAT
                ),
                2 * recordingChunkLengthInSeconds * sampleRate * bytesPerFloat
            )

            val audioRecord = AudioRecord.Builder()
                .setAudioSource(MediaRecorder.AudioSource.MIC)
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setSampleRate(sampleRate)
                        .setEncoding(AudioFormat.ENCODING_PCM_FLOAT)
                        .setChannelMask(AudioFormat.CHANNEL_IN_MONO)
                        .build()
                )
                .setBufferSizeInBytes(minBufferSize)
                .build()

            try {
                val floatAudioData = FloatArray(maxAudioLengthInSeconds * sampleRate) { 0.0f }
                var floatAudioDataOffset = 0

                audioRecord.startRecording()

                while (!stopRecordingFlag.get() && floatAudioDataOffset < floatAudioData.size) {
                    val numFloatsToRead = minOf(
                        recordingChunkLengthInSeconds * sampleRate,
                        floatAudioData.size - floatAudioDataOffset
                    )

                    val readResult = audioRecord.read(
                        floatAudioData, floatAudioDataOffset, numFloatsToRead,
                        AudioRecord.READ_BLOCKING
                    )

                    Log.d(MainActivity.TAG, "AudioRecord.read(float[], ...) returned $readResult")

                    if (readResult >= 0) {
                        floatAudioDataOffset += readResult
                    } else {
                        throw RuntimeException("AudioRecord.read() returned error code $readResult")
                    }
                }

                audioRecord.stop()

                return floatAudioData

            } finally {
                if (audioRecord.recordingState == AudioRecord.RECORDSTATE_RECORDING) {
                    audioRecord.stop()
                }
                audioRecord.release()
            }
        }
    }

}