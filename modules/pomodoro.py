"""
StudentTrack Pro — Pomodoro Timer Module
Circular countdown timer, session logging, XP awards, 7-day bar chart.
"""

import customtkinter as ctk
import math
from datetime import date
from database import db
from modules.theme_manager import ThemeManager

try:
    import winsound
    HAS_WINSOUND = True
except ImportError:
    HAS_WINSOUND = False


class PomodoroModule(ctk.CTkFrame):
    def __init__(self, parent, profile_id, tm: ThemeManager, refresh_xp_cb):
        super().__init__(parent, fg_color=tm.background, corner_radius=0)
        self._pid = profile_id
        self._tm = tm
        self._refresh_xp = refresh_xp_cb

        self._work_mins = 25
        self._break_mins = 5
        self._long_break = 15
        self._cycles_before_long = 4

        self._seconds_left = self._work_mins * 60
        self._total_seconds = self._work_mins * 60
        self._is_work = True
        self._running = False
        self._cycles = 0
        self._after_id = None
        self._session_id = None
        self._subject = ""

        self._build()

    def _build(self):
        tm = self._tm
        header = ctk.CTkFrame(self, fg_color=tm.surface, corner_radius=0, height=60)
        header.pack(fill="x")
        header.pack_propagate(False)
        ctk.CTkLabel(header, text="🍅 Pomodoro Timer",
                     font=ctk.CTkFont(size=20, weight="bold"),
                     text_color=tm.primary).pack(side="left", padx=20)

        body = ctk.CTkFrame(self, fg_color=tm.background, corner_radius=0)
        body.pack(fill="both", expand=True)

        # Left: timer controls
        left = ctk.CTkFrame(body, fg_color=tm.surface, corner_radius=16, width=400)
        left.pack(side="left", fill="y", padx=20, pady=20)
        left.pack_propagate(False)

        # Mode indicator
        self._mode_lbl = ctk.CTkLabel(left, text="🍅 Focus Time",
                                       font=ctk.CTkFont(size=16, weight="bold"),
                                       text_color=tm.primary)
        self._mode_lbl.pack(pady=(24, 8))

        # Canvas for circular timer
        self._canvas = ctk.CTkCanvas(left, width=200, height=200,
                                      bg=tm.surface, highlightthickness=0)
        self._canvas.pack(pady=10)
        self._draw_circle()

        # Time display
        self._time_lbl = ctk.CTkLabel(left, text=self._fmt(self._seconds_left),
                                       font=ctk.CTkFont(size=44, weight="bold"),
                                       text_color=tm.text)
        self._time_lbl.pack(pady=4)

        # Subject
        self._subj_var = ctk.StringVar()
        ctk.CTkLabel(left, text="Subject (optional):", font=ctk.CTkFont(size=12),
                     text_color=tm.text_secondary).pack()
        ctk.CTkEntry(left, textvariable=self._subj_var, width=200, height=32,
                     fg_color=tm.surface2, border_color=tm.border, text_color=tm.text,
                     corner_radius=8, placeholder_text="e.g. Mathematics").pack(pady=4)

        # Controls
        ctrl = ctk.CTkFrame(left, fg_color="transparent")
        ctrl.pack(pady=12)

        self._start_btn = ctk.CTkButton(ctrl, text="▶ Start", width=100, height=40,
                                         fg_color=tm.primary, hover_color=tm.secondary,
                                         corner_radius=8, font=ctk.CTkFont(size=14, weight="bold"),
                                         command=self._toggle)
        self._start_btn.pack(side="left", padx=6)

        ctk.CTkButton(ctrl, text="↺ Reset", width=80, height=40,
                      fg_color=tm.surface2, hover_color=tm.border,
                      text_color=tm.text, corner_radius=8,
                      command=self._reset).pack(side="left", padx=6)

        # Cycles
        self._cycles_lbl = ctk.CTkLabel(left, text=f"Cycles today: {self._get_today_cycles()}",
                                         font=ctk.CTkFont(size=12), text_color=tm.text_secondary)
        self._cycles_lbl.pack(pady=4)

        # Duration settings
        settings_row = ctk.CTkFrame(left, fg_color="transparent")
        settings_row.pack(pady=4)
        ctk.CTkLabel(settings_row, text="Work:", font=ctk.CTkFont(size=11),
                     text_color=tm.text_secondary).pack(side="left")
        self._work_var = ctk.IntVar(value=self._work_mins)
        ctk.CTkOptionMenu(settings_row, values=["15", "20", "25", "30", "45", "60"],
                          variable=ctk.StringVar(value="25"),
                          width=60, fg_color=tm.surface2, button_color=tm.primary,
                          text_color=tm.text,
                          command=lambda v: self._set_work(int(v))).pack(side="left", padx=4)
        ctk.CTkLabel(settings_row, text="Break:", font=ctk.CTkFont(size=11),
                     text_color=tm.text_secondary).pack(side="left", padx=(8, 0))
        ctk.CTkOptionMenu(settings_row, values=["3", "5", "10", "15"],
                          variable=ctk.StringVar(value="5"),
                          width=60, fg_color=tm.surface2, button_color=tm.primary,
                          text_color=tm.text,
                          command=lambda v: self._set_break(int(v))).pack(side="left", padx=4)

        # Right: history chart
        right = ctk.CTkScrollableFrame(body, fg_color=tm.background, corner_radius=0)
        right.pack(side="left", fill="both", expand=True, pady=20, padx=(0, 20))

        ctk.CTkLabel(right, text="📊 Last 7 Days",
                     font=ctk.CTkFont(size=16, weight="bold"),
                     text_color=tm.text).pack(anchor="w", pady=(10, 8))

        self._render_history(right)

    def _render_history(self, parent):
        from datetime import timedelta
        tm = self._tm
        today = date.today()
        max_focus = 1

        data = []
        for i in range(6, -1, -1):
            d = today - timedelta(days=i)
            row = db.fetch_one(
                "SELECT SUM(total_focus_minutes) as t FROM pomodoro_sessions WHERE profile_id=? AND date=?",
                [self._pid, d.isoformat()]
            )
            mins = row["t"] if row and row["t"] else 0
            data.append((d.strftime("%a"), mins))
            max_focus = max(max_focus, mins)

        # Today's total
        today_row = db.fetch_one(
            "SELECT SUM(total_focus_minutes) as t FROM pomodoro_sessions WHERE profile_id=? AND date=?",
            [self._pid, today.isoformat()]
        )
        today_mins = today_row["t"] if today_row and today_row["t"] else 0
        ctk.CTkLabel(parent, text=f"Today: {today_mins} focus minutes",
                     font=ctk.CTkFont(size=14), text_color=tm.primary).pack(anchor="w", padx=10)

        # Bar chart
        for day_name, mins in data:
            bar_row = ctk.CTkFrame(parent, fg_color="transparent")
            bar_row.pack(fill="x", padx=10, pady=4)
            ctk.CTkLabel(bar_row, text=day_name, width=40, font=ctk.CTkFont(size=11),
                         text_color=tm.text_secondary).pack(side="left")
            bar_pct = mins / max_focus if max_focus > 0 else 0
            bar_bg = ctk.CTkFrame(bar_row, fg_color=tm.surface2, corner_radius=4, height=22)
            bar_bg.pack(side="left", fill="x", expand=True, padx=4)
            if bar_pct > 0:
                bar_fill = ctk.CTkFrame(bar_bg, fg_color=tm.primary, corner_radius=4, height=22)
                bar_fill.place(relx=0, rely=0, relwidth=bar_pct, relheight=1)
            ctk.CTkLabel(bar_row, text=f"{mins}m", width=40,
                         font=ctk.CTkFont(size=11), text_color=tm.text_secondary).pack(side="left")

    def _draw_circle(self, progress: float = 1.0):
        tm = self._tm
        self._canvas.delete("all")
        cx, cy, r = 100, 100, 85
        # Background arc
        self._canvas.create_arc(cx - r, cy - r, cx + r, cy + r,
                                 start=90, extent=360,
                                 outline=tm.surface2, style="arc", width=14)
        # Progress arc
        color = tm.primary if self._is_work else tm.success
        extent = int(360 * progress)
        if extent > 0:
            self._canvas.create_arc(cx - r, cy - r, cx + r, cy + r,
                                     start=90, extent=-extent,
                                     outline=color, style="arc", width=14)

    def _fmt(self, seconds: int) -> str:
        return f"{seconds // 60:02d}:{seconds % 60:02d}"

    def _toggle(self):
        if self._running:
            self._running = False
            self._start_btn.configure(text="▶ Resume")
            if self._after_id:
                self.after_cancel(self._after_id)
        else:
            self._running = True
            self._subject = self._subj_var.get().strip()
            self._start_btn.configure(text="⏸ Pause")
            self._tick()

    def _tick(self):
        if not self._running:
            return
        if self._seconds_left <= 0:
            self._on_phase_end()
            return
        self._seconds_left -= 1
        self._time_lbl.configure(text=self._fmt(self._seconds_left))
        progress = self._seconds_left / self._total_seconds
        self._draw_circle(progress)
        self._after_id = self.after(1000, self._tick)

    def _on_phase_end(self):
        self._running = False
        if HAS_WINSOUND:
            try:
                winsound.Beep(880, 500)
            except Exception:
                pass

        if self._is_work:
            # Work phase done
            self._cycles += 1
            focus_mins = self._work_mins

            # Record session
            db.insert("pomodoro_sessions", {
                "profile_id":       self._pid,
                "subject":          self._subject,
                "work_duration":    self._work_mins,
                "break_duration":   self._break_mins,
                "cycles_completed": 1,
                "total_focus_minutes": focus_mins,
                "date":             date.today().isoformat(),
            })
            db.award_xp(self._pid, 15, "Completed Pomodoro cycle")
            db.check_and_award_badges(self._pid)
            self._refresh_xp()

            # Switch to break
            self._is_work = False
            if self._cycles % self._cycles_before_long == 0:
                self._seconds_left = self._long_break * 60
                self._total_seconds = self._long_break * 60
                self._mode_lbl.configure(text="☕ Long Break")
            else:
                self._seconds_left = self._break_mins * 60
                self._total_seconds = self._break_mins * 60
                self._mode_lbl.configure(text="🌿 Short Break")
        else:
            # Break done, back to work
            self._is_work = True
            self._seconds_left = self._work_mins * 60
            self._total_seconds = self._work_mins * 60
            self._mode_lbl.configure(text="🍅 Focus Time")

        self._cycles_lbl.configure(text=f"Cycles today: {self._get_today_cycles()}")
        self._time_lbl.configure(text=self._fmt(self._seconds_left))
        self._draw_circle(1.0)
        self._start_btn.configure(text="▶ Start")

    def _reset(self):
        if self._after_id:
            self.after_cancel(self._after_id)
        self._running = False
        self._is_work = True
        self._seconds_left = self._work_mins * 60
        self._total_seconds = self._work_mins * 60
        self._time_lbl.configure(text=self._fmt(self._seconds_left))
        self._mode_lbl.configure(text="🍅 Focus Time")
        self._draw_circle(1.0)
        self._start_btn.configure(text="▶ Start")

    def _set_work(self, mins: int):
        self._work_mins = mins
        if self._is_work and not self._running:
            self._seconds_left = mins * 60
            self._total_seconds = mins * 60
            self._time_lbl.configure(text=self._fmt(self._seconds_left))
            self._draw_circle(1.0)

    def _set_break(self, mins: int):
        self._break_mins = mins

    def _get_today_cycles(self) -> int:
        row = db.fetch_one(
            "SELECT SUM(cycles_completed) as s FROM pomodoro_sessions WHERE profile_id=? AND date=?",
            [self._pid, date.today().isoformat()]
        )
        return row["s"] if row and row["s"] else 0
