set -e

python3 - <<'PY'
import sys

K = 'app/src/main/java/com/goraya/videodownloader/MainActivity.kt'
k = open(K, encoding='utf-8').read()

def fail(msg):
    print("❌ " + msg)
    print("Kuch nahi badla gaya. Mujhe yeh message bhej dein.")
    sys.exit(1)

if 'checkForUpdate' in k:
    print("ℹ️ Update check pehle se shamil hai, kuch nahi badla.")
    sys.exit(0)

a1 = '\n        initEngine()\n'
a2 = '    // ---------- UI helpers ----------'
if k.count(a1) != 1:
    fail("onCreate mein initEngine() wali jagah nahi mili")
if k.count(a2) != 1:
    fail("UI helpers wali jagah nahi mili")

k = k.replace(a1, '\n        initEngine()\n        checkForUpdate()\n')

func = r'''    // ---------- Update check ----------
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

'''
k = k.replace(a2, func + a2)
open(K, 'w', encoding='utf-8').write(k)
print("✅ MainActivity.kt patch ho gayi")
PY

grep -c "checkForUpdate" app/src/main/java/com/goraya/videodownloader/MainActivity.kt

git add -A
git commit -m "Add in-app update check (GitHub Releases)"
git push origin HEAD

echo ""
echo "✅ Mukammal. Ab GitHub Actions mein build ka intezar karein."