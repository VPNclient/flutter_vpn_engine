package click.vpnclient.engine

import click.vpnclient.engine.service.VPNService

object VPNManager {
    private var vpnService: VPNService? = null

    fun bindService(service: VPNService) {
        vpnService = service
    }

    fun start(config: String): Boolean {
        val process = Runtime.getRuntime().exec("xray -config $config")
        return process != null
    }

    fun stop() {
        Runtime.getRuntime().exec("killall xray")
    }

    fun status(): String {
        return if (vpnService?.isRunning == true) "Running" else "Stopped"
    }
}
