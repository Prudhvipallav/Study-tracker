<div align="center">

# 🎓 StudentTrack Pro

**The ultimate all-in-one student productivity app — Desktop + Mobile**

Built for Engineering, Medical, Law & Competitive exam students.

![Python](https://img.shields.io/badge/Python-3.11+-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![SQLite](https://img.shields.io/badge/SQLite-Local--First-003B57?style=for-the-badge&logo=sqlite&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)
![Platform](https://img.shields.io/badge/Windows%20%7C%20Android-blue?style=for-the-badge)

</div>

> 🔒 **100% offline. Your data never leaves your device.** No accounts, no cloud, no tracking.

---

## 📥 Download & Install (Non-Technical Users)

### 🖥️ Desktop (Windows)

1. Go to [**Releases**](https://github.com/Prudhvipallav/Study-tracker/releases)
2. Download **`StudentTrackPro.exe`** (~40 MB)
3. Double-click to run — that's it!

> No Python, no setup, no installation needed. Just download and open.

### 📱 Mobile (Android)

1. Go to [**Releases**](https://github.com/Prudhvipallav/Study-tracker/releases)
2. Download **`StudentTrackPro.apk`**
3. Open it on your phone → Allow unknown apps → Install

---

## ✨ Features

### 🏠 Home Dashboard
- Animated XP progress bar with level display
- "Day N of your journey" counter
- 7-day week strip with task completion dots
- 🔥 Streak flames for consistency
- Motivational quote of the day

### ✅ To-Do List
- Priority tasks (High / Medium / Low) with color coding
- Due dates with overdue highlighting
- Tag-based filtering and search
- +10 XP on every task completion

### 🎯 Goals & Milestones
- Create long-term and short-term goals
- Break goals into milestones with deadlines
- Auto-progress tracking
- Active / Completed tabs

### 🔁 Habits
- Daily check-in with streak tracking
- **5-week GitHub-style heatmap** with completion intensity
- Irregular state tracking (yellow — partial days)
- Monthly stats summary

### 📅 Timetable
- Visual weekly schedule grid
- Color-coded subjects
- Add/edit classes with time and location

### ⏳ Exam Countdowns
- Countdown timers for upcoming exams
- Color-coded urgency (red when close!)

### 🍅 Pomodoro Timer
- Circular countdown timer with session tracking
- **6 bundled ambient sounds**: Rain, Ocean, Fireplace, Forest, Lo-fi Guitar, Birds
- Alarm on session completion
- Wakelock focus mode (keeps screen on)
- 7-day focus chart

### 📝 Notes & Drawing
- Two-panel editor with search, pin, and swipe-to-delete
- **Import .md files** with 3 modes:
  - Save as Note
  - Extract checklists → To-Do tasks
  - Generate study roadmap from headings
- **Freehand drawing canvas** with:
  - 7 color options
  - Pen/eraser toggle
  - Adjustable stroke width
  - Export as PNG embedded in notes

### 🃏 Flashcards
- Create decks by subject
- Study mode (flip cards)
- Quiz mode (text input)
- Spaced repetition tracking
- XP rewards for study sessions

### 📚 Resources Library
- Save links, videos, PDFs
- Search, filter, and favorite
- Organized by subject

### ❤️ Health Dashboard
- **Sleep**: Chart your sleep and wake times
- **Water**: Glass counter with daily goals
- **Mood**: Emoji mood log with notes
- **Exercise**: Type selection, duration slider, 7-day history

### 📋 Attendance
- Per-subject attendance percentage
- Monthly calendar grid with status dots
- **Can-miss calculator**: Shows how many classes you can skip and still hit 75%
- Subject filter chips

### 📊 Stats & Analytics
- Charts and graphs (Matplotlib on desktop, FL Chart on mobile)
- Task completion rate, habit analytics, goal progress
- Weekly and monthly breakdowns

### 🤝 Buddy System
- Add study partners from multiple profiles
- **Friend's Dashboard** — see your buddy's stats
- **Side-by-side comparison** — compare streaks, XP, habits
- **Leaderboard** — compete on XP, study hours, and streaks
- **Shared Goals** — work together on goals
- **Nudges** — motivational messages (💪)
- **Shared Pomodoro** — study sessions together

### 🏆 Gamification
- **17 badges** to earn (First Step, Unstoppable, Deep Worker, Elite Student, and more)
- XP system: +10 per task, +5 per habit, +100 per goal, +15 per Pomodoro
- **500 XP = Level Up** with stream-specific titles
- Multi-profile leaderboard

### 🔄 PC ↔ Mobile Sync
- Wireless sync over local WiFi — no internet needed
- Sync server runs automatically inside the desktop app
- Pull from PC / Push to PC / Full Sync
- Syncs all 16 tables: todos, habits, goals, notes, attendance, health, flashcards, badges, and more
- Auto-backup before every sync (keeps last 10)

### ⚙️ Settings
- Profile editing (name, avatar, stream)
- Dark / Light mode toggle
- Notification preferences
- JSON/CSV data export

---

## 🎨 Stream Themes

Each academic stream gets its own color theme:

| Stream | Color | Level Names |
|--------|-------|-------------|
| 🔧 Engineering | Deep Blue | Freshman → Graduate → Architect → Legend |
| 🩺 Medical | Teal Green | Intern → Resident → Specialist → Lifesaver |
| ⚖️ Law | Crimson Red | Clerk → Associate → Advocate → Justice |
| 📖 Competitive | Purple | Aspirant → Scholar → Master → Legend |

---

## 🔄 How Sync Works

Both the desktop and mobile apps store data in SQLite. To sync between them:

1. Open the **desktop app** — the sync server starts automatically on port `8765`
2. On your **phone**, go to **More → 🔄 Sync**
3. Enter the **IP address** shown in the desktop app's console
4. Tap **Connect** → then **Full Sync**

Both devices must be on the **same WiFi network**. No internet required.

---

## 🔧 Error Handling

- Desktop crashes are logged to `~/.studenttrackpro/crash.log`
- Database backups are stored in `~/.studenttrackpro/backups/`
- If the app fails to launch, check the crash log for stack traces

---

# 👨‍💻 Developer Guide

Everything below is for developers who want to build, modify, or contribute.

---

## 📁 Project Structure

```
StudentTrackPro/
├── main.py                  # Desktop app entry point (CTkinter)
├── sync_server.py           # HTTP sync server (auto-started by main.py)
├── build.spec               # PyInstaller build config (single-file EXE)
├── launch.pyw               # Windows consoleless launcher
├── requirements.txt         # Python dependencies (pinned)
│
├── database/                # SQLite data layer
│   ├── connection.py        # DB_DIR, DB_PATH, get_db()
│   ├── schema.py            # All CREATE TABLE + migrations + init_db()
│   ├── crud.py              # Generic CRUD + profile/settings helpers
│   ├── gamification.py      # XP engine, level names, badge definitions
│   └── db.py                # Backward-compatible re-export shim
│
├── modules/                 # 20 desktop UI modules
│   ├── home.py              # Home dashboard
│   ├── todo.py              # To-do list
│   ├── goals.py             # Goals & milestones
│   ├── habits.py            # Habits & heatmap
│   ├── timetable.py         # Weekly schedule
│   ├── countdown.py         # Exam countdowns
│   ├── pomodoro.py          # Pomodoro timer
│   ├── notes.py             # Notes editor
│   ├── flashcards.py        # Flashcard decks & study
│   ├── resources.py         # Resource library
│   ├── health.py            # Health dashboard
│   ├── attendance.py        # Attendance tracker
│   ├── stats.py             # Analytics & charts
│   ├── buddy.py             # Buddy / accountability system
│   ├── gamification.py      # Badges & XP UI
│   ├── weekly_review.py     # Weekly summary
│   ├── settings.py          # App settings
│   ├── onboarding.py        # First-run wizard
│   └── theme_manager.py     # Stream-based theming
│
├── assets/
│   ├── icon.ico             # App icon
│   ├── quotes.json          # 100+ motivational quotes
│   └── themes/              # 4 stream color themes
│
├── tests/
│   ├── conftest.py          # Pytest fixtures (temp DB)
│   └── test_db.py           # CRUD, XP, badge tests
│
└── mobile/                  # 📱 Flutter companion app
    ├── lib/
    │   ├── main.dart
    │   ├── database/db_helper.dart
    │   ├── theme/theme_manager.dart
    │   ├── services/
    │   │   ├── sound_service.dart      # Bundled audio playback
    │   │   └── sync_service.dart       # WiFi sync client
    │   ├── screens/
    │   │   ├── home/home_screen.dart
    │   │   ├── todo/todo_screen.dart
    │   │   ├── habits/habits_screen.dart
    │   │   ├── pomodoro/pomodoro_screen.dart
    │   │   ├── health/health_screen.dart
    │   │   ├── attendance/attendance_screen.dart
    │   │   ├── goals/goals_screen.dart
    │   │   ├── countdown/countdown_screen.dart
    │   │   ├── flashcards/flashcards_screen.dart
    │   │   └── more/ (notes, drawing, sync, stats, badges, settings)
    │   └── widgets/widgets.dart
    ├── assets/sounds/          # 7 bundled audio files
    └── pubspec.yaml
```

---

## 🛠️ Desktop Development Setup

### Prerequisites
- Python 3.11+
- pip

### Setup
```bash
git clone https://github.com/Prudhvipallav/Study-tracker.git
cd Study-tracker/StudentTrackPro

# Create virtual environment (recommended)
python -m venv venv
venv\Scripts\activate        # Windows
source venv/bin/activate     # macOS/Linux

# Install dependencies
pip install -r requirements.txt

# Run the app
python main.py
```

### Running Tests
```bash
pip install pytest
python -m pytest tests/ -v
```

### Building the EXE
```bash
pip install pyinstaller
python -m PyInstaller build.spec --noconfirm
# Output: dist/StudentTrackPro.exe (~40MB single file)
```

---

## 📱 Mobile Development Setup

### Prerequisites
- Flutter SDK 3.x
- Android Studio or VS Code with Flutter extension

### Setup
```bash
cd StudentTrackPro/mobile
flutter pub get
flutter run                  # Run on connected device/emulator
```

### Building the APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Flutter Dependencies
| Package | Purpose |
|---------|---------|
| `sqflite` | Local SQLite database |
| `fl_chart` | Charts and graphs |
| `table_calendar` | Calendar widget |
| `audioplayers` | Ambient sounds & alarm |
| `wakelock_plus` | Keep screen on during Pomodoro |
| `file_picker` | .md file import |
| `perfect_freehand` | Freehand drawing strokes |
| `http` | WiFi sync client |

---

## 📦 Tech Stack

| Component | Desktop | Mobile |
|-----------|---------|--------|
| **Language** | Python 3.11+ | Dart (Flutter 3.x) |
| **UI Framework** | CustomTkinter | Flutter Material |
| **Database** | SQLite3 | sqflite |
| **Charts** | Matplotlib | FL Chart |
| **Notifications** | Plyer | flutter_local_notifications |
| **Packaging** | PyInstaller | Flutter APK |
| **Sync** | HTTP server (built-in) | HTTP client |

---

## 🤝 Contributing

1. Fork the repo
2. Create a feature branch: `git checkout -b feat/my-feature`
3. Commit your changes: `git commit -m "feat: add my feature"`
4. Push: `git push origin feat/my-feature`
5. Open a Pull Request

### Code Style
- Desktop: Follow PEP 8 for Python
- Mobile: Follow Dart/Flutter conventions
- Commit messages: Use [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`)

---

## 📃 License

MIT License — free to use, modify, and distribute.

---

<div align="center">

Built with ❤️ for students who refuse to give up.

**[⬇️ Download Latest Release](https://github.com/Prudhvipallav/Study-tracker/releases)**

</div>
