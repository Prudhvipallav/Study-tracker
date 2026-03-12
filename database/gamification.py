"""
StudentTrack Pro — XP, Level, and Badge Engine
"""

from .crud import (
    fetch_all, fetch_one, insert, update, get_profile,
)


# ---------------------------------------------------------------------------
# XP / Level system
# ---------------------------------------------------------------------------

LEVEL_NAMES = {
    "engineering": [
        "Freshman", "Sophomore", "Junior", "Senior", "Graduate",
        "Engineer", "Architect", "Innovator", "Pioneer", "Legend"
    ],
    "medical": [
        "Intern", "Resident", "Registrar", "Fellow", "Consultant",
        "Specialist", "Professor", "Surgeon", "Chief", "Lifesaver"
    ],
    "law": [
        "Clerk", "Paralegal", "Associate", "Solicitor", "Barrister",
        "Counsel", "Advocate", "Partner", "Judge", "Justice"
    ],
    "competitive": [
        "Aspirant", "Scholar", "Qualifier", "Achiever", "Ranker",
        "Topper", "Champion", "Elite", "Master", "Legend"
    ],
}

XP_PER_LEVEL = 500


def get_level_name(stream: str, level: int) -> str:
    """Return the level display name for a given stream and level number."""
    names = LEVEL_NAMES.get(stream, LEVEL_NAMES["competitive"])
    idx = min(level - 1, len(names) - 1)
    return names[idx]


def award_xp(profile_id: int, amount: int, reason: str):
    """
    Award XP to a profile.
    - Inserts a log entry
    - Updates profiles.xp
    - Checks for level up (every 500 XP)
    Returns True if a level up occurred.
    """
    try:
        insert("xp_logs", {"profile_id": profile_id, "amount": amount, "reason": reason})
        profile = get_profile(profile_id)
        if not profile:
            return False

        new_xp = profile["xp"] + amount
        new_level = max(1, new_xp // XP_PER_LEVEL + 1)
        leveled_up = new_level > profile["level"]

        update("profiles", {"xp": new_xp, "level": new_level}, {"id": profile_id})

        if leveled_up:
            # Award level milestone badges
            check_and_award_badges(profile_id)
            return True
        return False
    except Exception as e:
        print(f"[DB] award_xp error: {e}")
        return False


# ---------------------------------------------------------------------------
# Badge system
# ---------------------------------------------------------------------------

BADGE_DEFINITIONS = {
    "first_task":             ("First Step", "✅"),
    "streak_3":               ("Habit Forming", "🔥"),
    "streak_7":               ("Week Warrior", "⚔️"),
    "streak_30":              ("Unstoppable", "💥"),
    "first_goal":             ("Goal Setter", "🎯"),
    "goal_crusher":           ("Goal Crusher", "💪"),
    "milestone_master":       ("Milestone Master", "🏆"),
    "pomodoro_10":            ("Focus Machine", "🍅"),
    "pomodoro_50":            ("Deep Worker", "🧠"),
    "note_taker":             ("Scholar", "📚"),
    "deck_creator":           ("Knowledge Seeker", "🃏"),
    "hydrated":               ("Hydration Hero", "💧"),
    "athlete":                ("Athlete", "🏃"),
    "early_bird":             ("Early Bird", "🌅"),
    "attendance_perfect":     ("Perfect Attendance", "⭐"),
    "level_5":                ("Rising Star", "🌟"),
    "level_10":               ("Elite Student", "👑"),
    # Phase 13 — Buddy badges
    "first_nudge":            ("Good Vibes", "💌"),
    "nudge_streak_7":         ("Hype Man", "📣"),
    "shared_goal_complete":   ("Better Together", "🤝"),
    "buddy_pomodoro_5":       ("Study Duo", "👥"),
    "buddy_pomodoro_25":      ("Inseparable", "🔗"),
    "shared_goal_creator":    ("Team Player", "🧩"),
}


def has_badge(profile_id: int, badge_key: str) -> bool:
    """Check if a profile already has a specific badge."""
    row = fetch_one(
        "SELECT id FROM badges WHERE profile_id = ? AND badge_key = ?",
        [profile_id, badge_key]
    )
    return row is not None


def award_badge(profile_id: int, badge_key: str) -> bool:
    """
    Award a badge to a profile if not already earned.
    Returns True if a new badge was awarded.
    """
    if has_badge(profile_id, badge_key):
        return False
    if badge_key not in BADGE_DEFINITIONS:
        return False
    name, icon = BADGE_DEFINITIONS[badge_key]
    insert("badges", {
        "profile_id": profile_id,
        "badge_key": badge_key,
        "badge_name": name,
        "badge_icon": icon,
    })
    return True


def check_and_award_badges(profile_id: int) -> list:
    """
    Run all badge checks for a profile.
    Returns list of newly awarded badge keys.
    """
    newly_earned = []

    try:
        profile = get_profile(profile_id)
        if not profile:
            return []

        # --- Level badges ---
        if profile["level"] >= 5 and award_badge(profile_id, "level_5"):
            newly_earned.append("level_5")
        if profile["level"] >= 10 and award_badge(profile_id, "level_10"):
            newly_earned.append("level_10")

        # --- First task ---
        completed_tasks = fetch_one(
            "SELECT COUNT(*) as c FROM todos WHERE profile_id = ? AND is_completed = 1",
            [profile_id]
        )
        if completed_tasks and completed_tasks["c"] >= 1 and award_badge(profile_id, "first_task"):
            newly_earned.append("first_task")

        # --- First goal ---
        goal_count = fetch_one(
            "SELECT COUNT(*) as c FROM goals WHERE profile_id = ?",
            [profile_id]
        )
        if goal_count and goal_count["c"] >= 1 and award_badge(profile_id, "first_goal"):
            newly_earned.append("first_goal")

        # --- Goal crusher ---
        completed_goals = fetch_one(
            "SELECT COUNT(*) as c FROM goals WHERE profile_id = ? AND is_completed = 1",
            [profile_id]
        )
        if completed_goals and completed_goals["c"] >= 1 and award_badge(profile_id, "goal_crusher"):
            newly_earned.append("goal_crusher")

        # --- Milestone master ---
        completed_milestones = fetch_one(
            """SELECT COUNT(*) as c FROM milestones m
               JOIN goals g ON m.goal_id = g.id
               WHERE g.profile_id = ? AND m.is_completed = 1""",
            [profile_id]
        )
        if completed_milestones and completed_milestones["c"] >= 10 and award_badge(profile_id, "milestone_master"):
            newly_earned.append("milestone_master")

        # --- Habit streaks ---
        habits = fetch_all(
            "SELECT current_streak, longest_streak FROM habits WHERE profile_id = ? AND is_archived = 0",
            [profile_id]
        )
        max_streak = max((h["current_streak"] for h in habits), default=0)
        if max_streak >= 3 and award_badge(profile_id, "streak_3"):
            newly_earned.append("streak_3")
        if max_streak >= 7 and award_badge(profile_id, "streak_7"):
            newly_earned.append("streak_7")
        if max_streak >= 30 and award_badge(profile_id, "streak_30"):
            newly_earned.append("streak_30")

        # --- Pomodoro badges ---
        pom = fetch_one(
            "SELECT SUM(cycles_completed) as total FROM pomodoro_sessions WHERE profile_id = ?",
            [profile_id]
        )
        pom_total = pom["total"] if pom and pom["total"] else 0
        if pom_total >= 10 and award_badge(profile_id, "pomodoro_10"):
            newly_earned.append("pomodoro_10")
        if pom_total >= 50 and award_badge(profile_id, "pomodoro_50"):
            newly_earned.append("pomodoro_50")

        # --- Note taker ---
        note_count = fetch_one(
            "SELECT COUNT(*) as c FROM notes WHERE profile_id = ?",
            [profile_id]
        )
        if note_count and note_count["c"] >= 10 and award_badge(profile_id, "note_taker"):
            newly_earned.append("note_taker")

        # --- Deck creator ---
        deck_count = fetch_one(
            "SELECT COUNT(*) as c FROM flashcard_decks WHERE profile_id = ?",
            [profile_id]
        )
        if deck_count and deck_count["c"] >= 5 and award_badge(profile_id, "deck_creator"):
            newly_earned.append("deck_creator")

        # --- Buddy badges ---
        nudge_count = fetch_one(
            "SELECT COUNT(*) as c FROM nudges WHERE from_profile_id = ?", [profile_id]
        )
        if nudge_count and nudge_count["c"] >= 1 and award_badge(profile_id, "first_nudge"):
            newly_earned.append("first_nudge")

        shared_goals_created = fetch_one(
            "SELECT COUNT(*) as c FROM shared_goals WHERE created_by_profile_id = ?", [profile_id]
        )
        if shared_goals_created and shared_goals_created["c"] >= 3 and award_badge(profile_id, "shared_goal_creator"):
            newly_earned.append("shared_goal_creator")

        completed_shared = fetch_one(
            """SELECT COUNT(*) as c FROM shared_goals sg
               JOIN shared_goal_members sgm ON sg.id=sgm.shared_goal_id
               WHERE sgm.profile_id=? AND sg.is_completed=1""",
            [profile_id]
        )
        if completed_shared and completed_shared["c"] >= 1 and award_badge(profile_id, "shared_goal_complete"):
            newly_earned.append("shared_goal_complete")

        buddy_pom = fetch_one(
            """SELECT SUM(spm.cycles_completed) as s FROM shared_pomodoro_members spm
               JOIN shared_pomodoro sp ON spm.session_id=sp.id
               WHERE spm.profile_id=? AND sp.is_active=0""",
            [profile_id]
        )
        buddy_pom_total = buddy_pom["s"] if buddy_pom and buddy_pom["s"] else 0
        if buddy_pom_total >= 5 and award_badge(profile_id, "buddy_pomodoro_5"):
            newly_earned.append("buddy_pomodoro_5")
        if buddy_pom_total >= 25 and award_badge(profile_id, "buddy_pomodoro_25"):
            newly_earned.append("buddy_pomodoro_25")

    except Exception as e:
        print(f"[DB] check_and_award_badges error: {e}")

    return newly_earned
