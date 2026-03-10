# 🎓 StudentTrack Pro

> The ultimate student productivity companion — built for Engineering, Medical, Law & Competitive Exam students.

---

## ✨ Features

| Module | What it does |
|---|---|
| 🏠 **Home Dashboard** | Greeting, daily quote, XP bar, quick stats, timetable preview, exam countdown, habit check-in |
| ✅ **To-Do List** | Priority tasks, filters (Today / Week / High Priority), XP on completion |
| 🎯 **Goals** | Short & long-term goals with milestones and subtasks, progress bars |
| 🔁 **Habits** | Daily check-in, streak tracking, 5-week GitHub-style heatmap |
| 📅 **Timetable** | Weekly schedule grid, today highlighted, colored subject slots |
| ⏳ **Countdown** | Exam countdown timers with color-coded urgency (>30d / 7-30d / <7d) |
| 🍅 **Pomodoro** | Circular timer, auto-session logging, 7-day study bar chart, sound alerts |
| 📝 **Notes & Journal** | Two-panel editor, search, pin, sort, Journal Today template, export .txt |
| 🃏 **Flashcards** | Decks, study mode (flip), quiz mode (text input scoring), XP rewards |
| 📚 **Resources** | Link/video/PDF/book library, search, filter by type, favorites, open URL |
| ❤️ **Health** | Sleep chart, water bottle tracker, mood emoji log, exercise log |
| 📋 **Attendance** | Per-subject %, can-miss/need-more calculator, mark present/absent/late |
| 📊 **Stats** | Matplotlib bar charts, task rate, habit analytics, goal progress, XP history |
| 🏆 **Gamification** | 17 badges, XP levels with stream names, multi-profile leaderboard |
| 📋 **Weekly Review** | 7-day summary, encouragement message, badges earned, day-by-day breakdown |
| ⚙️ **Settings** | Profile edit, dark/light mode, notifications config, JSON/CSV export |

---

## 🚀 Quick Start

### Prerequisites
- Python 3.11+
- Windows 10/11 (macOS/Linux also works)

### 1. Install dependencies
```bash
pip install -r requirements.txt
```

### 2. Run the app
```bash
python main.py
```

The app will:
1. Initialize the SQLite database in `~/.studenttrackpro/studenttrack.db`
2. Run the onboarding wizard (first launch only)
3. Load the main dashboard

---

## 📁 Project Structure

```
StudentTrackPro/
├── main.py                      # App entry point
├── requirements.txt
├── database/
│   ├── __init__.py
│   └── db.py                    # Full SQLite schema + CRUD + XP/badge helpers
├── modules/
│   ├── theme_manager.py         # ThemeManager class
│   ├── onboarding.py            # 3-step onboarding wizard
│   ├── home.py                  # Dashboard
│   ├── todo.py                  # To-do list
│   ├── goals.py                 # Goals + milestones + subtasks
│   ├── habits.py                # Habit tracker + heatmap
│   ├── timetable.py             # Weekly schedule grid
│   ├── countdown.py             # Exam countdown
│   ├── pomodoro.py              # Pomodoro timer
│   ├── notes.py                 # Notes & journal
│   ├── flashcards.py            # Flashcard decks + study/quiz modes
│   ├── resources.py             # Resource library
│   ├── health.py                # Health dashboard (4 tabs)
│   ├── attendance.py            # Attendance tracker
│   ├── stats.py                 # Analytics dashboard
│   ├── gamification.py          # Badges + leaderboard
│   ├── weekly_review.py         # Weekly summary
│   └── settings.py              # App settings
├── assets/
│   ├── icon.ico                 # Auto-generated on first run
│   ├── generate_icon.py         # Icon generation script
│   ├── quotes.json              # 100+ motivational quotes
│   └── themes/
│       ├── engineering.json
│       ├── medical.json
│       ├── law.json
│       └── competitive.json
└── installer/
    ├── build.spec               # PyInstaller spec
    └── installer.nsi            # NSIS installer script
```

---

## 🏆 Gamification System

| Action | XP |
|---|---|
| Complete a task | 10 XP |
| Habit check-in | 5 XP |
| Complete a goal | 100 XP |
| Complete a milestone | 25 XP |
| Finish a Pomodoro | 15 XP |
| Log health data | 3 XP |
| Weekly review | 20 XP |

Every **500 XP** = Level up! Level names are stream-specific (e.g., Engineering: Freshman → Legend).

## 🏅 Badges (17 total)

First Step, Habit Forming, Week Warrior, Unstoppable, Goal Setter, Goal Crusher, Milestone Master, Focus Machine, Deep Worker, Scholar, Knowledge Seeker, Hydration Hero, Athlete, Early Bird, Perfect Attendance, Rising Star, Elite Student.

---

## 🎨 Stream Themes

| Stream | Primary Color | Feel |
|---|---|---|
| 🔧 Engineering | Deep Blue | Technical, precise |
| 🏥 Medical | Teal Green | Clean, clinical |
| ⚖️ Law | Deep Purple | Professional, authoritative |
| 🎯 Competitive | Crimson Red | High energy, competitive |

---

## 🔨 Building a Standalone Executable

```bash
pip install pyinstaller
pyinstaller installer/build.spec
```

Output will be in `dist/StudentTrackPro/`

---

## 📊 Database

All data is stored locally in `~/.studenttrackpro/studenttrack.db` (SQLite).

**No internet connection required. Your data never leaves your device.**

Export your data anytime via **Settings → Data → Export JSON/CSV**.

---

## 🛠️ Tech Stack

- **GUI**: CustomTkinter 5.x (modern, dark-mode ready Tkinter)
- **Database**: SQLite3 (built into Python)
- **Charts**: Matplotlib + Pillow
- **Notifications**: Plyer
- **Scheduling**: Schedule
- **Packaging**: PyInstaller + NSIS

---

## 📃 License

MIT License — free to use, modify, and distribute.

---

*Built with ❤️ for students who refuse to give up.*
