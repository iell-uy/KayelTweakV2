package com.iyell.kayeltweak

import android.content.Context
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import kotlinx.coroutines.suspendCancellableCoroutine
import java.io.File
import java.security.KeyPairGenerator
import java.security.interfaces.RSAPrivateKey
import java.security.interfaces.RSAPublicKey
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

/**
 * Jembatan ke adbd lewat Wireless Debugging (bukan root).
 *
 * Levelnya SAMA PERSIS dengan yang dipakai AxManager/Shizuku: proses mendapat
 * hak "shell" (bukan root), yang cukup untuk settings/pm/device_config/cmd,
 * tapi tetap dibatasi SELinux seperti shell biasa.
 *
 * Nama service mDNS mengikuti standar Android 11+:
 *  - "_adb-tls-pairing._tcp"  -> dipakai sekali untuk PAIRING (butuh kode 6 digit)
 *  - "_adb-tls-connect._tcp" -> dipakai setiap kali CONNECT setelah ter-pairing
 *
 * Kunci privat/publik disimpan di filesDir supaya pairing tidak perlu diulang
 * setiap buka app (hanya perlu diulang jika user mematikan "Wireless debugging"
 * atau me-reset daftar perangkat ter-pairing di Developer Options).
 */
class AdbBridge(private val ctx: Context) {

    private val keyDir = File(ctx.filesDir, "adbkey").apply { mkdirs() }
    private val privFile = File(keyDir, "key")
    private val pubFile = File(keyDir, "key.pub")

    fun hasSavedKey() = privFile.exists() && pubFile.exists()

    private fun ensureKeyPair(): Pair<RSAPrivateKey, RSAPublicKey> {
        if (!hasSavedKey()) {
            val kp = KeyPairGenerator.getInstance("RSA").apply { initialize(2048) }.generateKeyPair()
            privFile.writeBytes(kp.private.encoded)
            pubFile.writeBytes(kp.public.encoded)
        }
        val privBytes = privFile.readBytes()
        val pubBytes = pubFile.readBytes()
        val kf = java.security.KeyFactory.getInstance("RSA")
        val priv = kf.generatePrivate(java.security.spec.PKCS8EncodedKeySpec(privBytes)) as RSAPrivateKey
        val pub = kf.generatePublic(java.security.spec.X509EncodedKeySpec(pubBytes)) as RSAPublicKey
        return priv to pub
    }

    /** Cari service mDNS dengan tipe [type]. Timeout [timeoutMs]. */
    private suspend fun discover(type: String, timeoutMs: Long = 12000): Pair<String, Int> =
        suspendCancellableCoroutine { cont ->
            val nsd = ctx.getSystemService(Context.NSD_SERVICE) as NsdManager
            var done = false
            lateinit var listener: NsdManager.DiscoveryListener
            listener = object : NsdManager.DiscoveryListener {
                override fun onDiscoveryStarted(t: String) {}
                override fun onServiceFound(info: NsdServiceInfo) {
                    if (done) return
                    nsd.resolveService(info, object : NsdManager.ResolveListener {
                        override fun onResolveFailed(i: NsdServiceInfo, e: Int) {}
                        override fun onServiceResolved(i: NsdServiceInfo) {
                            if (done) return
                            done = true
                            try { nsd.stopServiceDiscovery(listener) } catch (_: Exception) {}
                            cont.resume(i.host.hostAddress!! to i.port)
                        }
                    })
                }
                override fun onServiceLost(info: NsdServiceInfo) {}
                override fun onDiscoveryStopped(t: String) {}
                override fun onStartDiscoveryFailed(t: String, e: Int) { cont.resumeWithException(Exception("Gagal mulai cari layanan ($e)")) }
                override fun onStopDiscoveryFailed(t: String, e: Int) {}
            }
            cont.invokeOnCancellation { try { nsd.stopServiceDiscovery(listener) } catch (_: Exception) {} }
            nsd.discoverServices(type, NsdManager.PROTOCOL_DNS_SD, listener)
        }

    /** Langkah 1 (sekali saja): pairing pakai kode 6 digit dari Developer Options. */
    suspend fun pair(code: String): Result<Unit> = runCatching {
        val (host, port) = discover("_adb-tls-pairing._tcp")
        val (priv, pub) = ensureKeyPair()
        com.flyfishxu.kadb.Kadb.pair(host, port, code)
        // Setelah pairing sukses, device biasanya langsung membuka service "connect"
        // di port lain untuk host yang sama; sisanya ditangani connect().
    }

    /** Langkah 2: connect & jalankan satu perintah shell, kembalikan stdout+stderr. */
    suspend fun shell(cmd: String): String = withTimeoutSafe {
        val (host, port) = discover("_adb-tls-connect._tcp")
        val (priv, pub) = ensureKeyPair()
        com.flyfishxu.kadb.Kadb.create(host, port).use { k ->
            val r = k.shell(cmd)
            r.output + (if (r.exitCode != 0) "\n[exit ${r.exitCode}]" else "")
        }
    }

    private suspend fun <T> withTimeoutSafe(block: suspend () -> T): T =
        kotlinx.coroutines.withTimeout(20000) { block() }
}
