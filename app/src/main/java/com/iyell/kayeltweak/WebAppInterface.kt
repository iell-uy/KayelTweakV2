package com.iyell.kayeltweak

import android.webkit.JavascriptInterface
import android.webkit.WebView
import kotlinx.coroutines.*

/**
 * Dipanggil dari JS lewat window.KayelBridge.exec(cmd, callbackName).
 * Kontraknya sengaja dibuat mirip ksu.exec (AxManager) supaya UI (index.html)
 * yang sudah ada tinggal dipakai lagi, cukup ganti satu fungsi pengirimnya.
 */
class WebAppInterface(private val webView: WebView, private val bridge: AdbBridge) {

    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    @JavascriptInterface
    fun exec(cmd: String, callbackName: String) {
        scope.launch {
            val out = try { withContext(Dispatchers.IO) { bridge.shell(cmd) } }
            catch (e: Exception) { "" }
            val ok = true // kegagalan koneksi ditangani sbg output kosong, bukan dianggap error perintah
            val esc = out.replace("\\", "\\\\").replace("`", "\\`").replace("\$", "\\$")
            webView.evaluateJavascript(
                "window['$callbackName'] && window['$callbackName'](0, `$esc`, '')", null
            )
        }
    }

    @JavascriptInterface
    fun pairingNeeded(): Boolean = !bridge.hasSavedKey()
}
