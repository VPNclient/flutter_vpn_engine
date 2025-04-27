package click.vpnclient.engine.android

import android.content.Intent
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import click.vpnclient.engine.android.ui.theme.VPNclientEngineAndroidTheme
import click.vpnclient.engine.service.VPNService
import android.net.VpnService


private const val TAG = "MainActivity"

class MainActivity : ComponentActivity() {


    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            VPNclientEngineAndroidTheme {
                Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                    Greeting(
                        name = "Hello Android!",
                        modifier = Modifier.padding(innerPadding)
                    )
                }

                // Request VPN permission
                requestVPNAccess()

            }
        }
    }

    private fun requestVPNAccess() {
        val prepareIntent: Intent? = VpnService.prepare(this)
        if (prepareIntent != null) {
            Log.d(TAG, "Request VPN permission")
            startActivityForResult(prepareIntent, 0)
        } else {
            Log.d(TAG, "VPN permission already granted")
            startVPNService()
        }
    }

    private fun startVPNService() {
        val vpnIntent = Intent(this, VPNService::class.java)
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            startForegroundService(vpnIntent)
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
    VPNclientEngineAndroidTheme {
        Greeting("Android")
    }
}