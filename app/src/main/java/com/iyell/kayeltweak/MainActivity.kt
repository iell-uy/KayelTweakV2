package com.iyell.kayeltweak

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.*
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import kotlinx.coroutines.*

class MainActivity : AppCompatActivity() {

    private lateinit var bridge: AdbBridge
    private lateinit var web: WebView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.setFlags(WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS, WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS)
        bridge = AdbBridge(this)
        extractShellScript()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            ContextCompat.startForegroundService(this, Intent(this, BridgeService::class.java))
        }

        if (bridge.hasSavedKey()) showWeb() else showPairingScreen()
    }

    /** Layar sederhana: minta user buka Developer Options > Wireless debugging > Pair device,
     *  lalu masukkan kode 6 digit yang muncul di sana. Ini dilakukan SEKALI SAJA. */
    private fun showPairingScreen() {
        val pad = (24 * resources.displayMetrics.density).toInt()
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(pad, pad * 2, pad, pad)
            setBackgroundColor(0xFF08050A.toInt())
        }
        val title = TextView(this).apply {
            text = "Hubungkan Kayel Tweak"
            textSize = 22f; setTextColor(0xFFFBF1F2.toInt())
        }
        val desc = TextView(this).apply {
            text = "Langkah ini cuma sekali, langsung di HP, tanpa PC dan tanpa app lain:\n\n" +
                   "1. Buka Setelan > Tentang Ponsel > ketuk \"Nomor bentukan\" 7x (kalau Opsi Pengembang belum aktif)\n" +
                   "2. Buka Setelan > Opsi Pengembang > Wireless debugging > nyalakan\n" +
                   "3. Ketuk \"Pair device with pairing code\"\n" +
                   "4. Masukkan kode 6 digit yang muncul di sana ke kolom di bawah"
            setTextColor(0xFFB9A1A5.toInt()); setPadding(0, pad / 2, 0, pad)
        }
        val input = EditText(this).apply {
            hint = "Kode 6 digit"; inputType = android.text.InputType.TYPE_CLASS_NUMBER
            setTextColor(0xFFFBF1F2.toInt()); setHintTextColor(0xFF777777.toInt())
        }
        val status = TextView(this).apply { setTextColor(0xFFFF8A93.toInt()); setPadding(0, pad / 2, 0, 0) }
        val btn = Button(this).apply {
            text = "Pairing sekarang"
            setOnClickListener {
                val code = input.text.toString().trim()
                if (code.length < 6) { status.text = "Kode harus 6 digit."; return@setOnClickListener }
                status.text = "Mencari layanan pairing… pastikan Wireless debugging aktif."
                isEnabled = false
                CoroutineScope(Dispatchers.Main).launch {
                    val r = withContext(Dispatchers.IO) { bridge.pair(code) }
                    isEnabled = true
                    if (r.isSuccess) { status.text = "Berhasil!"; showWeb() }
                    else status.text = "Gagal: ${r.exceptionOrNull()?.message ?: "coba lagi, pastikan kode belum kedaluwarsa"}"
                }
            }
        }
        val skip = Button(this).apply {
            text = "Sudah pairing lewat cara lain? Lanjutkan"
            setOnClickListener { showWeb() }
        }
        layout.addView(title); layout.addView(desc); layout.addView(input); layout.addView(btn); layout.addView(status); layout.addView(skip)
        setContentView(layout)
    }

    private fun showWeb() {
        web = WebView(this).apply {
            settings.javaScriptEnabled = true
            settings.domStorageEnabled = true
            webViewClient = WebViewClient()
            addJavascriptInterface(WebAppInterface(this, bridge), "KayelBridge")
            loadUrl("file:///android_asset/index.html")
        }
        setContentView(web)
    }

    /** Salin kayel.sh dari assets ke filesDir, supaya bisa dijalankan lewat shell adb. */
    private fun extractShellScript() {
        val dst = java.io.File(filesDir, "kayel.sh")
        try {
            assets.open("kayel/kayel.sh").use { input ->
                dst.outputStream().use { output -> input.copyTo(output) }
            }
        } catch (_: Exception) { /* dicoba lagi lain kali kalau gagal */ }
    }

    override fun onBackPressed() {
        if (::web.isInitialized && web.canGoBack()) web.goBack() else super.onBackPressed()
    }
}
