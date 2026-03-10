"""
StudentTrack Pro — Resource Library Module
Add, filter, search, and open study resources (links, PDFs, videos, books).
"""

import customtkinter as ctk
import webbrowser
from database import db
from modules.theme_manager import ThemeManager

RESOURCE_TYPES = ["link", "video", "pdf", "book", "other"]
TYPE_ICONS = {"link": "🔗", "video": "🎥", "pdf": "📄", "book": "📕", "other": "📎"}


class ResourcesModule(ctk.CTkFrame):
    def __init__(self, parent, profile_id, tm: ThemeManager, refresh_xp_cb):
        super().__init__(parent, fg_color=tm.background, corner_radius=0)
        self._pid = profile_id
        self._tm = tm
        self._refresh_xp = refresh_xp_cb
        self._filter_type = "all"
        self._search_query = ""
        self._build()

    def _build(self):
        tm = self._tm
        header = ctk.CTkFrame(self, fg_color=tm.surface, corner_radius=0, height=60)
        header.pack(fill="x")
        header.pack_propagate(False)
        ctk.CTkLabel(header, text="📚 Resource Library",
                     font=ctk.CTkFont(size=20, weight="bold"),
                     text_color=tm.primary).pack(side="left", padx=20)
        ctk.CTkButton(header, text="+ Add Resource", width=130, height=34,
                      fg_color=tm.primary, hover_color=tm.secondary, corner_radius=8,
                      command=self._open_add).pack(side="right", padx=20)

        # Search + filter bar
        bar = ctk.CTkFrame(self, fg_color=tm.surface2, corner_radius=0, height=50)
        bar.pack(fill="x")
        self._search_var = ctk.StringVar()
        self._search_var.trace_add("write", lambda *_: self._render())
        ctk.CTkEntry(bar, textvariable=self._search_var, width=260, height=32,
                     placeholder_text="🔍 Search resources…",
                     fg_color=tm.surface, border_color=tm.border, text_color=tm.text,
                     corner_radius=8).pack(side="left", padx=16, pady=9)

        for rt in ["all"] + RESOURCE_TYPES:
            icon = TYPE_ICONS.get(rt, "📂") if rt != "all" else "🌐"
            btn = ctk.CTkButton(bar, text=f"{icon} {rt.capitalize()}",
                                width=80, height=28,
                                fg_color=tm.primary if rt == self._filter_type else "transparent",
                                hover_color=tm.surface, text_color=tm.text, corner_radius=6,
                                command=lambda x=rt: self._set_filter(x))
            btn.pack(side="left", padx=3, pady=11)

        self._list = ctk.CTkScrollableFrame(self, fg_color=tm.background, corner_radius=0)
        self._list.pack(fill="both", expand=True)
        self._render()

    def _render(self):
        for w in self._list.winfo_children():
            w.destroy()
        tm = self._tm
        q = self._search_var.get().strip()

        if self._filter_type == "all":
            type_clause = ""
            params = [self._pid]
        else:
            type_clause = "AND resource_type=?"
            params = [self._pid, self._filter_type]

        if q:
            resources = db.fetch_all(
                f"SELECT * FROM resources WHERE profile_id=? {type_clause} "
                f"AND (title LIKE ? OR description LIKE ? OR tags LIKE ?) "
                f"ORDER BY is_favorite DESC, created_at DESC",
                params + [f"%{q}%", f"%{q}%", f"%{q}%"]
            )
        else:
            resources = db.fetch_all(
                f"SELECT * FROM resources WHERE profile_id=? {type_clause} "
                f"ORDER BY is_favorite DESC, created_at DESC",
                params
            )

        if not resources:
            ctk.CTkLabel(self._list, text="No resources found. Add one above! 📚",
                         font=ctk.CTkFont(size=15), text_color=tm.text_secondary).pack(pady=60)
            return

        for r in resources:
            self._render_card(r)

    def _render_card(self, r):
        tm = self._tm
        icon = TYPE_ICONS.get(r["resource_type"], "📎")
        rid = r["id"]
        is_fav = bool(r["is_favorite"])

        card = ctk.CTkFrame(self._list, fg_color=tm.card, corner_radius=10,
                            border_width=1, border_color=tm.warning if is_fav else tm.border)
        card.pack(fill="x", padx=16, pady=5)

        row = ctk.CTkFrame(card, fg_color="transparent")
        row.pack(fill="x", padx=14, pady=12)

        ctk.CTkLabel(row, text=icon, font=ctk.CTkFont(size=26), width=36).pack(side="left")

        info = ctk.CTkFrame(row, fg_color="transparent")
        info.pack(side="left", fill="both", expand=True, padx=10)

        ctk.CTkLabel(info, text=r["title"],
                     font=ctk.CTkFont(size=13, weight="bold"),
                     text_color=tm.text, anchor="w").pack(anchor="w")

        if r["description"]:
            ctk.CTkLabel(info, text=r["description"][:90],
                         font=ctk.CTkFont(size=11), text_color=tm.text_secondary,
                         anchor="w").pack(anchor="w")

        meta = ctk.CTkFrame(info, fg_color="transparent")
        meta.pack(anchor="w")
        if r["subject"]:
            ctk.CTkLabel(meta, text=f"📘 {r['subject']}",
                         font=ctk.CTkFont(size=10), text_color=tm.primary).pack(side="left", padx=(0, 8))
        if r["tags"]:
            ctk.CTkLabel(meta, text=f"🏷 {r['tags']}",
                         font=ctk.CTkFont(size=10), text_color=tm.text_secondary).pack(side="left")

        btn_col = ctk.CTkFrame(row, fg_color="transparent")
        btn_col.pack(side="right")

        if r["url"]:
            ctk.CTkButton(btn_col, text="🌐 Open", width=72, height=28,
                          fg_color=tm.primary, hover_color=tm.secondary, corner_radius=6,
                          font=ctk.CTkFont(size=11),
                          command=lambda u=r["url"]: webbrowser.open(u)).pack(pady=2)

        fav_lbl = "⭐" if not is_fav else "★"
        ctk.CTkButton(btn_col, text=fav_lbl, width=36, height=28,
                      fg_color="transparent", hover_color=tm.surface2,
                      text_color=tm.warning, font=ctk.CTkFont(size=16),
                      command=lambda rid2=rid, fav=is_fav: self._toggle_fav(rid2, fav)).pack(pady=2)

        ctk.CTkButton(btn_col, text="🗑", width=36, height=28,
                      fg_color="transparent", hover_color=tm.danger,
                      text_color=tm.text_secondary, font=ctk.CTkFont(size=14),
                      command=lambda rid2=rid: self._delete(rid2)).pack(pady=2)

    def _toggle_fav(self, rid: int, current: bool):
        db.update("resources", {"is_favorite": 0 if current else 1}, {"id": rid})
        self._render()

    def _delete(self, rid: int):
        db.delete("resources", {"id": rid})
        self._render()

    def _set_filter(self, f: str):
        self._filter_type = f
        self._render()

    def _open_add(self):
        AddResourceDialog(self, self._pid, self._tm, self._render)


class AddResourceDialog(ctk.CTkToplevel):
    def __init__(self, parent, profile_id, tm, on_save_cb):
        super().__init__(parent)
        self._pid = profile_id
        self._tm = tm
        self._on_save = on_save_cb
        self._type_var = ctk.StringVar(value="link")
        self.title("Add Resource")
        self.geometry("440x480")
        self.resizable(False, False)
        self.grab_set()
        self.configure(fg_color=tm.background)
        self._build()

    def _build(self):
        tm = self._tm
        ctk.CTkLabel(self, text="Add Resource",
                     font=ctk.CTkFont(size=18, weight="bold"), text_color=tm.text).pack(pady=16)
        form = ctk.CTkFrame(self, fg_color=tm.surface, corner_radius=12)
        form.pack(fill="both", expand=True, padx=20, pady=10)

        self._vars = {}
        for label, key in [("Title *", "title"), ("URL", "url"), ("Description", "desc"),
                            ("Subject", "subject"), ("Tags", "tags")]:
            ctk.CTkLabel(form, text=label, font=ctk.CTkFont(size=12),
                         text_color=tm.text_secondary, anchor="w").pack(anchor="w", padx=16, pady=(6, 2))
            var = ctk.StringVar()
            ctk.CTkEntry(form, textvariable=var, height=32, fg_color=tm.surface2,
                         border_color=tm.border, text_color=tm.text, corner_radius=8).pack(fill="x", padx=16)
            self._vars[key] = var

        ctk.CTkLabel(form, text="Type", font=ctk.CTkFont(size=12),
                     text_color=tm.text_secondary, anchor="w").pack(anchor="w", padx=16, pady=(8, 2))
        ctk.CTkSegmentedButton(form, values=RESOURCE_TYPES,
                               variable=self._type_var,
                               fg_color=tm.surface2, selected_color=tm.primary,
                               text_color=tm.text).pack(anchor="w", padx=16)

        ctk.CTkButton(self, text="Save Resource", width=200, height=40,
                      fg_color=tm.primary, hover_color=tm.secondary, corner_radius=10,
                      font=ctk.CTkFont(size=14, weight="bold"),
                      command=self._save).pack(pady=14)

    def _save(self):
        title = self._vars["title"].get().strip()
        if not title:
            return
        db.insert("resources", {
            "profile_id":    self._pid,
            "title":         title,
            "url":           self._vars["url"].get().strip(),
            "description":   self._vars["desc"].get().strip(),
            "subject":       self._vars["subject"].get().strip(),
            "tags":          self._vars["tags"].get().strip(),
            "resource_type": self._type_var.get(),
        })
        self.destroy()
        self._on_save()
