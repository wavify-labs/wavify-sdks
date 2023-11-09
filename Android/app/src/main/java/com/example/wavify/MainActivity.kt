package com.example.wavify

import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import com.example.wavify.ui.theme.WavifyTheme
import java.io.File




class MainActivity : ComponentActivity() {
    init {
        try {
            System.loadLibrary("tensorflowlite_c")
            System.loadLibrary("wavify_core")
        } catch (err: Error) {
            Log.e("wavfiy", "$err")
        }
    }
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val greeter = RustGreetings(applicationContext)
        val utils = Utils(applicationContext)
        utils.copyAssetsToInternalStorage()
        val rustOutput = greeter.sayHello("foo")
        val modelPath = File(applicationContext.filesDir, "whisper-tiny.tflite").absolutePath
        val tokenizerPath = File(applicationContext.filesDir, "tokenizer.json").absolutePath
        val modelPointer = greeter.createModel(modelPath, tokenizerPath)
        val data = floatArrayOf(1.0f, 2.0f, 3.0f)
        val result = greeter.process(data, modelPointer)
        setContent {
            WavifyTheme {
                // A surface container using the 'background' color from the theme
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    Greeting(result)
                }
            }
        }
    }
}

@Composable
fun Greeting(name: String, modifier: Modifier = Modifier) {
    Text(
        text = "Hello $name!",
        modifier = modifier
    )
}

@Preview(showBackground = true)
@Composable
fun GreetingPreview() {
    WavifyTheme {
        Greeting("Android")
    }
}