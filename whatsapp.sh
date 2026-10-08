set -e

mkdir -p app/src/main/res/layout app/src/main/res/drawable

cat > app/src/main/res/drawable/ic_whatsapp.xml <<'WA_EOF'
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="64dp"
    android:height="64dp"
    android:viewportWidth="48"
    android:viewportHeight="48">
    <path android:fillColor="#25D366"
        android:pathData="M24,2a22,22 0,1 0,0 44a22,22 0,1 0,0 -44z" />
    <path android:fillColor="#FFFFFF"
        android:pathData="M24,12c-6.6,0 -12,5.1 -12,11.4c0,2.2 0.7,4.2 1.9,5.9l-1.4,5.7l6,-1.6c1.6,0.9 3.4,1.4 5.5,1.4c6.6,0 12,-5.1 12,-11.4S30.6,12 24,12z" />
</vector>
WA_EOF

cat > app/src/main/res/drawable/bg_dialog.xml <<'WA_EOF'
<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android"
    android:shape="rectangle">
    <solid android:color="?attr/colorSurface" />
    <corners android:radius="24dp" />
</shape>
WA_EOF

cat > app/src/main/res/layout/dialog_whatsapp.xml <<'WA_EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:background="@drawable/bg_dialog"
    android:gravity="center_horizontal"
    android:orientation="vertical"
    android:padding="24dp">

    <ImageView
        android:layout_width="64dp"
        android:layout_height="64dp"
        android:contentDescription="WhatsApp"
        android:src="@drawable/ic_whatsapp" />

    <TextView
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:lineSpacingExtra="4dp"
        android:paddingTop="16dp"
        android:text="ویڈیو ڈاؤنلوڈ کرنے کے لیے پہلے ہمارا WhatsApp Channel Join کریں۔"
        android:textAlignment="center"
        android:textColor="?attr/colorOnSurface"
        android:textSize="19sp"
        android:textStyle="bold" />

    <TextView
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:lineSpacingExtra="3dp"
        android:paddingTop="10dp"
        android:text="تازہ Updates، نئی Features اور اہم معلومات کے لیے ہمارے WhatsApp Channel کو Follow کریں۔"
        android:textAlignment="center"
        android:textColor="?attr/colorOnSurfaceVariant"
        android:textSize="14sp" />

    <com.google.android.material.button.MaterialButton
        android:id="@+id/btnWaJoin"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginTop="20dp"
        android:minHeight="52dp"
        android:text="WhatsApp Channel Join کریں"
        android:textColor="#FFFFFF"
        android:textSize="15sp"
        app:backgroundTint="#25D366"
        app:cornerRadius="28dp" />
    <TextView
        android:id="@+id/btnWaClose"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginTop="6dp"
        android:background="?attr/selectableItemBackground"
        android:clickable="true"
        android:focusable="true"
        android:padding="12dp"
        android:text="بعد میں"
        android:textColor="?attr/colorOnSurfaceVariant"
        android:textSize="14sp" />
</LinearLayout>
WA_EOF

python3 - <<'PY'
import sys

K = 'app/src/main/java/com/goraya/videodownloader/MainActivity.kt'
L = 'app/src/main/res/layout/activity_main.xml'

def fail(msg):
    print("❌ " + msg)
    print("Kuch nahi badla gaya. Mujhe yeh message bhej dein.")
    sys.exit(1)

k = open(K, encoding='utf-8').read()
l = open(L, encoding='utf-8').read()

# ---------- MainActivity.kt ----------
if 'showWhatsAppGate' not in k:
    a1 = 'b.btnCancel.setOnClickListener { cancelDownload() }'
    a2 = 'private fun startDownload() {'
    a3 = '    // ---------- UI helpers ----------'
    for a in (a1, a2, a3):
        if k.count(a) != 1:
            fail("MainActivity.kt mein yeh jagah nahi mili: " + a)

    k = k.replace(a1, a1 + '\n        b.btnWhatsapp.setOnClickListener { openWhatsAppChannel() }')

    k = k.replace(a2, r'''private fun startDownload() {
        val hasUrl = Regex("https?://\\S+").containsMatchIn(b.etUrl.text?.toString().orEmpty())
        if (!hasUrl || isWhatsAppConfirmed()) {
            startDownloadReal()
            return
        }
        showWhatsAppGate { startDownloadReal() }
    }

    private fun startDownloadReal() {''')

    gate = r'''    // ---------- WhatsApp Channel ----------
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

'''
    k = k.replace(a3, gate + a3)

# ---------- activity_main.xml ----------
if 'btnWhatsapp' not in l:
    t = 'android:text="Saved Downloads"'
    if l.count(t) != 1:
        fail("activity_main.xml mein 'Saved Downloads' wali jagah nahi mili")
    if 'xmlns:app=' not in l:
        x = 'xmlns:tools="http://schemas.android.com/tools"'
        if l.count(x) != 1:
            fail("activity_main.xml mein xmlns:tools nahi mila")
        l = l.replace(x, x + '\n    xmlns:app="http://schemas.android.com/apk/res-auto"')
    idx = l.index(t)
    start = l.rfind('<TextView', 0, idx)
    if start < 0:
        fail("Saved Downloads ka TextView nahi mila")
    btn = '''<com.google.android.material.button.MaterialButton
        android:id="@+id/btnWhatsapp"
        style="@style/Widget.Material3.Button.OutlinedButton"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginTop="12dp"
        android:text="📱 WhatsApp Channel"
        android:textColor="#128C7E"
        app:cornerRadius="24dp"
        app:strokeColor="#25D366" />

    '''
    l = l[:start] + btn + l[start:]

open(K, 'w', encoding='utf-8').write(k)
open(L, 'w', encoding='utf-8').write(l)
print("✅ Files patch ho gayin")
PY

grep -c "showWhatsAppGate" app/src/main/java/com/goraya/videodownloader/MainActivity.kt
grep -c "btnWhatsapp" app/src/main/res/layout/activity_main.xml

git add -A
git commit -m "Add WhatsApp Channel gate and permanent button"
git push origin HEAD

echo ""
echo "✅ Mukammal. Ab GitHub Actions mein build ka intezar karein."