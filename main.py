"""
StudentTrack Pro — Application Entry Point

Architecture:
  - ONE persistent ctk.CTk() root lives for the entire app lifetime.
  - Screens (profile select, onboarding, main) are plain CTkFrame subclasses
    that are packed/destroyed inside the root — no CTkToplevel roots.
  - This eliminates "invalid command name" after-callback errors that happen
    when a root Tk window is destroyed while pending callbacks remain.
"""

import os
import sys
import traceback
import logging
import customtkinter as ctk
import importlib

ROOT = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, ROOT)

# ---------------------------------------------------------------------------
# Global crash handler — logs to ~/.studenttrackpro/crash.log
# ---------------------------------------------------------------------------
_LOG_DIR = os.path.join(os.path.expanduser("~"), ".studenttrackpro")
os.makedirs(_LOG_DIR, exist_ok=True)
logging.basicConfig(
    filename=os.path.join(_LOG_DIR, "crash.log"),
    level=logging.ERROR,
    format="%(asctime)s — %(levelname)s — %(message)s",
)

def _crash_handler(exc_type, exc_value, exc_tb):
    """Log unhandled exceptions to crash.log before propagating."""
    logging.error("Unhandled exception", exc_info=(exc_type, exc_value, exc_tb))
    sys.__excepthook__(exc_type, exc_value, exc_tb)

sys.excepthook = _crash_handler


from database.db import (
    init_db, get_all_profiles, get_settings, get_profile,
    award_xp, check_and_award_badges, insert,
    BADGE_DEFINITIONS, update_settings
)
from modules.theme_manager import ThemeManager, set_active_theme

ICON_PATH = os.path.join(ROOT, "assets", "icon.ico")


def ensure_icon():
    if not os.path.exists(ICON_PATH):
        try:
            from assets.generate_icon import generate_icon
            generate_icon(ICON_PATH)
        except Exception as e:
            print(f"[Main] Could not generate icon: {e}")


# ===========================================================================
# Persistent root window
# ===========================================================================

class App(ctk.CTk):
    """Single Tk root. Screens live as child frames — never separate roots."""

    def __init__(self):
        super().__init__()
        self.title("StudentTrack Pro")
        self.geometry("760x560")
        self.resizable(True, True)

        if os.path.exists(ICON_PATH):
            try:
                self.iconbitmap(ICON_PATH)
            except Exception:
                pass

        ctk.set_appearance_mode("dark")
        ctk.set_default_color_theme("blue")
        self._screen = None
        self._show_launch()

    # ---------------------------------------------------------------- helpers

    def _swap(self, frame: ctk.CTkFrame):
        if self._screen is not None:
            self._screen.destroy()
        self._screen = frame
        frame.pack(fill="both", expand=True)

    def _show_launch(self):
        profiles = get_all_profiles()
        if profiles:
            self._swap(ProfileSelectScreen(self, profiles))
        else:
            self._swap(OnboardingScreen(self))

    def show_profile_select(self):
        self.geometry("760x560")
        self.title("StudentTrack Pro — Select Profile")
        profiles = get_all_profiles()
        self._swap(ProfileSelectScreen(self, profiles))

    def show_onboarding(self):
        self.geometry("700x620")
        self.title("StudentTrack Pro — Setup")
        self._swap(OnboardingScreen(self))

    def show_main_app(self, profile_id: int):
        from datetime import datetime
        from database.db import update
        update("profiles", {"last_seen": datetime.now().isoformat()}, {"id": profile_id})
        self.geometry("1280x800")
        self.minsize(1100, 700)
        self._swap(MainAppFrame(self, profile_id))


# ===========================================================================
# Profile select screen
# ===========================================================================

class ProfileSelectScreen(ctk.CTkFrame):
    STREAM_COLORS = {
        "engineering": "#1E90FF",
        "medical":     "#00C896",
        "law":         "#C0392B",
        "competitive": "#9B59B6",
    }
    STREAM_ICONS = {
        "engineering": "🔧",
        "medical":     "🩺",
        "law":         "⚖️",
        "competitive": "📖",
    }

    def __init__(self, app: App, profiles):
        super().__init__(app, fg_color="#1A1A2E", corner_radius=0)
        self._app = app
        self._build(profiles)

    def _build(self, profiles):
        ctk.CTkLabel(self, text="🎓 StudentTrack Pro",
                     font=ctk.CTkFont(size=30, weight="bold"),
                     text_color="#60A5FA").pack(pady=(50, 4))
        ctk.CTkLabel(self, text="Select your profile",
                     font=ctk.CTkFont(size=15), text_color="#94A3B8").pack(pady=(0, 24))

        scroll = ctk.CTkScrollableFrame(self, fg_color="transparent")
        scroll.pack(fill="both", expand=True, padx=60, pady=(0, 10))

        for p in profiles:
            color = self.STREAM_COLORS.get(p["stream"], "#888")
            icon  = p["avatar"] or self.STREAM_ICONS.get(p["stream"], "👤")
            pid   = p["id"]

            card = ctk.CTkFrame(scroll, fg_color="#2D3748", corner_radius=12,
                                border_width=2, border_color=color)
            card.pack(fill="x", pady=6)

            row = ctk.CTkFrame(card, fg_color="transparent")
            row.pack(fill="x", padx=16, pady=12)

            ctk.CTkLabel(row, text=icon, font=ctk.CTkFont(size=36), width=50).pack(side="left")

            info = ctk.CTkFrame(row, fg_color="transparent")
            info.pack(side="left", fill="both", expand=True, padx=12)
            ctk.CTkLabel(info, text=p["name"],
                         font=ctk.CTkFont(size=16, weight="bold"),
                         text_color="white", anchor="w").pack(anchor="w")
            ctk.CTkLabel(info,
                         text=f"{p['stream'].capitalize()}  ·  "
                              f"Level {p['level']}  ·  {p['xp']} XP",
                         font=ctk.CTkFont(size=12), text_color="#94A3B8", anchor="w").pack(anchor="w")

            ctk.CTkButton(row, text="Launch →", width=100, height=36,
                          fg_color=color, hover_color=color,
                          corner_radius=8, font=ctk.CTkFont(size=13, weight="bold"),
                          command=lambda pid=pid: self._app.show_main_app(pid)).pack(side="right")

        ctk.CTkButton(self, text="+ Add New Profile", width=200, height=38,
                      fg_color="transparent", border_width=1,
                      border_color="#60A5FA", text_color="#60A5FA",
                      hover_color="#2D3748", corner_radius=8,
                      command=self._app.show_onboarding).pack(pady=(4, 30))


# ===========================================================================
# Onboarding screen (3 steps, no separate window)
# ===========================================================================

class OnboardingScreen(ctk.CTkFrame):
    STREAMS = {
        "engineering": ("🔧 Engineering", "#1E90FF"),
        "medical":     ("🩺 Medical",     "#00C896"),
        "law":         ("⚖️  Law",         "#C0392B"),
        "competitive": ("📖 Competitive", "#9B59B6"),
    }
    AVATARS = ["🎓", "📚", "🔬", "⚖️", "💻", "🏆", "🎯", "🔭", "🎸", "🌟"]

    def __init__(self, app: App):
        super().__init__(app, fg_color="#1A1A2E", corner_radius=0)
        self._app = app
        self._name = ""
        self._stream = ""
        self._avatar = self.AVATARS[0]
        self._step1()

    def _clear(self):
        for w in self.winfo_children():
            w.destroy()

    # ---- Step 1: name ----
    def _step1(self):
        self._clear()
        ctk.CTkLabel(self, text="🎓 Welcome to StudentTrack Pro",
                     font=ctk.CTkFont(size=24, weight="bold"),
                     text_color="#60A5FA").pack(pady=(60, 8))
        ctk.CTkLabel(self, text="Step 1 of 3 — Let's set up your profile",
                     font=ctk.CTkFont(size=13), text_color="#94A3B8").pack(pady=(0, 40))
        ctk.CTkLabel(self, text="What's your name?",
                     font=ctk.CTkFont(size=16), text_color="white").pack(pady=(0, 8))
        self._name_var = ctk.StringVar()
        entry = ctk.CTkEntry(self, textvariable=self._name_var,
                              width=320, height=44, font=ctk.CTkFont(size=16),
                              fg_color="#2D3748", border_color="#60A5FA",
                              text_color="white", corner_radius=10,
                              placeholder_text="Enter your name…")
        entry.pack()
        entry.focus()
        entry.bind("<Return>", lambda e: self._s1_next())
        ctk.CTkButton(self, text="Continue →", width=200, height=44,
                      fg_color="#60A5FA", hover_color="#3B82F6",
                      corner_radius=10, font=ctk.CTkFont(size=15, weight="bold"),
                      command=self._s1_next).pack(pady=30)

    def _s1_next(self):
        name = self._name_var.get().strip()
        if not name:
            return
        self._name = name
        self._step2()

    # ---- Step 2: stream ----
    def _step2(self):
        self._clear()
        ctk.CTkLabel(self, text=f"Hi {self._name}! 👋",
                     font=ctk.CTkFont(size=24, weight="bold"),
                     text_color="#60A5FA").pack(pady=(50, 4))
        ctk.CTkLabel(self, text="Step 2 of 3 — Choose your stream  (permanent!)",
                     font=ctk.CTkFont(size=13), text_color="#F59E0B").pack(pady=(0, 24))

        grid = ctk.CTkFrame(self, fg_color="transparent")
        grid.pack()
        for i, (key, (label, color)) in enumerate(self.STREAMS.items()):
            ctk.CTkButton(grid, text=label, width=160, height=90,
                          fg_color="#2D3748", hover_color=color,
                          text_color="white", corner_radius=12,
                          font=ctk.CTkFont(size=14, weight="bold"),
                          border_width=2, border_color=color,
                          command=lambda k=key: self._s2_next(k)
                          ).grid(row=i // 2, column=i % 2, padx=12, pady=8)

        ctk.CTkLabel(self, text="🔒 Stream cannot be changed after selection.",
                     font=ctk.CTkFont(size=12), text_color="#94A3B8").pack(pady=(16, 0))

    def _s2_next(self, stream: str):
        self._stream = stream
        self._step3()

    # ---- Step 3: avatar ----
    def _step3(self):
        self._clear()
        _, color = self.STREAMS[self._stream]
        ctk.CTkLabel(self, text="Almost there!  (Step 3 of 3)",
                     font=ctk.CTkFont(size=22, weight="bold"),
                     text_color=color).pack(pady=(40, 4))
        ctk.CTkLabel(self, text="Pick an avatar",
                     font=ctk.CTkFont(size=14), text_color="#94A3B8").pack(pady=(0, 12))

        self._av_lbl = ctk.CTkLabel(self, text=self._avatar,
                                     font=ctk.CTkFont(size=80))
        self._av_lbl.pack(pady=6)

        av_row = ctk.CTkFrame(self, fg_color="transparent")
        av_row.pack()
        for av in self.AVATARS:
            ctk.CTkButton(av_row, text=av, width=44, height=44,
                          fg_color="transparent", hover_color="#2D3748",
                          font=ctk.CTkFont(size=22),
                          command=lambda a=av: self._pick_av(a)).pack(side="left", padx=2)

        stream_label = self.STREAMS[self._stream][0]
        ctk.CTkLabel(self, text=f"Profile: {self._name}  ·  {stream_label}",
                     font=ctk.CTkFont(size=14), text_color="white").pack(pady=16)

        ctk.CTkButton(self, text="Create Profile 🚀", width=220, height=46,
                      fg_color=color, hover_color=color,
                      corner_radius=10, font=ctk.CTkFont(size=16, weight="bold"),
                      command=self._finish).pack(pady=8)

    def _pick_av(self, av: str):
        self._avatar = av
        self._av_lbl.configure(text=av)

    def _finish(self):
        pid = insert("profiles", {
            "name":   self._name,
            "stream": self._stream,
            "theme":  self._stream,
            "avatar": self._avatar,
        })
        check_and_award_badges(pid)
        self._app.show_main_app(pid)


# ===========================================================================
# Main application frame
# ===========================================================================

class MainAppFrame(ctk.CTkFrame):
    NAV_ITEMS = [
        ("home",         "🏠", "Home"),
        ("todo",         "✅", "To-Do"),
        ("goals",        "🎯", "Goals"),
        ("habits",       "🔁", "Habits"),
        ("timetable",    "📅", "Schedule"),
        ("countdown",    "⏳", "Countdown"),
        ("pomodoro",     "🍅", "Pomodoro"),
        ("notes",        "📝", "Notes"),
        ("flashcards",   "🃏", "Flashcards"),
        ("health",       "❤️",  "Health"),
        ("resources",    "📚", "Resources"),
        ("attendance",   "📋", "Attendance"),
        ("stats",        "📊", "Stats"),
        ("gamification", "🏆", "Badges"),
        ("weekly_review","🗓",  "Review"),
        ("buddy",        "🤝", "Buddy"),
        ("settings",     "⚙️",  "Settings"),
    ]

    MODULE_MAP = {
        "home":         ("modules.home",         "HomeModule"),
        "todo":         ("modules.todo",         "TodoModule"),
        "goals":        ("modules.goals",        "GoalsModule"),
        "habits":       ("modules.habits",       "HabitsModule"),
        "timetable":    ("modules.timetable",    "TimetableModule"),
        "countdown":    ("modules.countdown",    "CountdownModule"),
        "pomodoro":     ("modules.pomodoro",     "PomodoroModule"),
        "notes":        ("modules.notes",        "NotesModule"),
        "flashcards":   ("modules.flashcards",   "FlashcardsModule"),
        "health":       ("modules.health",       "HealthModule"),
        "resources":    ("modules.resources",    "ResourcesModule"),
        "attendance":   ("modules.attendance",   "AttendanceModule"),
        "stats":        ("modules.stats",        "StatsModule"),
        "gamification": ("modules.gamification", "GamificationModule"),
        "weekly_review":("modules.weekly_review","WeeklyReviewModule"),
        "buddy":        ("modules.buddy",        "BuddyModule"),
        "settings":     ("modules.settings",     "SettingsModule"),
    }

    def __init__(self, app: App, profile_id: int):
        super().__init__(app, fg_color="#1A1A2E", corner_radius=0)
        self._app = app
        self._pid = profile_id
        self._sidebar_expanded = True
        self._focus_mode = False
        self._current_mod = None

        self._profile = dict(get_profile(profile_id))
        settings = get_settings(profile_id)
        dark = bool(settings.get("dark_mode", 1))
        self._tm = ThemeManager(self._profile["stream"], dark_mode=dark)
        set_active_theme(self._tm)
        self.configure(fg_color=self._tm.background)
        app.title(f"StudentTrack Pro — {self._profile['name']}")

        self._build_ui()
        self._load_module("home")

        app.bind("<F11>", lambda e: self._toggle_focus())
        app.bind("<Escape>", lambda e: self._exit_focus())

    # ---------------------------------------------------------------- UI build

    def _build_ui(self):
        tm = self._tm

        # Top bar
        self._topbar = ctk.CTkFrame(self, fg_color=tm.surface, height=56, corner_radius=0)
        self._topbar.pack(fill="x", side="top")
        self._topbar.pack_propagate(False)

        ctk.CTkLabel(self._topbar, text="🎓 StudentTrack Pro",
                     font=ctk.CTkFont(size=18, weight="bold"),
                     text_color=tm.primary).pack(side="left", padx=16)
        ctk.CTkLabel(self._topbar,
                     text=f"{self._profile['name']}  ·  {self._profile['stream'].capitalize()}",
                     font=ctk.CTkFont(size=13), text_color=tm.text_secondary).pack(side="left", padx=8)

        # XP area (right side)
        xp_frame = ctk.CTkFrame(self._topbar, fg_color="transparent")
        xp_frame.pack(side="right", padx=16)
        xp = self._profile["xp"]
        level = self._profile["level"]
        ctk.CTkLabel(xp_frame, text=f"Lvl {level}",
                     font=ctk.CTkFont(size=12, weight="bold"),
                     text_color=tm.highlight).pack(side="left", padx=(0, 6))
        self._xp_bar = ctk.CTkProgressBar(xp_frame, width=120, height=10,
                                           fg_color=tm.surface2, progress_color=tm.primary)
        self._xp_bar.set((xp % 500) / 500)
        self._xp_bar.pack(side="left")
        ctk.CTkLabel(xp_frame, text=f"  {xp} XP",
                     font=ctk.CTkFont(size=11), text_color=tm.text_secondary).pack(side="left")

        self._mode_btn = ctk.CTkButton(
            self._topbar, text="🌙" if tm.dark_mode else "☀️",
            width=36, height=28, corner_radius=8,
            fg_color=tm.surface2, hover_color=tm.border, text_color=tm.text,
            command=self._toggle_theme)
        self._mode_btn.pack(side="right", padx=4)
        ctk.CTkButton(self._topbar, text="⇄ Switch",
                      width=80, height=28, corner_radius=8,
                      fg_color=tm.surface2, hover_color=tm.border, text_color=tm.text,
                      command=lambda: self._app.show_profile_select()).pack(side="right", padx=4)

        # Body
        self._body = ctk.CTkFrame(self, fg_color=tm.background, corner_radius=0)
        self._body.pack(fill="both", expand=True)

        # Sidebar
        self._sidebar = ctk.CTkFrame(self._body, fg_color=tm.sidebar,
                                      width=224, corner_radius=0)
        self._sidebar.pack(side="left", fill="y")
        self._sidebar.pack_propagate(False)
        self._build_sidebar()

        # Content
        self._content = ctk.CTkFrame(self._body, fg_color=tm.background, corner_radius=0)
        self._content.pack(side="left", fill="both", expand=True)

    def _build_sidebar(self):
        tm = self._tm
        ctk.CTkButton(self._sidebar,
                      text="◀" if self._sidebar_expanded else "▶",
                      width=34, height=28, fg_color="transparent",
                      hover_color=tm.surface, text_color=tm.text_secondary,
                      corner_radius=6, command=self._toggle_sidebar
                      ).pack(anchor="e", padx=6, pady=(8, 2))

        self._nav_btns = {}
        for key, icon, label in self.NAV_ITEMS:
            txt = f"  {icon}  {label}" if self._sidebar_expanded else f" {icon}"
            btn = ctk.CTkButton(
                self._sidebar, text=txt, anchor="w",
                width=216 if self._sidebar_expanded else 52,
                height=36, fg_color="transparent",
                hover_color=tm.surface, text_color=tm.text,
                font=ctk.CTkFont(size=13), corner_radius=8,
                command=lambda k=key: self._load_module(k))
            btn.pack(padx=4, pady=2)
            self._nav_btns[key] = btn

    def _set_active_nav(self, active: str):
        tm = self._tm
        for k, btn in self._nav_btns.items():
            btn.configure(fg_color=tm.primary if k == active else "transparent",
                          text_color="white" if k == active else tm.text)

    # ---------------------------------------------------------------- module loading

    def _load_module(self, key: str):
        self._profile = dict(get_profile(self._pid))
        for w in self._content.winfo_children():
            w.destroy()
        self._set_active_nav(key)

        try:
            mod_path, cls_name = self.MODULE_MAP[key]
            mod = importlib.import_module(mod_path)
            cls = getattr(mod, cls_name)
            frame = cls(self._content, self._pid, self._tm, self._refresh_xp)
            frame.pack(fill="both", expand=True)
            self._current_mod = frame
        except Exception as exc:
            import traceback
            ctk.CTkLabel(
                self._content,
                text=f"⚠ Could not load '{key}':\n{exc}\n\n{traceback.format_exc()}",
                font=ctk.CTkFont(size=12), text_color=self._tm.danger,
                wraplength=700, justify="left"
            ).pack(padx=30, pady=30)

    # ---------------------------------------------------------------- XP / badges

    def _refresh_xp(self):
        self._profile = dict(get_profile(self._pid))
        xp = self._profile["xp"]
        self._xp_bar.set((xp % 500) / 500)
        for badge_key in check_and_award_badges(self._pid):
            self._show_badge_popup(badge_key)

    def _show_badge_popup(self, badge_key: str):
        if badge_key not in BADGE_DEFINITIONS:
            return
        name, icon = BADGE_DEFINITIONS[badge_key]
        tm = self._tm
        overlay = ctk.CTkFrame(self, fg_color="#00000099", corner_radius=0)
        overlay.place(relx=0, rely=0, relwidth=1, relheight=1)
        card = ctk.CTkFrame(overlay, fg_color=tm.card, corner_radius=20,
                             border_width=2, border_color=tm.primary)
        card.place(relx=0.5, rely=0.5, anchor="center")
        ctk.CTkLabel(card, text=icon, font=ctk.CTkFont(size=72)).pack(pady=(30, 8))
        ctk.CTkLabel(card, text="🎉 Achievement Unlocked!",
                     font=ctk.CTkFont(size=20, weight="bold"),
                     text_color=tm.primary).pack()
        ctk.CTkLabel(card, text=name,
                     font=ctk.CTkFont(size=26, weight="bold"),
                     text_color=tm.text).pack(pady=(4, 30))
        self.after(3000, overlay.destroy)

    # ---------------------------------------------------------------- sidebar / focus

    def _toggle_sidebar(self):
        self._sidebar_expanded = not self._sidebar_expanded
        for w in self._sidebar.winfo_children():
            w.destroy()
        self._sidebar.configure(width=224 if self._sidebar_expanded else 56)
        self._build_sidebar()

    def _toggle_focus(self):
        if self._focus_mode:
            self._exit_focus()
        else:
            self._topbar.pack_forget()
            self._sidebar.pack_forget()
            self._focus_mode = True

    def _exit_focus(self):
        if self._focus_mode:
            self._topbar.pack(fill="x", side="top", before=self._body)
            self._sidebar.pack(side="left", fill="y", before=self._content)
            self._focus_mode = False

    # ---------------------------------------------------------------- theme / profile

    def _toggle_theme(self):
        self._tm.toggle_dark_mode()
        update_settings(self._pid, {"dark_mode": 1 if self._tm.dark_mode else 0})
        # Recreate the main frame to apply new theme colours everywhere
        self._app.show_main_app(self._pid)


# ===========================================================================
# Entry point
# ===========================================================================

def _start_sync_server_thread():
    """Start the sync HTTP server in a daemon thread so it dies with the app."""
    import threading
    from sync_server import start_sync_server, get_local_ip, SYNC_PORT
    ip = get_local_ip()
    print(f"🔄 Sync server starting on http://{ip}:{SYNC_PORT}")
    t = threading.Thread(target=start_sync_server, daemon=True)
    t.start()
    return ip


if __name__ == "__main__":
    init_db()
    ensure_icon()
    # Start sync server in background (auto-available for mobile)
    try:
        sync_ip = _start_sync_server_thread()
        print(f"✅ Sync ready — enter {sync_ip} in your mobile app")
    except Exception as e:
        sync_ip = None
        print(f"⚠️ Sync server failed to start: {e}")
    App().mainloop()
