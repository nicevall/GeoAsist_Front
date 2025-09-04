// CREAR NUEVO ARCHIVO: android/app/src/main/kotlin/com/example/geo_asist_front/TrackingForegroundService.kt
package ec.edu.uide.geo_asist_front

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import android.util.Log

class TrackingForegroundService : Service() {
    
    companion object {
        private const val NOTIFICATION_ID = 9999
        private const val CHANNEL_ID = "geoasist_tracking_channel"
        private const val CHANNEL_NAME = "GeoAsist Tracking"
        private const val TAG = "TrackingService"
    }
    
    private var currentStatus = "Tracking Activo"
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "TrackingForegroundService creado")
        createNotificationChannel()
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action ?: "UNKNOWN"
        Log.d(TAG, "onStartCommand llamado con acción: $action")
        
        when (action) {
            "START_TRACKING" -> {
                Log.d(TAG, "Iniciando tracking foreground")
                startForegroundTracking()
            }
            "STOP_TRACKING" -> {
                Log.d(TAG, "Deteniendo tracking foreground")
                stopForegroundTracking()
            }
            "UPDATE_STATUS" -> {
                val status = intent?.getStringExtra("status") ?: "Tracking Activo"
                Log.d(TAG, "Actualizando estado: $status")
                updateNotification(status)
            }
            else -> {
                Log.w(TAG, "Acción desconocida: $action")
            }
        }
        
        // START_STICKY: Si el sistema mata el servicio, lo reinicia automáticamente
        return START_STICKY
    }
    
    override fun onBind(intent: Intent?): IBinder? {
        Log.d(TAG, "onBind llamado - retornando null (servicio no vinculable)")
        return null
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_LOW // Sin sonido, solo persistente
                ).apply {
                    description = "Notificación persistente para tracking de asistencia GeoAsist"
                    setShowBadge(false)
                    enableLights(false)
                    enableVibration(false)
                    setSound(null, null)
                    lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                }
                
                val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                notificationManager.createNotificationChannel(channel)
                Log.d(TAG, "Canal de notificación creado: $CHANNEL_ID")
            } catch (e: Exception) {
                Log.e(TAG, "Error creando canal de notificación", e)
            }
        }
    }
    
    private fun startForegroundTracking() {
        try {
            Log.d(TAG, "Iniciando servicio foreground con notificación")
            
            val notification = createTrackingNotification(currentStatus)
            startForeground(NOTIFICATION_ID, notification)
            
            Log.d(TAG, "Servicio foreground iniciado exitosamente")
        } catch (e: Exception) {
            Log.e(TAG, "Error iniciando servicio foreground", e)
        }
    }
    
    private fun stopForegroundTracking() {
        try {
            Log.d(TAG, "Deteniendo servicio foreground")
            
            stopForeground(true) // true = remover notificación también
            stopSelf()
            
            Log.d(TAG, "Servicio foreground detenido")
        } catch (e: Exception) {
            Log.e(TAG, "Error deteniendo servicio foreground", e)
        }
    }
    
    private fun updateNotification(status: String) {
        try {
            currentStatus = status
            Log.d(TAG, "Actualizando notificación con estado: $status")
            
            val notification = createTrackingNotification(status)
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(NOTIFICATION_ID, notification)
            
            Log.d(TAG, "Notificación actualizada exitosamente")
        } catch (e: Exception) {
            Log.e(TAG, "Error actualizando notificación", e)
        }
    }
    
    private fun createTrackingNotification(status: String): Notification {
        return try {
            // Intent para abrir la app cuando se toque la notificación
            val intent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            }
            
            val pendingIntent = PendingIntent.getActivity(
                this,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or 
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
            )
            
            // Crear la notificación
            NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("🎯 GeoAsist - $status")
                .setContentText("Tracking de asistencia en progreso. Mantén la app activa.")
                .setSmallIcon(android.R.drawable.ic_menu_mylocation) // Icono por defecto de Android
                .setContentIntent(pendingIntent)
                .setOngoing(true) // No puede ser eliminada por el usuario
                .setAutoCancel(false)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setCategory(NotificationCompat.CATEGORY_SERVICE)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setShowWhen(true)
                .setWhen(System.currentTimeMillis())
                .build()
                
        } catch (e: Exception) {
            Log.e(TAG, "Error creando notificación", e)
            // Notificación básica de emergencia
            NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("GeoAsist Tracking")
                .setContentText("Servicio activo")
                .setSmallIcon(android.R.drawable.ic_menu_mylocation)
                .build()
        }
    }
    
    override fun onDestroy() {
        Log.d(TAG, "TrackingForegroundService destruido")
        super.onDestroy()
    }
    
    override fun onTaskRemoved(rootIntent: Intent?) {
        Log.d(TAG, "Tarea removida - manteniendo servicio activo")
        super.onTaskRemoved(rootIntent)
        // No detener el servicio cuando se remueva la tarea
        // El servicio debe continuar ejecutándose en background
    }
}