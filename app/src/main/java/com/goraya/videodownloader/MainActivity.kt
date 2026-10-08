package com.goraya.videodownloader

import android.content.ActivityNotFoundException
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import android.util.Log
import android.view.View
import android.view.WindowManager
import android.widget.ArrayAdapter
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.goraya.videodownloader.databinding.ActivityMainBinding
import com.yausername.ffmpeg.FFmpeg
import com.yausername.youtubedl_android.YoutubeDL
import com.yausername.youtubedl_android.YoutubeDLRequest
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.IOException

class MainActivity : AppCompatActivity() {

    private lateinit var b: ActivityMainBinding

    private data class Saved(val name: String, val uri: String)

    private val qualities = linkedMapOf(
        "Best Quality" to "bv*+ba/b",
        "1080p" to "bv*[height<=1080]+ba/b[height<=1080]/b",
        "720p" to "bv*[height<=720]+ba/b[height<=720]/b",
        "480p" to "bv*[height<=480]+ba/b[height<=480]/b",
        "360p" to "bv*[height<=360]+ba/b[height<=360]/b",
        "Audio only (MP3)" to "AUDIO"
    )

    private val saved = mutableListOf<Saved>()
    private lateinit var listAdapter: ArrayAdapter<String>
    private var currentProcessId: String? = null
    private var cancelled = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        b = ActivityMainBinding.inflate(layoutInflater)
        setContentView(b.root)

        b.spQuality.adapter = ArrayAdapter(
            this, android.R.layout.simple_spinner_dropdown_item, qualities.keys.toList()
        )

        listAdapter = ArrayAdapter(this, android.R.layout.simple_list_item_1, mutableListOf<String>())
        b.listSaved.adapter = listAdapter
        b.listSaved.setOnItemClickListener { _, _, pos, _ -> openFile(saved[pos]) }
        loadSaved()

        handleSharedText(intent)

        b.btnDownload.setOnClickListener { startDownload() }
        b.btnCancel.setOnClickListener { cancelDownload() }
        b.btnAd.setOnClickListener { openAdvertisement() }
        b.btnWhatsapp.setOnClickListener { openWhatsAppChannel() }

        initEngine()
        checkForUpdate()
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        handleSharedText(intent)
    }

    private fun handleSharedText(i: Intent?) {
        if (i?.action == Intent.ACTION_SEND) {
            i.getStringExtra(Intent.EXTRA_TEXT)?.let { b.etUrl.setText(it) }
        }
    }

    // ---------- Engine ----------
    private fun initEngine() {
        b.btnDownload.isEnabled = false
        setStatus("Engine start ho raha hai (pehli baar thora waqt lagega)...")
        lifecycleScope.launch {
            val ok = withContext(Dispatchers.IO) {
                try {
                    YoutubeDL.getInstance().init(applicationContext)
                    FFmpeg.getInstance().init(applicationContext)
                    true
                } catch (e: Exception) {
                    Log.e("Goraya", "init failed", e)
                    false
                }
            }
            if (ok) {
                b.btnDownload.isEnabled = true
                setStatus("Ready")
                launch(Dispatchers.IO) {
                    try {
                        YoutubeDL.getInstance()
                            .updateYoutubeDL(applicationContext, YoutubeDL.UpdateChannel.STABLE)
                    } catch (e: Exception) {
                        Log.w("Goraya", "update skipped: ${e.message}")
                    }
                }
            } else {
                setStatus("Engine start nahi ho saka. App dobara kholein.")
            }
        }
    }

    // ---------- Download ----------
    private fun startDownload() {
        val hasUrl = Regex("https?://\\S+").containsMatchIn(b.etUrl.text?.toString().orEmpty())
        if (!hasUrl || isWhatsAppConfirmed()) {
            startDownloadReal()
            return
        }
        showWhatsAppGate { startDownloadReal() }
    }

    private fun startDownloadReal() {
        val raw = b.etUrl.text?.toString().orEmpty()
        val url = Regex("https?://\\S+").find(raw)?.value
        if (url == null) {
            Toast.makeText(this, "Sahi video link paste karein", Toast.LENGTH_SHORT).show()
            return
        }

        val fmt = qualities[b.spQuality.selectedItem as String] ?: "bv*+ba/b"
        val tmp = File(getExternalFilesDir(null) ?: filesDir, "tmp_${System.currentTimeMillis()}")
            .apply { mkdirs() }
        val pid = "goraya_${System.currentTimeMillis()}"
        currentProcessId = pid
        cancelled = false
        setDownloading(true)
        setStatus("Shuru ho raha hai...")

        lifecycleScope.launch {
            val result = withContext(Dispatchers.IO) {
                try {
                    val req = YoutubeDLRequest(url)
                    req.addOption("-o", "${tmp.absolutePath}/%(title).80s.%(ext)s")
                    req.addOption("--no-playlist")
                    req.addOption("--no-mtime")
                    if (fmt == "AUDIO") {
                        req.addOption("-x")
                        req.addOption("--audio-format", "mp3")
                    } else {
                        req.addOption("-f", fmt)
                        req.addOption("--merge-output-format", "mp4")
                    }

                    YoutubeDL.getInstance().execute(req, pid) { progress, eta, _ ->
                        if (progress >= 0) {
                            runOnUiThread {
                                b.progress.progress = progress.toInt().coerceIn(0, 100)
                                setStatus("${progress.toInt()}%  •  ETA ${eta}s")
                            }
                        }
                    }

                    val file = tmp.listFiles()
                        ?.filter { it.isFile && !it.name.endsWith(".part") && !it.name.endsWith(".ytdl") }
                        ?.maxByOrNull { it.length() }
                        ?: throw IOException("Downloaded file nahi mili")

                    val name = file.name
                    val uri = saveToDownloads(file)
                    Result.success(Saved(name, uri.toString()))
                } catch (e: Exception) {
                    Result.failure<Saved>(e)
                } finally {
                    tmp.deleteRecursively()
                }
            }

            setDownloading(false)
            result.onSuccess {
                saved.add(0, it)
                persistSaved()
                refreshList()
                b.progress.progress = 100
                setStatus("✅ Mukammal! Download/GorayaDownloader mein save ho gayi")
            }.onFailure {
                b.progress.progress = 0
                if (cancelled) setStatus("Cancel kar diya gaya")
                else setStatus("❌ Error: ${it.message?.takeLast(300)}")
            }
        }
    }

    private fun cancelDownload() {
        val pid = currentProcessId ?: return
        cancelled = true
        lifecycleScope.launch(Dispatchers.IO) {
            try { YoutubeDL.getInstance().destroyProcessById(pid) } catch (_: Exception) {}
        }
    }

    // ---------- Public Downloads folder mein save (MediaStore) ----------
    private fun saveToDownloads(src: File): Uri {
        val mime = when (src.extension.lowercase()) {
            "mp4" -> "video/mp4"
            "mkv" -> "video/x-matroska"
            "webm" -> "video/webm"
            "mp3" -> "audio/mpeg"
            "m4a" -> "audio/mp4"
            else -> "application/octet-stream"
        }
        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, src.name)
            put(MediaStore.Downloads.MIME_TYPE, mime)
            put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS + "/GorayaDownloader")
            put(MediaStore.Downloads.IS_PENDING, 1)
        }
        val resolver = contentResolver
        val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
            ?: throw IOException("Download folder mein file nahi ban saki")
        resolver.openOutputStream(uri).use { out ->
            if (out == null) throw IOException("Output stream nahi khula")
            src.inputStream().use { it.copyTo(out) }
        }
        values.clear()
        values.put(MediaStore.Downloads.IS_PENDING, 0)
        resolver.update(uri, values, null, null)
        return uri
    }

    // ---------- Saved list ----------
    private fun openFile(item: Saved) {
        val uri = Uri.parse(item.uri)
        val intent = Intent(Intent.ACTION_VIEW)
            .setDataAndType(uri, contentResolver.getType(uri) ?: "*/*")
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        try {
            startActivity(intent)
        } catch (e: ActivityNotFoundException) {
            Toast.makeText(this, "File kholne ke liye koi app nahi mili", Toast.LENGTH_SHORT).show()
        }
    }

    private fun refreshList() {
        listAdapter.clear()
        listAdapter.addAll(saved.map { it.name })
        listAdapter.notifyDataSetChanged()
    }

    private fun persistSaved() {
        val arr = JSONArray()
        saved.take(100).forEach {
            arr.put(JSONObject().put("n", it.name).put("u", it.uri))
        }
        getSharedPreferences("goraya", MODE_PRIVATE).edit().putString("saved", arr.toString()).apply()
    }

    private fun loadSaved() {
        val s = getSharedPreferences("goraya", MODE_PRIVATE).getString("saved", null) ?: return
        try {
            val arr = JSONArray(s)
            for (i in 0 until arr.length()) {
                val o = arr.getJSONObject(i)
                saved.add(Saved(o.getString("n"), o.getString("u")))
            }
        } catch (_: Exception) { }
        refreshList()
    }

    // ---------- WhatsApp Channel ----------
    private val waUrl = "https://whatsapp.com/channel/0029VaDMPDP11ulIDMh8NS02"

    private fun isWhatsAppConfirmed(): Boolean =
        getSharedPreferences("goraya", MODE_PRIVATE).getBoolean("wa_confirmed", false)

    private fun openWhatsAppChannel() {
        val uri = Uri.parse(waUrl)
        for (pkg in listOf("com.whatsapp", "com.whatsapp.w4b", null)) {
            try {
                val i = Intent(Intent.ACTION_VIEW, uri)
                if (pkg != null) i.setPackage(pkg)
                startActivity(i)
                return
            } catch (e: Exception) {
                // agla tareeqa aazmayein
            }
        }
        Toast.makeText(this, "Link nahi khul saka", Toast.LENGTH_SHORT).show()
    }

    private fun showWhatsAppGate(onConfirmed: () -> Unit) {
        val view = layoutInflater.inflate(R.layout.dialog_whatsapp, null)
        val dialog = android.app.Dialog(this)
        dialog.requestWindowFeature(android.view.Window.FEATURE_NO_TITLE)
        dialog.setContentView(view)
        dialog.window?.setBackgroundDrawable(
            android.graphics.drawable.ColorDrawable(android.graphics.Color.TRANSPARENT)
        )
        val maxW = (400 * resources.displayMetrics.density).toInt()
        val w = minOf((resources.displayMetrics.widthPixels * 0.92f).toInt(), maxW)
        dialog.window?.setLayout(w, android.view.ViewGroup.LayoutParams.WRAP_CONTENT)

        view.findViewById<View>(R.id.btnWaJoin).setOnClickListener { openWhatsAppChannel() }
        view.findViewById<View>(R.id.btnWaConfirm).setOnClickListener {
            getSharedPreferences("goraya", MODE_PRIVATE)
                .edit().putBoolean("wa_confirmed", true).apply()
            dialog.dismiss()
            onConfirmed()
        }
        view.findViewById<View>(R.id.btnWaClose).setOnClickListener { dialog.dismiss() }
        dialog.show()
    }

    // ---------- Update check ----------
    private val releasesApi =
        "https://api.github.com/repos/ali186-a/goraya-video-downloader/releases/latest"
    private val apkDirectUrl =
        "https://github.com/ali186-a/goraya-video-downloader/releases/latest/download/Goraya-Video-Downloader.apk"

    private fun checkForUpdate() {
        lifecycleScope.launch {
            val latest: Int? = withContext(Dispatchers.IO) {
                var result: Int? = null
                try {
                    val c = java.net.URL(releasesApi).openConnection() as java.net.HttpURLConnection
                    c.connectTimeout = 8000
                    c.readTimeout = 8000
                    c.setRequestProperty("Accept", "application/vnd.github+json")
                    try {
                        if (c.responseCode == 200) {
                            val body = c.inputStream.bufferedReader().readText()
                            val tag = JSONObject(body).optString("tag_name")
                            result = tag.substringAfterLast('.').toIntOrNull()
                        }
                    } finally {
                        c.disconnect()
                    }
                } catch (e: Exception) {
                    Log.w("Goraya", "update check skipped: ${e.message}")
                }
                result
            }

            val current: Long = try {
                packageManager.getPackageInfo(packageName, 0).longVersionCode
            } catch (e: Exception) {
                Long.MAX_VALUE
            }

            if (latest != null && latest.toLong() > current && !isFinishing && !isDestroyed) {
                showUpdateDialog()
            }
        }
    }

    private fun showUpdateDialog() {
        com.google.android.material.dialog.MaterialAlertDialogBuilder(this)
            .setTitle("نیا ورژن دستیاب ہے")
            .setMessage("Goraya Video Downloader کا نیا ورژن آ چکا ہے۔ تازہ فیچرز اور بہتری کے لیے اپڈیٹ کریں۔")
            .setPositiveButton("اپڈیٹ کریں") { _, _ ->
                try {
                    startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(apkDirectUrl)))
                } catch (e: Exception) {
                    Toast.makeText(this, "Link nahi khul saka", Toast.LENGTH_SHORT).show()
                }
            }
            .setNegativeButton("بعد میں", null)
            .show()
    }

    // ---------- Advertisement (Adsterra SmartLink) ----------
    // Zone: smart-link-3506915 | Placement: Smartlink_1 (31619689)
    // Link badalna ho to sirf neeche wali value badlein.
    private val ADSTERRA_SMARTLINK = "https://asiafilm.org/4/9a7912e1c40f447afcb67add365f3e88"

    private fun openAdvertisement() {
        try {
            startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(ADSTERRA_SMARTLINK)))
        } catch (e: ActivityNotFoundException) {
            Toast.makeText(this, "Browser nahi mila", Toast.LENGTH_SHORT).show()
        } catch (e: Exception) {
            Toast.makeText(this, "Link nahi khul saka", Toast.LENGTH_SHORT).show()
        }
    }

    // ---------- UI helpers ----------
    private fun setStatus(s: String) { b.tvStatus.text = s }

    private fun setDownloading(on: Boolean) {
        b.btnDownload.isEnabled = !on
        b.btnCancel.visibility = if (on) View.VISIBLE else View.GONE
        if (on) {
            b.progress.progress = 0
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }
    }
}
