package com.example.wavify

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.util.Log
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import java.io.File
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean


class MainActivity : AppCompatActivity() {
    private val usePrerecordedAudioButton: Button by lazy { findViewById(R.id.use_prerecorded_audio_button) }
    private val recordAudioButton: Button by lazy { findViewById(R.id.record_audio_button) }
    private val stopRecordingAudioButton: Button by lazy { findViewById(R.id.stop_recording_audio_button) }

    private val resultText: TextView by lazy { findViewById(R.id.result_text) }
    private val statusText: TextView by lazy { findViewById(R.id.status_text) }

    private val wavifyASR: WavifyASR by lazy {WavifyASR(applicationContext)}
    private val modelPointer: Long by lazy {
        val modelPath = File(applicationContext.filesDir, "whisper-tiny-en.tflite").absolutePath
        val apiKey = ""
        val modelPointer = wavifyASR.createModel(modelPath, apiKey) // TODO: error handling
        Log.d(TAG, "Loaded model")
        modelPointer
    }

    private val stopRecordingFlag = AtomicBoolean(false)

    private val workerThreadExecutor = Executors.newSingleThreadExecutor()

    init { // TODO: Whats first, the init or the attribute initialization from above?
        try {
            System.loadLibrary("wavify_core")
            System.loadLibrary("tensorflowlite_c")
        } catch (err: Error) {
            Log.e(TAG, "$err")
        }
    }
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.main_activity)

        val utils = Utils(applicationContext)
        utils.copyAssetsToInternalStorage()

        usePrerecordedAudioButton.setOnClickListener {

            disableAudioButtons()

            workerThreadExecutor.submit {
                try {
                    val audioFile = File(applicationContext.filesDir, "english.wav")
                    val audioFloats = Audio.fromWavFile(audioFile)

                    val start = System.currentTimeMillis()
                    val result = wavifyASR.process(audioFloats, modelPointer)
                    val processTimeMs = System.currentTimeMillis() - start
                    setSuccessfulResult(result, processTimeMs)
                } catch (e: Exception) {
                    setError(e)
                } finally {
                    resetDefaultAudioButtonState()
                }
            }
        }

        recordAudioButton.setOnClickListener {
            val hasPermission = ActivityCompat.checkSelfPermission(
                this,
                Manifest.permission.RECORD_AUDIO
            ) == PackageManager.PERMISSION_GRANTED

            if (!hasPermission) {
                requestPermissions(
                    arrayOf(Manifest.permission.RECORD_AUDIO),
                    RECORD_AUDIO_PERMISSION_REQUEST_CODE
                )
                return@setOnClickListener
            }

            disableAudioButtons()

            workerThreadExecutor.submit {
                try {
                    stopRecordingFlag.set(false)
                    runOnUiThread {
                        stopRecordingAudioButton.isEnabled = true
                    }

                    val audioFloats = Audio.fromRecording(stopRecordingFlag)
                    val start = System.currentTimeMillis()
                    val result = wavifyASR.process(audioFloats, modelPointer)
                    val processTimeMs = System.currentTimeMillis() - start
                    setSuccessfulResult(result, processTimeMs)
                } catch (e: Exception) {
                    setError(e)
                } finally {
                    resetDefaultAudioButtonState()
                }
            }
        }

        stopRecordingAudioButton.setOnClickListener {
            // Disable audio buttons first.
            // The audio button state will be reset at the end of the record audio task.
            disableAudioButtons()

            stopRecordingFlag.set(true)
        }

        resetDefaultAudioButtonState()

    }
    private fun disableAudioButtons() {
        runOnUiThread {
            usePrerecordedAudioButton.isEnabled = false
            recordAudioButton.isEnabled = false
            stopRecordingAudioButton.isEnabled = false
        }
    }

    private fun resetDefaultAudioButtonState() {
        runOnUiThread {
            usePrerecordedAudioButton.isEnabled = true
            recordAudioButton.isEnabled = true
            stopRecordingAudioButton.isEnabled = false
        }
    }

    private fun setSuccessfulResult(result: String, time: Long) {
        runOnUiThread {
            statusText.text = "Successful speech recognition ($time ms)"
            resultText.text = result.ifEmpty { "<No speech detected.>" }
        }}

    private fun setError(exception: Exception) {
        Log.e(TAG, "Error: ${exception.localizedMessage}", exception)
        runOnUiThread {
            statusText.text = "Error"
            resultText.text = exception.localizedMessage
        }
    }

    companion object {
        const val TAG = "WAVIFY"
        private const val RECORD_AUDIO_PERMISSION_REQUEST_CODE = 1
    }
}
