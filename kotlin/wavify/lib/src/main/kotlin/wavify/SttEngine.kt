package dev.wavify

class SttEngine private constructor(private val nativeHandle: Long) {

    init {
        System.loadLibrary("wavify_core")
    }

    companion object {
        @JvmStatic
        external fun createFfi(modelPath: String, apiKey: String, appName: String): Long

        @JvmStatic
        external fun destroyFfi(engineHandle: Long)

        @JvmStatic
        external fun sttFfi(engineHandle: Long, data: FloatArrayWrapper): String

        fun create(modelPath: String, apiKey: String, appName: String): SttEngine {
            val handle = createFfi(modelPath, apiKey, appName)
            return SttEngine(handle)
        }
    }

    fun destroy() {
        destroyFfi(nativeHandle)
    }

    fun stt(data: FloatArray): String {
        val dataWrapper = FloatArrayWrapper(data)
        return sttFfi(nativeHandle, dataWrapper)
    }
}
