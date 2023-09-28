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

class MainActivity : ComponentActivity() {
    init {
        try {
            System.loadLibrary("omp")
            System.loadLibrary("wavify_core_release")
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
        val modelFilesPath = applicationContext.filesDir.absolutePath
        val model = greeter.createModel(modelFilesPath)
        setContent {
            WavifyTheme {
                // A surface container using the 'background' color from the theme
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    Greeting("Android")
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