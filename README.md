# 🎓 StudentTrack Pro

<div align="center">

**The ultimate all-in-one student productivity app — built for Engineering, Medical, Law & Competitive students**

![Python](https://img.shields.io/badge/Python-3.11+-3776AB?style=for-the-badge&logo=python&logoColor=white)
![CustomTkinter](https://img.shields.io/badge/CustomTkinter-5.x-blue?style=for-the-badge)
![SQLite](https://img.shields.io/badge/SQLite-Local--First-003B57?style=for-the-badge&logo=sqlite&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)
![Platform](https://img.shields.io/badge/Platform-Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)

</div>

---

## ✨ Features at a Glance

| Module | Description |
|--------|-------------|
| 🏠 **Home Dashboard** | Daily quote, XP bar, quick stats, today's schedule & exam countdown |
| ✅ **To-Do List** | Priority tasks, filters, overdue highlighting, XP on completion |
| 🎯 **Goals** | Long/short-term goals with milestones, subtasks & progress bars |
| 🔁 **Habits** | Daily check-in, streak tracker, 5-week GitHub-style heatmap |
| 📅 **Timetable** | Visual weekly schedule grid with color-coded subjects |
| ⏳ **Countdown** | Exam countdown timers with color-coded urgency |
| 🍅 **Pomodoro** | Circular timer, auto session logging, 7-day focus chart |
| 📝 **Notes & Journal** | Two-panel editor, search, pin, journal template, export |
| 🃏 **Flashcards** | Decks, study mode (flip), quiz mode (text input), XP rewards |
| 📚 **Resources** | Link/video/PDF library with search, filter & favorites |
| ❤️ **Health Dashboard** | Sleep chart, water tracker, mood emoji log, exercise log |
| 📋 **Attendance** | Per-subject %, can-miss/need-more calculator |
| 📊 **Stats & Analytics** | Charts (Matplotlib), task rate, habit analytics, goal progress |
| 🏆 **Gamification** | 17 badges, XP levels, multi-profile leaderboard |
| 🗓 **Weekly Review** | 7-day summary, encouragement, badges earned, day-by-day |
| ⚙️ **Settings** | Profile edit, dark/light mode, notifications, JSON/CSV export |

---

## 🚀 Quick Start

### 1. Clone the repo
```bash
git clone https://github.com/Prudhvipallav/Study-tracker.git
cd Study-tracker
```

### 2. Install dependencies
```bash
pip install -r requirements.txt
```

### 3. Run the app
```bash
python main.py
```

The **onboarding wizard** will guide you through creating your first profile on first launch.

---

## 🏆 Gamification System

Every action earns you XP — complete tasks, build habits, stay consistent!

| Action | XP |
|--------|----|
| ✅ Complete a task | +10 XP |
| 🔁 Habit check-in | +5 XP |
| 🎯 Complete a goal | +100 XP |
| 🍅 Finish a Pomodoro | +15 XP |
| ❤️ Log health data | +3 XP |
| 🗓 Weekly review | +20 XP |

Every **500 XP = Level Up!** Level names are stream-specific (e.g. Engineering: *Freshman → Graduate → Architect → Legend*)

### 🏅 17 Badges to Earn
`First Step` · `Habit Forming` · `Week Warrior` · `Unstoppable` · `Goal Setter` · `Goal Crusher` · `Milestone Master` · `Focus Machine` · `Deep Worker` · `Scholar` · `Knowledge Seeker` · `Hydration Hero` · `Athlete` · `Early Bird` · `Perfect Attendance` · `Rising Star` · `Elite Student`

---

## 🎨 Stream Themes

| Stream | Color | Level Names |
|--------|-------|-------------|
| 🔧 Engineering | Deep Blue | Freshman → Legend |
| 🩺 Medical | Teal Green | Intern → Lifesaver |
| ⚖️ Law | Crimson Red | Clerk → Justice |
| 📖 Competitive | Purple | Aspirant → Legend |

---

## 📁 Project Structure

```
StudentTrackPro/
├── main.py                  # App entry point (single-root CTk)
├── requirements.txt
├── database/
│   └── db.py                # SQLite schema + CRUD + XP/badge engine
├── modules/                 # 16 feature modules
│   ├── home.py · todo.py · goals.py · habits.py
│   ├── timetable.py · countdown.py · pomodoro.py
│   ├── notes.py · flashcards.py · resources.py
│   ├── health.py · attendance.py · stats.py
│   ├── gamification.py · weekly_review.py · settings.py
│   └── theme_manager.py
└── assets/
    ├── quotes.json          # 100+ motivational quotes
    └── themes/              # 4 stream colour themes
```

---

## 📦 Tech Stack

- **GUI** — [CustomTkinter](https://github.com/TomSchimansky/CustomTkinter) (modern dark-mode Tkinter)
- **Database** — SQLite3 (built-in, fully local)
- **Charts** — Matplotlib + Pillow
- **Notifications** — Plyer
- **Packaging** — PyInstaller

> 🔒 **100% local-first. No internet required. Your data never leaves your device.**

---

## 📃 License

MIT License — free to use, modify, and distribute.

---

<div align="center">
Built with ❤️ for students who refuse to give up.
</div>
