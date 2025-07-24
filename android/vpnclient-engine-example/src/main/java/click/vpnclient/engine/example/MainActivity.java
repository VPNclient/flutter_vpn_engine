package click.vpnclient.engine.example;

import android.content.Intent;
import android.net.VpnService;
import android.os.Bundle;
import android.util.Log;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.appcompat.app.AppCompatActivity;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;

import click.vpnclient.engine.VpnClientEngine;

public class MainActivity extends AppCompatActivity {
    private static final String TAG = "MainActivity";

    private Button startButton;
    private Button stopButton;
    private TextView statusTextView;
    private VpnClientEngine engine;
    private boolean isVpnRunning = false;

    private final ActivityResultLauncher<Intent> vpnPermissionLauncher = registerForActivityResult(
            new ActivityResultContracts.StartActivityForResult(),
            result -> {
                if (result.getResultCode() == RESULT_OK) {
                    Log.d(TAG, "VPN permission granted");
                    startVpnConnection();
                } else {
                    Log.w(TAG, "VPN permission denied");
                    Toast.makeText(this, "VPN permission is required to start the connection", Toast.LENGTH_LONG).show();
                    updateUI(false);
                }
            }
    );

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        startButton = findViewById(R.id.start_button);
        stopButton = findViewById(R.id.stop_button);
        statusTextView = findViewById(R.id.status_text);

        engine = new VpnClientEngine(VpnClientEngine.DriverType.LibXray);

        // Create a basic config file if it doesn't exist
        createConfigFileIfNeeded();

        startButton.setOnClickListener(v -> requestVpnPermission());

        stopButton.setOnClickListener(v -> stopVpnConnection());

        // Initialize UI
        updateUI(false);
    }

    private void requestVpnPermission() {
        Intent vpnIntent = VpnService.prepare(this);
        if (vpnIntent != null) {
            // Permission not granted, request it
            Log.d(TAG, "Requesting VPN permission");
            vpnPermissionLauncher.launch(vpnIntent);
        } else {
            // Permission already granted
            Log.d(TAG, "VPN permission already granted");
            startVpnConnection();
        }
    }

    private void startVpnConnection() {
        Log.d(TAG, "Starting VPN connection");

        try {
            // Start VPN engine
            String dataDir = getApplicationInfo().dataDir;
            String configFilePath = new File(dataDir, "config.json").getAbsolutePath();
            boolean engineStarted = engine.start(dataDir, configFilePath);

            if (!engineStarted) {
                Log.e(TAG, "Failed to start VPN engine");
                Toast.makeText(this, "Failed to start VPN engine", Toast.LENGTH_SHORT).show();
                updateUI(false);
                return;
            }

            // Start VPN service
            Intent serviceIntent = new Intent(this, VPNService.class);
            startService(serviceIntent);

            isVpnRunning = true;
            updateUI(true);
            Toast.makeText(this, "VPN connection started", Toast.LENGTH_SHORT).show();

        } catch (Exception e) {
            Log.e(TAG, "Error starting VPN connection", e);
            Toast.makeText(this, "Error starting VPN: " + e.getMessage(), Toast.LENGTH_LONG).show();
            updateUI(false);
        }
    }

    private void stopVpnConnection() {
        Log.d(TAG, "Stopping VPN connection");

        try {
            // Stop VPN service
            Intent serviceIntent = new Intent(this, VPNService.class);
            serviceIntent.setAction("STOP_VPN");
            startService(serviceIntent);

            // Stop VPN engine
            engine.stop();

            isVpnRunning = false;
            updateUI(false);
            Toast.makeText(this, "VPN connection stopped", Toast.LENGTH_SHORT).show();

        } catch (Exception e) {
            Log.e(TAG, "Error stopping VPN connection", e);
            Toast.makeText(this, "Error stopping VPN: " + e.getMessage(), Toast.LENGTH_SHORT).show();
        }
    }

    private void updateUI(boolean isRunning) {
        startButton.setEnabled(!isRunning);
        stopButton.setEnabled(isRunning);

        if (isRunning) {
            statusTextView.setText(R.string.status_running);
        } else {
            statusTextView.setText(R.string.status_stopped);
        }
    }

    private void createConfigFileIfNeeded() {
        String dataDir = getApplicationInfo().dataDir;
        File configFile = new File(dataDir, "config.json");

        if (!configFile.exists()) {
            try {
                // Create a basic configuration
                String basicConfig = "{\n" +
                        "  \"log\": {\n" +
                        "    \"loglevel\": \"info\"\n" +
                        "  },\n" +
                        "  \"inbounds\": [\n" +
                        "    {\n" +
                        "      \"tag\": \"tun\",\n" +
                        "      \"type\": \"tun\",\n" +
                        "      \"interface_name\": \"tun0\",\n" +
                        "      \"inet4_address\": \"172.19.0.1/30\",\n" +
                        "      \"auto_route\": true,\n" +
                        "      \"strict_route\": false,\n" +
                        "      \"sniff\": true\n" +
                        "    }\n" +
                        "  ],\n" +
                        "  \"outbounds\": [\n" +
                        "    {\n" +
                        "      \"tag\": \"direct\",\n" +
                        "      \"type\": \"direct\"\n" +
                        "    }\n" +
                        "  ]\n" +
                        "}";

                FileOutputStream fos = new FileOutputStream(configFile);
                fos.write(basicConfig.getBytes());
                fos.close();

                Log.d(TAG, "Created basic config file at: " + configFile.getAbsolutePath());
            } catch (IOException e) {
                Log.e(TAG, "Failed to create config file", e);
            }
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (isVpnRunning) {
            stopVpnConnection();
        }
    }
}