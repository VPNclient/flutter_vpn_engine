package click.vpnclient.engine;

import android.util.Log;

import libXray.LibXray;

/**
 * @noinspection SwitchStatementWithTooFewBranches
 */
public class VpnClientEngine {
    private static final String TAG = "VpnClientEngine";

    public enum DriverType {
        LibXray
    }

    private final DriverType driver;
    private static boolean isRunning = false;

    public VpnClientEngine(DriverType driverType) {
        this.driver = driverType;
        switch (this.driver) {
            case LibXray:
                Log.i(TAG, "Using LibXray driver" + " version: " + LibXray.xrayVersion());
                break;
            default:
                throw new IllegalArgumentException("Unsupported driver type: " + driverType);
        }
    }

    public boolean start(String dataDir, String config) {
        if (isRunning) {
            Log.w(TAG, "Engine is already running");
            return false;
        }
        try {
            switch (this.driver) {
                case LibXray:
                    LibXray.runXrayFromJSON(LibXray.newXrayRunFromJSONRequest(dataDir, config));
                    break;
                default:
                    throw new IllegalStateException("Unsupported driver type: " + this.driver);
            }
        } catch (Exception e) {
            return false;
        }
        return true;
    }

    public void stop() {
        if (!isRunning) return;
        LibXray.stopXray();
        isRunning = false;
    }

    public boolean isRunning() {
        return LibXray.getXrayState();
    }

    public static String getVersion() {
        return LibXray.xrayVersion();
    }
}