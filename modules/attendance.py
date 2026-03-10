"""
StudentTrack Pro — Attendance Tracker Module
Track attendance per subject with percentage calculator, color coding, and log.
"""

import customtkinter as ctk
from datetime import date
from database import db
from modules.theme_manager import ThemeManager

STATUS_OPTIONS = ["present", "absent", "late", "cancelled"]
STATUS_COLORS = {
    "present":   "#3FB950",
    "absent":    "#F85149",
    "late":      "#D29922",
    "cancelled": "#8B949E",
}

STREAM_SUBJECTS = {
    "engineering":  ["Mathematics", "Physics", "Chemistry", "Programming", "Electronics", "Mechanics", "DSA", "DBMS"],
    "medical":      ["Anatomy", "Physiology", "Biochemistry", "Pathology", "Pharmacology", "Microbiology", "Medicine"],
    "law":          ["Constitutional Law", "Criminal Law", "Civil Procedure", "Contract Law", "Evidence", "Torts"],
    "competitive":  ["GS Paper 1", "GS Paper 2", "Mathematics", "Reasoning", "English", "Current Affairs"],
}


class AttendanceModule(ctk.CTkFrame):
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
        ctk.CTkLabel(header, text="📋 Attendance Tracker",
                     font=ctk.CTkFont(size=20, weight="bold"),
                     text_color=tm.primary).pack(side="left", padx=20)
        ctk.CTkButton(header, text="+ Add Subject", width=120, height=34,
                      fg_color=tm.primary, hover_color=tm.secondary, corner_radius=8,
                      command=self._add_subject).pack(side="right", padx=20)

        self._list = ctk.CTkScrollableFrame(self, fg_color=tm.background, corner_radius=0)
        self._list.pack(fill="both", expand=True)
        self._render()

    def _render(self):
        for w in self._list.winfo_children():
            w.destroy()
        tm = self._tm
        subjects = db.fetch_all(
            "SELECT * FROM attendance WHERE profile_id=? ORDER BY subject", [self._pid]
        )
        if not subjects:
            ctk.CTkLabel(self._list, text="No subjects added. Add one above! 📚",
                         font=ctk.CTkFont(size=15), text_color=tm.text_secondary).pack(pady=60)
            return

        for s in subjects:
            self._render_subject_card(s)

    def _render_subject_card(self, subj):
        tm = self._tm
        total = subj["total_classes"]
        attended = subj["attended"]
        required = subj["required_percent"]

        pct = round((attended / total * 100), 1) if total > 0 else 0
        pct_color = tm.success if pct >= required else (
            tm.warning if pct >= required - 5 else tm.danger
        )

        card = ctk.CTkFrame(self._list, fg_color=tm.card, corner_radius=12,
                            border_width=1, border_color=pct_color)
        card.pack(fill="x", padx=16, pady=6)

        top_row = ctk.CTkFrame(card, fg_color="transparent")
        top_row.pack(fill="x", padx=16, pady=(12, 4))

        ctk.CTkLabel(top_row, text=subj["subject"],
                     font=ctk.CTkFont(size=15, weight="bold"),
                     text_color=tm.text, anchor="w").pack(side="left")

        ctk.CTkLabel(top_row, text=f"{pct}%",
                     font=ctk.CTkFont(size=18, weight="bold"),
                     text_color=pct_color).pack(side="right")

        # Progress bar
        prog = ctk.CTkProgressBar(card, height=8, fg_color=tm.surface2, progress_color=pct_color)
        prog.set(pct / 100)
        prog.pack(fill="x", padx=16, pady=4)

        # Stats row
        stats = ctk.CTkFrame(card, fg_color="transparent")
        stats.pack(fill="x", padx=16)
        ctk.CTkLabel(stats, text=f"Attended: {attended}/{total}  ·  Required: {required}%",
                     font=ctk.CTkFont(size=11), text_color=tm.text_secondary).pack(side="left")

        # Calculator hints
        if total > 0:
            if pct >= required:
                can_miss = int((attended - required / 100 * total) / (1 - required / 100)) if required < 100 else 0
                ctk.CTkLabel(stats, text=f"Can miss: {can_miss} classes",
                             font=ctk.CTkFont(size=11), text_color=tm.success).pack(side="right")
            else:
                target = required / 100
                needed = (target * total - attended) / (1 - target)
                ctk.CTkLabel(stats, text=f"Need: {max(0, int(needed)) + 1} more present",
                             font=ctk.CTkFont(size=11), text_color=tm.danger).pack(side="right")

        # Mark attendance for today
        mark_row = ctk.CTkFrame(card, fg_color="transparent")
        mark_row.pack(fill="x", padx=16, pady=(6, 12))
        ctk.CTkLabel(mark_row, text="Today:", font=ctk.CTkFont(size=11),
                     text_color=tm.text_secondary).pack(side="left", padx=(0, 6))

        subj_id = subj["id"]
        for status in STATUS_OPTIONS:
            sc = STATUS_COLORS[status]
            ctk.CTkButton(mark_row, text=status.capitalize(),
                          width=80, height=26, corner_radius=6,
                          fg_color=sc, hover_color=sc,
                          font=ctk.CTkFont(size=11),
                          command=lambda sid=subj_id, st=status: self._mark(sid, st)
                          ).pack(side="left", padx=3)

    def _mark(self, attendance_id: int, status: str):
        today = date.today().isoformat()
        db.insert("attendance_logs", {"attendance_id": attendance_id, "date": today, "status": status})
        s = db.fetch_one("SELECT * FROM attendance WHERE id=?", [attendance_id])
        if status in ("present", "late"):
            db.update("attendance", {
                "total_classes": (s["total_classes"] or 0) + 1,
                "attended": (s["attended"] or 0) + 1
            }, {"id": attendance_id})
        elif status == "absent":
            db.update("attendance", {"total_classes": (s["total_classes"] or 0) + 1}, {"id": attendance_id})
        db.award_xp(self._pid, 2, "Logged attendance")
        self._refresh_xp()
        self._render()

    def _add_subject(self):
        AddSubjectDialog(self, self._pid, self._tm, self._render)


class AddSubjectDialog(ctk.CTkToplevel):
    def __init__(self, parent, profile_id, tm, on_save_cb):
        super().__init__(parent)
        self._pid = profile_id
        self._tm = tm
        self._on_save = on_save_cb
        self.title("Add Subject")
        self.geometry("400x340")
        self.resizable(False, False)
        self.grab_set()
        self.configure(fg_color=tm.background)
        self._build()

    def _build(self):
        tm = self._tm
        ctk.CTkLabel(self, text="Add Subject", font=ctk.CTkFont(size=18, weight="bold"),
                     text_color=tm.text).pack(pady=16)
        self._subj_var = ctk.StringVar()
        self._req_var = ctk.StringVar(value="75")

        ctk.CTkLabel(self, text="Subject Name *", font=ctk.CTkFont(size=12),
                     text_color=tm.text_secondary, anchor="w").pack(anchor="w", padx=20, pady=(6, 2))
        ctk.CTkEntry(self, textvariable=self._subj_var, height=36,
                     fg_color=tm.surface, border_color=tm.border, text_color=tm.text,
                     corner_radius=8).pack(fill="x", padx=20)

        ctk.CTkLabel(self, text="Required Attendance %", font=ctk.CTkFont(size=12),
                     text_color=tm.text_secondary, anchor="w").pack(anchor="w", padx=20, pady=(10, 2))
        ctk.CTkEntry(self, textvariable=self._req_var, height=36,
                     fg_color=tm.surface, border_color=tm.border, text_color=tm.text,
                     corner_radius=8).pack(fill="x", padx=20)

        ctk.CTkButton(self, text="Add Subject", width=180, height=40,
                      fg_color=tm.primary, corner_radius=10,
                      font=ctk.CTkFont(size=14, weight="bold"),
                      command=self._save).pack(pady=20)

    def _save(self):
        name = self._subj_var.get().strip()
        if not name:
            return
        try:
            req = int(self._req_var.get())
        except ValueError:
            req = 75
        db.insert("attendance", {"profile_id": self._pid, "subject": name, "required_percent": req})
        self.destroy()
        self._on_save()
