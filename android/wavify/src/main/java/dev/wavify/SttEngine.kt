package dev.wavify

import android.util.Log

enum class LogLevel(val level: String) {
    TRACE("trace"),
    DEBUG("debug"),
    INFO("info"),
    WARN("warn"),
    ERROR("error")
}

object Logger {
    init {
        System.loadLibrary("wavify_core")
        System.loadLibrary("tensorflowlite_c")
    }

    @JvmStatic
    private external fun setupLoggerFfi(logLevel: String)

    fun setLogLevel(logLevel: LogLevel = LogLevel.INFO) {
        setupLoggerFfi(logLevel.level)
    }
}

class SttEngine private constructor(private val nativeHandle: Long) {

    companion object {

        val TAG: String = "Wavify"

        @JvmStatic
        external fun createFfi(modelPath: String, apiKey: String, appName: String): Long

        @JvmStatic
        external fun destroyFfi(engineHandle: Long)

        @JvmStatic
        external fun sttFfi(data: FloatArray, engineHandle: Long): String

        fun create(modelPath: String, apiKey: String, appName: String): SttEngine {

            Log.d(TAG,"linking libraries")
            System.loadLibrary("wavify_core")
            System.loadLibrary("tensorflowlite_c")

            Log.d(TAG, "initializing engine")
            val handle = createFfi(modelPath, apiKey, appName)
            return SttEngine(handle)
        }
    }

    fun destroy() {
        destroyFfi(nativeHandle)
    }

    fun stt(data: FloatArray): String {
        return sttFfi(data, nativeHandle)
    }
}


