"""
StudentTrack Pro — To-Do List Module
Full task management: add, filter, complete, delete, XP awards.
"""

import customtkinter as ctk
from datetime import date, datetime
from database import db
from modules.theme_manager import ThemeManager


PRIORITIES = ["low", "medium", "high", "urgent"]
PRIORITY_COLORS = {
    "low":    "#3FB950",
    "medium": "#D29922",
    "high":   "#FF6B35",
    "urgent": "#F85149",
}
FILTER_OPTIONS = ["All", "Today", "This Week", "High Priority", "Completed"]


class TodoModule(ctk.CTkFrame):
    """To-Do List module frame."""

    def __init__(self, parent, profile_id: int, tm: ThemeManager, refresh_xp_cb):
        super().__init__(parent, fg_color=tm.background, corner_radius=0)
        self._pid = profile_id
        self._tm = tm
        self._refresh_xp = refresh_xp_cb
        self._filter = "All"
        self._build()

    def _build(self):
        tm = self._tm

        # Header
        header = ctk.CTkFrame(self, fg_color=tm.surface, corner_radius=0, height=60)
        header.pack(fill="x")
        header.pack_propagate(False)

        ctk.CTkLabel(
            header, text="✅ To-Do List",
            font=ctk.CTkFont(size=20, weight="bold"),
            text_color=tm.primary
        ).pack(side="left", padx=20)

        ctk.CTkButton(
            header, text="+ Add Task",
            width=120, height=34,
            fg_color=tm.primary, hover_color=tm.secondary,
            corner_radius=8, font=ctk.CTkFont(size=13, weight="bold"),
            command=self._open_add_dialog
        ).pack(side="right", padx=20)

        # Filters
        filter_row = ctk.CTkFrame(self, fg_color=tm.surface2, corner_radius=0, height=44)
        filter_row.pack(fill="x")
        filter_row.pack_propagate(False)

        self._filter_btns = {}
        for f in FILTER_OPTIONS:
            btn = ctk.CTkButton(
                filter_row, text=f,
                width=90, height=30,
                fg_color=tm.primary if f == self._filter else "transparent",
                hover_color=tm.surface,
                text_color=tm.text if f == self._filter else tm.text_secondary,
                corner_radius=6,
                command=lambda x=f: self._set_filter(x)
            )
            btn.pack(side="left", padx=4, pady=7)
            self._filter_btns[f] = btn

        # Task list
        self._list_frame = ctk.CTkScrollableFrame(self, fg_color=tm.background, corner_radius=0)
        self._list_frame.pack(fill="both", expand=True, padx=0, pady=0)

        self._render_tasks()

    def _render_tasks(self):
        """Clear and re-render the task list based on current filter."""
        for w in self._list_frame.winfo_children():
            w.destroy()

        tm = self._tm
        today = date.today().isoformat()

        if self._filter == "All":
            tasks = db.fetch_all(
                "SELECT * FROM todos WHERE profile_id=? AND is_completed=0 ORDER BY "
                "CASE priority WHEN 'urgent' THEN 1 WHEN 'high' THEN 2 WHEN 'medium' THEN 3 ELSE 4 END, due_date",
                [self._pid]
            )
        elif self._filter == "Today":
            tasks = db.fetch_all(
                "SELECT * FROM todos WHERE profile_id=? AND is_completed=0 AND due_date=?",
                [self._pid, today]
            )
        elif self._filter == "This Week":
            from datetime import timedelta
            week_end = (date.today() + timedelta(days=7)).isoformat()
            tasks = db.fetch_all(
                "SELECT * FROM todos WHERE profile_id=? AND is_completed=0 AND due_date BETWEEN ? AND ?",
                [self._pid, today, week_end]
            )
        elif self._filter == "High Priority":
            tasks = db.fetch_all(
                "SELECT * FROM todos WHERE profile_id=? AND is_completed=0 AND priority IN ('high','urgent') "
                "ORDER BY CASE priority WHEN 'urgent' THEN 1 ELSE 2 END",
                [self._pid]
            )
        elif self._filter == "Completed":
            tasks = db.fetch_all(
                "SELECT * FROM todos WHERE profile_id=? AND is_completed=1 ORDER BY completed_at DESC",
                [self._pid]
            )
        else:
            tasks = []

        if not tasks:
            ctk.CTkLabel(
                self._list_frame,
                text="No tasks here. Add one above! 🎯",
                font=ctk.CTkFont(size=15),
                text_color=tm.text_secondary
            ).pack(pady=60)
            return

        for task in tasks:
            self._render_task_card(task)

    def _render_task_card(self, task):
        """Render a single task card."""
        tm = self._tm
        is_overdue = (not task["is_completed"] and task["due_date"]
                      and task["due_date"] < date.today().isoformat())
        pcolor = PRIORITY_COLORS.get(task["priority"], tm.text_secondary)
        border_color = tm.danger if is_overdue else pcolor

        card = ctk.CTkFrame(
            self._list_frame,
            fg_color=tm.card,
            corner_radius=10,
            border_width=2,
            border_color=border_color
        )
        card.pack(fill="x", padx=16, pady=5)

        # Left priority bar
        bar = ctk.CTkFrame(card, fg_color=pcolor, width=5, corner_radius=3)
        bar.pack(side="left", fill="y", padx=(0, 12), pady=8)

        content = ctk.CTkFrame(card, fg_color="transparent")
        content.pack(side="left", fill="both", expand=True, pady=10)

        # Title row
        title_row = ctk.CTkFrame(content, fg_color="transparent")
        title_row.pack(fill="x")

        title_text = task["title"]
        if task["is_completed"]:
            title_text = "✓ " + title_text

        title_lbl = ctk.CTkLabel(
            title_row, text=title_text,
            font=ctk.CTkFont(size=14, weight="bold",
                              overstrike=bool(task["is_completed"])),
            text_color=tm.text_secondary if task["is_completed"] else tm.text,
            anchor="w"
        )
        title_lbl.pack(side="left", anchor="w")

        # Priority badge
        ctk.CTkLabel(
            title_row,
            text=f" {task['priority'].upper()} ",
            font=ctk.CTkFont(size=10),
            text_color=pcolor,
            fg_color=tm.surface2,
            corner_radius=4
        ).pack(side="left", padx=6)

        # Description + meta
        if task["description"]:
            ctk.CTkLabel(
                content, text=task["description"][:100],
                font=ctk.CTkFont(size=12),
                text_color=tm.text_secondary, anchor="w"
            ).pack(anchor="w")

        meta_row = ctk.CTkFrame(content, fg_color="transparent")
        meta_row.pack(fill="x", pady=(2, 0))

        if task["due_date"]:
            due_color = tm.danger if is_overdue else tm.text_secondary
            due_text = f"📅 {task['due_date']}" + (" (OVERDUE)" if is_overdue else "")
            ctk.CTkLabel(meta_row, text=due_text,
                         font=ctk.CTkFont(size=11), text_color=due_color).pack(side="left", padx=(0, 10))

        if task["tags"]:
            ctk.CTkLabel(meta_row, text=f"🏷 {task['tags']}",
                         font=ctk.CTkFont(size=11), text_color=tm.text_secondary).pack(side="left")

        # Buttons
        btn_frame = ctk.CTkFrame(card, fg_color="transparent")
        btn_frame.pack(side="right", padx=10, fill="y")

        task_id = task["id"]
        is_done = bool(task["is_completed"])

        if not is_done:
            ctk.CTkButton(
                btn_frame, text="✓ Done",
                width=72, height=30,
                fg_color=tm.success, hover_color="#2EA043",
                corner_radius=6, font=ctk.CTkFont(size=12),
                command=lambda tid=task_id: self._complete_task(tid)
            ).pack(pady=(10, 4))

        ctk.CTkButton(
            btn_frame, text="🗑",
            width=36, height=30,
            fg_color=tm.surface2, hover_color=tm.danger,
            text_color=tm.text_secondary, corner_radius=6,
            command=lambda tid=task_id: self._delete_task(tid)
        ).pack(pady=(0, 10))

    def _set_filter(self, f: str):
        """Switch active filter."""
        self._filter = f
        for key, btn in self._filter_btns.items():
            if key == f:
                btn.configure(fg_color=self._tm.primary, text_color=self._tm.text)
            else:
                btn.configure(fg_color="transparent", text_color=self._tm.text_secondary)
        self._render_tasks()

    def _complete_task(self, task_id: int):
        """Mark a task as complete and award XP."""
        db.update("todos", {
            "is_completed": 1,
            "completed_at": datetime.now().isoformat()
        }, {"id": task_id})
        db.award_xp(self._pid, 10, "Completed task")
        db.check_and_award_badges(self._pid)
        self._refresh_xp()
        self._render_tasks()

    def _delete_task(self, task_id: int):
        """Delete a task after confirmation."""
        db.delete("todos", {"id": task_id})
        self._render_tasks()

    def _open_add_dialog(self):
        """Open the Add Task dialog."""
        AddTaskDialog(self, self._pid, self._tm, self._on_task_added)

    def _on_task_added(self):
        self._filter = "All"
        self._render_tasks()


class AddTaskDialog(ctk.CTkToplevel):
    """Dialog to add a new task."""

    def __init__(self, parent, profile_id: int, tm: ThemeManager, on_save_cb):
        super().__init__(parent)
        self._pid = profile_id
        self._tm = tm
        self._on_save = on_save_cb
        self.title("Add Task")
        self.geometry("480x520")
        self.resizable(False, False)
        self.grab_set()
        self.configure(fg_color=tm.background)
        self._build()

    def _build(self):
        tm = self._tm

        ctk.CTkLabel(self, text="Add New Task",
                     font=ctk.CTkFont(size=18, weight="bold"),
                     text_color=tm.text).pack(pady=(20, 10))

        form = ctk.CTkFrame(self, fg_color=tm.surface, corner_radius=12)
        form.pack(fill="both", expand=True, padx=20, pady=10)

        fields = [
            ("Title *", "title", ctk.StringVar()),
            ("Description", "desc", ctk.StringVar()),
            ("Tags (comma-separated)", "tags", ctk.StringVar()),
            ("Due Date (YYYY-MM-DD)", "due", ctk.StringVar()),
        ]
        self._vars = {}

        for label, key, var in fields:
            ctk.CTkLabel(form, text=label,
                         font=ctk.CTkFont(size=12),
                         text_color=tm.text_secondary, anchor="w").pack(anchor="w", padx=16, pady=(10, 2))
            entry = ctk.CTkEntry(form, textvariable=var, height=36,
                                 fg_color=tm.surface2, border_color=tm.border,
                                 text_color=tm.text, corner_radius=8)
            entry.pack(fill="x", padx=16)
            self._vars[key] = var

        ctk.CTkLabel(form, text="Priority",
                     font=ctk.CTkFont(size=12),
                     text_color=tm.text_secondary, anchor="w").pack(anchor="w", padx=16, pady=(10, 2))

        self._priority_var = ctk.StringVar(value="medium")
        p_row = ctk.CTkFrame(form, fg_color="transparent")
        p_row.pack(anchor="w", padx=16)

        self._p_btns = {}
        for p in PRIORITIES:
            btn = ctk.CTkButton(
                p_row, text=p.capitalize(),
                width=80, height=30,
                fg_color=PRIORITY_COLORS[p] if p == "medium" else tm.surface2,
                hover_color=PRIORITY_COLORS[p],
                text_color=tm.text,
                corner_radius=6, font=ctk.CTkFont(size=12),
                command=lambda x=p: self._set_priority(x)
            )
            btn.pack(side="left", padx=2)
            self._p_btns[p] = btn

        ctk.CTkButton(
            self, text="Save Task",
            width=200, height=42,
            fg_color=tm.primary, hover_color=tm.secondary,
            corner_radius=10, font=ctk.CTkFont(size=14, weight="bold"),
            command=self._save
        ).pack(pady=16)

    def _set_priority(self, p: str):
        tm = self._tm
        self._priority_var.set(p)
        for key, btn in self._p_btns.items():
            btn.configure(fg_color=PRIORITY_COLORS[key] if key == p else tm.surface2)

    def _save(self):
        title = self._vars["title"].get().strip()
        if not title:
            return
        db.insert("todos", {
            "profile_id":  self._pid,
            "title":       title,
            "description": self._vars["desc"].get().strip(),
            "priority":    self._priority_var.get(),
            "tags":        self._vars["tags"].get().strip(),
            "due_date":    self._vars["due"].get().strip() or None,
        })
        self.destroy()
        self._on_save()
