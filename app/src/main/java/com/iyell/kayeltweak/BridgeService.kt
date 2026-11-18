package com.iyell.kayeltweak

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

/**
 * Service latar depan ringan: cuma supaya Android tidak "membekukan" proses
 * app saat layar mati, sehingga sesi shell ke adbd tidak gampang putus.
 * Ini BUKAN proses tersembunyi/berbahaya — notifikasinya selalu tampil
 * selama aktif, sesuai aturan Android untuk foreground service.
 */
class BridgeService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(1, buildNotification())
        return START_STICKY
    }

    private fun buildNotification(): Notification {
        val chId = "kayel_bridge"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val ch = NotificationChannel(chId, "Kayel Tweak aktif", NotificationManager.IMPORTANCE_MIN)
            (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).createNotificationChannel(ch)
        }
        return NotificationCompat.Builder(this, chId)
            .setContentTitle("Kayel Tweak")
            .setContentText("Jembatan shell aktif")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .build()
    }
}
