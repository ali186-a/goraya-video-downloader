set -e

mkdir -p .github/workflows \
  app/src/main/java/com/goraya/videodownloader \
  app/src/main/res/layout app/src/main/res/values app/src/main/res/drawable

cat > settings.gradle <<'GORAYA_EOF'
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "GorayaVideoDownloader"
include ':app'
GORAYA_EOF

cat > build.gradle <<'GORAYA_EOF'
plugins {
    id 'com.android.application' version '8.5.2' apply false
    id 'org.jetbrains.kotlin.android' version '1.9.24' apply false
}
GORAYA_EOF

cat > gradle.properties <<'GORAYA_EOF'
org.gradle.jvmargs=-Xmx3g -Dfile.encoding=UTF-8
android.useAndroidX=true
android.nonTransitiveRClass=true
kotlin.code.style=official
GORAYA_EOF

cat > .gitignore <<'GORAYA_EOF'
*.iml
.gradle/
build/
local.properties
.idea/
*.apk
GORAYA_EOF

cat > app/build.gradle <<'GORAYA_EOF'
plugins {
    id 'com.android.application'
    id 'org.jetbrains.kotlin.android'
}

android {
    namespace 'com.goraya.videodownloader'
    compileSdk 34

    defaultConfig {
        applicationId "com.goraya.videodownloader"
        minSdk 29
        targetSdk 34
        versionCode 1
        versionName "1.0"

        ndk {
            abiFilters 'arm64-v8a', 'armeabi-v7a'
        }
    }

    buildTypes {
        release {
            minifyEnabled false
            signingConfig signingConfigs.debug
        }
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = '17'
    }

    buildFeatures {
        viewBinding true
    }

    packagingOptions {
        jniLibs {
            useLegacyPackaging = true
        }
    }
}

dependencies {
    implementation 'androidx.core:core-ktx:1.13.1'
    implementation 'androidx.appcompat:appcompat:1.7.0'
    implementation 'com.google.android.material:material:1.12.0'
    implementation 'androidx.lifecycle:lifecycle-runtime-ktx:2.8.4'
    implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1'

    def ytdlp = '0.16.0'
    implementation "io.github.junkfood02.youtubedl-android:library:$ytdlp"
    implementation "io.github.junkfood02.youtubedl-android:ffmpeg:$ytdlp"
}
GORAYA_EOF

cat > app/src/main/AndroidManifest.xml <<'GORAYA_EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <application
        android:allowBackup="true"
        android:icon="@drawable/ic_launcher"
        android:label="Goraya Video Downloader"
        android:theme="@style/Theme.Goraya">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
            <intent-filter>
                <action android:name="android.intent.action.SEND" />
                <category android:name="android.intent.category.DEFAULT" />
                <data android:mimeType="text/plain" />
            </intent-filter>
        </activity>
    </application>
</manifest>
GORAYA_EOF

cat > app/src/main/res/values/themes.xml <<'GORAYA_EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="Theme.Goraya" parent="Theme.Material3.DayNight.NoActionBar" />
</resources>
GORAYA_EOF

cat > app/src/main/res/drawable/ic_launcher.xml <<'GORAYA_EOF'
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path android:fillColor="#1565C0" android:pathData="M0,0h108v108h-108z" />
    <path android:fillColor="#FFFFFF" android:pathData="M48,28h12v24h12L54,70L36,52h12z" />
    <path android:fillColor="#FFFFFF" android:pathData="M36,78h36v6h-36z" />
</vector>
GORAYA_EOF

cat > app/src/main/res/layout/activity_main.xml <<'GORAYA_EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:padding="16dp">

    <TextView
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="Goraya Video Downloader"
        android:textSize="22sp"
        android:textStyle="bold"
        android:paddingBottom="12dp" />

    <com.google.android.material.textfield.TextInputLayout
        style="@style/Widget.Material3.TextInputLayout.OutlinedBox"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:hint="Video link paste karein">

        <com.google.android.material.textfield.TextInputEditText
            android:id="@+id/etUrl"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:inputType="textUri"
            android:maxLines="3" />
    </com.google.android.material.textfield.TextInputLayout>

    <Spinner
        android:id="@+id/spQuality"
        android:layout_width="match_parent"
        android:layout_height="48dp"
        android:layout_marginTop="8dp" />

    <Button
        android:id="@+id/btnDownload"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="Download" />

    <Button
        android:id="@+id/btnCancel"
        style="@style/Widget.Material3.Button.OutlinedButton"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="Cancel"
        android:visibility="gone" />

    <ProgressBar
        android:id="@+id/progress"
        style="?android:attr/progressBarStyleHorizontal"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginTop="12dp"
        android:max="100" />

    <TextView
        android:id="@+id/tvStatus"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:paddingTop="6dp"
        android:text="Starting..."
        tools:text="Ready" />

    <TextView
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:paddingTop="16dp"
        android:paddingBottom="4dp"
        android:text="Saved Downloads"
        android:textSize="16sp"
        android:textStyle="bold" />

    <ListView
        android:id="@+id/listSaved"
        android:layout_width="match_parent"
        android:layout_height="0dp"
        android:layout_weight="1" />
</LinearLayout>
GORAYA_EOF

cat > app/src/main/java/com/goraya/videodownloader/MainActivity.kt <<'GORAYA_EOF'
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

        initEngine()
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
                else setStatus("❌ Error: ${it.message?.take(200)}")
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
GORAYA_EOF

cat > .github/workflows/build-apk.yml <<'GORAYA_EOF'
name: Build APK

on:
  push:
    branches: [ main ]
  workflow_dispatch:

permissions:
  contents: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Code checkout
        uses: actions/checkout@v4

      - name: JDK 17 setup
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: 17

      - name: Gradle setup
        uses: gradle/actions/setup-gradle@v4
        with:
          gradle-version: 8.7

      - name: Release APK build
        run: gradle assembleRelease --no-daemon --stacktrace

      - name: APK ka naam theek karein
        run: cp app/build/outputs/apk/release/app-release.apk Goraya-Video-Downloader.apk

      - name: APK ko artifact ke taur par upload karein
        uses: actions/upload-artifact@v4
        with:
          name: Goraya-Video-Downloader
          path: Goraya-Video-Downloader.apk

      - name: GitHub Release banayein
        uses: softprops/action-gh-release@v2
        with:
          tag_name: v1.0.${{ github.run_number }}
          name: Goraya Video Downloader v1.0.${{ github.run_number }}
          files: Goraya-Video-Downloader.apk
GORAYA_EOF

git add -A
git commit -m "Goraya Video Downloader: initial project"
git push origin HEAD

echo "✅ Sab files ban gayin aur GitHub par push ho gayin. Ab Actions tab dekhein."