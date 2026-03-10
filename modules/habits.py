"""
StudentTrack Pro — Habits Tracker Module
Daily habit check-ins, streaks, calendar heatmap, XP awards, badges.
"""

import customtkinter as ctk
from datetime import date, timedelta
from database import db
from modules.theme_manager import ThemeManager

FREQ_OPTIONS = ["daily", "weekdays", "weekends", "custom"]
HABIT_ICONS = ["✅", "📖", "💧", "🏃", "🧘", "💊", "🎸", "✏️", "🍎", "😴"]


class HabitsModule(ctk.CTkFrame):
    def __init__(self, parent, profile_id: int, tm: ThemeManager, refresh_xp_cb):
        super().__init__(parent, fg_color=tm.background, corner_radius=0)
        self._pid = profile_id
        self._tm = tm
        self._refresh_xp = refresh_xp_cb
        self._view = "daily"  # 'daily' or 'heatmap'
        self._build()

    def _build(self):
        tm = self._tm
        header = ctk.CTkFrame(self, fg_color=tm.surface, corner_radius=0, height=60)
        header.pack(fill="x")
        header.pack_propagate(False)
        ctk.CTkLabel(header, text="🔁 Habit Tracker",
                     font=ctk.CTkFont(size=20, weight="bold"),
                     text_color=tm.primary).pack(side="left", padx=20)

        ctk.CTkButton(header, text="+ New Habit", width=120, height=34,
                      fg_color=tm.primary, hover_color=tm.secondary, corner_radius=8,
                      font=ctk.CTkFont(size=13, weight="bold"),
                      command=self._open_add_dialog).pack(side="right", padx=20)

        # View toggle
        toggle = ctk.CTkSegmentedButton(
            header, values=["📋 Daily", "🗓 Heatmap"],
            fg_color=tm.surface2, selected_color=tm.primary, text_color=tm.text,
            command=lambda v: self._switch_view(v)
        )
        toggle.set("📋 Daily")
        toggle.pack(side="right", padx=10)

        self._list_area = ctk.CTkScrollableFrame(self, fg_color=tm.background, corner_radius=0)
        self._list_area.pack(fill="both", expand=True)
        self._render_daily()

    def _switch_view(self, val: str):
        self._view = "heatmap" if "Heatmap" in val else "daily"
        for w in self._list_area.winfo_children():
            w.destroy()
        if self._view == "daily":
            self._render_daily()
        else:
            self._render_heatmap()

    def _render_daily(self):
        for w in self._list_area.winfo_children():
            w.destroy()
        tm = self._tm
        today = date.today()
        habits = db.fetch_all(
            "SELECT * FROM habits WHERE profile_id=? AND is_archived=0 ORDER BY name",
            [self._pid]
        )
        if not habits:
            ctk.CTkLabel(self._list_area, text="No habits yet! Add one to start building streaks 🔥",
                         font=ctk.CTkFont(size=15), text_color=tm.text_secondary).pack(pady=60)
            return

        ctk.CTkLabel(self._list_area, text=f"📅 {today.strftime('%A, %B %d')}",
                     font=ctk.CTkFont(size=16, weight="bold"),
                     text_color=tm.text).pack(anchor="w", padx=20, pady=(16, 8))

        for h in habits:
            done_row = db.fetch_one(
                "SELECT is_done FROM habit_logs WHERE habit_id=? AND date=?",
                [h["id"], today.isoformat()]
            )
            is_done = done_row["is_done"] if done_row else 0
            self._render_habit_card(h, is_done, today)

    def _render_habit_card(self, habit, is_done: bool, today: date):
        tm = self._tm
        hcolor = habit["color"] or tm.primary
        habit_id = habit["id"]

        card = ctk.CTkFrame(self._list_area, fg_color=tm.card, corner_radius=12,
                            border_width=2,
                            border_color=tm.success if is_done else tm.border)
        card.pack(fill="x", padx=16, pady=5)

        row = ctk.CTkFrame(card, fg_color="transparent")
        row.pack(fill="x", padx=16, pady=12)

        icon_lbl = ctk.CTkLabel(row, text=habit["icon"] or "🔁",
                                font=ctk.CTkFont(size=30), width=40)
        icon_lbl.pack(side="left", padx=(0, 14))

        info = ctk.CTkFrame(row, fg_color="transparent")
        info.pack(side="left", fill="both", expand=True)

        ctk.CTkLabel(info, text=habit["name"],
                     font=ctk.CTkFont(size=14, weight="bold"),
                     text_color=tm.success if is_done else tm.text, anchor="w").pack(anchor="w")

        streak_text = f"🔥 {habit['current_streak']} day streak  |  Best: {habit['longest_streak']}"
        ctk.CTkLabel(info, text=streak_text, font=ctk.CTkFont(size=11),
                     text_color=tm.text_secondary, anchor="w").pack(anchor="w")

        # Check button
        check_btn = ctk.CTkButton(
            row, text="✅ Done" if is_done else "○ Mark Done",
            width=110, height=38,
            fg_color=tm.success if is_done else tm.surface2,
            hover_color="#2EA043" if is_done else tm.primary,
            text_color="white" if is_done else tm.text,
            corner_radius=8, font=ctk.CTkFont(size=12),
            command=lambda hid=habit_id: self._toggle_habit(hid)
        )
        check_btn.pack(side="right")

    def _toggle_habit(self, habit_id: int):
        today = date.today().isoformat()
        existing = db.fetch_one("SELECT * FROM habit_logs WHERE habit_id=? AND date=?", [habit_id, today])
        if existing:
            new_done = 0 if existing["is_done"] else 1
            db.update("habit_logs", {"is_done": new_done}, {"id": existing["id"]})
            xp_delta = 5 if new_done else 0
        else:
            db.insert("habit_logs", {"habit_id": habit_id, "date": today, "is_done": 1})
            new_done = 1
            xp_delta = 5

        self._update_streak(habit_id)
        if xp_delta:
            db.award_xp(self._pid, xp_delta, "Habit check-in")
            db.check_and_award_badges(self._pid)
        self._refresh_xp()
        self._render_daily()

    def _update_streak(self, habit_id: int):
        """Recalculate current streak for a habit."""
        today = date.today()
        streak = 0
        d = today
        while True:
            log = db.fetch_one(
                "SELECT is_done FROM habit_logs WHERE habit_id=? AND date=?",
                [habit_id, d.isoformat()]
            )
            if log and log["is_done"]:
                streak += 1
                d -= timedelta(days=1)
            else:
                break

        habit = db.fetch_one("SELECT longest_streak FROM habits WHERE id=?", [habit_id])
        longest = max(habit["longest_streak"] if habit else 0, streak)
        db.update("habits", {"current_streak": streak, "longest_streak": longest}, {"id": habit_id})

    def _render_heatmap(self):
        tm = self._tm
        habits = db.fetch_all(
            "SELECT * FROM habits WHERE profile_id=? AND is_archived=0", [self._pid]
        )
        if not habits:
            ctk.CTkLabel(self._list_area, text="No habits to display.",
                         font=ctk.CTkFont(size=14), text_color=tm.text_secondary).pack(pady=40)
            return

        for h in habits:
            ctk.CTkLabel(self._list_area,
                         text=f"{h['icon'] or '🔁'}  {h['name']}  — {h['current_streak']} day streak",
                         font=ctk.CTkFont(size=14, weight="bold"),
                         text_color=tm.text).pack(anchor="w", padx=20, pady=(14, 4))

            hmap = ctk.CTkFrame(self._list_area, fg_color=tm.surface, corner_radius=8)
            hmap.pack(fill="x", padx=20, pady=(0, 10))

            today = date.today()
            days_back = 35  # 5 weeks
            row_frame = None

            for i in range(days_back - 1, -1, -1):
                if i % 7 == days_back % 7 - 1 or row_frame is None:
                    row_frame = ctk.CTkFrame(hmap, fg_color="transparent")
                    row_frame.pack(anchor="w", padx=8, pady=2)

                d = today - timedelta(days=i)
                log = db.fetch_one(
                    "SELECT is_done FROM habit_logs WHERE habit_id=? AND date=?",
                    [h["id"], d.isoformat()]
                )
                is_done = log and log["is_done"]
                cell_color = tm.primary if is_done else tm.surface2

                cell = ctk.CTkFrame(row_frame, fg_color=cell_color,
                                    corner_radius=2, width=14, height=14)
                cell.pack(side="left", padx=1)

    def _open_add_dialog(self):
        AddHabitDialog(self, self._pid, self._tm, self._build)


class AddHabitDialog(ctk.CTkToplevel):
    def __init__(self, parent, profile_id, tm, on_save_cb):
        super().__init__(parent)
        self._pid = profile_id
        self._tm = tm
        self._on_save = on_save_cb
        self._icon_var = ctk.StringVar(value=HABIT_ICONS[0])
        self._freq_var = ctk.StringVar(value="daily")
        self.title("New Habit")
        self.geometry("420x460")
        self.resizable(False, False)
        self.grab_set()
        self.configure(fg_color=tm.background)
        self._build()

    def _build(self):
        tm = self._tm
        ctk.CTkLabel(self, text="New Habit", font=ctk.CTkFont(size=18, weight="bold"),
                     text_color=tm.text).pack(pady=(16, 10))

        form = ctk.CTkFrame(self, fg_color=tm.surface, corner_radius=12)
        form.pack(fill="both", expand=True, padx=20, pady=10)

        self._title_var = ctk.StringVar()
        ctk.CTkLabel(form, text="Habit Name *", font=ctk.CTkFont(size=12),
                     text_color=tm.text_secondary, anchor="w").pack(anchor="w", padx=16, pady=(12, 2))
        ctk.CTkEntry(form, textvariable=self._title_var, height=36,
                     fg_color=tm.surface2, border_color=tm.border, text_color=tm.text,
                     corner_radius=8).pack(fill="x", padx=16)

        ctk.CTkLabel(form, text="Icon", font=ctk.CTkFont(size=12),
                     text_color=tm.text_secondary, anchor="w").pack(anchor="w", padx=16, pady=(10, 2))
        icon_row = ctk.CTkFrame(form, fg_color="transparent")
        icon_row.pack(anchor="w", padx=16)
        for ic in HABIT_ICONS:
            btn = ctk.CTkButton(icon_row, text=ic, width=36, height=36,
                                fg_color=tm.primary if ic == self._icon_var.get() else tm.surface2,
                                corner_radius=18, font=ctk.CTkFont(size=18),
                                command=lambda x=ic: self._set_icon(x, icon_row))
            btn.pack(side="left", padx=2)

        ctk.CTkLabel(form, text="Frequency", font=ctk.CTkFont(size=12),
                     text_color=tm.text_secondary, anchor="w").pack(anchor="w", padx=16, pady=(10, 2))
        ctk.CTkSegmentedButton(form, values=["daily", "weekdays", "weekends"],
                               variable=self._freq_var,
                               fg_color=tm.surface2, selected_color=tm.primary,
                               text_color=tm.text).pack(anchor="w", padx=16)

        self._color_var = ctk.StringVar(value=tm.primary)
        ctk.CTkLabel(form, text="Color (hex)", font=ctk.CTkFont(size=12),
                     text_color=tm.text_secondary, anchor="w").pack(anchor="w", padx=16, pady=(10, 2))
        ctk.CTkEntry(form, textvariable=self._color_var, height=32,
                     fg_color=tm.surface2, border_color=tm.border, text_color=tm.text,
                     corner_radius=8).pack(fill="x", padx=16)

        ctk.CTkButton(self, text="Create Habit", width=200, height=42,
                      fg_color=tm.primary, hover_color=tm.secondary, corner_radius=10,
                      font=ctk.CTkFont(size=14, weight="bold"),
                      command=self._save).pack(pady=14)

    def _set_icon(self, ic: str, icon_row):
        self._icon_var.set(ic)
        tm = self._tm
        for btn in icon_row.winfo_children():
            btn.configure(fg_color=tm.primary if btn.cget("text") == ic else tm.surface2)

    def _save(self):
        title = self._title_var.get().strip()
        if not title:
            return
        db.insert("habits", {
            "profile_id": self._pid,
            "name":       title,
            "frequency":  self._freq_var.get(),
            "icon":       self._icon_var.get(),
            "color":      self._color_var.get(),
        })
        self.destroy()
        self._on_save()
