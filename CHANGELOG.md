# StudentTrack Pro — Changelog

All notable changes to this project are documented here.
Format: [Version] — Date / What changed

---

## [1.1.0] — 2026-03-11

### Added
- **Phase 13 — Buddy & Accountability Partner System** (brand new module 🤝)
  - Tab 1: Friend's Dashboard — live read-only mirror of study partner's daily stats
  - Tab 2: Side-by-Side Stats — head-to-head comparison with matplotlib grouped bar chart
  - Tab 3: Multi-category Leaderboard (Overall XP, This Week, Study Hours, Task Master, Streak Lord)
  - Tab 4: Shared Goals — create goals both profiles contribute to, track individual contributions
  - Tab 5: Nudges — send emoji + message encouragement bursts, inbox with unread counter
  - Tab 6: Shared Pomodoro — synced timer via SQLite, both profiles study together, +5 buddy XP bonus
- 5 new database tables: `nudges`, `shared_goals`, `shared_goal_members`, `shared_pomodoro`, `shared_pomodoro_members`
- 6 new badges: Good Vibes, Hype Man, Better Together, Study Duo, Inseparable, Team Player
- GitHub Actions CI/CD workflow (`.github/workflows/build.yml`) — auto-builds Windows installer on every push to `main`
- `launch.pyw` — silent launcher (no black console window), powers the Desktop shortcut
- Desktop shortcut installer script (`installer/create_shortcut.ps1`)
- `CHANGELOG.md` — this file

### Fixed
- Replaced single-root CTk architecture — eliminated all `invalid command name` after-callback errors
- Fixed 8-digit hex color crash (`#RRGGBBAA` not supported by Tkinter) in profile select screen
- Git identity configured correctly for `Prudhvipallav` account

---

## [1.0.0] — 2026-03-10

### Added
- Initial release of StudentTrack Pro
- 16 core modules: Home, To-Do, Goals, Habits, Timetable, Countdown, Pomodoro, Notes, Flashcards, Resources, Health, Attendance, Stats, Gamification, Weekly Review, Settings
- 4 stream themes: Engineering (blue), Medical (teal), Law (crimson), Competitive (purple)
- XP & leveling system (500 XP per level)
- 17 achievement badges
- Multi-profile support with locked stream selection
- Local SQLite database — fully offline, zero cloud
- Desktop shortcut via `pythonw.exe` (no console window)
- PyInstaller + NSIS packaging setup
- 100+ motivational quotes in `assets/quotes.json`
