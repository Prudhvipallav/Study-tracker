"""
StudentTrack Pro — Health Dashboard Module
4-tab health tracker: Sleep, Water, Mood, Exercise.
"""

import customtkinter as ctk
from datetime import date, timedelta
from database import db
from modules.theme_manager import ThemeManager


class HealthModule(ctk.CTkFrame):
    def __init__(self, parent, profile_id, tm: ThemeManager, refresh_xp_cb):
        super().__init__(parent, fg_color=tm.background, corner_radius=0)
        self._pid = profile_id
        self._tm = tm
        self._refresh_xp = refresh_xp_cb
        self._build()

    def _build(self):
        tm = self._tm
        header = ctk.CTkFrame(self, fg_color=tm.surface, corner_radius=0, height=60)
        header.pack(fill="x")
        header.pack_propagate(False)
        ctk.CTkLabel(header, text="❤️ Health Dashboard",
                     font=ctk.CTkFont(size=20, weight="bold"),
                     text_color=tm.primary).pack(side="left", padx=20)

        self._tabview = ctk.CTkTabview(self, fg_color=tm.background,
                                        segmented_button_fg_color=tm.surface,
                                        segmented_button_selected_color=tm.primary,
                                        text_color=tm.text)
        self._tabview.pack(fill="both", expand=True, padx=16, pady=16)

        for tab_name in ["😴 Sleep", "💧 Water", "😊 Mood", "🏃 Exercise"]:
            self._tabview.add(tab_name)

        self._build_sleep(self._tabview.tab("😴 Sleep"))
        self._build_water(self._tabview.tab("💧 Water"))
        self._build_mood(self._tabview.tab("😊 Mood"))
        self._build_exercise(self._tabview.tab("🏃 Exercise"))

    # ------------------------------------------------------------------
    # Sleep Tab
    # ------------------------------------------------------------------
    def _build_sleep(self, parent):
        tm = self._tm
        today = date.today().isoformat()
        log = db.fetch_one("SELECT * FROM health_logs WHERE profile_id=? AND date=?", [self._pid, today])

        form = ctk.CTkFrame(parent, fg_color=tm.surface, corner_radius=12)
        form.pack(fill="x", padx=20, pady=14)

        row = ctk.CTkFrame(form, fg_color="transparent")
        row.pack(pady=16, padx=20)

        self._sleep_var = ctk.StringVar(value=log["sleep_time"] if log and log["sleep_time"] else "23:00")
        self._wake_var = ctk.StringVar(value=log["wake_time"] if log and log["wake_time"] else "07:00")

        for label, var in [("Bedtime (HH:MM):", self._sleep_var), ("Wake time (HH:MM):", self._wake_var)]:
            ctk.CTkLabel(row, text=label, font=ctk.CTkFont(size=13),
                         text_color=tm.text).pack(side="left", padx=(0, 6))
            ctk.CTkEntry(row, textvariable=var, width=90, height=34,
                         fg_color=tm.surface2, border_color=tm.border, text_color=tm.text,
                         corner_radius=8).pack(side="left", padx=(0, 20))

        ctk.CTkButton(form, text="Log Sleep", width=160, height=36,
                      fg_color=tm.primary, corner_radius=8,
                      command=self._log_sleep).pack(pady=10)

        if log and log["sleep_hours"]:
            h = log["sleep_hours"]
            color = tm.danger if h < 6 else (tm.warning if h < 7 else (tm.success if h <= 9 else "#00BFFF"))
            ctk.CTkLabel(parent, text=f"Last night: {h:.1f} hours",
                         font=ctk.CTkFont(size=20, weight="bold"),
                         text_color=color).pack(pady=10)

        # 14-day history
        ctk.CTkLabel(parent, text="Last 14 days:",
                     font=ctk.CTkFont(size=13, weight="bold"),
                     text_color=tm.text).pack(anchor="w", padx=20, pady=(8, 4))
        for i in range(13, -1, -1):
            d = (date.today() - timedelta(days=i)).isoformat()
            row_log = db.fetch_one("SELECT sleep_hours FROM health_logs WHERE profile_id=? AND date=?", [self._pid, d])
            h = row_log["sleep_hours"] if row_log and row_log["sleep_hours"] else 0
            row_frame = ctk.CTkFrame(parent, fg_color="transparent")
            row_frame.pack(fill="x", padx=20, pady=1)
            ctk.CTkLabel(row_frame, text=d[-5:], width=50, font=ctk.CTkFont(size=10),
                         text_color=tm.text_secondary).pack(side="left")
            pct = min(h / 10, 1.0)
            color = tm.danger if h < 6 else (tm.warning if h < 7 else tm.success)
            bar_bg = ctk.CTkFrame(row_frame, fg_color=tm.surface2, corner_radius=3, height=14)
            bar_bg.pack(side="left", fill="x", expand=True, padx=4)
            if pct > 0:
                ctk.CTkFrame(bar_bg, fg_color=color, corner_radius=3, height=14).place(
                    relx=0, rely=0, relwidth=pct, relheight=1)
            ctk.CTkLabel(row_frame, text=f"{h:.1f}h", width=42,
                         font=ctk.CTkFont(size=10), text_color=tm.text_secondary).pack(side="left")

    def _log_sleep(self):
        today = date.today().isoformat()
        sleep_t = self._sleep_var.get().strip()
        wake_t = self._wake_var.get().strip()
        try:
            sh, sm = map(int, sleep_t.split(":"))
            wh, wm = map(int, wake_t.split(":"))
            total = ((wh * 60 + wm) - (sh * 60 + sm)) % (24 * 60)
            sleep_hours = round(total / 60, 2)
        except Exception:
            sleep_hours = 0

        existing = db.fetch_one("SELECT id FROM health_logs WHERE profile_id=? AND date=?", [self._pid, today])
        if existing:
            db.update("health_logs", {"sleep_time": sleep_t, "wake_time": wake_t, "sleep_hours": sleep_hours},
                      {"id": existing["id"]})
        else:
            db.insert("health_logs", {"profile_id": self._pid, "date": today,
                                       "sleep_time": sleep_t, "wake_time": wake_t, "sleep_hours": sleep_hours})
        db.award_xp(self._pid, 3, "Logged sleep")
        self._refresh_xp()

    # ------------------------------------------------------------------
    # Water Tab
    # ------------------------------------------------------------------
    def _build_water(self, parent):
        tm = self._tm
        today = date.today().isoformat()
        log = db.fetch_one("SELECT * FROM health_logs WHERE profile_id=? AND date=?", [self._pid, today])
        glasses = log["water_glasses"] if log and log["water_glasses"] else 0

        goal = 8
        pct = min(glasses / goal, 1.0)

        ctk.CTkLabel(parent, text=f"💧 {glasses} / {goal} glasses",
                     font=ctk.CTkFont(size=26, weight="bold"),
                     text_color=tm.primary).pack(pady=20)

        # Visual water bottle (canvas)
        canvas = ctk.CTkCanvas(parent, width=100, height=200,
                                bg=tm.background, highlightthickness=0)
        canvas.pack()
        # Bottle outline
        canvas.create_rectangle(20, 30, 80, 190, outline=tm.primary, width=3,
                                 fill=tm.surface)
        # Water fill
        fill_height = int(160 * pct)
        if fill_height > 0:
            canvas.create_rectangle(20, 190 - fill_height, 80, 190,
                                     fill="#00BFFF", outline="")
        canvas.create_rectangle(35, 10, 65, 30, outline=tm.primary, width=3, fill=tm.surface)

        prog = ctk.CTkProgressBar(parent, width=300, height=16,
                                   fg_color=tm.surface2, progress_color="#00BFFF", corner_radius=8)
        prog.set(pct)
        prog.pack(pady=10)

        ctk.CTkButton(parent, text="+ 1 Glass 💧", width=180, height=46,
                      font=ctk.CTkFont(size=16, weight="bold"),
                      fg_color="#00BFFF", hover_color="#0099CC", corner_radius=10,
                      command=self._add_glass).pack(pady=16)

    def _add_glass(self):
        today = date.today().isoformat()
        existing = db.fetch_one("SELECT * FROM health_logs WHERE profile_id=? AND date=?", [self._pid, today])
        if existing:
            db.update("health_logs", {"water_glasses": (existing["water_glasses"] or 0) + 1},
                      {"id": existing["id"]})
        else:
            db.insert("health_logs", {"profile_id": self._pid, "date": today, "water_glasses": 1})
        db.award_xp(self._pid, 3, "Logged water")
        self._refresh_xp()
        # Refresh
        for w in self.winfo_children():
            w.destroy()
        self._build()

    # ------------------------------------------------------------------
    # Mood Tab
    # ------------------------------------------------------------------
    def _build_mood(self, parent):
        tm = self._tm
        today = date.today().isoformat()
        log = db.fetch_one("SELECT * FROM health_logs WHERE profile_id=? AND date=?", [self._pid, today])
        current_mood = log["mood"] if log and log["mood"] else None

        ctk.CTkLabel(parent, text="How are you feeling today?",
                     font=ctk.CTkFont(size=16, weight="bold"),
                     text_color=tm.text).pack(pady=20)

        moods = ["😞 Awful", "😕 Bad", "😐 Okay", "😊 Good", "😄 Great"]
        btn_row = ctk.CTkFrame(parent, fg_color="transparent")
        btn_row.pack()

        mood_colors = [tm.danger, tm.warning, tm.text_secondary, tm.success, tm.primary]
        self._mood_note_var = ctk.StringVar(value=log["mood_note"] if log and log["mood_note"] else "")

        for i, (mood_text, mcolor) in enumerate(zip(moods, mood_colors)):
            score = i + 1
            is_active = current_mood == score
            btn = ctk.CTkButton(btn_row, text=mood_text.split()[0],
                                 width=64, height=64,
                                 fg_color=mcolor if is_active else tm.surface2,
                                 hover_color=mcolor, corner_radius=32,
                                 font=ctk.CTkFont(size=30),
                                 command=lambda s=score: self._log_mood(s))
            btn.pack(side="left", padx=6)

        ctk.CTkLabel(parent, text="Add a note (optional):",
                     font=ctk.CTkFont(size=12), text_color=tm.text_secondary).pack(pady=(16, 4))
        ctk.CTkEntry(parent, textvariable=self._mood_note_var, width=320, height=34,
                     fg_color=tm.surface, border_color=tm.border, text_color=tm.text,
                     corner_radius=8, placeholder_text="How are you feeling?").pack()

    def _log_mood(self, score: int):
        today = date.today().isoformat()
        note = self._mood_note_var.get().strip()
        existing = db.fetch_one("SELECT id FROM health_logs WHERE profile_id=? AND date=?", [self._pid, today])
        if existing:
            db.update("health_logs", {"mood": score, "mood_note": note}, {"id": existing["id"]})
        else:
            db.insert("health_logs", {"profile_id": self._pid, "date": today, "mood": score, "mood_note": note})
        db.award_xp(self._pid, 3, "Logged mood")
        self._refresh_xp()
        for w in self.winfo_children():
            w.destroy()
        self._build()

    # ------------------------------------------------------------------
    # Exercise Tab
    # ------------------------------------------------------------------
    def _build_exercise(self, parent):
        tm = self._tm
        today = date.today().isoformat()
        log = db.fetch_one("SELECT * FROM health_logs WHERE profile_id=? AND date=?", [self._pid, today])

        form = ctk.CTkFrame(parent, fg_color=tm.surface, corner_radius=12)
        form.pack(fill="x", padx=20, pady=14)

        inner = ctk.CTkFrame(form, fg_color="transparent")
        inner.pack(padx=20, pady=16)

        self._ex_type = ctk.StringVar(value="")
        self._ex_mins = ctk.StringVar(value="30")
        self._ex_steps = ctk.StringVar(value="")

        for label, var in [("Exercise type:", self._ex_type), ("Minutes:", self._ex_mins), ("Steps:", self._ex_steps)]:
            ctk.CTkLabel(inner, text=label, font=ctk.CTkFont(size=13), text_color=tm.text).pack(side="left", padx=4)
            ctk.CTkEntry(inner, textvariable=var, width=100, height=34,
                         fg_color=tm.surface2, border_color=tm.border, text_color=tm.text,
                         corner_radius=8).pack(side="left", padx=4)

        ctk.CTkButton(form, text="Log Exercise", width=160, height=36,
                      fg_color=tm.primary, corner_radius=8,
                      command=self._log_exercise).pack(pady=(0, 14))

        if log and log["exercise_minutes"]:
            ctk.CTkLabel(parent, text=f"Today: {log['exercise_minutes']} minutes of {log['exercise_type'] or 'exercise'}",
                         font=ctk.CTkFont(size=16, weight="bold"),
                         text_color=tm.success).pack(pady=10)

    def _log_exercise(self):
        today = date.today().isoformat()
        try:
            mins = int(self._ex_mins.get())
        except ValueError:
            mins = 0
        try:
            steps = int(self._ex_steps.get())
        except ValueError:
            steps = 0
        ex_type = self._ex_type.get().strip()

        existing = db.fetch_one("SELECT id FROM health_logs WHERE profile_id=? AND date=?", [self._pid, today])
        if existing:
            db.update("health_logs", {"exercise_type": ex_type, "exercise_minutes": mins, "steps": steps},
                      {"id": existing["id"]})
        else:
            db.insert("health_logs", {"profile_id": self._pid, "date": today,
                                       "exercise_type": ex_type, "exercise_minutes": mins, "steps": steps})
        db.award_xp(self._pid, 3, "Logged exercise")
        self._refresh_xp()
        for w in self.winfo_children():
            w.destroy()
        self._build()
