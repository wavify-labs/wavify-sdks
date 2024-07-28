package dev.wavify

import android.util.Log
import dev.wavify.SttEngine.Companion

enum class LogLevel(val level: String) {
    TRACE("trace"),
    DEBUG("debug"),
    INFO("info"),
    WARN("warn"),
    ERROR("error")
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

        @JvmStatic
        external fun setupLoggerFfi(logLevel: String)

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

    fun setLogLevel(logLevel: LogLevel? = null) {
        val defaultLevel = LogLevel.INFO
        val level = logLevel ?: defaultLevel
        setupLoggerFfi(level.level)
    }

}


