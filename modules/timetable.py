"""
StudentTrack Pro — Timetable Module (Weekly Schedule)
Visual weekly grid showing study sessions Mon–Sun.
"""

import customtkinter as ctk
from datetime import date
from database import db
from modules.theme_manager import ThemeManager

DAYS = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
HOURS = [f"{h:02d}:00" for h in range(6, 23)]


class TimetableModule(ctk.CTkFrame):
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
        ctk.CTkLabel(header, text="📅 Weekly Schedule",
                     font=ctk.CTkFont(size=20, weight="bold"),
                     text_color=tm.primary).pack(side="left", padx=20)
        ctk.CTkButton(header, text="+ Add Slot", width=110, height=34,
                      fg_color=tm.primary, hover_color=tm.secondary, corner_radius=8,
                      command=self._open_add_slot).pack(side="right", padx=20)

        # Grid area
        grid_scroll = ctk.CTkScrollableFrame(self, fg_color=tm.background, corner_radius=0)
        grid_scroll.pack(fill="both", expand=True)

        today_dow = date.today().weekday()

        # Day headers
        header_row = ctk.CTkFrame(grid_scroll, fg_color="transparent")
        header_row.pack(fill="x", pady=(10, 0))

        ctk.CTkLabel(header_row, text="     ", width=54, fg_color="transparent",
                     font=ctk.CTkFont(size=11)).pack(side="left")

        for di, day in enumerate(DAYS):
            is_today = di == today_dow
            ctk.CTkLabel(
                header_row, text=day[:3],
                width=92, height=32,
                fg_color=tm.primary if is_today else tm.surface,
                corner_radius=6,
                font=ctk.CTkFont(size=12, weight="bold"),
                text_color="white" if is_today else tm.text
            ).pack(side="left", padx=2)

        # Slots data
        all_slots = db.fetch_all(
            "SELECT * FROM timetable WHERE profile_id=?", [self._pid]
        )

        # Build hour rows
        for hour_str in HOURS:
            row = ctk.CTkFrame(grid_scroll, fg_color="transparent", height=46)
            row.pack(fill="x", pady=1)
            row.pack_propagate(False)

            ctk.CTkLabel(row, text=hour_str, width=54,
                         font=ctk.CTkFont(size=10), text_color=tm.text_secondary).pack(side="left")

            for di in range(7):
                slot = next((s for s in all_slots
                             if s["day_of_week"] == di and s["start_time"] == hour_str), None)
                is_today = di == today_dow
                cell_bg = tm.surface2 if is_today else tm.surface

                cell = ctk.CTkFrame(row, fg_color=cell_bg, corner_radius=4, width=92)
                cell.pack(side="left", padx=2, fill="y")
                cell.pack_propagate(False)

                if slot:
                    subj_color = slot["color"] or tm.primary
                    lbl = ctk.CTkLabel(cell, text=slot["subject"][:10],
                                       font=ctk.CTkFont(size=10),
                                       text_color="white", fg_color=subj_color,
                                       corner_radius=3)
                    lbl.place(relx=0, rely=0, relwidth=1, relheight=1)
                    slot_id = slot["id"]
                    lbl.bind("<Button-3>", lambda e, sid=slot_id: self._delete_slot(sid))

    def _delete_slot(self, slot_id: int):
        db.delete("timetable", {"id": slot_id})
        for w in self.winfo_children():
            w.destroy()
        self._build()

    def _open_add_slot(self):
        AddSlotDialog(self, self._pid, self._tm, lambda: (
            [w.destroy() for w in self.winfo_children()], self._build()
        ))


class AddSlotDialog(ctk.CTkToplevel):
    def __init__(self, parent, profile_id, tm, on_save_cb):
        super().__init__(parent)
        self._pid = profile_id
        self._tm = tm
        self._on_save = on_save_cb
        self.title("Add Schedule Slot")
        self.geometry("420x420")
        self.resizable(False, False)
        self.grab_set()
        self.configure(fg_color=tm.background)
        self._day_var = ctk.IntVar(value=0)
        self._build()

    def _build(self):
        tm = self._tm
        ctk.CTkLabel(self, text="Add Schedule Slot", font=ctk.CTkFont(size=18, weight="bold"),
                     text_color=tm.text).pack(pady=(16, 10))

        form = ctk.CTkFrame(self, fg_color=tm.surface, corner_radius=12)
        form.pack(fill="both", expand=True, padx=20, pady=10)

        self._vars = {}
        for label, key in [("Subject *", "subject"), ("Start Time (HH:MM)", "start"),
                            ("End Time (HH:MM)", "end"), ("Location", "location"),
                            ("Color (hex)", "color")]:
            ctk.CTkLabel(form, text=label, font=ctk.CTkFont(size=12),
                         text_color=tm.text_secondary, anchor="w").pack(anchor="w", padx=16, pady=(8, 2))
            var = ctk.StringVar()
            ctk.CTkEntry(form, textvariable=var, height=34,
                         fg_color=tm.surface2, border_color=tm.border, text_color=tm.text,
                         corner_radius=8).pack(fill="x", padx=16)
            self._vars[key] = var

        ctk.CTkLabel(form, text="Day", font=ctk.CTkFont(size=12),
                     text_color=tm.text_secondary, anchor="w").pack(anchor="w", padx=16, pady=(8, 2))
        day_menu = ctk.CTkOptionMenu(form, values=DAYS, fg_color=tm.surface2,
                                     text_color=tm.text, button_color=tm.primary,
                                     command=lambda v: self._day_var.set(DAYS.index(v)))
        day_menu.pack(fill="x", padx=16)

        ctk.CTkButton(self, text="Save Slot", width=180, height=40,
                      fg_color=tm.primary, hover_color=tm.secondary, corner_radius=10,
                      font=ctk.CTkFont(size=14, weight="bold"),
                      command=self._save).pack(pady=14)

    def _save(self):
        subject = self._vars["subject"].get().strip()
        start = self._vars["start"].get().strip()
        end = self._vars["end"].get().strip()
        if not all([subject, start, end]):
            return
        db.insert("timetable", {
            "profile_id":  self._pid,
            "day_of_week": self._day_var.get(),
            "start_time":  start,
            "end_time":    end,
            "subject":     subject,
            "location":    self._vars["location"].get().strip(),
            "color":       self._vars["color"].get().strip() or None,
        })
        self.destroy()
        self._on_save()
