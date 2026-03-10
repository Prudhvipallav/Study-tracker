"""
StudentTrack Pro — Onboarding Wizard
Multi-step wizard for first-time profile creation.

Steps:
  1. Welcome + name entry
  2. Stream selection (LOCKED after save)
  3. Profile confirmation + avatar selection
"""

import customtkinter as ctk
from database.db import insert, get_settings
from modules.theme_manager import ThemeManager, set_active_theme

STREAM_OPTIONS = [
    {
        "key":   "engineering",
        "icon":  "🔧",
        "name":  "Engineering (BTech/BE)",
        "desc":  "Programming, Math, Physics, Electronics & more",
        "color": "#1E90FF",
    },
    {
        "key":   "medical",
        "icon":  "🩺",
        "name":  "Medical (MBBS/BDS)",
        "desc":  "Anatomy, Physiology, Biochemistry, Pathology & more",
        "color": "#00C896",
    },
    {
        "key":   "law",
        "icon":  "⚖️",
        "name":  "Law (LLB/LLM)",
        "desc":  "Constitutional, Criminal, Civil & Contract Law",
        "color": "#C0392B",
    },
    {
        "key":   "competitive",
        "icon":  "📖",
        "name":  "Competitive Exams",
        "desc":  "GS, Maths, Reasoning, English & Current Affairs",
        "color": "#9B59B6",
    },
]

AVATARS = ["🎓", "🦋", "🌟", "🔥", "💎", "🚀"]


class OnboardingWizard(ctk.CTk):
    """Three-step onboarding wizard that creates a new student profile."""

    def __init__(self, on_complete_callback):
        super().__init__()
        self._callback = on_complete_callback
        self._name = ""
        self._stream = None
        self._avatar = AVATARS[0]

        # Neutral theme during onboarding
        self._tm = ThemeManager("engineering", dark_mode=True)
        self._tm.apply()

        self.title("StudentTrack Pro — Welcome")
        self.geometry("800x600")
        self.resizable(False, False)
        self.configure(fg_color=self._tm.background)

        self._container = ctk.CTkFrame(self, fg_color="transparent")
        self._container.pack(fill="both", expand=True)

        self._show_step1()

    # ------------------------------------------------------------------
    # Step 1 — Welcome & Name
    # ------------------------------------------------------------------

    def _show_step1(self):
        self._clear()
        tm = self._tm

        ctk.CTkLabel(
            self._container, text="🎓 Welcome to StudentTrack Pro",
            font=ctk.CTkFont(size=28, weight="bold"),
            text_color=tm.primary
        ).pack(pady=(60, 6))

        ctk.CTkLabel(
            self._container,
            text="Your personal student productivity companion.\nLet's get you set up in under a minute.",
            font=ctk.CTkFont(size=15),
            text_color=tm.text_secondary,
            justify="center"
        ).pack(pady=(0, 40))

        ctk.CTkLabel(
            self._container, text="What's your name?",
            font=ctk.CTkFont(size=16, weight="bold"),
            text_color=tm.text
        ).pack()

        self._name_var = ctk.StringVar(value=self._name)
        name_entry = ctk.CTkEntry(
            self._container,
            textvariable=self._name_var,
            width=320, height=46,
            font=ctk.CTkFont(size=15),
            placeholder_text="Enter your name…",
            fg_color=tm.surface,
            border_color=tm.border,
            text_color=tm.text,
            corner_radius=10
        )
        name_entry.pack(pady=14)
        name_entry.focus()

        err_label = ctk.CTkLabel(
            self._container, text="",
            font=ctk.CTkFont(size=12),
            text_color=tm.danger
        )
        err_label.pack()

        def next_step():
            name = self._name_var.get().strip()
            if len(name) < 2:
                err_label.configure(text="Please enter at least 2 characters.")
                return
            self._name = name
            self._show_step2()

        ctk.CTkButton(
            self._container,
            text="Continue →",
            width=180, height=46,
            font=ctk.CTkFont(size=15, weight="bold"),
            fg_color=tm.primary, hover_color=tm.secondary,
            corner_radius=10,
            command=next_step
        ).pack(pady=20)

        # Step indicator
        self._step_indicator(1)

    # ------------------------------------------------------------------
    # Step 2 — Stream Selection
    # ------------------------------------------------------------------

    def _show_step2(self):
        self._clear()
        tm = self._tm

        ctk.CTkLabel(
            self._container,
            text="Choose Your Path",
            font=ctk.CTkFont(size=26, weight="bold"),
            text_color=tm.primary
        ).pack(pady=(40, 4))

        ctk.CTkLabel(
            self._container,
            text="This Cannot Be Changed Later  ⚠️",
            font=ctk.CTkFont(size=14, weight="bold"),
            text_color=tm.danger
        ).pack(pady=(0, 20))

        grid = ctk.CTkFrame(self._container, fg_color="transparent")
        grid.pack(padx=40)
        grid.columnconfigure((0, 1), weight=1)

        self._stream_selected = ctk.StringVar(value=self._stream or "")
        self._stream_cards = {}

        for i, opt in enumerate(STREAM_OPTIONS):
            row, col = divmod(i, 2)
            card = ctk.CTkFrame(
                grid,
                fg_color=tm.card,
                corner_radius=14,
                border_width=2,
                border_color=tm.border,
                width=280, height=130
            )
            card.grid(row=row, column=col, padx=10, pady=8, sticky="nsew")
            card.pack_propagate(False)
            card.grid_propagate(False)

            inner = ctk.CTkFrame(card, fg_color="transparent")
            inner.pack(expand=True)

            ctk.CTkLabel(inner, text=opt["icon"], font=ctk.CTkFont(size=36)).pack()
            ctk.CTkLabel(inner, text=opt["name"],
                         font=ctk.CTkFont(size=13, weight="bold"),
                         text_color=tm.text).pack()
            ctk.CTkLabel(inner, text=opt["desc"],
                         font=ctk.CTkFont(size=11),
                         text_color=tm.text_secondary,
                         wraplength=240, justify="center").pack()

            self._stream_cards[opt["key"]] = (card, opt["color"])

            key = opt["key"]
            card.bind("<Button-1>", lambda e, k=key: self._select_stream(k))
            for child in inner.winfo_children():
                child.bind("<Button-1>", lambda e, k=key: self._select_stream(k))

        # Confirm button
        self._confirm_btn = ctk.CTkButton(
            self._container,
            text="Confirm Stream →",
            width=200, height=46,
            font=ctk.CTkFont(size=15, weight="bold"),
            fg_color=tm.text_secondary,
            state="disabled",
            corner_radius=10,
            command=self._show_step3
        )
        self._confirm_btn.pack(pady=(18, 0))

        err = ctk.CTkLabel(
            self._container, text="",
            text_color=tm.danger, font=ctk.CTkFont(size=12)
        )
        err.pack()

        if self._stream:
            self._select_stream(self._stream)

        self._step_indicator(2)

    def _select_stream(self, key: str):
        """Highlight selected stream card and enable confirm."""
        tm = self._tm
        self._stream = key
        for k, (card, color) in self._stream_cards.items():
            if k == key:
                card.configure(border_color=color, border_width=3, fg_color=tm.surface2)
            else:
                card.configure(border_color=tm.border, border_width=2, fg_color=tm.card)

        # Update the active theme preview
        self._tm = ThemeManager(key, dark_mode=True)
        self._confirm_btn.configure(
            state="normal",
            fg_color=self._tm.primary,
            hover_color=self._tm.secondary
        )

    # ------------------------------------------------------------------
    # Step 3 — Confirmation + Avatar
    # ------------------------------------------------------------------

    def _show_step3(self):
        self._clear()
        tm = ThemeManager(self._stream, dark_mode=True)
        set_active_theme(tm)
        self.configure(fg_color=tm.background)

        ctk.CTkLabel(
            self._container,
            text="Your Profile",
            font=ctk.CTkFont(size=26, weight="bold"),
            text_color=tm.primary
        ).pack(pady=(40, 4))

        # Profile preview card
        preview_card = ctk.CTkFrame(
            self._container,
            fg_color=tm.card,
            corner_radius=16,
            border_width=2,
            border_color=tm.primary
        )
        preview_card.pack(padx=80, pady=(10, 20), fill="x")

        info_row = ctk.CTkFrame(preview_card, fg_color="transparent")
        info_row.pack(fill="x", padx=24, pady=20)

        self._avatar_label = ctk.CTkLabel(
            info_row, text=self._avatar,
            font=ctk.CTkFont(size=56)
        )
        self._avatar_label.pack(side="left", padx=(0, 20))

        info = ctk.CTkFrame(info_row, fg_color="transparent")
        info.pack(side="left", fill="both", expand=True)

        ctk.CTkLabel(info, text=self._name,
                     font=ctk.CTkFont(size=22, weight="bold"),
                     text_color=tm.text, anchor="w").pack(anchor="w")

        stream_display = next(o["name"] for o in STREAM_OPTIONS if o["key"] == self._stream)
        ctk.CTkLabel(info, text=f"🎯 {stream_display}",
                     font=ctk.CTkFont(size=14),
                     text_color=tm.text_secondary, anchor="w").pack(anchor="w")

        xp_bar = ctk.CTkProgressBar(preview_card, height=8,
                                     fg_color=tm.surface2, progress_color=tm.primary)
        xp_bar.set(0)
        xp_bar.pack(fill="x", padx=24, pady=(0, 10))

        ctk.CTkLabel(preview_card, text="Level 1  |  0 XP  |  Just Getting Started 🌱",
                     font=ctk.CTkFont(size=12),
                     text_color=tm.text_secondary).pack(pady=(0, 16))

        # Avatar row
        ctk.CTkLabel(self._container, text="Choose your avatar:",
                     font=ctk.CTkFont(size=14, weight="bold"),
                     text_color=tm.text).pack()

        av_row = ctk.CTkFrame(self._container, fg_color="transparent")
        av_row.pack(pady=8)

        self._av_btns = {}
        for av in AVATARS:
            btn = ctk.CTkButton(
                av_row, text=av,
                width=52, height=52,
                font=ctk.CTkFont(size=26),
                fg_color=tm.surface2 if av != self._avatar else tm.primary,
                hover_color=tm.surface,
                corner_radius=26,
                command=lambda a=av: self._select_avatar(a)
            )
            btn.pack(side="left", padx=5)
            self._av_btns[av] = btn

        ctk.CTkButton(
            self._container,
            text="🚀 Launch StudentTrack Pro",
            width=260, height=50,
            font=ctk.CTkFont(size=16, weight="bold"),
            fg_color=tm.primary, hover_color=tm.secondary,
            corner_radius=12,
            command=self._create_profile
        ).pack(pady=24)

        self._step_indicator(3)

    def _select_avatar(self, av: str):
        """Update avatar selection UI."""
        tm = get_theme()
        self._avatar = av
        self._avatar_label.configure(text=av)
        for a, btn in self._av_btns.items():
            btn.configure(fg_color=self._tm.primary if a == av else self._tm.surface2)

    def _create_profile(self):
        """Save profile to DB and launch main app."""
        profile_id = insert("profiles", {
            "name":          self._name,
            "avatar":        self._avatar,
            "stream":        self._stream,
            "stream_locked": 1,
            "theme":         self._stream,
            "xp":            0,
            "level":         1,
        })
        # Create default settings
        get_settings(profile_id)
        self.destroy()
        self._callback(profile_id)

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------

    def _clear(self):
        """Remove all children from container."""
        for w in self._container.winfo_children():
            w.destroy()

    def _step_indicator(self, current: int):
        """Render step dots at the bottom."""
        tm = self._tm
        row = ctk.CTkFrame(self._container, fg_color="transparent")
        row.pack(pady=10)
        for i in range(1, 4):
            dot = ctk.CTkLabel(
                row,
                text="●" if i == current else "○",
                font=ctk.CTkFont(size=14),
                text_color=tm.primary if i == current else tm.text_secondary
            )
            dot.pack(side="left", padx=4)

    # Fix: expose get_theme for avatar callback
    def _get_tm(self):
        return self._tm


def get_theme():
    from modules.theme_manager import get_theme as _gt
    return _gt()
