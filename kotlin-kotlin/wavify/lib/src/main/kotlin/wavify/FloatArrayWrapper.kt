package dev.wavify

import java.nio.ByteBuffer

class FloatArrayWrapper(private val data: FloatArray) {

    val pointer: ByteBuffer = ByteBuffer.allocateDirect(data.size * 4).apply {
        asFloatBuffer().put(data)
    }

    val length: Long = data.size.toLong()
}
