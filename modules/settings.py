"""
StudentTrack Pro — Settings Module
5-tab settings: Profile, Appearance, Notifications, Data, About.
Also contains the ThemeManager (imported separately from theme_manager.py).
"""

import customtkinter as ctk
import json
import os
import csv
from database import db
from modules.theme_manager import ThemeManager


class SettingsModule(ctk.CTkScrollableFrame):
    def __init__(self, parent, profile_id, tm: ThemeManager, refresh_xp_cb):
        super().__init__(parent, fg_color=tm.background, corner_radius=0)
        self._pid = profile_id
        self._tm = tm
        self._refresh_xp = refresh_xp_cb
        self._build()

    def _build(self):
        tm = self._tm
        ctk.CTkLabel(self, text="⚙️ Settings",
                     font=ctk.CTkFont(size=22, weight="bold"),
                     text_color=tm.primary).pack(anchor="w", padx=20, pady=(20, 10))

        self._tabview = ctk.CTkTabview(self, fg_color=tm.background,
                                        segmented_button_fg_color=tm.surface,
                                        segmented_button_selected_color=tm.primary,
                                        text_color=tm.text)
        self._tabview.pack(fill="both", expand=True, padx=16, pady=8)

        for tab in ["👤 Profile", "🎨 Appearance", "🔔 Notifications", "💾 Data", "ℹ️ About"]:
            self._tabview.add(tab)

        self._build_profile(self._tabview.tab("👤 Profile"))
        self._build_appearance(self._tabview.tab("🎨 Appearance"))
        self._build_notifications(self._tabview.tab("🔔 Notifications"))
        self._build_data(self._tabview.tab("💾 Data"))
        self._build_about(self._tabview.tab("ℹ️ About"))

    # ------------------------------------------------------------------
    # Profile Tab
    # ------------------------------------------------------------------
    def _build_profile(self, parent):
        tm = self._tm
        profile = dict(db.get_profile(self._pid))

        info_card = ctk.CTkFrame(parent, fg_color=tm.card, corner_radius=12)
        info_card.pack(fill="x", padx=20, pady=14)

        ctk.CTkLabel(info_card, text=profile["avatar"] or "🎓",
                     font=ctk.CTkFont(size=52)).pack(pady=(16, 4))

        name_var = ctk.StringVar(value=profile["name"])
        ctk.CTkLabel(info_card, text="Name:", font=ctk.CTkFont(size=12),
                     text_color=tm.text_secondary).pack()
        name_entry = ctk.CTkEntry(info_card, textvariable=name_var, width=240, height=34,
                                   fg_color=tm.surface, border_color=tm.border, text_color=tm.text,
                                   corner_radius=8)
        name_entry.pack(pady=4)

        ctk.CTkButton(info_card, text="Save Name", width=140, height=32,
                      fg_color=tm.primary, corner_radius=8,
                      command=lambda: (
                          db.update("profiles", {"name": name_var.get()}, {"id": self._pid}),
                      )).pack(pady=(4, 8))

        # Stream — shown but LOCKED
        stream_frame = ctk.CTkFrame(info_card, fg_color=tm.surface2, corner_radius=8)
        stream_frame.pack(fill="x", padx=20, pady=(0, 8))
        ctk.CTkLabel(stream_frame, text=f"🔒 Stream: {profile['stream'].capitalize()}  (Permanent)",
                     font=ctk.CTkFont(size=13),
                     text_color=tm.text_secondary).pack(side="left", padx=12, pady=10)

        ctk.CTkLabel(info_card, text=f"Joined: {profile['created_at'][:10]}  ·  Level {profile['level']}  ·  {profile['xp']} XP",
                     font=ctk.CTkFont(size=11), text_color=tm.text_secondary).pack(pady=(0, 14))

        # Add new profile
        ctk.CTkButton(parent, text="+ Add New Profile", width=200, height=38,
                      fg_color=tm.surface2, hover_color=tm.primary, text_color=tm.text,
                      corner_radius=8, border_width=1, border_color=tm.primary,
                      command=self._add_profile).pack(pady=10)

        # Delete profile
        ctk.CTkButton(parent, text="🗑 Delete Profile", width=200, height=38,
                      fg_color="transparent", hover_color=tm.danger, text_color=tm.danger,
                      corner_radius=8, border_width=1, border_color=tm.danger,
                      command=self._delete_profile).pack(pady=4)

    def _add_profile(self):
        from modules.onboarding import OnboardingWizard
        # Open onboarding to create a new profile without closing current app
        def on_done(pid):
            pass  # Profile created, will be available on next profile switch
        OnboardingWizard(on_done)

    def _delete_profile(self):
        dialog = ctk.CTkInputDialog(
            text="Type 'DELETE' to confirm profile deletion:",
            title="⚠️ Delete Profile"
        )
        ans = dialog.get_input()
        if ans == "DELETE":
            # Delete all profile data
            for table in ["todos", "goals", "milestones", "habits", "habit_logs", "timetable",
                          "countdowns", "pomodoro_sessions", "notes", "flashcard_decks",
                          "flashcards", "attendance", "attendance_logs", "health_logs",
                          "resources", "xp_logs", "badges", "settings"]:
                try:
                    db.delete(table, {"profile_id": self._pid})
                except Exception:
                    pass
            db.delete("profiles", {"id": self._pid})

    # ------------------------------------------------------------------
    # Appearance Tab
    # ------------------------------------------------------------------
    def _build_appearance(self, parent):
        tm = self._tm
        settings = db.get_settings(self._pid)

        card = ctk.CTkFrame(parent, fg_color=tm.card, corner_radius=12)
        card.pack(fill="x", padx=20, pady=14)

        # Dark mode toggle
        row = ctk.CTkFrame(card, fg_color="transparent")
        row.pack(fill="x", padx=20, pady=14)
        ctk.CTkLabel(row, text="🌙 Dark Mode", font=ctk.CTkFont(size=13), text_color=tm.text).pack(side="left")
        dark_var = ctk.BooleanVar(value=bool(settings.get("dark_mode", 1)))
        ctk.CTkSwitch(row, text="", variable=dark_var,
                      onvalue=True, offvalue=False,
                      fg_color=tm.surface2, progress_color=tm.primary,
                      command=lambda: db.update_settings(self._pid, {"dark_mode": 1 if dark_var.get() else 0})
                      ).pack(side="right")

        # Font size
        row2 = ctk.CTkFrame(card, fg_color="transparent")
        row2.pack(fill="x", padx=20, pady=8)
        ctk.CTkLabel(row2, text="🔤 Font Size", font=ctk.CTkFont(size=13), text_color=tm.text).pack(side="left")
        font_var = ctk.StringVar(value=settings.get("font_size", "medium"))
        ctk.CTkOptionMenu(row2, values=["small", "medium", "large"],
                          variable=font_var, width=110, fg_color=tm.surface2,
                          button_color=tm.primary, text_color=tm.text,
                          command=lambda v: db.update_settings(self._pid, {"font_size": v})
                          ).pack(side="right")

        # Sidebar default
        row3 = ctk.CTkFrame(card, fg_color="transparent")
        row3.pack(fill="x", padx=20, pady=(8, 14))
        ctk.CTkLabel(row3, text="📐 Sidebar", font=ctk.CTkFont(size=13), text_color=tm.text).pack(side="left")
        sb_var = ctk.StringVar(value="expanded" if settings.get("sidebar_expanded", 1) else "collapsed")
        ctk.CTkSegmentedButton(row3, values=["expanded", "collapsed"], variable=sb_var,
                               fg_color=tm.surface2, selected_color=tm.primary, text_color=tm.text,
                               command=lambda v: db.update_settings(self._pid, {"sidebar_expanded": 1 if v == "expanded" else 0})
                               ).pack(side="right")

    # ------------------------------------------------------------------
    # Notifications Tab
    # ------------------------------------------------------------------
    def _build_notifications(self, parent):
        tm = self._tm
        settings = db.get_settings(self._pid)

        card = ctk.CTkFrame(parent, fg_color=tm.card, corner_radius=12)
        card.pack(fill="x", padx=20, pady=14)

        items = [
            ("Enable Notifications", "notifications_enabled", "switch"),
            ("Water Reminder (hours)", "water_reminder_hours", "entry"),
            ("Habit Reminder Time (HH:MM)", "habit_reminder_time", "entry"),
            ("Exam Warning (days before)", "exam_warning_days", "entry"),
            ("Attendance Warning (%)", "attendance_warning_percent", "entry"),
        ]

        for label, key, widget_type in items:
            row = ctk.CTkFrame(card, fg_color="transparent")
            row.pack(fill="x", padx=20, pady=8)
            ctk.CTkLabel(row, text=label, font=ctk.CTkFont(size=13), text_color=tm.text).pack(side="left")

            val = settings.get(key, "")
            if widget_type == "switch":
                var = ctk.BooleanVar(value=bool(val))
                ctk.CTkSwitch(row, text="", variable=var,
                              fg_color=tm.surface2, progress_color=tm.primary,
                              command=lambda v=var, k=key: db.update_settings(self._pid, {k: 1 if v.get() else 0})
                              ).pack(side="right")
            else:
                var = ctk.StringVar(value=str(val))
                entry = ctk.CTkEntry(row, textvariable=var, width=100, height=30,
                                     fg_color=tm.surface2, border_color=tm.border, text_color=tm.text,
                                     corner_radius=6)
                entry.pack(side="right")
                entry.bind("<FocusOut>", lambda e, k=key, v=var: db.update_settings(self._pid, {k: v.get()}))

    # ------------------------------------------------------------------
    # Data Tab
    # ------------------------------------------------------------------
    def _build_data(self, parent):
        tm = self._tm
        from database.db import DB_PATH

        ctk.CTkLabel(parent, text=f"📁 DB: {DB_PATH}",
                     font=ctk.CTkFont(size=11), text_color=tm.text_secondary).pack(anchor="w", padx=20, pady=10)

        for btn_text, fn in [
            ("📤 Export JSON Backup", self._export_json),
            ("📊 Export CSV", self._export_csv),
            ("📥 Import JSON", self._import_json),
        ]:
            ctk.CTkButton(parent, text=btn_text, width=220, height=40,
                          fg_color=tm.surface2, hover_color=tm.primary, text_color=tm.text,
                          corner_radius=10, command=fn).pack(pady=6)

        ctk.CTkButton(parent, text="⚠️ Clear All My Data", width=220, height=40,
                      fg_color="transparent", hover_color=tm.danger, text_color=tm.danger,
                      corner_radius=10, border_width=1, border_color=tm.danger,
                      command=self._clear_data).pack(pady=10)

    def _export_json(self):
        import tkinter.filedialog as fd
        path = fd.asksaveasfilename(defaultextension=".json",
                                    filetypes=[("JSON", "*.json")],
                                    initialfile="studenttrack_backup.json")
        if not path:
            return
        data = {}
        for table in ["todos", "goals", "habits", "notes"]:
            rows = db.fetch_all(f"SELECT * FROM {table} WHERE profile_id=?", [self._pid])
            data[table] = [dict(r) for r in rows]
        with open(path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)

    def _export_csv(self):
        import tkinter.filedialog as fd
        folder = fd.askdirectory(title="Select folder for CSV files")
        if not folder:
            return
        for table in ["todos", "goals", "habits", "notes"]:
            rows = db.fetch_all(f"SELECT * FROM {table} WHERE profile_id=?", [self._pid])
            if rows:
                path = os.path.join(folder, f"{table}.csv")
                with open(path, "w", newline="", encoding="utf-8") as f:
                    writer = csv.DictWriter(f, fieldnames=rows[0].keys())
                    writer.writeheader()
                    writer.writerows([dict(r) for r in rows])

    def _import_json(self):
        import tkinter.filedialog as fd
        path = fd.askopenfilename(filetypes=[("JSON", "*.json")])
        if not path:
            return
        try:
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)
            # Simple import — insert each row
            for table, rows in data.items():
                for row in rows:
                    row["profile_id"] = self._pid
                    row.pop("id", None)
                    try:
                        db.insert(table, row)
                    except Exception:
                        pass
        except Exception as e:
            print(f"[Settings] Import error: {e}")

    def _clear_data(self):
        dialog = ctk.CTkInputDialog(text="Type 'CLEAR' to delete all your data:",
                                     title="⚠️ Clear Data")
        ans = dialog.get_input()
        if ans == "CLEAR":
            for table in ["todos", "goals", "habits", "notes", "habit_logs",
                          "timetable", "countdowns", "pomodoro_sessions",
                          "flashcard_decks", "flashcards", "attendance",
                          "attendance_logs", "health_logs", "resources",
                          "xp_logs", "badges"]:
                try:
                    db.delete(table, {"profile_id": self._pid})
                except Exception:
                    pass

    # ------------------------------------------------------------------
    # About Tab
    # ------------------------------------------------------------------
    def _build_about(self, parent):
        tm = self._tm
        ctk.CTkLabel(parent, text="🎓 StudentTrack Pro",
                     font=ctk.CTkFont(size=24, weight="bold"),
                     text_color=tm.primary).pack(pady=(30, 4))
        ctk.CTkLabel(parent, text="Version 1.0.0",
                     font=ctk.CTkFont(size=14), text_color=tm.text_secondary).pack()
        ctk.CTkLabel(parent, text="Built with Python + CustomTkinter ❤️",
                     font=ctk.CTkFont(size=13), text_color=tm.text).pack(pady=16)

        libs = [
            "customtkinter — Modern GUI framework",
            "matplotlib — Charts & analytics",
            "Pillow (PIL) — Image processing & icon",
            "plyer — Desktop notifications",
            "schedule — Background scheduling",
            "python-dateutil — Date utilities",
        ]
        for lib in libs:
            ctk.CTkLabel(parent, text=f"• {lib}",
                         font=ctk.CTkFont(size=12), text_color=tm.text_secondary).pack(anchor="w", padx=60)
