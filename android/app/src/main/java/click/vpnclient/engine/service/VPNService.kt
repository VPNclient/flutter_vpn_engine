package click.vpnclient.engine

import android.app.PendingIntent
import android.content.Intent
import android.net.VpnService
import android.os.ParcelFileDescriptor
import android.util.Log
import java.io.FileInputStream
import java.io.FileOutputStream
import java.net.InetSocketAddress
import java.nio.channels.DatagramChannel

class VPNService : VpnService() {
    companion object {
        private const val TAG = "VPNService"
    }

    private var vpnInterface: ParcelFileDescriptor? = null

    /**
     * Indicates whether the VPN service is currently running.
     */
    var isRunning = false; private set

    /**
     * Called when the service is first created.
     */
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "VPNService created")
    }

    /**
     * Called when the service is started.
     *
     * @param intent The Intent supplied to [startService], as given.
     * @param flags Additional data about this start request.
     * @param startId A unique integer representing this specific request to start.
     * @return The return value indicates what semantics the system should use for the service's
     * current started state.
     */
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand: Starting VPN service")
        try {
            setupVPN()
            isRunning = true
            // Notify that vpn started
        } catch (e: Exception) {
            Log.e(TAG, "Error starting VPN service", e)
            // Notify about start vpn error
        }
        return START_NOT_STICKY
    }

    /**
     * Called when the service is no longer used and is being destroyed.
     */
    override fun onDestroy() {
        Log.d(TAG, "onDestroy: Stopping VPN service")
        vpnInterface?.close()
        vpnInterface = null
        isRunning = false
        super.onDestroy()

    }

    private fun setupVPN() {
        // Here you can add other configures, for example:
        // addAddress addRoute addDnsServer
        vpnInterface = Builder()
            .setSession("VPNClient")
            .establish()
    }
}
