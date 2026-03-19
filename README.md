<div align="center">

<!-- Banner -->
<img src="https://capsule-render.vercel.app/api?type=waving&color=0:0f0f23,50:1a1a3e,100:00d4ff&height=200&section=header&text=CardoCard&fontSize=70&fontColor=ffffff&fontAlignY=38&desc=Smart%20NFC%20Business%20Card%20Writer&descAlignY=58&descSize=22&animation=fadeIn" width="100%"/>

<!-- Badges -->
<p>
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/NFC-Technology-00d4ff?style=for-the-badge&logo=nfc&logoColor=white" />
  <img src="https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" />
  <img src="https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=ios&logoColor=white" />
</p>

<p>
  <img src="https://img.shields.io/github/languages/top/NufalXBaalash/CardoCard?style=flat-square&color=00d4ff" />
  <img src="https://img.shields.io/github/repo-size/NufalXBaalash/CardoCard?style=flat-square&color=7c3aed" />
  <img src="https://img.shields.io/github/last-commit/NufalXBaalash/CardoCard?style=flat-square&color=10b981" />
  <img src="https://img.shields.io/badge/license-MIT-yellow?style=flat-square" />
</p>

<br/>

> **CardoCard** turns your smartphone into a smart business card writer.  
> Encode your contact info, links, or any data onto NFC cards — instantly, wirelessly, effortlessly.

<br/>

</div>

---

## 🌟 What is CardoCard?

**CardoCard** is a cross-platform Flutter application that lets you **read, write, and manage NFC cards** — turning a blank NFC tag into a fully customized digital business card. Whether you're a developer, entrepreneur, or just someone who loves tap-to-share technology, CardoCard gives you full control over your NFC experience.

Forget paper business cards. Tap, write, share.

---

## ✨ Features

| Feature | Description |
|---|---|
| 📝 **NFC Write** | Write custom data (URLs, text, contact info) to any NFC tag |
| 📖 **NFC Read** | Instantly read and display data from NFC tags |
| 💳 **Card Profiles** | Create and manage multiple card profiles |
| 📱 **Cross-Platform** | Runs on both Android and iOS |
| ⚡ **Fast & Lightweight** | Native NFC bridge via C/C++ for maximum performance |
| 🔒 **Secure** | No cloud, no data collection — fully offline |

---

## 🗂️ Project Structure

```
CardoCard/
│
├── 📁 nfc_writer/          # Core Flutter NFC writer application
│   ├── lib/                # Dart source code
│   ├── android/            # Android-specific NFC native code
│   ├── ios/                # iOS-specific NFC native code
│   └── pubspec.yaml        # Flutter dependencies
│
├── 📁 test_1/              # Test module & NFC experiments
│   └── lib/                # Test Dart code
│
├── 📁 images/              # App screenshots & assets
│
├── 📁 .idea/               # IDE configuration
│
└── README.md
```

---

## 🛠️ Tech Stack

<div align="center">

| Layer | Technology |
|---|---|
| **UI Framework** | Flutter / Dart |
| **Native Bridge** | C / C++ (CMake) |
| **NFC Protocol** | NDEF (NFC Data Exchange Format) |
| **iOS Support** | Swift + CoreNFC |
| **Build System** | CMake + Gradle |

</div>

```
📊 Language Breakdown

  Dart      ████████████████░░░░░░░░░░░░░░  46.2%
  C++       ████████░░░░░░░░░░░░░░░░░░░░░░  22.0%
  C         ███████░░░░░░░░░░░░░░░░░░░░░░░  18.7%
  CMake     █████░░░░░░░░░░░░░░░░░░░░░░░░░  12.1%
  Swift     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   0.5%
  HTML      ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   0.3%
```

---

## 🚀 Getting Started

### Prerequisites

Before running CardoCard, make sure you have the following installed:

- ✅ [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.0+)
- ✅ Dart SDK (comes with Flutter)
- ✅ Android Studio **or** Xcode (for iOS)
- ✅ A physical NFC-capable device (NFC cannot be tested on emulators)
- ✅ Git

---

### 📦 Installation

**1. Clone the repository**
```bash
git clone https://github.com/NufalXBaalash/CardoCard.git
cd CardoCard
```

**2. Navigate to the main app**
```bash
cd nfc_writer
```

**3. Install Flutter dependencies**
```bash
flutter pub get
```

**4. Run the app**
```bash
flutter run
```

> ⚠️ Make sure your device is connected via USB with developer mode enabled.

---

### 🤖 Android Setup

Add the NFC permission to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.NFC" />
<uses-feature android:name="android.hardware.nfc" android:required="true" />
```

---

### 🍎 iOS Setup

1. Open `ios/Runner.xcworkspace` in **Xcode**
2. Go to **Signing & Capabilities** → add **Near Field Communication Tag Reading**
3. In `ios/Runner/Info.plist`, add:

```xml
<key>NFCReaderUsageDescription</key>
<string>CardoCard needs NFC access to read and write your smart cards.</string>
```

---

## 📲 How It Works

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│   User enters data  →  App encodes NDEF message         │
│                                                         │
│   App activates NFC  →  User taps NFC tag               │
│                                                         │
│   NFC tag is written  →  Tag is ready to share! 🎉      │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Step-by-step:**
1. Open CardoCard and enter the data you want to write (URL, name, contact, etc.)
2. Press **Write** — the app will activate your device's NFC scanner
3. Tap your NFC card/tag to the back of your phone
4. Done! Your card is now programmed and ready to share

To **read** a card: tap your phone to any NFC tag and the app will instantly display its contents.

---

## 🔧 Running Tests

```bash
cd test_1
flutter pub get
flutter test
```

---

## 📋 Requirements

| Requirement | Minimum Version |
|---|---|
| Flutter | 3.0.0+ |
| Dart | 2.17.0+ |
| Android SDK | API 19+ |
| iOS | 13.0+ |
| Xcode | 14+ |

---

## 🤝 Contributing

Contributions are always welcome! Here's how to get started:

1. **Fork** the repository
2. Create your feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add some amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a **Pull Request**

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

## 👤 Author

<div align="center">

**NufalXBaalash**

[![GitHub](https://img.shields.io/badge/GitHub-NufalXBaalash-181717?style=for-the-badge&logo=github)](https://github.com/NufalXBaalash)

</div>

---

<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:00d4ff,50:1a1a3e,100:0f0f23&height=120&section=footer" width="100%"/>

*Built with ❤️ and Flutter — tap to connect, tap to share*

</div>
