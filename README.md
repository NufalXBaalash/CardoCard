<div align="center">

<!-- Banner -->
<img src="https://capsule-render.vercel.app/api?type=waving&color=0:0f0f23,50:1a1a3e,100:00d4ff&height=200&section=header&text=CardoCard&fontSize=70&fontColor=ffffff&fontAlignY=38&desc=AI-Powered%20Health%20Platform&descAlignY=58&descSize=22&animation=fadeIn" width="100%"/>

<!-- Badges -->
<p>
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white" />
  <img src="https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white" />
  <img src="https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white" />
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" />
</p>

<p>
  <img src="https://img.shields.io/github/languages/top/NufalXBaalash/CardoCard?style=flat-square&color=00d4ff" />
  <img src="https://img.shields.io/github/repo-size/NufalXBaalash/CardoCard?style=flat-square&color=7c3aed" />
  <img src="https://img.shields.io/github/last-commit/NufalXBaalash/CardoCard?style=flat-square&color=10b981" />
  <img src="https://img.shields.io/badge/license-MIT-yellow?style=flat-square" />
</p>

<br/>

> **CardoCard** is an AI-powered health platform with role-based access for patients and doctors.
> Book appointments, manage medical records, track medications, and chat with an AI health assistant.

<br/>

</div>

---

## Features

### Patient
- Book appointments with doctors by specialty
- View and manage medical records
- Track medications and health metrics
- AI health assistant (chat with real-time responses)
- NFC card authentication for quick login
- Profile and medical info management
- Dark mode, RTL (Arabic) support

### Doctor
- Dashboard with patient and appointment stats
- Manage patient list and view their records
- Accept, complete, or cancel appointments
- Upload medical reports for patients
- Manage weekly schedule and availability slots

### AI Orchestrator (Python Backend)
- Intent detection (health questions, report analysis, appointments, general chat)
- Medical report analysis via Groq LLM
- RAG-based Q&A over uploaded medical documents
- Doctor search and appointment booking
- General health and app-related conversation

---

## Tech Stack

| Layer | Technology |
|---|---|
| **Mobile App** | Flutter / Dart |
| **Backend API** | Python + FastAPI |
| **AI / LLM** | Groq (llama-3.3-70b-versatile) + LangGraph |
| **Auth** | Firebase Authentication |
| **Database** | Supabase (PostgreSQL) |
| **Analytics** | Firebase Analytics |
| **Vector Store** | ChromaDB (for RAG) |
| **NFC** | NDEF protocol + USB serial bridge |

---

## Project Structure

```
CardoCard/
├── test_1/                    # Flutter mobile app
│   ├── lib/
│   │   ├── pages/             # UI pages (patient + doctor)
│   │   ├── database/          # Supabase service layer
│   │   ├── utils/             # Theme, language, NFC, serial
│   │   └── main.dart          # App entry point
│   ├── .env                   # App environment config
│   └── pubspec.yaml
│
├── cardocare_ai/              # Python AI backend
│   ├── app/
│   │   ├── agents/            # Orchestrator, Medical, RAG, General, Appointment
│   │   ├── graph/             # LangGraph flow
│   │   ├── api/               # FastAPI routes (/chat, /upload, /health)
│   │   ├── models/            # Pydantic schemas
│   │   └── services/          # Supabase, config, vector store
│   ├── .env                   # AI server environment config
│   ├── main.py                # Server entry point
│   └── requirements.txt
│
├── supabase_migration.sql     # Full database schema
├── supabase_doctor_link.sql   # Doctor-user link migration
└── README.md
```

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.0+
- [Python](https://www.python.org/) 3.10+
- [Supabase](https://supabase.com/) account (free tier works)
- [Firebase](https://console.firebase.google.com/) project
- [Groq](https://console.groq.com/) API key (free tier available)
- Physical Android/iOS device (NFC features require hardware)

---

### 1. Clone the Repository

```bash
git clone https://github.com/NufalXBaalash/CardoCard.git
cd CardoCard
```

---

### 2. Set Up Supabase

Create a project at [supabase.com](https://supabase.com), then copy your **Project URL** and **anon/public key** from Dashboard > Settings > API.

You'll need these for both the Flutter app and the AI server `.env` files.

---

### 3. Set Up the Flutter App

```bash
cd test_1
flutter pub get
```

Create a `.env` file in `test_1/`:

```env
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=your-supabase-anon-key
AI_API_URL=http://192.168.x.x:8000
```

> For `AI_API_URL`: use your PC's local IP (find it with `ip addr` on Linux or `ipconfig` on Windows). Your phone must be on the same WiFi network. For Android emulator, use `http://10.0.2.2:8000`.

Make sure you have Firebase configured:
- Add `google-services.json` to `test_1/android/app/`
- Add `GoogleService-Info.plist` to `test_1/ios/Runner/` (for iOS)
- Update `firebase_options.dart` with your Firebase project config

Run the app:

```bash
flutter run
```

---

### 4. Set Up the AI Server

```bash
cd cardocare_ai
```

Create a `.env` file in `cardocare_ai/`:

```env
ENV=dev
MOCK_MODE=false

GROQ_API_KEY=gsk_your_groq_api_key_here
GROQ_MODEL=llama-3.3-70b-versatile

SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-supabase-anon-key

VECTOR_DB_PATH=./chroma_db
CACHE_TTL=300
```

Install Python dependencies:

```bash
pip install -r requirements.txt
```

Or if using a virtual environment:

```bash
/path/to/your/venv/bin/pip install -r requirements.txt
```

Start the server:

```bash
python main.py
```

Or with a specific Python environment:

```bash
/path/to/your/venv/bin/python main.py
```

The server starts on `http://0.0.0.0:8000`.

Test it:

```bash
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"user_id":"test","message":"Hello, who are you?"}'
```

---

### 5. Using ngrok (Optional)

If your phone can't reach your PC via local IP (different network, firewall, etc.):

```bash
ngrok http 8000
```

Then set `AI_API_URL` in `test_1/.env` to the ngrok URL:

```env
AI_API_URL=https://your-ngrok-url.ngrok-free.dev
```

---

## API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/chat` | Send a message to the AI assistant |
| `POST` | `/upload` | Upload a medical report for a patient |
| `GET` | `/health` | Health check |

### Chat Request

```json
{
  "user_id": "firebase-uid",
  "message": "What is blood pressure?",
  "history": [{"role": "user", "content": "hello"}]
}
```

### Chat Response

```json
{
  "reply": "Blood pressure is the force of blood against artery walls...",
  "action": "none",
  "payload": {}
}
```

Actions: `none`, `show_analysis`, `show_doctors`, `show_slots`, `show_alert`

---

## Running Tests

```bash
cd test_1
flutter test
```

---

## Requirements

| Requirement | Minimum Version |
|---|---|
| Flutter | 3.0.0+ |
| Dart | 2.17.0+ |
| Python | 3.10+ |
| Android SDK | API 19+ |
| iOS | 13.0+ |

---

## Contributing

1. **Fork** the repository
2. Create your feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add some amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a **Pull Request**

---

## License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

## Author

<div align="center">

**NufalXBaalash**

[![GitHub](https://img.shields.io/badge/GitHub-NufalXBaalash-181717?style=for-the-badge&logo=github)](https://github.com/NufalXBaalash)

</div>

---

<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:00d4ff,50:1a1a3e,100:0f0f23&height=120&section=footer" width="100%"/>

*Built with Flutter + FastAPI + Supabase + Groq AI*

</div>
