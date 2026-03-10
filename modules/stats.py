"""
StudentTrack Pro — Stats & Analytics Module
Scrollable dashboard with matplotlib charts embedded in tkinter.
"""

import customtkinter as ctk
from datetime import date, timedelta
from database import db
from modules.theme_manager import ThemeManager

try:
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    from matplotlib.backends.backend_agg import FigureCanvasAgg
    from PIL import Image, ImageTk
    import io
    HAS_MPL = True
except ImportError:
    HAS_MPL = False


def _make_chart(fig, tm) -> ctk.CTkLabel | None:
    """Convert a matplotlib figure to a CTkLabel with image."""
    if not HAS_MPL:
        return None
    try:
        buf = io.BytesIO()
        fig.savefig(buf, format="png", dpi=80, bbox_inches="tight",
                    facecolor=tm.surface, edgecolor="none")
        buf.seek(0)
        img = Image.open(buf)
        photo = ImageTk.PhotoImage(img)
        lbl = ctk.CTkLabel(None, image=photo, text="")
        lbl._photo = photo  # prevent GC
        plt.close(fig)
        return lbl, img
    except Exception as e:
        plt.close(fig)
        print(f"[Stats] chart error: {e}")
        return None


class StatsModule(ctk.CTkScrollableFrame):
    def __init__(self, parent, profile_id, tm: ThemeManager, refresh_xp_cb):
        super().__init__(parent, fg_color=tm.background, corner_radius=0)
        self._pid = profile_id
        self._tm = tm
        self._refresh_xp = refresh_xp_cb
        self._build()

    def _build(self):
        tm = self._tm

        ctk.CTkLabel(self, text="📊 Analytics Dashboard",
                     font=ctk.CTkFont(size=22, weight="bold"),
                     text_color=tm.primary).pack(anchor="w", padx=20, pady=(20, 4))

        # --- Section 1: Study Overview ---
        self._section("📖 Study Overview")
        today = date.today()

        # Pomodoro last 7 days
        days = []
        hours_list = []
        for i in range(6, -1, -1):
            d = today - timedelta(days=i)
            row = db.fetch_one(
                "SELECT SUM(total_focus_minutes) as t FROM pomodoro_sessions WHERE profile_id=? AND date=?",
                [self._pid, d.isoformat()]
            )
            days.append(d.strftime("%a"))
            hours_list.append((row["t"] or 0) / 60 if row else 0)

        if HAS_MPL:
            fig, ax = plt.subplots(figsize=(7, 2.5))
            ax.bar(days, hours_list, color=tm.primary, alpha=0.85)
            ax.set_facecolor(tm.surface)
            fig.patch.set_facecolor(tm.surface)
            ax.tick_params(colors=tm.text_secondary)
            ax.set_ylabel("Hours", color=tm.text_secondary, fontsize=9)
            ax.set_title("Study Hours – Last 7 Days", color=tm.text, fontsize=10)
            ax.spines[:].set_color(tm.border)
            result = _make_chart(fig, tm)
            if result:
                lbl, img = result
                ctk_img = ctk.CTkImage(light_image=img, dark_image=img, size=img.size)
                ctk.CTkLabel(self, image=ctk_img, text="").pack(padx=20, pady=6)
        else:
            ctk.CTkLabel(self, text="Install matplotlib + Pillow for charts.",
                         text_color=tm.warning).pack(padx=20)

        # Stat summary cards
        total_pom = db.fetch_one("SELECT SUM(cycles_completed) as s FROM pomodoro_sessions WHERE profile_id=?", [self._pid])
        pom_cycles = total_pom["s"] if total_pom and total_pom["s"] else 0
        total_focus = db.fetch_one("SELECT SUM(total_focus_minutes) as s FROM pomodoro_sessions WHERE profile_id=?", [self._pid])
        focus_mins = total_focus["s"] if total_focus and total_focus["s"] else 0

        self._stat_row([
            ("🍅", "Total Pomodoros", str(pom_cycles), tm.primary),
            ("⏱", "Total Focus Hours", f"{focus_mins // 60}h {focus_mins % 60}m", tm.secondary),
        ])

        # --- Section 2: Task Performance ---
        self._section("✅ Task Performance")
        completed_tasks = db.fetch_one("SELECT COUNT(*) as c FROM todos WHERE profile_id=? AND is_completed=1", [self._pid])
        all_tasks = db.fetch_one("SELECT COUNT(*) as c FROM todos WHERE profile_id=?", [self._pid])
        done = completed_tasks["c"] if completed_tasks else 0
        total_t = all_tasks["c"] if all_tasks else 0
        rate = round(done / total_t * 100) if total_t > 0 else 0

        self._stat_row([
            ("✅", "Tasks Completed", str(done), tm.success),
            ("📋", "Total Created", str(total_t), tm.text_secondary),
            ("📊", "Completion Rate", f"{rate}%", tm.warning),
        ])

        # --- Section 3: Habit Analytics ---
        self._section("🔁 Habit Analytics")
        habits = db.fetch_all("SELECT * FROM habits WHERE profile_id=? AND is_archived=0", [self._pid])
        for h in habits:
            total_logs = db.fetch_one("SELECT COUNT(*) as c FROM habit_logs WHERE habit_id=? AND is_done=1", [h["id"]])
            days_old = (date.today() - date.fromisoformat(h["created_at"][:10])).days + 1 if h["created_at"] else 30
            rate_h = round((total_logs["c"] if total_logs else 0) / days_old * 100)

            hab_row = ctk.CTkFrame(self, fg_color=tm.surface, corner_radius=8)
            hab_row.pack(fill="x", padx=20, pady=3)
            ctk.CTkLabel(hab_row, text=f"{h['icon'] or '🔁'}  {h['name']}",
                         font=ctk.CTkFont(size=12), text_color=tm.text, anchor="w").pack(side="left", padx=12)
            ctk.CTkLabel(hab_row, text=f"{rate_h}%  🔥{h['current_streak']}d",
                         font=ctk.CTkFont(size=12), text_color=tm.primary).pack(side="right", padx=12)

        # --- Section 4: Goal Progress ---
        self._section("🎯 Goals Progress")
        active_goals = db.fetch_all(
            "SELECT * FROM goals WHERE profile_id=? AND is_completed=0 ORDER BY deadline", [self._pid]
        )
        for g in active_goals:
            pct = g["progress_percent"] or 0
            gf = ctk.CTkFrame(self, fg_color=tm.surface, corner_radius=8)
            gf.pack(fill="x", padx=20, pady=3)
            ctk.CTkLabel(gf, text=g["title"], font=ctk.CTkFont(size=12), text_color=tm.text, anchor="w").pack(anchor="w", padx=12, pady=(6, 0))
            pb = ctk.CTkProgressBar(gf, height=6, fg_color=tm.surface2, progress_color=tm.primary)
            pb.set(pct / 100)
            pb.pack(fill="x", padx=12, pady=(2, 6))

        # --- Section 5: XP & Growth ---
        self._section("🏆 XP & Growth")
        profile = db.get_profile(self._pid)
        if profile:
            from database.db import get_level_name
            level_name = get_level_name(profile["stream"], profile["level"])
            xp = profile["xp"]
            xp_in_level = xp % 500
            badges_earned = db.fetch_all("SELECT COUNT(*) as c FROM badges WHERE profile_id=?", [self._pid])
            badge_count = badges_earned[0]["c"] if badges_earned else 0

            self._stat_row([
                ("⭐", "Level", f"{profile['level']} – {level_name}", tm.highlight),
                ("✨", "Total XP", str(xp), tm.primary),
                ("🏅", "Badges", str(badge_count), tm.warning),
            ])

            xp_prog = ctk.CTkProgressBar(self, height=10, fg_color=tm.surface2, progress_color=tm.highlight)
            xp_prog.set(xp_in_level / 500)
            xp_prog.pack(fill="x", padx=20, pady=4)
            ctk.CTkLabel(self, text=f"{xp_in_level}/500 XP to next level",
                         font=ctk.CTkFont(size=11), text_color=tm.text_secondary).pack(anchor="w", padx=20)

    def _section(self, title: str):
        ctk.CTkLabel(self, text=title,
                     font=ctk.CTkFont(size=16, weight="bold"),
                     text_color=self._tm.text_secondary).pack(anchor="w", padx=20, pady=(20, 6))
        sep = ctk.CTkFrame(self, fg_color=self._tm.border, height=1, corner_radius=0)
        sep.pack(fill="x", padx=20, pady=(0, 8))

    def _stat_row(self, items):
        tm = self._tm
        row = ctk.CTkFrame(self, fg_color="transparent")
        row.pack(fill="x", padx=20, pady=4)
        row.columnconfigure(list(range(len(items))), weight=1)
        for i, (icon, label, value, color) in enumerate(items):
            card = ctk.CTkFrame(row, fg_color=tm.card, corner_radius=10)
            card.grid(row=0, column=i, padx=6, sticky="nsew")
            ctk.CTkLabel(card, text=icon, font=ctk.CTkFont(size=24)).pack(pady=(12, 2))
            ctk.CTkLabel(card, text=value, font=ctk.CTkFont(size=18, weight="bold"),
                         text_color=color).pack()
            ctk.CTkLabel(card, text=label, font=ctk.CTkFont(size=11),
                         text_color=tm.text_secondary).pack(pady=(0, 12))
