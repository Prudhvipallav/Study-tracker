"""
StudentTrack Pro — Weekly Review Module
Sunday summary dashboard showing week's accomplishments.
"""

import customtkinter as ctk
from datetime import date, timedelta
from database import db
from modules.theme_manager import ThemeManager


class WeeklyReviewModule(ctk.CTkScrollableFrame):
    def __init__(self, parent, profile_id, tm: ThemeManager, refresh_xp_cb):
        super().__init__(parent, fg_color=tm.background, corner_radius=0)
        self._pid = profile_id
        self._tm = tm
        self._refresh_xp = refresh_xp_cb
        self._build()

    def _build(self):
        tm = self._tm
        today = date.today()
        # Week start = last Monday
        week_start = today - timedelta(days=today.weekday())
        week_end = week_start + timedelta(days=6)

        ctk.CTkLabel(self, text="📋 Weekly Review",
                     font=ctk.CTkFont(size=22, weight="bold"),
                     text_color=tm.primary).pack(anchor="w", padx=20, pady=(20, 4))

        ctk.CTkLabel(self, text=f"Week of {week_start.strftime('%B %d')} – {week_end.strftime('%B %d, %Y')}",
                     font=ctk.CTkFont(size=13), text_color=tm.text_secondary).pack(anchor="w", padx=20, pady=(0, 16))

        # Stats
        tasks_done = db.fetch_one(
            "SELECT COUNT(*) as c FROM todos WHERE profile_id=? AND is_completed=1 AND completed_at>=?",
            [self._pid, week_start.isoformat()]
        )
        habits_hit = db.fetch_one(
            "SELECT COUNT(*) as c FROM habit_logs hl JOIN habits h ON hl.habit_id=h.id "
            "WHERE h.profile_id=? AND hl.is_done=1 AND hl.date>=?",
            [self._pid, week_start.isoformat()]
        )
        pom_total = db.fetch_one(
            "SELECT SUM(total_focus_minutes) as t FROM pomodoro_sessions WHERE profile_id=? AND date>=?",
            [self._pid, week_start.isoformat()]
        )
        xp_earned = db.fetch_one(
            "SELECT SUM(amount) as s FROM xp_logs WHERE profile_id=? AND earned_at>=?",
            [self._pid, week_start.isoformat()]
        )
        new_badges = db.fetch_all(
            "SELECT * FROM badges WHERE profile_id=? AND earned_at>=?",
            [self._pid, week_start.isoformat()]
        )

        td = tasks_done["c"] if tasks_done else 0
        hh = habits_hit["c"] if habits_hit else 0
        focus_mins = pom_total["t"] if pom_total and pom_total["t"] else 0
        xp = xp_earned["s"] if xp_earned and xp_earned["s"] else 0

        # Summary grid
        summary_data = [
            ("✅", "Tasks Completed", str(td), tm.success),
            ("🔁", "Habit Check-ins", str(hh), tm.primary),
            ("🍅", "Focus Time", f"{focus_mins // 60}h {focus_mins % 60}m", tm.accent),
            ("✨", "XP Earned", str(xp), tm.highlight),
        ]

        grid = ctk.CTkFrame(self, fg_color="transparent")
        grid.pack(fill="x", padx=20, pady=4)
        grid.columnconfigure((0, 1, 2, 3), weight=1)

        for col, (icon, label, value, color) in enumerate(summary_data):
            card = ctk.CTkFrame(grid, fg_color=tm.card, corner_radius=12)
            card.grid(row=0, column=col, padx=6, pady=6, sticky="nsew")
            ctk.CTkLabel(card, text=icon, font=ctk.CTkFont(size=28)).pack(pady=(14, 2))
            ctk.CTkLabel(card, text=value,
                         font=ctk.CTkFont(size=22, weight="bold"),
                         text_color=color).pack()
            ctk.CTkLabel(card, text=label, font=ctk.CTkFont(size=11),
                         text_color=tm.text_secondary).pack(pady=(0, 14))

        # Encouragement message
        if td == 0 and hh == 0:
            msg = "A quiet week — tomorrow is a fresh start! 🌅"
            msg_color = tm.text_secondary
        elif td >= 5 and hh >= 5:
            msg = "Absolutely crushing it! You're unstoppable! 🚀"
            msg_color = tm.success
        elif xp > 200:
            msg = "Great XP week! Keep the momentum going! ⚡"
            msg_color = tm.primary
        else:
            msg = "Good effort! Every step counts. Keep going! 💪"
            msg_color = tm.accent

        msg_card = ctk.CTkFrame(self, fg_color=tm.surface, corner_radius=12)
        msg_card.pack(fill="x", padx=20, pady=10)
        ctk.CTkLabel(msg_card, text=msg,
                     font=ctk.CTkFont(size=16, slant="italic"),
                     text_color=msg_color).pack(pady=16)

        # Badges earned this week
        if new_badges:
            ctk.CTkLabel(self, text="🏅 Badges Earned This Week",
                         font=ctk.CTkFont(size=16, weight="bold"),
                         text_color=tm.text).pack(anchor="w", padx=20, pady=(12, 6))
            badge_row = ctk.CTkFrame(self, fg_color="transparent")
            badge_row.pack(anchor="w", padx=20)
            for b in new_badges:
                f = ctk.CTkFrame(badge_row, fg_color=tm.card, corner_radius=10)
                f.pack(side="left", padx=6)
                ctk.CTkLabel(f, text=b["badge_icon"] or "🏅",
                             font=ctk.CTkFont(size=30)).pack(padx=14, pady=(12, 2))
                ctk.CTkLabel(f, text=b["badge_name"],
                             font=ctk.CTkFont(size=10), text_color=tm.text).pack(padx=10, pady=(0, 12))

        # Day-by-day breakdown
        ctk.CTkLabel(self, text="📅 Day-by-Day Summary",
                     font=ctk.CTkFont(size=16, weight="bold"),
                     text_color=tm.text).pack(anchor="w", padx=20, pady=(16, 6))

        for i in range(7):
            d = week_start + timedelta(days=i)
            if d > today:
                break
            tasks_d = db.fetch_one(
                "SELECT COUNT(*) as c FROM todos WHERE profile_id=? AND is_completed=1 AND completed_at LIKE ?",
                [self._pid, f"{d.isoformat()}%"]
            )
            habits_d = db.fetch_one(
                "SELECT COUNT(*) as c FROM habit_logs hl JOIN habits h ON hl.habit_id=h.id "
                "WHERE h.profile_id=? AND hl.is_done=1 AND hl.date=?",
                [self._pid, d.isoformat()]
            )
            pom_d = db.fetch_one(
                "SELECT SUM(total_focus_minutes) as t FROM pomodoro_sessions WHERE profile_id=? AND date=?",
                [self._pid, d.isoformat()]
            )

            is_today = d == today
            df = ctk.CTkFrame(self, fg_color=tm.card if is_today else tm.surface, corner_radius=8)
            df.pack(fill="x", padx=20, pady=2)
            row_inner = ctk.CTkFrame(df, fg_color="transparent")
            row_inner.pack(fill="x", padx=14, pady=8)

            ctk.CTkLabel(row_inner, text=f"{'→ ' if is_today else ''}{d.strftime('%A %d')}",
                         font=ctk.CTkFont(size=12, weight="bold" if is_today else "normal"),
                         text_color=tm.primary if is_today else tm.text,
                         width=110, anchor="w").pack(side="left")

            td_d = tasks_d["c"] if tasks_d else 0
            hd = habits_d["c"] if habits_d else 0
            pm = pom_d["t"] if pom_d and pom_d["t"] else 0

            ctk.CTkLabel(row_inner,
                         text=f"✅ {td_d} tasks  |  🔁 {hd} habits  |  🍅 {pm}m focus",
                         font=ctk.CTkFont(size=11), text_color=tm.text_secondary).pack(side="left")

        # Award XP for generating weekly review
        db.award_xp(self._pid, 20, "Generated weekly review")
        self._refresh_xp()
