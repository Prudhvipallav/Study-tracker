"""
StudentTrack Pro — Notes & Journal Module
Create, search, pin, export notes. Daily journal mode.
"""

import customtkinter as ctk
import json
from datetime import date, datetime
from database import db
from modules.theme_manager import ThemeManager


class NotesModule(ctk.CTkFrame):
    def __init__(self, parent, profile_id, tm: ThemeManager, refresh_xp_cb):
        super().__init__(parent, fg_color=tm.background, corner_radius=0)
        self._pid = profile_id
        self._tm = tm
        self._refresh_xp = refresh_xp_cb
        self._sort = "newest"
        self._search_query = ""
        self._editing_id = None
        self._build()

    def _build(self):
        tm = self._tm
        header = ctk.CTkFrame(self, fg_color=tm.surface, corner_radius=0, height=60)
        header.pack(fill="x")
        header.pack_propagate(False)
        ctk.CTkLabel(header, text="📝 Notes & Journal",
                     font=ctk.CTkFont(size=20, weight="bold"),
                     text_color=tm.primary).pack(side="left", padx=20)
        ctk.CTkButton(header, text="📓 Journal Today", width=130, height=34,
                      fg_color=tm.accent, hover_color=tm.warning, corner_radius=8,
                      command=self._journal_today).pack(side="right", padx=6)
        ctk.CTkButton(header, text="+ New Note", width=110, height=34,
                      fg_color=tm.primary, hover_color=tm.secondary, corner_radius=8,
                      command=self._open_new_note).pack(side="right", padx=6)

        # Search + sort bar
        bar = ctk.CTkFrame(self, fg_color=tm.surface2, corner_radius=0, height=46)
        bar.pack(fill="x")
        self._search_var = ctk.StringVar()
        self._search_var.trace_add("write", lambda *_: self._render_list())
        ctk.CTkEntry(bar, textvariable=self._search_var, width=280, height=32,
                     placeholder_text="🔍 Search notes…",
                     fg_color=tm.surface, border_color=tm.border, text_color=tm.text,
                     corner_radius=8).pack(side="left", padx=16, pady=7)

        ctk.CTkOptionMenu(bar, values=["newest", "oldest", "pinned", "subject"],
                          fg_color=tm.surface, button_color=tm.primary, text_color=tm.text,
                          width=110,
                          command=lambda v: self._set_sort(v)).pack(side="left", padx=4)

        # Two-panel layout
        panels = ctk.CTkFrame(self, fg_color=tm.background, corner_radius=0)
        panels.pack(fill="both", expand=True)

        # Left: note list
        self._list_frame = ctk.CTkScrollableFrame(panels, fg_color=tm.background,
                                                   corner_radius=0, width=300)
        self._list_frame.pack(side="left", fill="y")

        sep = ctk.CTkFrame(panels, fg_color=tm.border, width=1, corner_radius=0)
        sep.pack(side="left", fill="y")

        # Right: editor
        self._editor_frame = ctk.CTkFrame(panels, fg_color=tm.surface, corner_radius=0)
        self._editor_frame.pack(side="left", fill="both", expand=True)

        self._render_list()
        self._show_placeholder()

    def _render_list(self):
        for w in self._list_frame.winfo_children():
            w.destroy()
        tm = self._tm
        q = self._search_var.get().strip()

        if self._sort == "newest":
            order = "ORDER BY is_pinned DESC, created_at DESC"
        elif self._sort == "oldest":
            order = "ORDER BY is_pinned DESC, created_at ASC"
        elif self._sort == "pinned":
            order = "ORDER BY is_pinned DESC, created_at DESC"
        else:
            order = "ORDER BY subject, created_at DESC"

        if q:
            notes = db.fetch_all(
                f"SELECT * FROM notes WHERE profile_id=? AND (title LIKE ? OR content LIKE ? OR tags LIKE ?) {order}",
                [self._pid, f"%{q}%", f"%{q}%", f"%{q}%"]
            )
        else:
            notes = db.fetch_all(f"SELECT * FROM notes WHERE profile_id=? {order}", [self._pid])

        if not notes:
            ctk.CTkLabel(self._list_frame, text="No notes yet.\nAdd one above!",
                         font=ctk.CTkFont(size=13), text_color=tm.text_secondary).pack(pady=30)
            return

        for n in notes:
            self._render_note_card(n)

    def _render_note_card(self, note):
        tm = self._tm
        nid = note["id"]
        card = ctk.CTkFrame(self._list_frame, fg_color=tm.card, corner_radius=8,
                            border_width=1, border_color=tm.primary if note["is_pinned"] else tm.border)
        card.pack(fill="x", padx=8, pady=4)
        card.bind("<Button-1>", lambda e, n_id=nid: self._open_editor(n_id))

        top = ctk.CTkFrame(card, fg_color="transparent")
        top.pack(fill="x", padx=10, pady=(8, 0))
        top.bind("<Button-1>", lambda e, n_id=nid: self._open_editor(n_id))

        title = ("📌 " if note["is_pinned"] else "") + note["title"]
        ctk.CTkLabel(top, text=title[:28], font=ctk.CTkFont(size=12, weight="bold"),
                     text_color=tm.text, anchor="w").pack(side="left")

        preview = note["content"][:60].replace("\n", " ") + "…" if note["content"] else ""
        ctk.CTkLabel(card, text=preview, font=ctk.CTkFont(size=11),
                     text_color=tm.text_secondary, anchor="w",
                     wraplength=260).pack(anchor="w", padx=10, pady=(2, 8))

    def _show_placeholder(self):
        for w in self._editor_frame.winfo_children():
            w.destroy()
        tm = self._tm
        ctk.CTkLabel(self._editor_frame, text="Select a note to view or edit",
                     font=ctk.CTkFont(size=14), text_color=tm.text_secondary).pack(expand=True)

    def _open_editor(self, note_id: int):
        note = db.fetch_one("SELECT * FROM notes WHERE id=?", [note_id])
        if not note:
            return
        for w in self._editor_frame.winfo_children():
            w.destroy()
        tm = self._tm
        self._editing_id = note_id

        title_var = ctk.StringVar(value=note["title"])
        subj_var = ctk.StringVar(value=note["subject"] or "")
        tags_var = ctk.StringVar(value=note["tags"] or "")

        top = ctk.CTkFrame(self._editor_frame, fg_color=tm.surface2, corner_radius=0, height=46)
        top.pack(fill="x")
        top.pack_propagate(False)

        ctk.CTkEntry(top, textvariable=title_var, height=34, width=300,
                     fg_color=tm.surface, border_color=tm.border, text_color=tm.text,
                     font=ctk.CTkFont(size=14, weight="bold"),
                     corner_radius=8).pack(side="left", padx=10, pady=6)

        ctk.CTkButton(top, text="💾 Save", width=80, height=32,
                      fg_color=tm.primary, corner_radius=6,
                      command=lambda: self._save_note(note_id, title_var.get(),
                                                       text_box.get("1.0", "end-1c"),
                                                       subj_var.get(), tags_var.get())).pack(side="right", padx=6)

        ctk.CTkButton(top, text="🗑", width=36, height=32,
                      fg_color=tm.surface2, hover_color=tm.danger, text_color=tm.text_secondary,
                      corner_radius=6,
                      command=lambda: self._delete_note(note_id)).pack(side="right", padx=2)

        pin_btn = ctk.CTkButton(top, text="📌" if not note["is_pinned"] else "📍",
                                 width=36, height=32, fg_color=tm.surface2,
                                 hover_color=tm.accent, text_color=tm.text, corner_radius=6,
                                 command=lambda: self._toggle_pin(note_id))
        pin_btn.pack(side="right", padx=2)

        meta_row = ctk.CTkFrame(self._editor_frame, fg_color="transparent")
        meta_row.pack(fill="x", padx=10, pady=4)
        for label, var in [("Subject:", subj_var), ("Tags:", tags_var)]:
            ctk.CTkLabel(meta_row, text=label, font=ctk.CTkFont(size=11),
                         text_color=tm.text_secondary).pack(side="left")
            ctk.CTkEntry(meta_row, textvariable=var, width=120, height=26,
                         fg_color=tm.surface2, border_color=tm.border, text_color=tm.text,
                         corner_radius=6).pack(side="left", padx=(2, 12))

        text_box = ctk.CTkTextbox(self._editor_frame, fg_color=tm.background,
                                   text_color=tm.text, font=ctk.CTkFont(size=13),
                                   corner_radius=0)
        text_box.pack(fill="both", expand=True, padx=0, pady=0)
        if note["content"]:
            text_box.insert("1.0", note["content"])

        # Export button
        ctk.CTkButton(self._editor_frame, text="📤 Export .txt",
                      width=120, height=28, fg_color=tm.surface2, hover_color=tm.primary,
                      text_color=tm.text, corner_radius=6,
                      command=lambda: self._export_note(note)).pack(anchor="e", padx=10, pady=6)

    def _save_note(self, nid, title, content, subject, tags):
        db.update("notes", {
            "title": title, "content": content,
            "subject": subject, "tags": tags,
            "updated_at": datetime.now().isoformat()
        }, {"id": nid})
        self._render_list()

    def _delete_note(self, nid):
        db.delete("notes", {"id": nid})
        self._show_placeholder()
        self._render_list()

    def _toggle_pin(self, nid):
        note = db.fetch_one("SELECT is_pinned FROM notes WHERE id=?", [nid])
        if note:
            db.update("notes", {"is_pinned": 0 if note["is_pinned"] else 1}, {"id": nid})
        self._render_list()

    def _export_note(self, note):
        import tkinter.filedialog as fd
        path = fd.asksaveasfilename(defaultextension=".txt",
                                    filetypes=[("Text files", "*.txt")],
                                    initialfile=note["title"])
        if path:
            with open(path, "w", encoding="utf-8") as f:
                f.write(f"# {note['title']}\n\n{note['content'] or ''}")

    def _set_sort(self, v: str):
        self._sort = v
        self._render_list()

    def _open_new_note(self):
        nid = db.insert("notes", {
            "profile_id": self._pid,
            "title": "New Note",
            "content": "",
        })
        db.check_and_award_badges(self._pid)
        self._render_list()
        self._open_editor(nid)

    def _journal_today(self):
        today_str = date.today().strftime("%A, %B %d %Y")
        title = f"📓 Journal — {today_str}"
        existing = db.fetch_one("SELECT id FROM notes WHERE profile_id=? AND title=?",
                                [self._pid, title])
        if existing:
            self._open_editor(existing["id"])
        else:
            template = f"# {today_str}\n\n✅ Today I accomplished:\n\n🎯 Goals for tomorrow:\n\n💭 Thoughts:\n"
            nid = db.insert("notes", {
                "profile_id": self._pid,
                "title":      title,
                "content":    template,
                "tags":       "journal",
            })
            self._render_list()
            self._open_editor(nid)
