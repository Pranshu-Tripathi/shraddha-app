package com.example.shanti

import android.app.WallpaperManager
import android.content.ActivityNotFoundException
import android.content.ContentValues
import android.content.Intent
import android.graphics.BitmapFactory
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, "shanti/wallpaper").setMethodCallHandler { call, result ->
            when (call.method) {
                "setWallpaper" -> setWallpaper(
                    call.argument<ByteArray>("bytes"),
                    call.argument<String>("target") ?: "both",
                    result,
                )
                else -> result.notImplemented()
            }
        }

        MethodChannel(messenger, "shanti/ringtone").setMethodCallHandler { call, result ->
            when (call.method) {
                "setRingtone" -> setRingtone(
                    call.argument<ByteArray>("bytes"),
                    call.argument<String>("name") ?: "shanti",
                    call.argument<String>("mimeType") ?: "audio/x-wav",
                    result,
                )
                else -> result.notImplemented()
            }
        }

        MethodChannel(messenger, "shanti/status").setMethodCallHandler { call, result ->
            when (call.method) {
                "shareToWhatsApp" -> shareToWhatsApp(call.argument<String>("path"), result)
                "isWhatsAppInstalled" -> result.success(isPackageInstalled("com.whatsapp"))
                else -> result.notImplemented()
            }
        }
    }

    private fun setWallpaper(bytes: ByteArray?, target: String, result: MethodChannel.Result) {
        if (bytes == null) { result.error("no_bytes", "bytes is required", null); return }
        try {
            val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
                ?: throw IllegalArgumentException("could not decode image")
            val wm = WallpaperManager.getInstance(applicationContext)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                var which = 0
                if (target == "home" || target == "both") which = which or WallpaperManager.FLAG_SYSTEM
                if (target == "lock" || target == "both") which = which or WallpaperManager.FLAG_LOCK
                wm.setBitmap(bitmap, null, true, which)
            } else {
                wm.setBitmap(bitmap)
            }
            result.success(true)
        } catch (e: Exception) {
            result.error("set_failed", e.message, null)
        }
    }

    private fun setRingtone(bytes: ByteArray?, name: String, mimeType: String, result: MethodChannel.Result) {
        if (bytes == null) { result.error("no_bytes", "bytes is required", null); return }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.System.canWrite(applicationContext)) {
            try {
                startActivity(
                    Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS)
                        .setData(Uri.parse("package:$packageName"))
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                )
            } catch (_: Exception) {}
            result.success("needs_permission")
            return
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            result.error("unsupported", "ringtone setting requires Android 10+", null)
            return
        }
        try {
            val resolver = applicationContext.contentResolver
            val collection = MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            val extension = extensionForMimeType(mimeType)
            val fileName = "${name}_shanti.$extension"
            resolver.delete(collection, "${MediaStore.Audio.Media.DISPLAY_NAME}=?", arrayOf(fileName))
            val values = ContentValues().apply {
                put(MediaStore.Audio.Media.DISPLAY_NAME, fileName)
                put(MediaStore.Audio.Media.MIME_TYPE, mimeType)
                put(MediaStore.Audio.Media.RELATIVE_PATH, "${Environment.DIRECTORY_RINGTONES}/Shanti")
                put(MediaStore.Audio.Media.IS_RINGTONE, true)
                put(MediaStore.Audio.Media.IS_PENDING, 1)
            }
            val uri = resolver.insert(collection, values)
                ?: throw IllegalStateException("could not create ringtone entry")
            resolver.openOutputStream(uri).use { it!!.write(bytes) }
            values.clear()
            values.put(MediaStore.Audio.Media.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            RingtoneManager.setActualDefaultRingtoneUri(
                applicationContext, RingtoneManager.TYPE_RINGTONE, uri,
            )
            result.success("set")
        } catch (e: Exception) {
            result.error("set_failed", e.message, null)
        }
    }

    private fun extensionForMimeType(mimeType: String): String {
        return when (mimeType.lowercase()) {
            "audio/aac" -> "aac"
            "audio/flac" -> "flac"
            "audio/mp4", "audio/m4a", "audio/x-m4a" -> "m4a"
            "audio/mpeg", "audio/mp3" -> "mp3"
            "audio/ogg", "audio/opus" -> "ogg"
            "audio/wav", "audio/x-wav", "audio/wave" -> "wav"
            else -> "audio"
        }
    }

    private fun shareToWhatsApp(path: String?, result: MethodChannel.Result) {
        if (path == null) { result.error("no_path", "path is required", null); return }
        try {
            val file = File(path)
            val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
            // Go straight to WhatsApp (or WhatsApp Business) — never an app chooser.
            for (pkg in listOf("com.whatsapp", "com.whatsapp.w4b")) {
                val send = Intent(Intent.ACTION_SEND).apply {
                    type = "image/*"
                    putExtra(Intent.EXTRA_STREAM, uri)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    setPackage(pkg)
                }
                try {
                    startActivity(send)
                    result.success("shared")
                    return
                } catch (e: ActivityNotFoundException) {
                    // Try the next WhatsApp variant.
                }
            }
            result.success("not_installed")
        } catch (e: Exception) {
            result.error("share_failed", e.message, null)
        }
    }

    private fun isPackageInstalled(pkg: String): Boolean {
        return try {
            packageManager.getPackageInfo(pkg, 0)
            true
        } catch (e: Exception) {
            false
        }
    }
}
