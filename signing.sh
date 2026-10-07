set -e

ALIAS="goraya"
PASS="$(head -c 200 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 20)"

if ! command -v keytool >/dev/null 2>&1; then
  echo "keytool nahi mila, Java install kar raha hon..."
  sudo apt-get update -y && sudo apt-get install -y default-jre-headless
fi

if [ -f goraya-release.jks ]; then
  echo "❌ goraya-release.jks pehle se maujood hai. Purani key na mitayein. Script band."
  exit 1
fi

# 1) Keystore banayein
keytool -genkeypair -v -keystore goraya-release.jks -alias "$ALIAS" \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass "$PASS" -keypass "$PASS" \
  -dname "CN=Goraya Video Downloader, O=Goraya, C=PK"

base64 -w0 goraya-release.jks > keystore.b64
printf "KEYSTORE_PASSWORD=%s\nKEY_ALIAS=%s\nKEY_PASSWORD=%s\n" "$PASS" "$ALIAS" "$PASS" > keystore-info.txt

# 2) Raaz repo mein commit hone se rokein
printf "\n*.jks\nkeystore.b64\nkeystore-info.txt\n" >> .gitignore

# 3) build.gradle mein signing aur auto versionCode
python3 - <<'PY'
p = 'app/build.gradle'
s = open(p).read()
if 'KEYSTORE_PATH' not in s:
    block = """    signingConfigs {
        release {
            def ksPath = System.getenv("KEYSTORE_PATH")
            if (ksPath) {
                storeFile file(ksPath)
                storePassword System.getenv("KEYSTORE_PASSWORD")
                keyAlias System.getenv("KEY_ALIAS")
                keyPassword System.getenv("KEY_PASSWORD")
            }
        }
    }

"""
    s = s.replace("    buildTypes {", block + "    buildTypes {", 1)
    s = s.replace("signingConfig signingConfigs.debug",
                  'signingConfig(System.getenv("KEYSTORE_PATH") ? signingConfigs.release : signingConfigs.debug)')
    s = s.replace("versionCode 1",
                  'versionCode Integer.parseInt(System.getenv("GITHUB_RUN_NUMBER") ?: "1")')
    open(p, 'w').write(s)
PY

# 4) Workflow dobara likhein
cat > .github/workflows/build-apk.yml <<'SIGN_EOF'
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

      - name: Keystore tayyar karein
        env:
          KEYSTORE_BASE64: ${{ secrets.KEYSTORE_BASE64 }}
        run: |
          if [ -n "$KEYSTORE_BASE64" ]; then
            echo "$KEYSTORE_BASE64" | base64 -d > "$RUNNER_TEMP/release.jks"
            echo "KEYSTORE_PATH=$RUNNER_TEMP/release.jks" >> "$GITHUB_ENV"
            echo "Apni keystore se sign hoga"
          else
            echo "Keystore nahi mili, debug key use hogi"
          fi

      - name: Release APK build
        env:
          KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
          KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
          KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
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
SIGN_EOF

# 5) GitHub Secrets khud set karne ki koshish
set +e
gh secret set KEYSTORE_BASE64 < keystore.b64 >/dev/null 2>&1 && \
gh secret set KEYSTORE_PASSWORD -b "$PASS" >/dev/null 2>&1 && \
gh secret set KEY_ALIAS -b "$ALIAS" >/dev/null 2>&1 && \
gh secret set KEY_PASSWORD -b "$PASS" >/dev/null 2>&1
SECRETS_RC=$?
set -e

git add -A
git commit -m "Permanent keystore signing + auto versionCode"
git push origin HEAD

echo ""
echo "================ ZAROORI ================"
cat keystore-info.txt
if [ "$SECRETS_RC" -eq 0 ]; then
  echo "✅ GitHub Secrets khud set ho gaye."
else
  echo "⚠️ Secrets khud set nahi huay. Neeche diya gaya dastee tareeqa karein."
fi
echo "========================================="