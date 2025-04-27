package click.vpnclient.engine;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.IBinder;
import android.util.Log;
import click.vpnclient.engine.service.VPNService;

public class VPNManager {
    private static final String TAG = "VPNManager";
    private static VPNService vpnService;
    private static boolean isBound = false;

    private static ServiceConnection serviceConnection = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName className, IBinder service) {
            // We've bound to VPNService, cast the IBinder and get VPNService instance
            VPNService.LocalBinder binder = (VPNService.LocalBinder) service;
            vpnService = binder.getService();
            isBound = true;
            Log.d(TAG, "onServiceConnected: VPN service connected");
        }

        @Override
        public void onServiceDisconnected(ComponentName arg0) {
            isBound = false;
            Log.d(TAG, "onServiceDisconnected: VPN service disconnected");
        }
    };

    // Binds the VPN service to the manager
    public static void bindService(Context context) {
        Intent intent = new Intent(context, VPNService.class);
        context.bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE);
    }

    public static boolean start(String config) {
        return vpnService != null && vpnService.startVPN(config);
    }

    public static void stop() {
        if (vpnService != null) vpnService.stopVPN();
    }

    public static String status() {
        return vpnService != null && vpnService.isRunning() ? "Running" : "Stopped";
    }
}
