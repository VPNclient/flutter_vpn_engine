import android.content.Intent
import android.net.VpnService

class VPNService : VpnService() {
    var isRunning = false

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        VPNManager.bindService(this)
        isRunning = true
        return START_STICKY
    }

    override fun onDestroy() {
        isRunning = false
        super.onDestroy()
    }
}

