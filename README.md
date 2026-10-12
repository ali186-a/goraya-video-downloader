# 📥 All Video Downloader

A light, simple and fast Android app. Paste a video link and save the video or audio on your phone.

The app is built on the open-source tools **yt-dlp** and **FFmpeg**.

[⬇ Download the latest APK](https://github.com/ali186-a/goraya-video-downloader/releases/latest/download/Goraya-Video-Downloader.apk) | [All versions](https://github.com/ali186-a/goraya-video-downloader/releases)

---

## ✨ Features

| Feature | Details |
|---|---|
| 🔗 **Download from a link** | Paste the video link and tap Download |
| 🎞 **Quality choice** | Best Quality, 1080p, 720p, 480p, 360p |
| 🎵 **MP3 audio** | Save only the sound of a video as MP3 |
| ⏱ **Full video duration** | Shown as `HH:MM:SS` as soon as you paste a link |
| ✂️ **Download a part of a video** | Enter a Start Time and an End Time to get only the part you want |
| 🧮 **Automatic selected length** | The length of your selected part updates as you type |
| 📊 **Progress bar** | Shows percentage and time left (ETA) |
| ❌ **Cancel** | Stop a running download at any time |
| 📂 **Saved Downloads** | A list of your downloads. Tap a file to open it |
| 📤 **Share to app** | Use "Share" in your browser to send a link straight to the app |
| 💾 **Public Downloads folder** | Files are saved in `Download/GorayaDownloader` |
| 🔄 **Update notice** | The app tells you when a new version is available |
| 🔒 **No sign-up** | No account and no password |
| 🌗 **Light and Dark theme** | Follows your phone settings |

---

## 📱 Requirements

- Android 10 (API 29) or newer
- Internet connection
- About 100 MB of free space (the app is 40 to 70 MB because it includes Python and FFmpeg)
- Supported processors: `arm64-v8a` and `armeabi-v7a` (almost all modern phones)

---

## 📲 Installation

1. Tap **"Download the latest APK"** above, or open [Releases](https://github.com/ali186-a/goraya-video-downloader/releases) and take the top APK.
2. Open the downloaded file.
3. If your phone asks, allow **"Install unknown apps"** for your browser or file manager.
4. If Play Protect shows a warning, tap **"Install anyway"**. This warning is normal for apps outside the Play Store.
5. Open the app. **The first start takes a little time** while the engine is prepared. Wait until the status says "Ready".

> All releases are signed with the same key, so a new APK installs **directly over the old app**. You do not need to uninstall, and your Saved Downloads list is kept.

---

## 🧭 How to use

### 1) Download a full video

1. Copy the video link.
2. Paste it into the link box. The full duration appears automatically.
3. Choose a **quality** from the list (or **Audio only (MP3)** for sound only).
4. Tap **Download**.
5. When the progress bar is complete, the file is added to **Saved Downloads**.

### 2) Download only a part of a video

1. Paste the link and wait for the duration to appear.
2. Type the **Start** time and the **End** time.
3. The **selected length** is shown below the boxes.
4. Tap **Download**.

**Example:** For a video that is 24 minutes 35 seconds long, enter Start `05:00` and End `08:00`. The app shows a selected length of `00:03:00` (three minutes) and downloads only those three minutes.

**Accepted time formats:**

| Format | Example | Meaning |
|---|---|---|
| `MM:SS` | `05:00` | 5 minutes |
| `HH:MM:SS` | `01:05:30` | 1 hour 5 minutes 30 seconds |

**Rules:**
- If both boxes are empty, the **full video** is downloaded.
- If you enter only Start, the download runs from there to the end.
- If you enter only End, the download runs from the beginning to there.
- End must be **greater than** Start.
- End cannot be **after** the end of the video.
- If the format or time is wrong, the app shows a message and the download does not start.

### 3) Send a link from another app

In your browser or another app, tap **Share** on the video link and choose **All Video Downloader**. The link is filled in automatically.

### 4) Open a downloaded file

Tap a file name in **Saved Downloads** to open it in your video or music player. You can also find the files in the `Download/GorayaDownloader` folder using your Files app or Gallery.

### 5) File name and format

- The name comes from the video title (up to 80 characters).
- Videos are saved as **MP4** and audio as **MP3**.
- Only one video is downloaded, not a whole playlist (`--no-playlist`).

---

## ⚙️ How a download works

```
Paste link -> Duration is fetched -> Tap Download
        |
Time check (if Start/End were entered)
        |
WhatsApp Channel message (first time only)
        |
yt-dlp finds the best video and audio formats
        |
Download into the app's temporary folder
        |
FFmpeg joins video and audio into MP4 (or extracts MP3)
        |
Saved to Download/GorayaDownloader through MediaStore
        |
Temporary files are cleaned -> added to Saved Downloads
```

**How files are saved:** Since Android 10, apps cannot write directly into the Downloads folder. The app first downloads into its own temporary folder and then copies the file into the public Downloads folder using Android's official **MediaStore** system. This is why **no storage permission is needed**.

**Quality formats:** Each quality uses a yt-dlp format selector. For example, 720p uses `bv*[height<=720]+ba/b[height<=720]/b`, which means "best video up to 720p plus best audio". If that quality is not available, the closest available format is used.

---

## 🧰 Technologies

| Part | Details |
|---|---|
| **Language** | Kotlin |
| **UI** | Android Views, Material Components (Material 3), ViewBinding |
| **Background work** | Kotlin Coroutines with `lifecycleScope` |
| **Download engine** | [youtubedl-android](https://github.com/JunkFood02/youtubedl-android) (junkfood02 fork), version `0.18.1` |
| **yt-dlp** | Bundled in that library, runs on Python 3.11 |
| **FFmpeg** | `youtubedl-android:ffmpeg` module |
| **Saving files** | MediaStore (Downloads) |
| **Saving data** | SharedPreferences (Saved Downloads list) |
| **Min SDK** | 29 (Android 10) |
| **Target / Compile SDK** | 34 |
| **Build tools** | Gradle 8.7, Android Gradle Plugin 8.5.2, Kotlin 1.9.24, JDK 17 |
| **CI/CD** | GitHub Actions |
| **Package name** | `com.goraya.videodownloader` |

---

## 🎬 About yt-dlp

[yt-dlp](https://github.com/yt-dlp/yt-dlp) is a popular open-source command-line tool, written in Python, that reads video and audio information from hundreds of websites and downloads it.

**What it does in this app:**

- Gets the **title, duration and available formats** of a video
- Chooses the best video and audio stream for the selected quality
- Downloads the file and reports progress
- Downloads only a part of a video (`--download-sections "*05:00-08:00"`)

**Main options used by the app:**

| Option | Purpose |
|---|---|
| `-f <format>` | Choose the quality |
| `-o <path>` | File name and location |
| `--merge-output-format mp4` | Join video and audio into MP4 |
| `-x --audio-format mp3` | Extract only the audio as MP3 |
| `--no-playlist` | Download one video only |
| `--no-mtime` | Use the download time as the file date |
| `--download-sections` | Download only the selected part |
| `--force-keyframes-at-cuts` | Start the cut at the exact second |

**Automatic update:** Websites change often, so each time the app opens it tries to update yt-dlp to the latest version in the background. This keeps the app working without reinstalling it.

---

## 🎞 About FFmpeg

[FFmpeg](https://ffmpeg.org/) is a powerful open-source tool for working with video and audio.

**What it does in this app:**

- **Merge:** High-quality video and audio often come as separate files. FFmpeg joins them into one MP4 file.
- **Make MP3:** Extracts the sound from a video and converts it to MP3.
- **Cut:** Cuts the video to the selected Start and End time (yt-dlp uses it internally).

All of this runs inside the app through the `ffmpeg` module of `youtubedl-android`. You do not need to install anything else.

---

## 🗂 Project structure

```
.
├── .github/workflows/build-apk.yml      # Automatic APK build
├── app/
│   ├── build.gradle                     # App Gradle settings and dependencies
│   └── src/main/
│       ├── AndroidManifest.xml          # Permissions and app details
│       ├── java/com/goraya/videodownloader/
│       │   └── MainActivity.kt          # All app logic
│       └── res/
│           ├── layout/activity_main.xml     # Main screen
│           ├── layout/dialog_whatsapp.xml   # WhatsApp Channel prompt
│           ├── drawable/                    # Icon and backgrounds
│           └── values/themes.xml            # Theme
├── build.gradle                         # Project-level Gradle
├── settings.gradle
├── gradle.properties
└── README.md
```

---

## 🏗 Build the APK with GitHub Actions

You do **not** need Android Studio to build this project. GitHub builds the APK automatically after every push to the `main` branch.

**Workflow steps** (`.github/workflows/build-apk.yml`):

1. Check out the code
2. Set up JDK 17
3. Set up Gradle 8.7
4. Restore the keystore (if the Secrets exist)
5. Build the release APK with `gradle assembleRelease`
6. Rename the APK to `Goraya-Video-Downloader.apk`
7. Save it as an artifact
8. Create a new **GitHub Release** (`v1.0.<build number>`) and attach the APK

**To build it yourself:**

1. Fork this repo, or put the files in your own repo.
2. Open the **Actions** tab, choose **Build APK** and press **Run workflow**.
3. After 4 to 8 minutes, take the APK from **Releases**.

### 🔑 Permanent signing

For an update to install over the old app, every APK must be signed with **the same key (keystore)**. Create these four Secrets in **Settings → Secrets and variables → Actions**:

| Secret name | Content |
|---|---|
| `KEYSTORE_BASE64` | Base64 text of the keystore file |
| `KEYSTORE_PASSWORD` | Keystore password |
| `KEY_ALIAS` | Key alias |
| `KEY_PASSWORD` | Key password |

- Without Secrets, the build is signed with a debug key. It installs, but you must uninstall the old app before each update.
- `versionCode` increases automatically on every build (from `GITHUB_RUN_NUMBER`).
- ⚠️ **Never put the keystore or passwords in the repo, and keep a safe backup.** If you lose them, you cannot publish updates for this app.

---

## 🔐 Permissions

| Permission | Why |
|---|---|
| `INTERNET` | To read video information and download files |
| `ACCESS_NETWORK_STATE` | To know the network state |

**No storage permission is requested.** Files are saved through Android's official MediaStore system.

---

## 🔄 How updates work

- When the app opens, it checks GitHub Releases in the background for the newest version number.
- If a newer version exists, a **"New version available"** message appears.
- Tap **Update** and the new APK downloads in your browser. Then install it.
- Android does not allow silent installs outside a store, so you must tap Install yourself at the end.

---

## ⚠️ Limits and FAQ

**Does it work with every website?**
No. The app depends on yt-dlp, which supports many sites but not all. Private videos, age-restricted videos, videos that need a login, and DRM-protected videos cannot be downloaded.

**What if a download fails?**
A message appears in the status line. Reopen the app so yt-dlp can update, check the link, and check your internet.

**The duration is not shown. Why?**
Some sites and live streams do not give a duration. In that case the End Time upper limit is not checked, but the download can still work.

**The progress bar seems stuck when I download a part.**
When cutting a part, yt-dlp uses FFmpeg inside, which does not report percentage. The download is running, but the bar may not move. Full-video progress works normally.

**What if I leave the app or the screen turns off?**
The screen stays on during a download, but some phones (especially with battery saver) may close the app in the background. If that happens, start the download again.

**Why does it not run on Android 9 or older?**
The app is built for Android 10 (API 29) or newer.

**Is it on the Play Store?**
No. It is only available as an APK from GitHub Releases.

---

## ⚖️ Legal notice

- **Download only content that you own or have permission to download.**
- Following copyright laws and each website's terms of service is **the user's own responsibility**.
- The developer is not responsible for misuse by users.
- This app is not connected to, or approved by, any website or company (YouTube, TikTok, Facebook, etc.).

---

## 🙏 Credits and license

This project uses these open-source projects:

- [yt-dlp](https://github.com/yt-dlp/yt-dlp)
- [youtubedl-android (junkfood02 fork)](https://github.com/JunkFood02/youtubedl-android), based on [yausername/youtubedl-android](https://github.com/yausername/youtubedl-android)
- [FFmpeg](https://ffmpeg.org/)
- [Material Components for Android](https://github.com/material-components/material-components-android)

Each project has its own license. See the linked repositories for details. `youtubedl-android` is under the GPL license, so when you share this project further you may need to make the source code available.

**About the advertisement:** The app has a clearly labelled **"View Advertisement"** button that opens an ad link in the browser. It is separate from the Download button and does not affect downloads.

**WhatsApp Channel:** The app has a permanent WhatsApp Channel button and a short invitation message on the first download.

---

<p align="center">⭐ If you like the app, please star the repo</p>