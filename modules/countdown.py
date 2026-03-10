"""
StudentTrack Pro — Exam Countdown Module
Countdown timers for exams and deadlines with color-coded urgency.
"""

import customtkinter as ctk
from datetime import date
from database import db
from modules.theme_manager import ThemeManager


class CountdownModule(ctk.CTkFrame):
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
        ctk.CTkLabel(header, text="⏳ Exam Countdown",
                     font=ctk.CTkFont(size=20, weight="bold"),
                     text_color=tm.primary).pack(side="left", padx=20)
        ctk.CTkButton(header, text="+ Add Exam", width=110, height=34,
                      fg_color=tm.primary, hover_color=tm.secondary, corner_radius=8,
                      command=self._open_add).pack(side="right", padx=20)

        self._list = ctk.CTkScrollableFrame(self, fg_color=tm.background, corner_radius=0)
        self._list.pack(fill="both", expand=True)
        self._render()

    def _render(self):
        for w in self._list.winfo_children():
            w.destroy()
        tm = self._tm
        today = date.today()

        countdowns = db.fetch_all(
            "SELECT * FROM countdowns WHERE profile_id=? AND is_archived=0 ORDER BY exam_date",
            [self._pid]
        )

        # Auto-archive past exams
        for c in countdowns:
            try:
                if date.fromisoformat(c["exam_date"]) < today:
                    db.update("countdowns", {"is_archived": 1}, {"id": c["id"]})
            except Exception:
                pass

        # Re-fetch after archive
        countdowns = db.fetch_all(
            "SELECT * FROM countdowns WHERE profile_id=? AND is_archived=0 ORDER BY exam_date",
            [self._pid]
        )

        if not countdowns:
            ctk.CTkLabel(self._list, text="No upcoming exams! You're free 🎉",
                         font=ctk.CTkFont(size=15), text_color=tm.text_secondary).pack(pady=60)
            return

        for c in countdowns:
            try:
                exam_day = date.fromisoformat(c["exam_date"])
                days_left = (exam_day - today).days
            except Exception:
                days_left = 999

            if days_left > 30:
                color = tm.success
                urgency = "Plenty of time! Keep grinding 💪"
            elif days_left > 7:
                color = tm.warning
                urgency = "Getting closer! Build momentum 🔥"
            else:
                color = tm.danger
                urgency = "Almost here! Final push! 🚀"

            card = ctk.CTkFrame(self._list, fg_color=tm.card, corner_radius=14,
                                border_width=2, border_color=color)
            card.pack(fill="x", padx=20, pady=8)

            row = ctk.CTkFrame(card, fg_color="transparent")
            row.pack(fill="x", padx=20, pady=16)

            left = ctk.CTkFrame(row, fg_color="transparent")
            left.pack(side="left", fill="both", expand=True)

            ctk.CTkLabel(left, text=c["title"],
                         font=ctk.CTkFont(size=17, weight="bold"),
                         text_color=tm.text, anchor="w").pack(anchor="w")
            if c["subject"]:
                ctk.CTkLabel(left, text=f"📚 {c['subject']}  ·  📅 {c['exam_date']}",
                             font=ctk.CTkFont(size=12), text_color=tm.text_secondary).pack(anchor="w")
            ctk.CTkLabel(left, text=urgency, font=ctk.CTkFont(size=12, slant="italic"),
                         text_color=color).pack(anchor="w", pady=(4, 0))

            # Days counter (large)
            right = ctk.CTkFrame(row, fg_color=tm.surface, corner_radius=10)
            right.pack(side="right", padx=(20, 0))
            ctk.CTkLabel(right, text=str(days_left),
                         font=ctk.CTkFont(size=40, weight="bold"),
                         text_color=color).pack(padx=20, pady=(12, 0))
            ctk.CTkLabel(right, text="days left",
                         font=ctk.CTkFont(size=11), text_color=tm.text_secondary).pack(padx=20, pady=(0, 12))

            countdown_id = c["id"]
            ctk.CTkButton(card, text="🗑 Archive", width=90, height=26,
                          fg_color=tm.surface2, hover_color=tm.danger,
                          text_color=tm.text_secondary, corner_radius=6,
                          command=lambda cid=countdown_id: self._archive(cid)).pack(anchor="e", padx=16, pady=(0, 10))

    def _archive(self, c_id: int):
        db.update("countdowns", {"is_archived": 1}, {"id": c_id})
        self._render()

    def _open_add(self):
        AddCountdownDialog(self, self._pid, self._tm, self._render)


class AddCountdownDialog(ctk.CTkToplevel):
    def __init__(self, parent, profile_id, tm, on_save_cb):
        super().__init__(parent)
        self._pid = profile_id
        self._tm = tm
        self._on_save = on_save_cb
        self.title("Add Exam Countdown")
        self.geometry("400x380")
        self.resizable(False, False)
        self.grab_set()
        self.configure(fg_color=tm.background)
        self._build()

    def _build(self):
        tm = self._tm
        ctk.CTkLabel(self, text="Add Exam Countdown",
                     font=ctk.CTkFont(size=18, weight="bold"),
                     text_color=tm.text).pack(pady=(16, 10))

        form = ctk.CTkFrame(self, fg_color=tm.surface, corner_radius=12)
        form.pack(fill="both", expand=True, padx=20, pady=10)

        self._vars = {}
        for label, key in [("Exam Title *", "title"), ("Subject", "subject"),
                            ("Exam Date * (YYYY-MM-DD)", "date"), ("Notes", "notes")]:
            ctk.CTkLabel(form, text=label, font=ctk.CTkFont(size=12),
                         text_color=tm.text_secondary, anchor="w").pack(anchor="w", padx=16, pady=(8, 2))
            var = ctk.StringVar()
            ctk.CTkEntry(form, textvariable=var, height=34,
                         fg_color=tm.surface2, border_color=tm.border, text_color=tm.text,
                         corner_radius=8).pack(fill="x", padx=16)
            self._vars[key] = var

        ctk.CTkButton(self, text="Add Countdown", width=200, height=42,
                      fg_color=tm.primary, hover_color=tm.secondary, corner_radius=10,
                      font=ctk.CTkFont(size=14, weight="bold"),
                      command=self._save).pack(pady=14)

    def _save(self):
        title = self._vars["title"].get().strip()
        exam_date = self._vars["date"].get().strip()
        if not title or not exam_date:
            return
        db.insert("countdowns", {
            "profile_id": self._pid,
            "title":      title,
            "subject":    self._vars["subject"].get().strip(),
            "exam_date":  exam_date,
            "notes":      self._vars["notes"].get().strip(),
        })
        self.destroy()
        self._on_save()
