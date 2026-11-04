package app.iftekarhossain.oruv

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Build
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.Calendar

open class MainActivity : FlutterActivity() {
    companion object {
        private const val SCREEN_TIME_CHANNEL = "oruv/screen_time"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SCREEN_TIME_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkAuthorizationStatus" -> {
                    val authorized = hasUsageStatsPermission()
                    result(mapOf("authorized" to authorized))
                }

                "requestAuthorization" -> {
                    val authorized = hasUsageStatsPermission()
                    if (!authorized) {
                        openUsageAccessSettings()
                    }
                    result(
                        mapOf(
                            "authorized" to hasUsageStatsPermission()
                        )
                    )
                }

                "getDailyScreenTime" -> {
                    val maxApps = (call.argument<Int>("maxApps") ?: 8).coerceIn(1, 25)
                    val payload = queryTodayScreenTime(maxApps)
                    result(payload)
                }

                "applyShield", "clearShield", "syncShield" -> {
                    result(true)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as? AppOpsManager ?: return false
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun openUsageAccessSettings() {
        try {
            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                data = Uri.fromParts("package", packageName, null)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
        } catch (_: Exception) {
            try {
                val fallback = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(fallback)
            } catch (_: Exception) {
            }
        }
    }

    private fun queryTodayScreenTime(maxApps: Int): Map<String, Any> {
        val authorized = hasUsageStatsPermission()
        if (!authorized) {
            return mapOf(
                "authorized" to false,
                "totalMinutes" to 0,
                "apps" to emptyList<Map<String, Any?>>()
            )
        }

        val usageStatsManager =
            getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
                ?: return mapOf(
                    "authorized" to false,
                    "totalMinutes" to 0,
                    "apps" to emptyList<Map<String, Any?>>()
                )

        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val startOfDayMillis = calendar.timeInMillis
        val nowMillis = System.currentTimeMillis()

        val aggregatedStats = usageStatsManager.queryAndAggregateUsageStats(
            startOfDayMillis,
            nowMillis
        )

        val pm = applicationContext.packageManager
        val appEntries = mutableListOf<Map<String, Any?>>()
        var totalForegroundMillis = 0L

        for ((pkgName, stats) in aggregatedStats) {
            val foregroundMs = stats.totalTimeInForeground
            if (foregroundMs < 60_000L) continue // Skip apps used under 1 minute

            val appInfo = try {
                pm.getApplicationInfo(pkgName, 0)
            } catch (_: PackageManager.NameNotFoundException) {
                null
            } ?: continue

            // Include user-installed apps, updated system apps, or apps with a launcher icon
            val hasLaunchIntent = pm.getLaunchIntentForPackage(pkgName) != null
            val isSystemOnly = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0 &&
                (appInfo.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) == 0
            if (isSystemOnly && !hasLaunchIntent && pkgName != packageName) {
                continue
            }

            totalForegroundMillis += foregroundMs
            val minutes = (foregroundMs / 60_000L).toInt().coerceAtLeast(1)
            val appLabel = pm.getApplicationLabel(appInfo).toString().ifBlank { pkgName }
            val iconBytes = extractAppIconPngBytes(pm, pkgName)

            appEntries.add(
                mapOf(
                    "id" to pkgName,
                    "name" to appLabel,
                    "durationMinutes" to minutes,
                    "iconBytes" to iconBytes,
                    "isOwnApp" to (pkgName == packageName)
                )
            )
        }

        val sortedApps = appEntries
            .sortedByDescending { (it["durationMinutes"] as? Int) ?: 0 }
            .take(maxApps)

        val totalMinutes = (totalForegroundMillis / 60_000L).toInt()

        return mapOf(
            "authorized" to true,
            "totalMinutes" to totalMinutes,
            "apps" to sortedApps
        )
    }

    private fun extractAppIconPngBytes(pm: PackageManager, pkgName: String): ByteArray? {
        return try {
            val drawable: Drawable = pm.getApplicationIcon(pkgName)
            val bitmap = drawableToBitmap(drawable, 96, 96)
            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            stream.toByteArray()
        } catch (_: Exception) {
            null
        }
    }

    private fun drawableToBitmap(drawable: Drawable, width: Int, height: Int): Bitmap {
        if (drawable is BitmapDrawable && drawable.bitmap != null) {
            return Bitmap.createScaledBitmap(drawable.bitmap, width, height, true)
        }
        val bmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bmp
    }
}

