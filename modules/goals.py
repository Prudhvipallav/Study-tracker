"""
StudentTrack Pro — Goals Module
Full goals system with milestones, subtasks, progress tracking, XP, and badges.
"""

import customtkinter as ctk
from datetime import date, datetime
from database import db
from modules.theme_manager import ThemeManager


GOAL_TYPES = ["short_term", "long_term"]
GOAL_CATEGORIES = ["academic", "health", "personal", "career"]
CATEGORY_ICONS = {"academic": "📚", "health": "❤️", "personal": "🌱", "career": "💼"}


class GoalsModule(ctk.CTkFrame):
    def __init__(self, parent, profile_id: int, tm: ThemeManager, refresh_xp_cb):
        super().__init__(parent, fg_color=tm.background, corner_radius=0)
        self._pid = profile_id
        self._tm = tm
        self._refresh_xp = refresh_xp_cb
        self._tab = "All"
        self._build()

    def _build(self):
        tm = self._tm
        header = ctk.CTkFrame(self, fg_color=tm.surface, corner_radius=0, height=60)
        header.pack(fill="x")
        header.pack_propagate(False)
        ctk.CTkLabel(header, text="🎯 Goals", font=ctk.CTkFont(size=20, weight="bold"),
                     text_color=tm.primary).pack(side="left", padx=20)
        ctk.CTkButton(header, text="+ New Goal", width=120, height=34,
                      fg_color=tm.primary, hover_color=tm.secondary, corner_radius=8,
                      font=ctk.CTkFont(size=13, weight="bold"),
                      command=self._open_add_dialog).pack(side="right", padx=20)

        # Summary row
        summary_row = ctk.CTkFrame(self, fg_color=tm.surface2, corner_radius=0, height=60)
        summary_row.pack(fill="x")
        summary_row.pack_propagate(False)
        summary_row.columnconfigure((0,1,2), weight=1)

        active = db.fetch_one("SELECT COUNT(*) as c FROM goals WHERE profile_id=? AND is_completed=0", [self._pid])
        completed = db.fetch_one("SELECT COUNT(*) as c FROM goals WHERE profile_id=? AND is_completed=1", [self._pid])

        for col, (label, val, color) in enumerate([
            ("Active Goals", str(active["c"] if active else 0), tm.primary),
            ("Completed", str(completed["c"] if completed else 0), tm.success),
            ("Categories", "4 Types", tm.accent),
        ]):
            f = ctk.CTkFrame(summary_row, fg_color="transparent")
            f.grid(row=0, column=col, pady=8, sticky="nsew")
            ctk.CTkLabel(f, text=val, font=ctk.CTkFont(size=22, weight="bold"),
                         text_color=color).pack()
            ctk.CTkLabel(f, text=label, font=ctk.CTkFont(size=11),
                         text_color=tm.text_secondary).pack()

        # Tabs
        tab_row = ctk.CTkFrame(self, fg_color=tm.background, corner_radius=0, height=44)
        tab_row.pack(fill="x")
        self._tab_btns = {}
        for t in ["All", "Short Term", "Long Term", "Completed"]:
            btn = ctk.CTkButton(tab_row, text=t, width=110, height=32,
                                fg_color=tm.primary if t == self._tab else "transparent",
                                hover_color=tm.surface, text_color=tm.text, corner_radius=6,
                                command=lambda x=t: self._set_tab(x))
            btn.pack(side="left", padx=4, pady=6)
            self._tab_btns[t] = btn

        self._list = ctk.CTkScrollableFrame(self, fg_color=tm.background, corner_radius=0)
        self._list.pack(fill="both", expand=True)
        self._render_goals()

    def _render_goals(self):
        for w in self._list.winfo_children():
            w.destroy()
        tm = self._tm
        if self._tab == "All":
            goals = db.fetch_all("SELECT * FROM goals WHERE profile_id=? ORDER BY deadline, created_at", [self._pid])
        elif self._tab == "Short Term":
            goals = db.fetch_all("SELECT * FROM goals WHERE profile_id=? AND type='short_term' AND is_completed=0", [self._pid])
        elif self._tab == "Long Term":
            goals = db.fetch_all("SELECT * FROM goals WHERE profile_id=? AND type='long_term' AND is_completed=0", [self._pid])
        elif self._tab == "Completed":
            goals = db.fetch_all("SELECT * FROM goals WHERE profile_id=? AND is_completed=1", [self._pid])
        else:
            goals = []

        if not goals:
            ctk.CTkLabel(self._list, text="No goals yet. Add one to get started! 🎯",
                         font=ctk.CTkFont(size=15), text_color=tm.text_secondary).pack(pady=60)
            return

        for g in goals:
            self._render_goal_card(g)

    def _render_goal_card(self, goal):
        tm = self._tm
        today = date.today()
        cat_icon = CATEGORY_ICONS.get(goal["category"], "🎯")
        try:
            days_left = (date.fromisoformat(goal["deadline"]) - today).days if goal["deadline"] else None
        except Exception:
            days_left = None

        dl_color = tm.success
        if days_left is not None:
            dl_color = tm.success if days_left > 14 else (tm.warning if days_left > 3 else tm.danger)

        card = ctk.CTkFrame(self._list, fg_color=tm.card, corner_radius=12,
                            border_width=1, border_color=tm.primary if not goal["is_completed"] else tm.success)
        card.pack(fill="x", padx=16, pady=6)

        top = ctk.CTkFrame(card, fg_color="transparent")
        top.pack(fill="x", padx=16, pady=(12, 4))

        ctk.CTkLabel(top, text=f"{cat_icon} {goal['title']}",
                     font=ctk.CTkFont(size=15, weight="bold"),
                     text_color=tm.text, anchor="w").pack(side="left")

        if days_left is not None:
            ctk.CTkLabel(top, text=f"{days_left}d left",
                         font=ctk.CTkFont(size=12, weight="bold"),
                         text_color=dl_color).pack(side="right")

        pct = goal["progress_percent"] or 0
        prog_bar = ctk.CTkProgressBar(card, height=8, fg_color=tm.surface2, progress_color=tm.primary)
        prog_bar.set(pct / 100)
        prog_bar.pack(fill="x", padx=16, pady=4)

        meta = ctk.CTkFrame(card, fg_color="transparent")
        meta.pack(fill="x", padx=16, pady=(0, 10))
        ctk.CTkLabel(meta, text=f"{pct}% complete  ·  {goal['type'].replace('_',' ').title()}  ·  {goal['category'].title()}",
                     font=ctk.CTkFont(size=11), text_color=tm.text_secondary).pack(side="left")

        goal_id = goal["id"]
        btn_row = ctk.CTkFrame(meta, fg_color="transparent")
        btn_row.pack(side="right")

        ctk.CTkButton(btn_row, text="View", width=60, height=26,
                      fg_color=tm.surface2, hover_color=tm.primary, text_color=tm.text,
                      corner_radius=6, font=ctk.CTkFont(size=11),
                      command=lambda gid=goal_id: self._view_goal(gid)).pack(side="left", padx=2)

        if not goal["is_completed"]:
            ctk.CTkButton(btn_row, text="✓ Complete", width=80, height=26,
                          fg_color=tm.success, hover_color="#2EA043", text_color="white",
                          corner_radius=6, font=ctk.CTkFont(size=11),
                          command=lambda gid=goal_id: self._complete_goal(gid)).pack(side="left", padx=2)

    def _complete_goal(self, goal_id: int):
        db.update("goals", {"is_completed": 1, "progress_percent": 100}, {"id": goal_id})
        db.award_xp(self._pid, 100, "Completed a goal")
        db.check_and_award_badges(self._pid)
        self._refresh_xp()
        self._render_goals()

    def _view_goal(self, goal_id: int):
        GoalDetailView(self, goal_id, self._pid, self._tm, self._refresh_xp, self._render_goals)

    def _set_tab(self, t: str):
        self._tab = t
        for k, btn in self._tab_btns.items():
            btn.configure(fg_color=self._tm.primary if k == t else "transparent")
        self._render_goals()

    def _open_add_dialog(self):
        AddGoalDialog(self, self._pid, self._tm, self._render_goals)


class GoalDetailView(ctk.CTkToplevel):
    def __init__(self, parent, goal_id, profile_id, tm, refresh_xp_cb, reload_cb):
        super().__init__(parent)
        self._gid = goal_id
        self._pid = profile_id
        self._tm = tm
        self._refresh_xp = refresh_xp_cb
        self._reload = reload_cb
        self.title("Goal Details")
        self.geometry("700x600")
        self.grab_set()
        self.configure(fg_color=tm.background)
        self._build()

    def _build(self):
        tm = self._tm
        goal = db.fetch_one("SELECT * FROM goals WHERE id=?", [self._gid])
        if not goal:
            self.destroy()
            return

        scroll = ctk.CTkScrollableFrame(self, fg_color=tm.background)
        scroll.pack(fill="both", expand=True)

        ctk.CTkLabel(scroll, text=goal["title"],
                     font=ctk.CTkFont(size=22, weight="bold"),
                     text_color=tm.primary).pack(anchor="w", padx=20, pady=(20, 4))

        if goal["description"]:
            ctk.CTkLabel(scroll, text=goal["description"],
                         font=ctk.CTkFont(size=13), text_color=tm.text_secondary,
                         anchor="w", wraplength=640, justify="left").pack(anchor="w", padx=20)

        pct = goal["progress_percent"] or 0
        ctk.CTkLabel(scroll, text=f"Progress: {pct}%",
                     font=ctk.CTkFont(size=14), text_color=tm.text).pack(anchor="w", padx=20, pady=(10, 4))
        pb = ctk.CTkProgressBar(scroll, height=12, fg_color=tm.surface2, progress_color=tm.primary)
        pb.set(pct / 100)
        pb.pack(fill="x", padx=20, pady=(0, 10))

        ctk.CTkLabel(scroll, text="Milestones",
                     font=ctk.CTkFont(size=16, weight="bold"),
                     text_color=tm.text).pack(anchor="w", padx=20, pady=(10, 4))

        milestones = db.fetch_all(
            "SELECT * FROM milestones WHERE goal_id=? ORDER BY order_index", [self._gid]
        )
        for ms in milestones:
            self._render_milestone(scroll, ms)

        ctk.CTkButton(scroll, text="+ Add Milestone",
                      fg_color=tm.surface2, hover_color=tm.primary,
                      text_color=tm.text, corner_radius=8,
                      command=lambda: self._add_milestone(scroll)).pack(anchor="w", padx=20, pady=8)

    def _render_milestone(self, parent, ms):
        tm = self._tm
        mf = ctk.CTkFrame(parent, fg_color=tm.surface, corner_radius=10)
        mf.pack(fill="x", padx=20, pady=5)

        ms_top = ctk.CTkFrame(mf, fg_color="transparent")
        ms_top.pack(fill="x", padx=12, pady=8)

        done_icon = "✅" if ms["is_completed"] else "○"
        ctk.CTkLabel(ms_top, text=f"{done_icon}  {ms['title']}",
                     font=ctk.CTkFont(size=13, weight="bold"),
                     text_color=tm.success if ms["is_completed"] else tm.text,
                     anchor="w").pack(side="left")

        ms_id = ms["id"]
        if not ms["is_completed"]:
            ctk.CTkButton(ms_top, text="Complete", width=80, height=26,
                          fg_color=tm.success, corner_radius=6, text_color="white",
                          font=ctk.CTkFont(size=11),
                          command=lambda mid=ms_id: self._complete_milestone(mid)).pack(side="right")

        subtasks = db.fetch_all("SELECT * FROM subtasks WHERE milestone_id=?", [ms["id"]])
        for st in subtasks:
            self._render_subtask(mf, st)

        ctk.CTkButton(mf, text="+ Subtask", width=80, height=22,
                      fg_color="transparent", hover_color=tm.surface2, text_color=tm.text_secondary,
                      corner_radius=6, font=ctk.CTkFont(size=11),
                      command=lambda mid=ms_id: self._add_subtask(mid, parent)).pack(anchor="w", padx=12, pady=(0, 8))

    def _render_subtask(self, parent, st):
        tm = self._tm
        sf = ctk.CTkFrame(parent, fg_color="transparent")
        sf.pack(fill="x", padx=24)
        icon = "☑" if st["is_completed"] else "□"
        st_id = st["id"]
        ctk.CTkButton(sf, text=f"{icon}  {st['title']}",
                      anchor="w", fg_color="transparent", hover_color=tm.surface2,
                      text_color=tm.text_secondary if st["is_completed"] else tm.text,
                      font=ctk.CTkFont(size=12),
                      command=lambda sid=st_id: self._toggle_subtask(sid)).pack(side="left")

    def _toggle_subtask(self, subtask_id: int):
        st = db.fetch_one("SELECT * FROM subtasks WHERE id=?", [subtask_id])
        if not st:
            return
        new_val = 0 if st["is_completed"] else 1
        db.update("subtasks", {"is_completed": new_val}, {"id": subtask_id})
        if new_val:
            db.award_xp(self._pid, 5, "Completed subtask")
        self._update_goal_progress()
        self._build()

    def _complete_milestone(self, ms_id: int):
        db.update("milestones", {"is_completed": 1}, {"id": ms_id})
        db.award_xp(self._pid, 25, "Completed milestone")
        db.check_and_award_badges(self._pid)
        self._update_goal_progress()
        self._refresh_xp()
        self._reload()
        self._build()

    def _update_goal_progress(self):
        milestones = db.fetch_all("SELECT * FROM milestones WHERE goal_id=?", [self._gid])
        if not milestones:
            return
        done = sum(1 for m in milestones if m["is_completed"])
        pct = int((done / len(milestones)) * 100)
        db.update("goals", {"progress_percent": pct}, {"id": self._gid})

    def _add_milestone(self, parent):
        title = ctk.CTkInputDialog(text="Milestone title:", title="Add Milestone").get_input()
        if title:
            db.insert("milestones", {"goal_id": self._gid, "title": title, "order_index": 99})
            for w in self.winfo_children():
                w.destroy()
            self._build()

    def _add_subtask(self, ms_id: int, parent):
        title = ctk.CTkInputDialog(text="Subtask title:", title="Add Subtask").get_input()
        if title:
            db.insert("subtasks", {"milestone_id": ms_id, "title": title})
            for w in self.winfo_children():
                w.destroy()
            self._build()


class AddGoalDialog(ctk.CTkToplevel):
    def __init__(self, parent, profile_id, tm, on_save_cb):
        super().__init__(parent)
        self._pid = profile_id
        self._tm = tm
        self._on_save = on_save_cb
        self.title("New Goal")
        self.geometry("480x560")
        self.resizable(False, False)
        self.grab_set()
        self.configure(fg_color=tm.background)
        self._type_var = ctk.StringVar(value="short_term")
        self._cat_var = ctk.StringVar(value="academic")
        self._build()

    def _build(self):
        tm = self._tm
        scroll = ctk.CTkScrollableFrame(self, fg_color=tm.background)
        scroll.pack(fill="both", expand=True, padx=0, pady=0)

        ctk.CTkLabel(scroll, text="New Goal", font=ctk.CTkFont(size=18, weight="bold"),
                     text_color=tm.text).pack(pady=(16, 8))

        self._vars = {}
        for label, key in [("Title *", "title"), ("Description", "desc")]:
            ctk.CTkLabel(scroll, text=label, font=ctk.CTkFont(size=12),
                         text_color=tm.text_secondary, anchor="w").pack(anchor="w", padx=16, pady=(8, 2))
            var = ctk.StringVar()
            ctk.CTkEntry(scroll, textvariable=var, height=36,
                         fg_color=tm.surface, border_color=tm.border,
                         text_color=tm.text, corner_radius=8).pack(fill="x", padx=16)
            self._vars[key] = var

        for label, key in [("Start Date (YYYY-MM-DD)", "start"), ("Deadline (YYYY-MM-DD)", "deadline")]:
            ctk.CTkLabel(scroll, text=label, font=ctk.CTkFont(size=12),
                         text_color=tm.text_secondary, anchor="w").pack(anchor="w", padx=16, pady=(8, 2))
            var = ctk.StringVar()
            ctk.CTkEntry(scroll, textvariable=var, height=36,
                         fg_color=tm.surface, border_color=tm.border,
                         text_color=tm.text, corner_radius=8).pack(fill="x", padx=16)
            self._vars[key] = var

        ctk.CTkLabel(scroll, text="Type", font=ctk.CTkFont(size=12),
                     text_color=tm.text_secondary, anchor="w").pack(anchor="w", padx=16, pady=(8, 2))
        ctk.CTkSegmentedButton(scroll, values=["short_term", "long_term"],
                               variable=self._type_var,
                               fg_color=tm.surface, selected_color=tm.primary,
                               text_color=tm.text).pack(anchor="w", padx=16)

        ctk.CTkLabel(scroll, text="Category", font=ctk.CTkFont(size=12),
                     text_color=tm.text_secondary, anchor="w").pack(anchor="w", padx=16, pady=(8, 2))
        ctk.CTkSegmentedButton(scroll, values=GOAL_CATEGORIES,
                               variable=self._cat_var,
                               fg_color=tm.surface, selected_color=tm.primary,
                               text_color=tm.text).pack(anchor="w", padx=16)

        ctk.CTkButton(scroll, text="Save Goal", width=200, height=42,
                      fg_color=tm.primary, hover_color=tm.secondary, corner_radius=10,
                      font=ctk.CTkFont(size=14, weight="bold"),
                      command=self._save).pack(pady=20)

    def _save(self):
        title = self._vars["title"].get().strip()
        if not title:
            return
        db.insert("goals", {
            "profile_id":  self._pid,
            "title":       title,
            "description": self._vars["desc"].get().strip(),
            "type":        self._type_var.get(),
            "category":    self._cat_var.get(),
            "start_date":  self._vars["start"].get().strip() or None,
            "deadline":    self._vars["deadline"].get().strip() or None,
        })
        db.award_xp(self._pid, 5, "Created a goal")
        db.check_and_award_badges(self._pid)
        self.destroy()
        self._on_save()
