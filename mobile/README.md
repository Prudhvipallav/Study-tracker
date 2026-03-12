# 📱 StudentTrack Pro — Mobile Companion App

A standalone **Flutter/Dart** companion app for StudentTrack Pro.

> ⚠️ This is a **separate offline app** with its own local SQLite database. There is no sync layer between the desktop and mobile versions — each operates independently.

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🏠 Home Dashboard | Greeting, daily quote, XP bar, quick stats, today's habits |
| ✅ To-Do List | Priority tasks with filters, swipe to complete/delete |
| 🔁 Habits | Daily check-in with streak tracking |
| 🍅 Focus Timer | Pomodoro timer with cycle tracking |
| 🃏 Flashcards | Create decks, flip-card study with Easy/Hard scoring |
| ⏰ Countdowns | Exam countdown timers |
| 🎯 Goals | Goal progress with milestone checklists |
| ❤️ Health | Sleep, water, mood, and exercise tracking |
| 📊 Attendance | Per-subject attendance with % calculator |
| 📝 Notes | Create, edit, pin, and search notes |
| 📈 Stats | Weekly focus chart, habit streaks, all-time overview |
| 🏅 Badges | 23 achievement badges to earn |
| ⚙️ Settings | Notifications, data reset, about info |

---

## 🚀 Build & Run

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.19+)
- Android SDK / connected Android device

### Commands
```bash
cd mobile
flutter pub get
flutter run --debug
```

### Build Release APK
```bash
flutter build apk --release --split-per-abi
```

APKs will be in `build/app/outputs/flutter-apk/`.

---

## 📁 Structure

```
mobile/
├── lib/
│   ├── main.dart              # Entry point + ProfileProvider
│   ├── database/db_helper.dart # SQLite schema + CRUD + XP engine
│   ├── providers/             # State management
│   ├── screens/               # All UI screens
│   │   ├── home/ · todo/ · habits/ · pomodoro/
│   │   ├── flashcards/ · countdown/ · goals/
│   │   ├── health/ · attendance/
│   │   ├── more/ (badges, stats, notes, settings)
│   │   └── onboarding/ (splash, welcome, stream, profile)
│   ├── services/              # Notification, quote, XP services
│   ├── theme/                 # ThemeManager + AppTheme
│   └── widgets/               # Shared reusable widgets
├── assets/
│   ├── quotes.json
│   └── themes/*.json          # 4 stream color themes
└── pubspec.yaml
```

---

## 📃 License

MIT License — same as the main project.
