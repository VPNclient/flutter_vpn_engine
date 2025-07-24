package click.vpnclient.engine.example;

import android.content.Intent;
import android.net.VpnService;
import android.os.ParcelFileDescriptor;
import android.util.Log;

import java.io.IOException;

public class VPNService extends VpnService {
    private static final String TAG = "VPNService";
    private ParcelFileDescriptor vpnInterface;
    private Thread vpnThread;
    private boolean isRunning = false;

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Log.d(TAG, "VPN Service starting");

        if (intent != null && "STOP_VPN".equals(intent.getAction())) {
            stopVPN();
            return START_NOT_STICKY;
        }

        startVPN();
        return START_STICKY;
    }

    private void startVPN() {
        if (isRunning) {
            Log.d(TAG, "VPN already running");
            return;
        }

        try {
            // Create VPN interface
            Builder builder = new Builder()
                    .setSession("VPN Client Engine")
                    .addAddress("10.0.0.2", 24)
                    .addDnsServer("8.8.8.8")
                    .addDnsServer("8.8.4.4")
                    .addRoute("0.0.0.0", 0);

            vpnInterface = builder.establish();

            if (vpnInterface == null) {
                Log.e(TAG, "Failed to establish VPN interface");
                return;
            }

            isRunning = true;
            Log.d(TAG, "VPN interface established");

            // Start VPN thread
            vpnThread = new Thread(this::runVPN);
            vpnThread.start();

        } catch (Exception e) {
            Log.e(TAG, "Error starting VPN", e);
            stopVPN();
        }
    }

    private void runVPN() {
        Log.d(TAG, "VPN thread started");

        try {
            // Keep the VPN service running
            while (isRunning && !Thread.currentThread().isInterrupted()) {
                synchronized (this) {
                    wait(5000); // Wait for 5 seconds or until interrupted
                }
            }
        } catch (InterruptedException e) {
            Log.d(TAG, "VPN thread interrupted");
        } finally {
            Log.d(TAG, "VPN thread stopped");
        }
    }

    private void stopVPN() {
        Log.d(TAG, "Stopping VPN");
        isRunning = false;

        if (vpnThread != null) {
            vpnThread.interrupt();
            try {
                vpnThread.join(1000);
            } catch (InterruptedException e) {
                Log.w(TAG, "Interrupted while waiting for VPN thread to stop");
            }
            vpnThread = null;
        }

        if (vpnInterface != null) {
            try {
                vpnInterface.close();
            } catch (IOException e) {
                Log.e(TAG, "Error closing VPN interface", e);
            }
            vpnInterface = null;
        }

        stopSelf();
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        stopVPN();
        Log.d(TAG, "VPN Service destroyed");
    }

    @Override
    public void onRevoke() {
        super.onRevoke();
        Log.d(TAG, "VPN permission revoked");
        stopVPN();
    }
}