package dev.wavify

import android.util.Log

class SttEngine private constructor(private val nativeHandle: Long) {

    companion object {

        val TAG: String = "Wavify"

        @JvmStatic
        external fun createFfi(modelPath: String, apiKey: String, appName: String): Long

        @JvmStatic
        external fun destroyFfi(engineHandle: Long)

        @JvmStatic
        external fun sttFfi(engineHandle: Long, data: FloatArray): String

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
        return sttFfi(nativeHandle, data)
    }

}