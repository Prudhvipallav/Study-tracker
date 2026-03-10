"""
StudentTrack Pro — Gamification Module
XP, levels, badges display and leaderboard.
"""

import customtkinter as ctk
from database import db
from modules.theme_manager import ThemeManager
from database.db import get_level_name, BADGE_DEFINITIONS


class GamificationModule(ctk.CTkScrollableFrame):
    def __init__(self, parent, profile_id, tm: ThemeManager, refresh_xp_cb):
        super().__init__(parent, fg_color=tm.background, corner_radius=0)
        self._pid = profile_id
        self._tm = tm
        self._refresh_xp = refresh_xp_cb
        self._build()

    def _build(self):
        tm = self._tm
        profile = dict(db.get_profile(self._pid))

        ctk.CTkLabel(self, text="🏆 Achievements & Leaderboard",
                     font=ctk.CTkFont(size=22, weight="bold"),
                     text_color=tm.primary).pack(anchor="w", padx=20, pady=(20, 4))

        # XP card
        xp_card = ctk.CTkFrame(self, fg_color=tm.card, corner_radius=16,
                               border_width=2, border_color=tm.primary)
        xp_card.pack(fill="x", padx=20, pady=8)

        xp = profile["xp"]
        level = profile["level"]
        level_name = get_level_name(profile["stream"], level)
        xp_in_level = xp % 500

        row = ctk.CTkFrame(xp_card, fg_color="transparent")
        row.pack(fill="x", padx=20, pady=16)

        ctk.CTkLabel(row, text=f"⭐  Level {level}",
                     font=ctk.CTkFont(size=28, weight="bold"),
                     text_color=tm.highlight).pack(side="left")

        ctk.CTkLabel(row, text=f"{level_name}\n{xp} XP total",
                     font=ctk.CTkFont(size=14),
                     text_color=tm.text_secondary, justify="right").pack(side="right")

        prog = ctk.CTkProgressBar(xp_card, height=14, fg_color=tm.surface2, progress_color=tm.primary)
        prog.set(xp_in_level / 500)
        prog.pack(fill="x", padx=20, pady=(0, 8))
        ctk.CTkLabel(xp_card, text=f"{xp_in_level}/500 XP to Level {level + 1}",
                     font=ctk.CTkFont(size=11), text_color=tm.text_secondary).pack(pady=(0, 12))

        # Badges section
        ctk.CTkLabel(self, text="🏅 Badges",
                     font=ctk.CTkFont(size=18, weight="bold"),
                     text_color=tm.text).pack(anchor="w", padx=20, pady=(14, 6))

        earned_keys = {r["badge_key"] for r in db.fetch_all(
            "SELECT badge_key FROM badges WHERE profile_id=?", [self._pid]
        )}

        grid = ctk.CTkFrame(self, fg_color="transparent")
        grid.pack(fill="x", padx=20)
        grid.columnconfigure((0, 1, 2, 3), weight=1)

        for i, (key, (name, icon)) in enumerate(BADGE_DEFINITIONS.items()):
            row_idx, col_idx = divmod(i, 4)
            is_earned = key in earned_keys

            badge_card = ctk.CTkFrame(grid,
                                      fg_color=tm.card if is_earned else tm.surface,
                                      corner_radius=10,
                                      border_width=2 if is_earned else 0,
                                      border_color=tm.highlight if is_earned else tm.border)
            badge_card.grid(row=row_idx, column=col_idx, padx=6, pady=6, sticky="nsew")

            ctk.CTkLabel(badge_card,
                         text=icon if is_earned else "🔒",
                         font=ctk.CTkFont(size=28)).pack(pady=(12, 2))
            ctk.CTkLabel(badge_card,
                         text=name,
                         font=ctk.CTkFont(size=10, weight="bold"),
                         text_color=tm.text if is_earned else tm.text_secondary,
                         wraplength=120, justify="center").pack(pady=(0, 12))

        # Leaderboard
        ctk.CTkLabel(self, text="🥇 Leaderboard",
                     font=ctk.CTkFont(size=18, weight="bold"),
                     text_color=tm.text).pack(anchor="w", padx=20, pady=(20, 6))

        all_profiles = db.get_all_profiles()
        sorted_profiles = sorted(all_profiles, key=lambda p: p["xp"], reverse=True)

        for rank, p in enumerate(sorted_profiles):
            is_me = p["id"] == self._pid
            bc = tm.card if is_me else tm.surface
            lb_card = ctk.CTkFrame(self, fg_color=bc, corner_radius=10,
                                   border_width=2 if is_me else 0,
                                   border_color=tm.primary)
            lb_card.pack(fill="x", padx=20, pady=4)

            row2 = ctk.CTkFrame(lb_card, fg_color="transparent")
            row2.pack(fill="x", padx=14, pady=10)

            medals = ["🥇", "🥈", "🥉"]
            medal = medals[rank] if rank < 3 else f"#{rank+1}"
            ctk.CTkLabel(row2, text=medal, font=ctk.CTkFont(size=22), width=40).pack(side="left")

            ctk.CTkLabel(row2, text=f"{p['avatar'] or '🎓'}  {p['name']}",
                         font=ctk.CTkFont(size=14, weight="bold"),
                         text_color=tm.primary if is_me else tm.text).pack(side="left", padx=10)

            ctk.CTkLabel(row2, text=f"Lvl {p['level']}  |  {p['xp']} XP  |  {p['stream'].capitalize()}",
                         font=ctk.CTkFont(size=12),
                         text_color=tm.text_secondary).pack(side="right")
