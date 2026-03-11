"""
StudentTrack Pro — Phase 13: Buddy / Accountability Partner Module
6-tab module: Friend Dashboard, Side-by-Side Stats, Leaderboard,
Shared Goals, Nudges, Shared Pomodoro.
All data is shared via the local SQLite database — fully offline.
"""

import customtkinter as ctk
from datetime import date, datetime, timedelta
from database import db
from modules.theme_manager import ThemeManager

# ---------------------------------------------------------------------------
# Helper: get the "other" profiles (everyone except current user)
# ---------------------------------------------------------------------------

def _other_profiles(my_pid: int) -> list:
    return [p for p in db.get_all_profiles() if p["id"] != my_pid]


def _stat(parent, label: str, value: str, color: str, tm: ThemeManager):
    f = ctk.CTkFrame(parent, fg_color=tm.surface, corner_radius=8)
    f.pack(fill="x", padx=0, pady=3)
    ctk.CTkLabel(f, text=label, font=ctk.CTkFont(size=11),
                 text_color=tm.text_secondary, anchor="w").pack(side="left", padx=10, pady=8)
    ctk.CTkLabel(f, text=value, font=ctk.CTkFont(size=13, weight="bold"),
                 text_color=color).pack(side="right", padx=10)


# ===========================================================================
# Main Buddy Module
# ===========================================================================

class BuddyModule(ctk.CTkFrame):
    def __init__(self, parent, profile_id: int, tm: ThemeManager, refresh_xp_cb):
        super().__init__(parent, fg_color=tm.background, corner_radius=0)
        self._pid = profile_id
        self._tm = tm
        self._refresh_xp = refresh_xp_cb
        self._build()

    def _build(self):
        tm = self._tm
        others = _other_profiles(self._pid)

        ctk.CTkLabel(self, text="🤝 Buddy & Accountability",
                     font=ctk.CTkFont(size=22, weight="bold"),
                     text_color=tm.primary).pack(anchor="w", padx=20, pady=(20, 4))

        if not others:
            ctk.CTkLabel(self,
                         text="No other profiles yet.\nCreate a second profile for your study buddy!",
                         font=ctk.CTkFont(size=15), text_color=tm.text_secondary,
                         justify="center").pack(expand=True)
            return

        # Check unread nudges and show badge
        unread = db.fetch_one(
            "SELECT COUNT(*) as c FROM nudges WHERE to_profile_id=? AND is_read=0",
            [self._pid]
        )
        unread_count = unread["c"] if unread else 0

        tab_names = [
            "👀 Friend",
            "📊 Compare",
            "🏆 Leaderboard",
            "🎯 Shared Goals",
            f"💪 Nudges{' (' + str(unread_count) + ')' if unread_count else ''}",
            "🍅 Shared Pomo",
        ]

        self._tabs = ctk.CTkTabview(self, fg_color=tm.background,
                                     segmented_button_fg_color=tm.surface,
                                     segmented_button_selected_color=tm.primary,
                                     text_color=tm.text)
        for t in tab_names:
            self._tabs.add(t)
        self._tabs.pack(fill="both", expand=True, padx=16, pady=8)

        FriendDashTab(self._tabs.tab(tab_names[0]), self._pid, tm, others)
        CompareSideBySideTab(self._tabs.tab(tab_names[1]), self._pid, tm, others)
        LeaderboardTab(self._tabs.tab(tab_names[2]), self._pid, tm)
        SharedGoalsTab(self._tabs.tab(tab_names[3]), self._pid, tm, others, self._refresh_xp)
        NudgesTab(self._tabs.tab(tab_names[4]), self._pid, tm, others, self._refresh_xp)
        SharedPomodoroTab(self._tabs.tab(tab_names[5]), self._pid, tm, others, self._refresh_xp)


# ===========================================================================
# Tab 1 — Friend's Dashboard
# ===========================================================================

class FriendDashTab(ctk.CTkScrollableFrame):
    def __init__(self, parent, my_pid: int, tm: ThemeManager, others: list):
        super().__init__(parent, fg_color=tm.background, corner_radius=0)
        self._pid = my_pid
        self._tm = tm
        self._build(others)

    def _build(self, others):
        tm = self._tm
        today = date.today().isoformat()

        for friend in others:
            fid = friend["id"]
            ftm = ThemeManager(friend["stream"], dark_mode=True)

            # Profile card
            card = ctk.CTkFrame(self, fg_color=tm.card, corner_radius=14,
                                border_width=2, border_color=ftm.primary)
            card.pack(fill="x", padx=20, pady=10)

            # Header row
            hdr = ctk.CTkFrame(card, fg_color="transparent")
            hdr.pack(fill="x", padx=16, pady=(14, 6))
            ctk.CTkLabel(hdr, text=friend["avatar"] or "👤",
                         font=ctk.CTkFont(size=40)).pack(side="left")

            info = ctk.CTkFrame(hdr, fg_color="transparent")
            info.pack(side="left", padx=12)
            ctk.CTkLabel(info, text=friend["name"],
                         font=ctk.CTkFont(size=18, weight="bold"),
                         text_color=ftm.primary).pack(anchor="w")
            ctk.CTkLabel(info, text=f"{friend['stream'].capitalize()}  ·  Level {friend['level']}  ·  {friend['xp']} XP",
                         font=ctk.CTkFont(size=12), text_color=tm.text_secondary).pack(anchor="w")

            # XP bar
            xp_bar = ctk.CTkProgressBar(card, height=6, fg_color=tm.surface2,
                                         progress_color=ftm.primary)
            xp_bar.set((friend["xp"] % 500) / 500)
            xp_bar.pack(fill="x", padx=16, pady=(0, 8))

            # Today stats
            ctk.CTkLabel(card, text="Today at a glance",
                         font=ctk.CTkFont(size=13, weight="bold"),
                         text_color=tm.text).pack(anchor="w", padx=16, pady=(4, 2))

            stats_frame = ctk.CTkFrame(card, fg_color="transparent")
            stats_frame.pack(fill="x", padx=16, pady=(0, 10))

            tasks_done = db.fetch_one(
                "SELECT COUNT(*) as c FROM todos WHERE profile_id=? AND is_completed=1 AND completed_at LIKE ?",
                [fid, f"{today}%"]
            )
            tasks_total = db.fetch_one(
                "SELECT COUNT(*) as c FROM todos WHERE profile_id=? AND is_completed=0 AND (due_date=? OR due_date IS NULL)",
                [fid, today]
            )
            habits_done = db.fetch_one(
                "SELECT COUNT(*) as c FROM habit_logs hl JOIN habits h ON hl.habit_id=h.id "
                "WHERE h.profile_id=? AND hl.date=? AND hl.is_done=1",
                [fid, today]
            )
            habits_total = db.fetch_one(
                "SELECT COUNT(*) as c FROM habits WHERE profile_id=? AND is_archived=0", [fid]
            )
            poms_today = db.fetch_one(
                "SELECT SUM(cycles_completed) as s FROM pomodoro_sessions WHERE profile_id=? AND date=?",
                [fid, today]
            )
            mood_today = db.fetch_one(
                "SELECT mood FROM health_logs WHERE profile_id=? AND date=?", [fid, today]
            )
            water_today = db.fetch_one(
                "SELECT water_glasses FROM health_logs WHERE profile_id=? AND date=?", [fid, today]
            )
            habits = db.fetch_all("SELECT current_streak FROM habits WHERE profile_id=? AND is_archived=0", [fid])
            max_streak = max((h["current_streak"] for h in habits), default=0)

            mood_emojis = {1: "😞", 2: "😕", 3: "😐", 4: "😊", 5: "😄"}
            mood_v = mood_today["mood"] if mood_today and mood_today["mood"] else None
            mood_str = mood_emojis.get(mood_v, "—") if mood_v else "—"
            water_v = water_today["water_glasses"] if water_today and water_today["water_glasses"] else 0
            poms_v = poms_today["s"] if poms_today and poms_today["s"] else 0
            td_v = tasks_done["c"] if tasks_done else 0
            tt_v = tasks_total["c"] if tasks_total else 0
            hd_v = habits_done["c"] if habits_done else 0
            ht_v = habits_total["c"] if habits_total else 0

            items = [
                ("✅ Tasks", f"{td_v} done / {tt_v} due"),
                ("🔁 Habits", f"{hd_v}/{ht_v} done"),
                ("🍅 Pomodoros", str(poms_v)),
                ("🔥 Streak", f"{max_streak} days"),
                ("😊 Mood", mood_str),
                ("💧 Water", f"{water_v}/8"),
            ]
            cols_f = ctk.CTkFrame(stats_frame, fg_color="transparent")
            cols_f.pack(fill="x")
            cols_f.columnconfigure((0, 1, 2), weight=1)
            for i, (label, val) in enumerate(items):
                c = ctk.CTkFrame(cols_f, fg_color=tm.surface, corner_radius=8)
                c.grid(row=i // 3, column=i % 3, padx=4, pady=3, sticky="nsew")
                ctk.CTkLabel(c, text=label, font=ctk.CTkFont(size=10),
                             text_color=tm.text_secondary).pack(pady=(6, 0))
                ctk.CTkLabel(c, text=val, font=ctk.CTkFont(size=13, weight="bold"),
                             text_color=ftm.primary).pack(pady=(0, 6))

            # Hasn't studied notice
            if poms_v == 0 and td_v == 0:
                ctk.CTkLabel(card,
                             text=f"🌙 {friend['name']} hasn't studied yet today — send a nudge!",
                             font=ctk.CTkFont(size=12, slant="italic"),
                             text_color=tm.warning).pack(pady=(0, 10))


# ===========================================================================
# Tab 2 — Side-by-Side Stats Comparison
# ===========================================================================

class CompareSideBySideTab(ctk.CTkScrollableFrame):
    def __init__(self, parent, my_pid: int, tm: ThemeManager, others: list):
        super().__init__(parent, fg_color=tm.background, corner_radius=0)
        self._pid = my_pid
        self._tm = tm
        self._build(others)

    def _build(self, others):
        tm = self._tm
        me = dict(db.get_profile(self._pid))
        my_tm = ThemeManager(me["stream"], dark_mode=True)
        friend = dict(others[0])  # compare with first other
        ftm = ThemeManager(friend["stream"], dark_mode=True)

        today = date.today()
        week_start = (today - timedelta(days=today.weekday())).isoformat()

        def week_xp(pid):
            r = db.fetch_one("SELECT SUM(amount) as s FROM xp_logs WHERE profile_id=? AND earned_at>=?",
                              [pid, week_start])
            return r["s"] if r and r["s"] else 0

        def week_tasks(pid):
            r = db.fetch_one("SELECT COUNT(*) as c FROM todos WHERE profile_id=? AND is_completed=1 AND completed_at>=?",
                              [pid, week_start])
            return r["c"] if r else 0

        def pom_today(pid):
            r = db.fetch_one("SELECT SUM(cycles_completed) as s FROM pomodoro_sessions WHERE profile_id=? AND date=?",
                              [pid, today.isoformat()])
            return r["s"] if r and r["s"] else 0

        def avg_sleep(pid):
            r = db.fetch_one(
                "SELECT AVG(sleep_hours) as a FROM health_logs WHERE profile_id=? AND sleep_hours IS NOT NULL AND date>=?",
                [pid, (today - timedelta(days=7)).isoformat()])
            v = r["a"] if r and r["a"] else 0
            return round(v, 1)

        def max_streak(pid):
            rows = db.fetch_all("SELECT current_streak FROM habits WHERE profile_id=? AND is_archived=0", [pid])
            return max((r["current_streak"] for r in rows), default=0)

        def water_today(pid):
            r = db.fetch_one("SELECT water_glasses FROM health_logs WHERE profile_id=? AND date=?",
                              [pid, today.isoformat()])
            return r["water_glasses"] if r and r["water_glasses"] else 0

        def habit_rate(pid):
            total = db.fetch_one("SELECT COUNT(*) as c FROM habits WHERE profile_id=? AND is_archived=0", [pid])
            done = db.fetch_one(
                "SELECT COUNT(*) as c FROM habit_logs hl JOIN habits h ON hl.habit_id=h.id "
                "WHERE h.profile_id=? AND hl.is_done=1 AND hl.date>=?",
                [pid, week_start])
            t = total["c"] if total else 1
            d = done["c"] if done else 0
            days = 7
            return round(d / (t * days) * 100) if t > 0 else 0

        rows = [
            ("Level",          me["level"],                friend["level"],            ">"),
            ("Total XP",       me["xp"],                   friend["xp"],               ">"),
            ("Study Streak 🔥", f"{max_streak(self._pid)}d", f"{max_streak(friend['id'])}d", ">"),
            ("Tasks This Week", week_tasks(self._pid),      week_tasks(friend["id"]),   ">"),
            ("Habit Score",    f"{habit_rate(self._pid)}%", f"{habit_rate(friend['id'])}%", ">"),
            ("Pomodoros Today", pom_today(self._pid),       pom_today(friend["id"]),    ">"),
            ("Avg Sleep (7d)", f"{avg_sleep(self._pid)}h",  f"{avg_sleep(friend['id'])}h", ">"),
            ("Water Today 💧", f"{water_today(self._pid)}/8", f"{water_today(friend['id'])}/8", ">"),
        ]

        # Header
        hdr = ctk.CTkFrame(self, fg_color=tm.surface, corner_radius=10)
        hdr.pack(fill="x", padx=20, pady=(10, 0))
        hdr.columnconfigure((0, 1, 2), weight=1)
        ctk.CTkLabel(hdr, text=f"{me['avatar'] or '👤'} {me['name']}",
                     font=ctk.CTkFont(size=14, weight="bold"),
                     text_color=my_tm.primary).grid(row=0, column=0, padx=10, pady=10)
        ctk.CTkLabel(hdr, text="vs", font=ctk.CTkFont(size=13),
                     text_color=tm.text_secondary).grid(row=0, column=1)
        ctk.CTkLabel(hdr, text=f"{friend['avatar'] or '👤'} {friend['name']}",
                     font=ctk.CTkFont(size=14, weight="bold"),
                     text_color=ftm.primary).grid(row=0, column=2, padx=10)

        for label, my_val, fr_val, cmp in rows:
            row_f = ctk.CTkFrame(self, fg_color=tm.card, corner_radius=8)
            row_f.pack(fill="x", padx=20, pady=3)
            row_f.columnconfigure((0, 1, 2), weight=1)

            try:
                my_n = float(str(my_val).replace("%", "").replace("d", "").replace("h", ""))
                fr_n = float(str(fr_val).replace("%", "").replace("d", "").replace("h", ""))
                my_col = my_tm.primary if my_n >= fr_n else tm.text_secondary
                fr_col = ftm.primary if fr_n >= my_n else tm.text_secondary
            except Exception:
                my_col = my_tm.primary
                fr_col = ftm.primary

            ctk.CTkLabel(row_f, text=str(my_val), font=ctk.CTkFont(size=14, weight="bold"),
                         text_color=my_col).grid(row=0, column=0, padx=10, pady=10)
            ctk.CTkLabel(row_f, text=label, font=ctk.CTkFont(size=11),
                         text_color=tm.text_secondary).grid(row=0, column=1)
            ctk.CTkLabel(row_f, text=str(fr_val), font=ctk.CTkFont(size=14, weight="bold"),
                         text_color=fr_col).grid(row=0, column=2, padx=10)

        # Motivation caption
        my_xp = me["xp"]
        fr_xp = friend["xp"]
        if my_xp > fr_xp + 100:
            caption = "You're leading! Keep the pressure on 💪"
        elif fr_xp > my_xp + 100:
            caption = f"{friend['name']} is pulling ahead — time to catch up! 🔥"
        else:
            caption = "You're neck and neck — who blinks first? 👀"

        ctk.CTkLabel(self, text=caption, font=ctk.CTkFont(size=14, slant="italic"),
                     text_color=tm.highlight).pack(pady=14)


# ===========================================================================
# Tab 3 — Leaderboard
# ===========================================================================

class LeaderboardTab(ctk.CTkScrollableFrame):
    def __init__(self, parent, my_pid: int, tm: ThemeManager):
        super().__init__(parent, fg_color=tm.background, corner_radius=0)
        self._pid = my_pid
        self._tm = tm
        self._build()

    def _build(self):
        tm = self._tm
        today = date.today()
        week_start = (today - timedelta(days=today.weekday())).isoformat()
        month_start = today.replace(day=1).isoformat()

        categories = {
            "⭐ Overall XP": lambda p: p["xp"],
            "📅 This Week XP": lambda p: (db.fetch_one(
                "SELECT SUM(amount) as s FROM xp_logs WHERE profile_id=? AND earned_at>=?",
                [p["id"], week_start]) or {}).get("s") or 0,
            "🍅 Study Hours": lambda p: (db.fetch_one(
                "SELECT SUM(total_focus_minutes) as s FROM pomodoro_sessions WHERE profile_id=?",
                [p["id"]]) or {}).get("s") or 0,
            "✅ Task Master": lambda p: (db.fetch_one(
                "SELECT COUNT(*) as c FROM todos WHERE profile_id=? AND is_completed=1 AND completed_at>=?",
                [p["id"], month_start]) or {}).get("c") or 0,
            "🔥 Streak Lord": lambda p: max(
                (r["current_streak"] for r in db.fetch_all(
                    "SELECT current_streak FROM habits WHERE profile_id=? AND is_archived=0", [p["id"]])),
                default=0),
        }

        all_profiles = db.get_all_profiles()
        medals = ["🥇", "🥈", "🥉"]

        for cat_name, key_fn in categories.items():
            ctk.CTkLabel(self, text=cat_name,
                         font=ctk.CTkFont(size=15, weight="bold"),
                         text_color=tm.text).pack(anchor="w", padx=20, pady=(14, 4))

            sorted_profiles = sorted(all_profiles, key=key_fn, reverse=True)
            for rank, p in enumerate(sorted_profiles):
                is_me = p["id"] == self._pid
                ptm = ThemeManager(p["stream"], dark_mode=True)
                val = key_fn(p)

                row = ctk.CTkFrame(self,
                                   fg_color=tm.card if is_me else tm.surface,
                                   corner_radius=8,
                                   border_width=2 if is_me else 0,
                                   border_color=ptm.primary)
                row.pack(fill="x", padx=20, pady=2)

                inner = ctk.CTkFrame(row, fg_color="transparent")
                inner.pack(fill="x", padx=12, pady=8)

                ctk.CTkLabel(inner, text=medals[rank] if rank < 3 else f"#{rank+1}",
                             font=ctk.CTkFont(size=20), width=36).pack(side="left")
                ctk.CTkLabel(inner, text=f"{p['avatar'] or '👤'} {p['name']}",
                             font=ctk.CTkFont(size=13, weight="bold"),
                             text_color=ptm.primary).pack(side="left", padx=8)
                ctk.CTkLabel(inner, text=str(val),
                             font=ctk.CTkFont(size=14, weight="bold"),
                             text_color=tm.highlight).pack(side="right")


# ===========================================================================
# Tab 4 — Shared Goals
# ===========================================================================

class SharedGoalsTab(ctk.CTkScrollableFrame):
    def __init__(self, parent, my_pid: int, tm: ThemeManager, others: list, refresh_xp_cb):
        super().__init__(parent, fg_color=tm.background, corner_radius=0)
        self._pid = my_pid
        self._tm = tm
        self._others = others
        self._refresh_xp = refresh_xp_cb
        self._build()

    def _build(self):
        tm = self._tm

        ctk.CTkButton(self, text="+ Create Shared Goal", height=40, corner_radius=10,
                      fg_color=tm.primary, hover_color=tm.secondary,
                      command=self._create_goal).pack(padx=20, pady=10)

        goals = db.fetch_all("SELECT sg.*, p.name as creator_name FROM shared_goals sg "
                              "JOIN profiles p ON sg.created_by_profile_id=p.id "
                              "WHERE sg.is_completed=0 ORDER BY sg.deadline", [])

        if not goals:
            ctk.CTkLabel(self, text="No shared goals yet.\nCreate one together! 🎯",
                         font=ctk.CTkFont(size=14), text_color=tm.text_secondary,
                         justify="center").pack(pady=40)
            return

        ctk.CTkLabel(self, text="Active Shared Goals",
                     font=ctk.CTkFont(size=15, weight="bold"),
                     text_color=tm.text).pack(anchor="w", padx=20, pady=(8, 4))

        for g in goals:
            members = db.fetch_all(
                "SELECT sgm.*, p.name, p.avatar, p.stream, sgm.contribution_percent "
                "FROM shared_goal_members sgm JOIN profiles p ON sgm.profile_id=p.id "
                "WHERE sgm.shared_goal_id=?", [g["id"]])

            card = ctk.CTkFrame(self, fg_color=tm.card, corner_radius=12,
                                border_width=1, border_color=tm.border)
            card.pack(fill="x", padx=20, pady=6)

            hdr = ctk.CTkFrame(card, fg_color="transparent")
            hdr.pack(fill="x", padx=14, pady=(12, 4))

            ctk.CTkLabel(hdr, text=g["title"],
                         font=ctk.CTkFont(size=15, weight="bold"),
                         text_color=tm.text).pack(side="left")
            if g["deadline"]:
                try:
                    days_left = (date.fromisoformat(g["deadline"]) - date.today()).days
                    ctk.CTkLabel(hdr, text=f"⏰ {days_left}d left",
                                 font=ctk.CTkFont(size=11),
                                 text_color=tm.warning if days_left < 7 else tm.text_secondary
                                 ).pack(side="right")
                except Exception:
                    pass

            pb = ctk.CTkProgressBar(card, height=8, fg_color=tm.surface2,
                                     progress_color=tm.primary)
            pb.set((g["progress_percent"] or 0) / 100)
            pb.pack(fill="x", padx=14, pady=4)

            # Member contributions
            for m in members:
                m_row = ctk.CTkFrame(card, fg_color="transparent")
                m_row.pack(fill="x", padx=14, pady=1)
                ctk.CTkLabel(m_row, text=f"{m['avatar'] or '👤'} {m['name']}",
                             font=ctk.CTkFont(size=11), text_color=tm.text_secondary).pack(side="left")
                ctk.CTkLabel(m_row, text=f"{m['contribution_percent']}%",
                             font=ctk.CTkFont(size=11, weight="bold"),
                             text_color=tm.primary).pack(side="right")

            ctk.CTkLabel(card, text=f"Created by {g['creator_name']}",
                         font=ctk.CTkFont(size=10), text_color=tm.text_secondary).pack(anchor="w", padx=14, pady=(0, 10))

        # Completed
        done_goals = db.fetch_all(
            "SELECT * FROM shared_goals WHERE is_completed=1 ORDER BY created_at DESC LIMIT 5", [])
        if done_goals:
            ctk.CTkLabel(self, text="✅ Completed Shared Goals",
                         font=ctk.CTkFont(size=14, weight="bold"),
                         text_color=tm.success).pack(anchor="w", padx=20, pady=(16, 4))
            for g in done_goals:
                df = ctk.CTkFrame(self, fg_color=tm.surface, corner_radius=8)
                df.pack(fill="x", padx=20, pady=3)
                ctk.CTkLabel(df, text=f"✅  {g['title']}",
                             font=ctk.CTkFont(size=12), text_color=tm.text).pack(side="left", padx=12, pady=8)

    def _create_goal(self):
        dialog = ctk.CTkToplevel(self)
        dialog.title("Create Shared Goal")
        dialog.geometry("440x320")
        dialog.grab_set()
        tm = self._tm

        ctk.CTkLabel(dialog, text="🎯 New Shared Goal",
                     font=ctk.CTkFont(size=18, weight="bold"),
                     text_color=tm.primary).pack(pady=(20, 10))

        title_var = ctk.StringVar()
        ctk.CTkEntry(dialog, textvariable=title_var, placeholder_text="Goal title…",
                     width=360, height=36, fg_color=tm.surface,
                     border_color=tm.border, text_color=tm.text,
                     corner_radius=8).pack(pady=6)

        desc_var = ctk.StringVar()
        ctk.CTkEntry(dialog, textvariable=desc_var, placeholder_text="Description (optional)…",
                     width=360, height=36, fg_color=tm.surface,
                     border_color=tm.border, text_color=tm.text,
                     corner_radius=8).pack(pady=6)

        deadline_var = ctk.StringVar()
        ctk.CTkEntry(dialog, textvariable=deadline_var, placeholder_text="Deadline YYYY-MM-DD…",
                     width=200, height=36, fg_color=tm.surface,
                     border_color=tm.border, text_color=tm.text,
                     corner_radius=8).pack(pady=6)

        def save():
            if not title_var.get().strip():
                return
            gid = db.insert("shared_goals", {
                "title": title_var.get().strip(),
                "description": desc_var.get().strip(),
                "deadline": deadline_var.get().strip() or None,
                "created_by_profile_id": self._pid,
            })
            # Add all profiles as members
            for p in db.get_all_profiles():
                db.insert("shared_goal_members", {
                    "shared_goal_id": gid,
                    "profile_id": p["id"],
                    "contribution_percent": 0,
                })
            db.award_xp(self._pid, 10, "Created shared goal")
            self._refresh_xp()
            dialog.destroy()
            # Refresh view
            for w in self.winfo_children():
                w.destroy()
            self._build()

        ctk.CTkButton(dialog, text="Create Goal", width=200, height=40,
                      fg_color=tm.primary, corner_radius=10,
                      command=save).pack(pady=16)


# ===========================================================================
# Tab 5 — Nudges
# ===========================================================================

class NudgesTab(ctk.CTkScrollableFrame):
    def __init__(self, parent, my_pid: int, tm: ThemeManager, others: list, refresh_xp_cb):
        super().__init__(parent, fg_color=tm.background, corner_radius=0)
        self._pid = my_pid
        self._tm = tm
        self._others = others
        self._refresh_xp = refresh_xp_cb
        self._build()

    def _build(self):
        tm = self._tm
        others = self._others

        # Send section
        ctk.CTkLabel(self, text="💪 Send a Nudge",
                     font=ctk.CTkFont(size=15, weight="bold"),
                     text_color=tm.text).pack(anchor="w", padx=20, pady=(14, 6))

        send_card = ctk.CTkFrame(self, fg_color=tm.card, corner_radius=12)
        send_card.pack(fill="x", padx=20, pady=4)

        templates = [
            ("💪", "Keep going, you've got this!"),
            ("🔥", "Your streak is on fire!"),
            ("📚", "Time to study!"),
            ("😴", "Don't forget to sleep!"),
            ("💧", "Drink some water!"),
            ("🍅", "Let's do a Pomodoro together!"),
            ("🎯", "Work on our shared goal today!"),
        ]

        btn_frame = ctk.CTkFrame(send_card, fg_color="transparent")
        btn_frame.pack(fill="x", padx=14, pady=10)

        self._custom_var = ctk.StringVar()
        ctk.CTkEntry(send_card, textvariable=self._custom_var,
                     placeholder_text="Or type a custom message (max 100 chars)…",
                     width=360, height=34, fg_color=tm.surface,
                     border_color=tm.border, text_color=tm.text,
                     corner_radius=8).pack(padx=14, pady=(0, 8))

        # Quick template buttons
        row = ctk.CTkFrame(send_card, fg_color="transparent")
        row.pack(fill="x", padx=14, pady=(0, 10))
        for emoji, msg in templates:
            ctk.CTkButton(row, text=emoji, width=40, height=36,
                          fg_color=tm.surface, hover_color=tm.primary,
                          corner_radius=8,
                          command=lambda e=emoji, m=msg: self._send_nudge(others[0]["id"], m, e)
                          ).pack(side="left", padx=2)

        ctk.CTkButton(send_card, text="📤 Send Custom",
                      width=180, height=36, fg_color=tm.primary,
                      corner_radius=8,
                      command=lambda: self._send_nudge(
                          others[0]["id"],
                          self._custom_var.get()[:100],
                          "💪"
                      )).pack(pady=(0, 10))

        # Inbox
        ctk.CTkLabel(self, text="📥 Received Nudges",
                     font=ctk.CTkFont(size=15, weight="bold"),
                     text_color=tm.text).pack(anchor="w", padx=20, pady=(16, 4))

        received = db.fetch_all(
            "SELECT n.*, p.name as sender_name, p.avatar as sender_avatar, p.stream as sender_stream "
            "FROM nudges n JOIN profiles p ON n.from_profile_id=p.id "
            "WHERE n.to_profile_id=? ORDER BY n.sent_at DESC LIMIT 20",
            [self._pid]
        )

        if not received:
            ctk.CTkLabel(self, text="No nudges yet! Your buddy will cheer you on soon.",
                         font=ctk.CTkFont(size=12), text_color=tm.text_secondary).pack(padx=20)
        else:
            for n in received:
                stm = ThemeManager(n["sender_stream"], dark_mode=True)
                is_unread = not n["is_read"]
                nc = ctk.CTkFrame(self,
                                  fg_color=tm.card if is_unread else tm.surface,
                                  corner_radius=10,
                                  border_width=2 if is_unread else 0,
                                  border_color=stm.primary)
                nc.pack(fill="x", padx=20, pady=3)

                row2 = ctk.CTkFrame(nc, fg_color="transparent")
                row2.pack(fill="x", padx=12, pady=8)
                ctk.CTkLabel(row2, text=n["emoji"] or "💪",
                             font=ctk.CTkFont(size=24), width=36).pack(side="left")
                ctk.CTkLabel(row2, text=n["message"],
                             font=ctk.CTkFont(size=12), text_color=tm.text,
                             anchor="w", wraplength=300).pack(side="left", padx=8)
                ctk.CTkLabel(row2, text=f"— {n['sender_name']}",
                             font=ctk.CTkFont(size=10), text_color=stm.primary).pack(side="right")

                if is_unread:
                    db.update("nudges", {"is_read": 1}, {"id": n["id"]})

        # Sent nudges
        ctk.CTkLabel(self, text="📤 Sent Nudges",
                     font=ctk.CTkFont(size=14, weight="bold"),
                     text_color=tm.text_secondary).pack(anchor="w", padx=20, pady=(14, 4))

        sent = db.fetch_all(
            "SELECT n.*, p.name as to_name FROM nudges n JOIN profiles p ON n.to_profile_id=p.id "
            "WHERE n.from_profile_id=? ORDER BY n.sent_at DESC LIMIT 10",
            [self._pid]
        )
        for n in sent:
            sf = ctk.CTkFrame(self, fg_color=tm.surface, corner_radius=8)
            sf.pack(fill="x", padx=20, pady=2)
            row3 = ctk.CTkFrame(sf, fg_color="transparent")
            row3.pack(fill="x", padx=10, pady=6)
            ctk.CTkLabel(row3, text=n["emoji"] or "💪",
                         font=ctk.CTkFont(size=16)).pack(side="left")
            ctk.CTkLabel(row3, text=f"To {n['to_name']}: {n['message'][:50]}",
                         font=ctk.CTkFont(size=11), text_color=tm.text_secondary).pack(side="left", padx=6)

    def _send_nudge(self, to_pid: int, msg: str, emoji: str = "💪"):
        if not msg.strip():
            return
        db.insert("nudges", {
            "from_profile_id": self._pid,
            "to_profile_id": to_pid,
            "message": msg[:100],
            "emoji": emoji,
        })
        db.award_xp(self._pid, 2, "Sent a nudge")
        db.check_and_award_badges(self._pid)
        self._refresh_xp()
        # Check first nudge badge
        nudge_count = db.fetch_one("SELECT COUNT(*) as c FROM nudges WHERE from_profile_id=?", [self._pid])
        if nudge_count and nudge_count["c"] >= 1:
            if db.award_badge(self._pid, "first_nudge"):
                pass  # badge popup handled by refresh_xp → check_and_award_badges

        self._custom_var.set("")
        for w in self.winfo_children():
            w.destroy()
        self._build()


# ===========================================================================
# Tab 6 — Shared Pomodoro
# ===========================================================================

class SharedPomodoroTab(ctk.CTkFrame):
    def __init__(self, parent, my_pid: int, tm: ThemeManager, others: list, refresh_xp_cb):
        super().__init__(parent, fg_color=tm.background, corner_radius=0)
        self._pid = my_pid
        self._tm = tm
        self._others = others
        self._refresh_xp = refresh_xp_cb
        self._timer_running = False
        self._time_left = 0
        self._after_id = None
        self._session_id = None
        self._pack_frame()
        self._build()

    def _pack_frame(self):
        self.pack(fill="both", expand=True)

    def _build(self):
        for w in self.winfo_children():
            w.destroy()

        tm = self._tm
        others = self._others

        # Check for active session
        active = db.fetch_one(
            "SELECT sp.* FROM shared_pomodoro sp "
            "JOIN shared_pomodoro_members spm ON sp.id=spm.session_id "
            "WHERE sp.is_active=1 AND spm.profile_id=?",
            [self._pid]
        )

        if active:
            self._session_id = active["id"]
            self._show_active_session(active)
        else:
            self._show_start_ui()

    def _show_start_ui(self):
        tm = self._tm
        others = self._others

        ctk.CTkLabel(self, text="🍅 Shared Pomodoro",
                     font=ctk.CTkFont(size=20, weight="bold"),
                     text_color=tm.primary).pack(pady=(30, 8))
        ctk.CTkLabel(self, text="Study together in sync — both timers run from the same session",
                     font=ctk.CTkFont(size=12), text_color=tm.text_secondary).pack()

        card = ctk.CTkFrame(self, fg_color=tm.card, corner_radius=14)
        card.pack(padx=60, pady=20, fill="x")

        ctk.CTkLabel(card, text="Start a Session",
                     font=ctk.CTkFont(size=16, weight="bold"),
                     text_color=tm.text).pack(pady=(16, 8))

        row1 = ctk.CTkFrame(card, fg_color="transparent")
        row1.pack(pady=4)
        ctk.CTkLabel(row1, text="Subject:", font=ctk.CTkFont(size=12),
                     text_color=tm.text_secondary).pack(side="left")
        self._subj_var = ctk.StringVar(value="Study Session")
        ctk.CTkEntry(row1, textvariable=self._subj_var, width=200, height=32,
                     fg_color=tm.surface, border_color=tm.border, text_color=tm.text,
                     corner_radius=6).pack(side="left", padx=8)

        row2 = ctk.CTkFrame(card, fg_color="transparent")
        row2.pack(pady=4)
        ctk.CTkLabel(row2, text="Work (min):", font=ctk.CTkFont(size=12),
                     text_color=tm.text_secondary).pack(side="left")
        self._work_var = ctk.StringVar(value="25")
        ctk.CTkEntry(row2, textvariable=self._work_var, width=60, height=32,
                     fg_color=tm.surface, border_color=tm.border, text_color=tm.text,
                     corner_radius=6).pack(side="left", padx=8)
        ctk.CTkLabel(row2, text="Break (min):", font=ctk.CTkFont(size=12),
                     text_color=tm.text_secondary).pack(side="left", padx=(12, 0))
        self._break_var = ctk.StringVar(value="5")
        ctk.CTkEntry(row2, textvariable=self._break_var, width=60, height=32,
                     fg_color=tm.surface, border_color=tm.border, text_color=tm.text,
                     corner_radius=6).pack(side="left", padx=8)

        ctk.CTkButton(card, text="🍅 Start & Invite Buddy", width=240, height=44,
                      fg_color=tm.primary, hover_color=tm.secondary, corner_radius=10,
                      font=ctk.CTkFont(size=14, weight="bold"),
                      command=self._start_session).pack(pady=16)

        # Check if there's already a session we can JOIN (started by someone else)
        joinable = db.fetch_one(
            "SELECT sp.*, p.name as starter_name FROM shared_pomodoro sp "
            "JOIN profiles p ON sp.initiated_by_profile_id=p.id "
            "WHERE sp.is_active=1 AND sp.initiated_by_profile_id != ?",
            [self._pid]
        )
        if joinable:
            banner = ctk.CTkFrame(self, fg_color=tm.success, corner_radius=10)
            banner.pack(fill="x", padx=20, pady=8)
            row = ctk.CTkFrame(banner, fg_color="transparent")
            row.pack(fill="x", padx=14, pady=10)
            ctk.CTkLabel(row, text=f"🍅 {joinable['starter_name']} is studying right now!",
                         font=ctk.CTkFont(size=13, weight="bold"),
                         text_color="white").pack(side="left")
            ctk.CTkButton(row, text="JOIN →", width=80, height=30,
                          fg_color="white", text_color=tm.success, corner_radius=6,
                          command=lambda sid=joinable["id"]: self._join_session(sid)
                          ).pack(side="right")

        # History
        ctk.CTkLabel(self, text="📋 Session History",
                     font=ctk.CTkFont(size=14, weight="bold"),
                     text_color=tm.text_secondary).pack(anchor="w", padx=20, pady=(16, 4))

        sessions = db.fetch_all(
            "SELECT sp.*, p.name as starter FROM shared_pomodoro sp "
            "JOIN profiles p ON sp.initiated_by_profile_id=p.id "
            "WHERE sp.is_active=0 ORDER BY sp.started_at DESC LIMIT 10", []
        )
        for s in sessions:
            sf = ctk.CTkFrame(self, fg_color=tm.surface, corner_radius=8)
            sf.pack(fill="x", padx=20, pady=2)
            ctk.CTkLabel(sf,
                         text=f"🍅 {s['subject'] or 'Study'}  ·  {s['work_duration']}min  ·  by {s['starter']}  ·  {s['started_at'][:10]}",
                         font=ctk.CTkFont(size=11), text_color=tm.text_secondary).pack(padx=10, pady=8, anchor="w")

    def _start_session(self):
        try:
            work = int(self._work_var.get())
            brk = int(self._break_var.get())
        except ValueError:
            work, brk = 25, 5

        sid = db.insert("shared_pomodoro", {
            "initiated_by_profile_id": self._pid,
            "subject": self._subj_var.get().strip(),
            "work_duration": work,
            "break_duration": brk,
            "is_active": 1,
        })
        # Add initiator as member
        db.insert("shared_pomodoro_members", {
            "session_id": sid, "profile_id": self._pid, "cycles_completed": 0
        })
        # Send nudge to others
        for other in self._others:
            db.insert("nudges", {
                "from_profile_id": self._pid,
                "to_profile_id": other["id"],
                "message": f"{db.get_profile(self._pid)['name']} started a study session — join them!",
                "emoji": "🍅",
            })
        self._session_id = sid
        self._build()

    def _join_session(self, sid: int):
        # Check if already member
        existing = db.fetch_one(
            "SELECT id FROM shared_pomodoro_members WHERE session_id=? AND profile_id=?",
            [sid, self._pid]
        )
        if not existing:
            db.insert("shared_pomodoro_members", {
                "session_id": sid, "profile_id": self._pid, "cycles_completed": 0
            })
        self._session_id = sid
        self._build()

    def _show_active_session(self, session):
        tm = self._tm
        work_mins = session["work_duration"]

        # Participants
        members = db.fetch_all(
            "SELECT spm.*, p.name, p.avatar, p.stream, spm.cycles_completed "
            "FROM shared_pomodoro_members spm JOIN profiles p ON spm.profile_id=p.id "
            "WHERE spm.session_id=?", [session["id"]]
        )
        avatars = " + ".join(f"{m['avatar'] or '👤'} {m['name']}" for m in members)
        ctk.CTkLabel(self, text=f"🍅 {avatars}  studying together",
                     font=ctk.CTkFont(size=14, weight="bold"),
                     text_color=tm.primary).pack(pady=(24, 4))
        ctk.CTkLabel(self, text=f"Subject: {session['subject'] or 'Study Session'}",
                     font=ctk.CTkFont(size=12), text_color=tm.text_secondary).pack()

        # Circular timer canvas
        self._canvas = ctk.CTkCanvas(self, width=220, height=220,
                                      bg=tm.background, highlightthickness=0)
        self._canvas.pack(pady=16)
        self._time_left = work_mins * 60
        self._phase = "work"
        self._draw_timer(work_mins * 60, work_mins * 60)

        # Timer label
        self._timer_lbl = ctk.CTkLabel(self, text=f"{work_mins:02d}:00",
                                        font=ctk.CTkFont(size=40, weight="bold"),
                                        text_color=tm.primary)
        self._timer_lbl.pack()

        # Cycles per member
        for m in members:
            ctk.CTkLabel(self,
                         text=f"{m['avatar'] or '👤'} {m['name']}: {m['cycles_completed']} cycles",
                         font=ctk.CTkFont(size=12), text_color=tm.text_secondary).pack()

        btn_row = ctk.CTkFrame(self, fg_color="transparent")
        btn_row.pack(pady=12)

        ctk.CTkButton(btn_row, text="▶ Start", width=110, height=40,
                      fg_color=tm.primary, corner_radius=10,
                      command=self._start_timer).pack(side="left", padx=6)
        ctk.CTkButton(btn_row, text="⏹ End Session", width=130, height=40,
                      fg_color=tm.danger, corner_radius=10,
                      command=self._end_session).pack(side="left", padx=6)

    def _draw_timer(self, remaining: int, total: int):
        if not hasattr(self, "_canvas"):
            return
        pct = remaining / total if total > 0 else 0
        c = self._canvas
        c.delete("all")
        tm = self._tm
        cx, cy, r = 110, 110, 90
        c.create_oval(cx-r, cy-r, cx+r, cy+r, outline=tm.surface2, width=12)
        import math
        extent = pct * 359.9
        c.create_arc(cx-r, cy-r, cx+r, cy+r,
                     start=90, extent=extent,
                     outline=tm.primary, width=12, style="arc")

    def _start_timer(self):
        if not self._timer_running:
            self._timer_running = True
            self._tick()

    def _tick(self):
        if not self._timer_running or self._time_left <= 0:
            self._timer_running = False
            self._on_phase_end()
            return
        self._time_left -= 1
        m, s = divmod(self._time_left, 60)
        if hasattr(self, "_timer_lbl"):
            self._timer_lbl.configure(text=f"{m:02d}:{s:02d}")
        session = db.fetch_one("SELECT * FROM shared_pomodoro WHERE id=?", [self._session_id])
        total = (session["work_duration"] if self._phase == "work" else session["break_duration"]) * 60 if session else 25*60
        self._draw_timer(self._time_left, total)
        self._after_id = self.after(1000, self._tick)

    def _on_phase_end(self):
        # Award XP to all members
        members = db.fetch_all(
            "SELECT profile_id FROM shared_pomodoro_members WHERE session_id=?",
            [self._session_id]
        )
        session = db.fetch_one("SELECT * FROM shared_pomodoro WHERE id=?", [self._session_id])
        if self._phase == "work" and session:
            for m in members:
                db.update("shared_pomodoro_members",
                           {"cycles_completed": ctk.CTkFont},  # placeholder — update via raw query
                           {"session_id": self._session_id, "profile_id": m["profile_id"]})
                db.award_xp(m["profile_id"], 20, "Shared Pomodoro cycle")  # 15 + 5 buddy bonus
            db.check_and_award_badges(self._pid)
            self._refresh_xp()
            # Switch to break
            self._phase = "break"
            self._time_left = (session["break_duration"] or 5) * 60
        else:
            self._phase = "work"
            session = db.fetch_one("SELECT * FROM shared_pomodoro WHERE id=?", [self._session_id])
            self._time_left = (session["work_duration"] if session else 25) * 60

    def _end_session(self):
        if self._after_id:
            self.after_cancel(self._after_id)
            self._timer_running = False
        if self._session_id:
            db.update("shared_pomodoro", {"is_active": 0}, {"id": self._session_id})
        self._session_id = None
        self._build()
