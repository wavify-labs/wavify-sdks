package dev.wavify

import java.io.File
import java.io.InputStream
import org.slf4j.LoggerFactory

class SttEngine private constructor(private val nativeHandle: Long) {

    companion object {

        private val logger = LoggerFactory.getLogger(SttEngine::class.java)

        @JvmStatic
        external fun createFfi(modelPath: String, apiKey: String, appName: String): Long

        @JvmStatic
        external fun destroyFfi(engineHandle: Long)

        @JvmStatic
        external fun sttFfi(engineHandle: Long, data: FloatArrayWrapper): String

        fun create(modelPath: String, apiKey: String, appName: String): SttEngine {

            logger.debug("linking libraries")
            loadLibrary("wavify_core")
            loadLibrary("tensorflowlite_c")

            logger.debug("initializing engine")
            val handle = createFfi(modelPath, apiKey, appName)
            return SttEngine(handle)
        }

        private fun loadLibrary(libName: String) {
            try {
                val libPath = "/lib${libName}.so"

                val classLoader = SttEngine::class.java.classLoader
                val inputStream = classLoader.getResourceAsStream(libPath)

                if (inputStream == null) {
                    logger.error("Cannot find library: $libPath")
                    throw UnsatisfiedLinkError("Cannot find library: $libPath")
                }

                val tempFile = File.createTempFile(libName, ".so")
                tempFile.deleteOnExit()
                inputStream.use { input ->
                    tempFile.outputStream().use { output ->
                        input.copyTo(output)
                    }
                }

                System.load(tempFile.absolutePath)
            } catch (e: Exception) {
                logger.error("$e")
                throw e
            }
        }

        private fun getLibDir(): String {
            val arch = System.getProperty("os.arch")
            return when (arch) {
                "aarch64" -> "arm64-v8a"
                else -> {
                    logger.error("Unsupported architecture: $arch")
                    throw UnsupportedOperationException("Unsupported architecture: $arch")
                }
            }
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
