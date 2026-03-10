"""
StudentTrack Pro — Home Dashboard Module
Shows daily overview: greeting, quote, XP, quick stats, timetable preview, countdowns, habits ring.
"""

import customtkinter as ctk
import random
import json
import os
from datetime import datetime, date
from database import db
from modules.theme_manager import ThemeManager


ASSETS_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "assets")
QUOTES_PATH = os.path.join(ASSETS_DIR, "quotes.json")


def _load_quote() -> dict:
    """Load a random motivational quote."""
    try:
        with open(QUOTES_PATH, "r", encoding="utf-8") as f:
            quotes = json.load(f)
        return random.choice(quotes)
    except Exception:
        return {"quote": "The secret of getting ahead is getting started.", "author": "Mark Twain"}


class HomeModule(ctk.CTkScrollableFrame):
    """Main home dashboard rendered in the content area."""

    def __init__(self, parent, profile_id: int, tm: ThemeManager, refresh_xp_cb):
        super().__init__(parent, fg_color=tm.background, corner_radius=0)
        self._pid = profile_id
        self._tm = tm
        self._refresh_xp = refresh_xp_cb
        self._profile = dict(db.get_profile(profile_id))
        self._build()

    def _build(self):
        tm = self._tm
        p = self._profile
        today = date.today()
        hour = datetime.now().hour

        greeting = "Good morning" if hour < 12 else "Good afternoon" if hour < 17 else "Good evening"

        # ---- Header ----
        header = ctk.CTkFrame(self, fg_color=tm.surface, corner_radius=16)
        header.pack(fill="x", padx=20, pady=(20, 10))

        row = ctk.CTkFrame(header, fg_color="transparent")
        row.pack(fill="x", padx=20, pady=20)

        left = ctk.CTkFrame(row, fg_color="transparent")
        left.pack(side="left", fill="both", expand=True)

        ctk.CTkLabel(
            left,
            text=f"{greeting}, {p['name']}! 🌟",
            font=ctk.CTkFont(size=24, weight="bold"),
            text_color=tm.text, anchor="w"
        ).pack(anchor="w")

        from database.db import get_level_name
        level_name = get_level_name(p["stream"], p["level"])
        xp_pct = (p["xp"] % 500) / 500
        ctk.CTkLabel(
            left,
            text=f"Level {p['level']} · {level_name}  |  {p['xp']} XP",
            font=ctk.CTkFont(size=13),
            text_color=tm.text_secondary, anchor="w"
        ).pack(anchor="w", pady=(2, 6))

        xp_bar = ctk.CTkProgressBar(left, height=10, fg_color=tm.surface2, progress_color=tm.primary)
        xp_bar.set(xp_pct)
        xp_bar.pack(anchor="w", fill="x")

        # Quote
        q = _load_quote()
        ctk.CTkLabel(
            row,
            text=f'"{q["quote"]}"\n— {q["author"]}',
            font=ctk.CTkFont(size=12, slant="italic"),
            text_color=tm.text_secondary,
            wraplength=300,
            justify="right"
        ).pack(side="right", padx=(20, 0))

        # ---- Quick stats row ----
        stats_frame = ctk.CTkFrame(self, fg_color="transparent")
        stats_frame.pack(fill="x", padx=20, pady=4)
        stats_frame.columnconfigure((0, 1, 2, 3), weight=1)

        # tasks due today
        tasks_today = db.fetch_all(
            "SELECT COUNT(*) as c FROM todos WHERE profile_id=? AND is_completed=0 AND due_date=?",
            [self._pid, today.isoformat()]
        )
        tasks_count = tasks_today[0]["c"] if tasks_today else 0

        # habits done today
        habits_done = db.fetch_all(
            """SELECT COUNT(*) as c FROM habit_logs hl
               JOIN habits h ON hl.habit_id=h.id
               WHERE h.profile_id=? AND hl.date=? AND hl.is_done=1""",
            [self._pid, today.isoformat()]
        )
        habits_count = habits_done[0]["c"] if habits_done else 0

        # max streak
        streaks = db.fetch_all(
            "SELECT current_streak FROM habits WHERE profile_id=? AND is_archived=0",
            [self._pid]
        )
        max_streak = max((r["current_streak"] for r in streaks), default=0)

        # pomodoro sessions today
        pom_today = db.fetch_one(
            "SELECT SUM(cycles_completed) as s FROM pomodoro_sessions WHERE profile_id=? AND date=?",
            [self._pid, today.isoformat()]
        )
        pom_count = pom_today["s"] if pom_today and pom_today["s"] else 0

        stat_data = [
            ("📋", "Tasks Due Today", str(tasks_count), tm.warning),
            ("🔁", "Habits Done", str(habits_count), tm.success),
            ("🔥", "Study Streak", f"{max_streak}d", tm.accent),
            ("🍅", "Pomodoros", str(pom_count), tm.primary),
        ]

        for col, (icon, label, value, color) in enumerate(stat_data):
            card = ctk.CTkFrame(stats_frame, fg_color=tm.card, corner_radius=12,
                                border_width=1, border_color=tm.border)
            card.grid(row=0, column=col, padx=6, pady=6, sticky="nsew")
            ctk.CTkLabel(card, text=icon, font=ctk.CTkFont(size=28)).pack(pady=(14, 2))
            ctk.CTkLabel(card, text=value,
                         font=ctk.CTkFont(size=22, weight="bold"),
                         text_color=color).pack()
            ctk.CTkLabel(card, text=label,
                         font=ctk.CTkFont(size=11),
                         text_color=tm.text_secondary).pack(pady=(0, 14))

        # ---- Two-column body ----
        body = ctk.CTkFrame(self, fg_color="transparent")
        body.pack(fill="both", expand=True, padx=20, pady=4)
        body.columnconfigure((0, 1), weight=1)

        # Left: Today's timetable
        left_col = ctk.CTkFrame(body, fg_color="transparent")
        left_col.grid(row=0, column=0, sticky="nsew", padx=(0, 8))

        self._section(left_col, "📅 Today's Schedule")
        day_of_week = today.weekday()  # 0=Mon
        slots = db.fetch_all(
            "SELECT * FROM timetable WHERE profile_id=? AND day_of_week=? ORDER BY start_time LIMIT 4",
            [self._pid, day_of_week]
        )
        if not slots:
            ctk.CTkLabel(left_col, text="No classes scheduled today! 🎉",
                         font=ctk.CTkFont(size=13), text_color=tm.text_secondary).pack(pady=10)
        for s in slots:
            f = ctk.CTkFrame(left_col, fg_color=tm.surface, corner_radius=8,
                             border_width=1, border_color=s["color"] or tm.border)
            f.pack(fill="x", pady=3)
            ctk.CTkLabel(f, text=f"  {s['start_time']} – {s['end_time']}   {s['subject']}",
                         font=ctk.CTkFont(size=13), text_color=tm.text, anchor="w").pack(side="left", padx=8)
            if s["location"]:
                ctk.CTkLabel(f, text=f"📍{s['location']}",
                             font=ctk.CTkFont(size=11), text_color=tm.text_secondary).pack(side="right", padx=8)

        # Upcoming countdowns
        self._section(left_col, "⏳ Upcoming Exams")
        countdowns = db.fetch_all(
            "SELECT * FROM countdowns WHERE profile_id=? AND is_archived=0 ORDER BY exam_date LIMIT 3",
            [self._pid]
        )
        if not countdowns:
            ctk.CTkLabel(left_col, text="No exams added yet.",
                         font=ctk.CTkFont(size=13), text_color=tm.text_secondary).pack(pady=6)
        for c in countdowns:
            try:
                exam_day = date.fromisoformat(c["exam_date"])
                days_left = (exam_day - today).days
            except Exception:
                days_left = 999
            color = tm.success if days_left > 30 else (tm.warning if days_left > 7 else tm.danger)
            f = ctk.CTkFrame(left_col, fg_color=tm.surface, corner_radius=8)
            f.pack(fill="x", pady=3)
            ctk.CTkLabel(f, text=f"  {c['title']}",
                         font=ctk.CTkFont(size=13, weight="bold"),
                         text_color=tm.text, anchor="w").pack(side="left", padx=8)
            ctk.CTkLabel(f, text=f"{days_left}d  ",
                         font=ctk.CTkFont(size=14, weight="bold"),
                         text_color=color).pack(side="right", padx=8)

        # Right: Top priority task + recent habits
        right_col = ctk.CTkFrame(body, fg_color="transparent")
        right_col.grid(row=0, column=1, sticky="nsew", padx=(8, 0))

        self._section(right_col, "🎯 Today's Focus")
        top_task = db.fetch_one(
            """SELECT * FROM todos WHERE profile_id=? AND is_completed=0
               ORDER BY CASE priority WHEN 'urgent' THEN 1 WHEN 'high' THEN 2
                                      WHEN 'medium' THEN 3 ELSE 4 END,
               due_date ASC LIMIT 1""",
            [self._pid]
        )
        if top_task:
            p_colors = {"urgent": tm.danger, "high": tm.accent, "medium": tm.warning, "low": tm.success}
            pcolor = p_colors.get(top_task["priority"], tm.text_secondary)
            fc = ctk.CTkFrame(right_col, fg_color=tm.card, corner_radius=12,
                              border_width=2, border_color=pcolor)
            fc.pack(fill="x", pady=4)
            ctk.CTkLabel(fc, text=f"  {top_task['priority'].upper()}",
                         font=ctk.CTkFont(size=10, weight="bold"),
                         text_color=pcolor, anchor="w").pack(anchor="w", padx=12, pady=(10, 0))
            ctk.CTkLabel(fc, text=f"  {top_task['title']}",
                         font=ctk.CTkFont(size=15, weight="bold"),
                         text_color=tm.text, anchor="w").pack(anchor="w", padx=12)
            if top_task["description"]:
                ctk.CTkLabel(fc, text=f"  {top_task['description'][:80]}",
                             font=ctk.CTkFont(size=12), text_color=tm.text_secondary,
                             anchor="w", wraplength=300).pack(anchor="w", padx=12, pady=(0, 10))
        else:
            ctk.CTkLabel(right_col, text="All caught up! No pending tasks. 🎉",
                         font=ctk.CTkFont(size=13), text_color=tm.success).pack(pady=8)

        self._section(right_col, "🔁 Today's Habits")
        habits = db.fetch_all(
            "SELECT * FROM habits WHERE profile_id=? AND is_archived=0 LIMIT 5",
            [self._pid]
        )
        if not habits:
            ctk.CTkLabel(right_col, text="No habits added yet.",
                         font=ctk.CTkFont(size=13), text_color=tm.text_secondary).pack(pady=6)
        for h in habits:
            done_row = db.fetch_one(
                "SELECT is_done FROM habit_logs WHERE habit_id=? AND date=?",
                [h["id"], today.isoformat()]
            )
            is_done = done_row["is_done"] if done_row else 0

            hf = ctk.CTkFrame(right_col, fg_color=tm.surface, corner_radius=8)
            hf.pack(fill="x", pady=3)

            ctk.CTkLabel(hf, text=f"  {h['icon'] or '🔁'}  {h['name']}",
                         font=ctk.CTkFont(size=13), text_color=tm.text, anchor="w").pack(side="left", padx=6)

            status_text = "✅" if is_done else "○"
            status_color = tm.success if is_done else tm.text_secondary

            habit_id = h["id"]
            check_btn = ctk.CTkButton(
                hf, text=status_text, width=36, height=28,
                fg_color="transparent", hover_color=tm.surface2,
                text_color=status_color,
                font=ctk.CTkFont(size=16),
                command=lambda hid=habit_id: self._check_habit(hid)
            )
            check_btn.pack(side="right", padx=6)

    def _section(self, parent, title: str):
        ctk.CTkLabel(
            parent, text=title,
            font=ctk.CTkFont(size=14, weight="bold"),
            text_color=self._tm.text_secondary, anchor="w"
        ).pack(anchor="w", pady=(14, 4))

    def _check_habit(self, habit_id: int):
        """Toggle habit done for today."""
        today = date.today().isoformat()
        existing = db.fetch_one(
            "SELECT * FROM habit_logs WHERE habit_id=? AND date=?", [habit_id, today]
        )
        if existing:
            new_done = 0 if existing["is_done"] else 1
            db.update("habit_logs", {"is_done": new_done}, {"id": existing["id"]})
            if new_done:
                db.award_xp(self._pid, 5, "Habit check-in")
        else:
            db.insert("habit_logs", {"habit_id": habit_id, "date": today, "is_done": 1})
            db.award_xp(self._pid, 5, "Habit check-in")

        self._refresh_xp()
        # Reload
        for w in self.winfo_children():
            w.destroy()
        self._build()
