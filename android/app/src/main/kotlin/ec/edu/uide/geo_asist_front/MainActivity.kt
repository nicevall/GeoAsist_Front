// REEMPLAZAR CONTENIDO DE: android/app/src/main/kotlin/com/example/geo_asist_front/MainActivity.kt
package ec.edu.uide.geo_asist_front

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.content.Context
import android.os.PowerManager
import android.provider.Settings
import android.net.Uri
import android.util.Log

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.geoasist/foreground_service"
    private lateinit var methodChannel: MethodChannel
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        Log.d("MainActivity", "Configurando Flutter Engine con MethodChannel")
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel.setMethodCallHandler { call, result ->
            Log.d("MainActivity", "MethodChannel llamado: ${call.method}")
            
            when (call.method) {
                "startForegroundService" -> {
                    Log.d("MainActivity", "Iniciando ForegroundService")
                    startTrackingService()
                    result.success(true)
                }
                "stopForegroundService" -> {
                    Log.d("MainActivity", "Deteniendo ForegroundService")
                    stopTrackingService()
                    result.success(true)
                }
                "updateNotificationStatus" -> {
                    val status = call.argument<String>("status") ?: "Tracking Activo"
                    Log.d("MainActivity", "Actualizando notificación: $status")
                    updateTrackingServiceStatus(status)
                    result.success(true)
                }
                "requestBatteryOptimizationExemption" -> {
                    Log.d("MainActivity", "Solicitando exención de batería")
                    requestBatteryOptimizationExemption()
                    result.success(true)
                }
                "isBatteryOptimizationIgnored" -> {
                    val ignored = isBatteryOptimizationIgnored()
                    Log.d("MainActivity", "Battery optimization ignored: $ignored")
                    result.success(ignored)
                }
                else -> {
                    Log.w("MainActivity", "Método no implementado: ${call.method}")
                    result.notImplemented()
                }
            }
        }
        
        Log.d("MainActivity", "MethodChannel configurado correctamente")
    }
    
    private fun startTrackingService() {
        try {
            val serviceIntent = Intent(this, TrackingForegroundService::class.java)
            serviceIntent.action = "START_TRACKING"
            startForegroundService(serviceIntent)
            Log.d("MainActivity", "ForegroundService iniciado exitosamente")
        } catch (e: Exception) {
            Log.e("MainActivity", "Error iniciando ForegroundService", e)
        }
    }
    
    private fun stopTrackingService() {
        try {
            val serviceIntent = Intent(this, TrackingForegroundService::class.java)
            serviceIntent.action = "STOP_TRACKING"
            stopService(serviceIntent)
            Log.d("MainActivity", "ForegroundService detenido exitosamente")
        } catch (e: Exception) {
            Log.e("MainActivity", "Error deteniendo ForegroundService", e)
        }
    }
    
    private fun updateTrackingServiceStatus(status: String) {
        try {
            val serviceIntent = Intent(this, TrackingForegroundService::class.java)
            serviceIntent.action = "UPDATE_STATUS"
            serviceIntent.putExtra("status", status)
            startService(serviceIntent)
            Log.d("MainActivity", "Estado del servicio actualizado: $status")
        } catch (e: Exception) {
            Log.e("MainActivity", "Error actualizando estado del servicio", e)
        }
    }
    
    private fun requestBatteryOptimizationExemption() {
        try {
            val intent = Intent()
            val packageName = packageName
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            
            if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                intent.action = Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
                intent.data = Uri.parse("package:$packageName")
                startActivity(intent)
                Log.d("MainActivity", "Solicitando exención de optimización de batería")
            } else {
                Log.d("MainActivity", "App ya está exenta de optimización de batería")
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error solicitando exención de batería", e)
        }
    }
    
    private fun isBatteryOptimizationIgnored(): Boolean {
        return try {
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            val ignored = pm.isIgnoringBatteryOptimizations(packageName)
            Log.d("MainActivity", "Battery optimization ignored status: $ignored")
            ignored
        } catch (e: Exception) {
            Log.e("MainActivity", "Error verificando optimización de batería", e)
            false
        }
    }
}