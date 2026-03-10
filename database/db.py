"""
StudentTrack Pro — Database Layer
All SQLite schema creation and CRUD helpers.
"""

import sqlite3
import os
from datetime import datetime, date

# Database file location — stored in user app data folder
DB_DIR = os.path.join(os.path.expanduser("~"), ".studenttrackpro")
DB_PATH = os.path.join(DB_DIR, "studenttrack.db")

os.makedirs(DB_DIR, exist_ok=True)

# ---------------------------------------------------------------------------
# Connection helper
# ---------------------------------------------------------------------------

def get_db() -> sqlite3.Connection:
    """Return a database connection with row_factory set."""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


# ---------------------------------------------------------------------------
# Schema — all tables
# ---------------------------------------------------------------------------

SCHEMA = """
PRAGMA journal_mode=WAL;

CREATE TABLE IF NOT EXISTS profiles (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    avatar TEXT DEFAULT 'default',
    stream TEXT NOT NULL,
    stream_locked INTEGER DEFAULT 1,
    theme TEXT NOT NULL,
    xp INTEGER DEFAULT 0,
    level INTEGER DEFAULT 1,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS todos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    profile_id INTEGER,
    title TEXT NOT NULL,
    description TEXT,
    priority TEXT DEFAULT 'medium',
    tags TEXT,
    due_date TEXT,
    goal_id INTEGER,
    is_completed INTEGER DEFAULT 0,
    completed_at TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (profile_id) REFERENCES profiles(id)
);

CREATE TABLE IF NOT EXISTS goals (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    profile_id INTEGER,
    title TEXT NOT NULL,
    description TEXT,
    type TEXT NOT NULL,
    category TEXT,
    start_date TEXT,
    deadline TEXT,
    progress_percent INTEGER DEFAULT 0,
    is_completed INTEGER DEFAULT 0,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (profile_id) REFERENCES profiles(id)
);

CREATE TABLE IF NOT EXISTS milestones (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    goal_id INTEGER,
    title TEXT NOT NULL,
    deadline TEXT,
    is_completed INTEGER DEFAULT 0,
    order_index INTEGER DEFAULT 0,
    FOREIGN KEY (goal_id) REFERENCES goals(id)
);

CREATE TABLE IF NOT EXISTS subtasks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    milestone_id INTEGER,
    title TEXT NOT NULL,
    is_completed INTEGER DEFAULT 0,
    FOREIGN KEY (milestone_id) REFERENCES milestones(id)
);

CREATE TABLE IF NOT EXISTS habits (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    profile_id INTEGER,
    name TEXT NOT NULL,
    description TEXT,
    frequency TEXT DEFAULT 'daily',
    custom_days TEXT,
    color TEXT,
    icon TEXT,
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    is_archived INTEGER DEFAULT 0,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (profile_id) REFERENCES profiles(id)
);

CREATE TABLE IF NOT EXISTS habit_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    habit_id INTEGER,
    date TEXT NOT NULL,
    is_done INTEGER DEFAULT 0,
    note TEXT,
    FOREIGN KEY (habit_id) REFERENCES habits(id)
);

CREATE TABLE IF NOT EXISTS timetable (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    profile_id INTEGER,
    day_of_week INTEGER NOT NULL,
    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL,
    subject TEXT NOT NULL,
    location TEXT,
    color TEXT,
    recurring INTEGER DEFAULT 1,
    FOREIGN KEY (profile_id) REFERENCES profiles(id)
);

CREATE TABLE IF NOT EXISTS countdowns (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    profile_id INTEGER,
    title TEXT NOT NULL,
    exam_date TEXT NOT NULL,
    subject TEXT,
    notes TEXT,
    color TEXT,
    is_archived INTEGER DEFAULT 0,
    FOREIGN KEY (profile_id) REFERENCES profiles(id)
);

CREATE TABLE IF NOT EXISTS pomodoro_sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    profile_id INTEGER,
    subject TEXT,
    work_duration INTEGER DEFAULT 25,
    break_duration INTEGER DEFAULT 5,
    cycles_completed INTEGER DEFAULT 0,
    total_focus_minutes INTEGER DEFAULT 0,
    date TEXT DEFAULT CURRENT_DATE,
    FOREIGN KEY (profile_id) REFERENCES profiles(id)
);

CREATE TABLE IF NOT EXISTS notes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    profile_id INTEGER,
    title TEXT NOT NULL,
    content TEXT,
    tags TEXT,
    subject TEXT,
    is_pinned INTEGER DEFAULT 0,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (profile_id) REFERENCES profiles(id)
);

CREATE TABLE IF NOT EXISTS flashcard_decks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    profile_id INTEGER,
    name TEXT NOT NULL,
    subject TEXT,
    color TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (profile_id) REFERENCES profiles(id)
);

CREATE TABLE IF NOT EXISTS flashcards (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    deck_id INTEGER,
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    difficulty TEXT DEFAULT 'medium',
    last_reviewed TEXT,
    times_correct INTEGER DEFAULT 0,
    times_wrong INTEGER DEFAULT 0,
    FOREIGN KEY (deck_id) REFERENCES flashcard_decks(id)
);

CREATE TABLE IF NOT EXISTS attendance (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    profile_id INTEGER,
    subject TEXT NOT NULL,
    total_classes INTEGER DEFAULT 0,
    attended INTEGER DEFAULT 0,
    required_percent INTEGER DEFAULT 75,
    FOREIGN KEY (profile_id) REFERENCES profiles(id)
);

CREATE TABLE IF NOT EXISTS attendance_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    attendance_id INTEGER,
    date TEXT NOT NULL,
    status TEXT NOT NULL,
    note TEXT,
    FOREIGN KEY (attendance_id) REFERENCES attendance(id)
);

CREATE TABLE IF NOT EXISTS health_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    profile_id INTEGER,
    date TEXT DEFAULT CURRENT_DATE,
    sleep_time TEXT,
    wake_time TEXT,
    sleep_hours REAL,
    water_glasses INTEGER DEFAULT 0,
    mood INTEGER,
    mood_note TEXT,
    exercise_minutes INTEGER DEFAULT 0,
    exercise_type TEXT,
    steps INTEGER DEFAULT 0,
    FOREIGN KEY (profile_id) REFERENCES profiles(id)
);

CREATE TABLE IF NOT EXISTS resources (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    profile_id INTEGER,
    title TEXT NOT NULL,
    url TEXT,
    description TEXT,
    subject TEXT,
    tags TEXT,
    resource_type TEXT,
    is_favorite INTEGER DEFAULT 0,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (profile_id) REFERENCES profiles(id)
);

CREATE TABLE IF NOT EXISTS xp_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    profile_id INTEGER,
    amount INTEGER NOT NULL,
    reason TEXT,
    earned_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (profile_id) REFERENCES profiles(id)
);

CREATE TABLE IF NOT EXISTS badges (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    profile_id INTEGER,
    badge_key TEXT NOT NULL,
    badge_name TEXT NOT NULL,
    badge_icon TEXT,
    earned_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (profile_id) REFERENCES profiles(id)
);

CREATE TABLE IF NOT EXISTS settings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    profile_id INTEGER UNIQUE,
    dark_mode INTEGER DEFAULT 1,
    font_size TEXT DEFAULT 'medium',
    sidebar_expanded INTEGER DEFAULT 1,
    animation_speed TEXT DEFAULT 'normal',
    notifications_enabled INTEGER DEFAULT 1,
    water_reminder_hours INTEGER DEFAULT 2,
    habit_reminder_time TEXT DEFAULT '20:00',
    exam_warning_days INTEGER DEFAULT 7,
    attendance_warning_percent INTEGER DEFAULT 80,
    FOREIGN KEY (profile_id) REFERENCES profiles(id)
);
"""


def init_db():
    """Create all tables on first run. Enable WAL mode. Called on every launch."""
    try:
        conn = get_db()
        for statement in SCHEMA.strip().split(";"):
            s = statement.strip()
            if s:
                conn.execute(s)
        conn.commit()
        conn.close()
    except Exception as e:
        print(f"[DB] init_db error: {e}")
        raise


# ---------------------------------------------------------------------------
# Profile helpers
# ---------------------------------------------------------------------------

def get_all_profiles():
    """Return all profiles."""
    return fetch_all("SELECT * FROM profiles ORDER BY created_at", [])


def get_profile(profile_id: int):
    """Return a single profile by ID."""
    return fetch_one("SELECT * FROM profiles WHERE id = ?", [profile_id])


# ---------------------------------------------------------------------------
# Generic CRUD
# ---------------------------------------------------------------------------

def insert(table: str, data: dict) -> int:
    """Insert a row into table. Returns the new row id."""
    try:
        cols = ", ".join(data.keys())
        placeholders = ", ".join(["?"] * len(data))
        sql = f"INSERT INTO {table} ({cols}) VALUES ({placeholders})"
        conn = get_db()
        cur = conn.execute(sql, list(data.values()))
        conn.commit()
        row_id = cur.lastrowid
        conn.close()
        return row_id
    except Exception as e:
        print(f"[DB] insert error on {table}: {e}")
        raise


def update(table: str, data: dict, where: dict):
    """Update rows in table matching where clause."""
    try:
        set_clause = ", ".join([f"{k} = ?" for k in data.keys()])
        where_clause = " AND ".join([f"{k} = ?" for k in where.keys()])
        sql = f"UPDATE {table} SET {set_clause} WHERE {where_clause}"
        conn = get_db()
        conn.execute(sql, list(data.values()) + list(where.values()))
        conn.commit()
        conn.close()
    except Exception as e:
        print(f"[DB] update error on {table}: {e}")
        raise


def delete(table: str, where: dict):
    """Delete rows from table matching where clause."""
    try:
        where_clause = " AND ".join([f"{k} = ?" for k in where.keys()])
        sql = f"DELETE FROM {table} WHERE {where_clause}"
        conn = get_db()
        conn.execute(sql, list(where.values()))
        conn.commit()
        conn.close()
    except Exception as e:
        print(f"[DB] delete error on {table}: {e}")
        raise


def fetch_all(query: str, params: list) -> list:
    """Execute query and return all rows as list of Row objects."""
    try:
        conn = get_db()
        cur = conn.execute(query, params)
        rows = cur.fetchall()
        conn.close()
        return rows
    except Exception as e:
        print(f"[DB] fetch_all error: {e}")
        return []


def fetch_one(query: str, params: list):
    """Execute query and return a single Row object or None."""
    try:
        conn = get_db()
        cur = conn.execute(query, params)
        row = cur.fetchone()
        conn.close()
        return row
    except Exception as e:
        print(f"[DB] fetch_one error: {e}")
        return None


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
    "first_task":          ("First Step", "✅"),
    "streak_3":            ("Habit Forming", "🔥"),
    "streak_7":            ("Week Warrior", "⚔️"),
    "streak_30":           ("Unstoppable", "💥"),
    "first_goal":          ("Goal Setter", "🎯"),
    "goal_crusher":        ("Goal Crusher", "💪"),
    "milestone_master":    ("Milestone Master", "🏆"),
    "pomodoro_10":         ("Focus Machine", "🍅"),
    "pomodoro_50":         ("Deep Worker", "🧠"),
    "note_taker":          ("Scholar", "📚"),
    "deck_creator":        ("Knowledge Seeker", "🃏"),
    "hydrated":            ("Hydration Hero", "💧"),
    "athlete":             ("Athlete", "🏃"),
    "early_bird":          ("Early Bird", "🌅"),
    "attendance_perfect":  ("Perfect Attendance", "⭐"),
    "level_5":             ("Rising Star", "🌟"),
    "level_10":            ("Elite Student", "👑"),
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

    except Exception as e:
        print(f"[DB] check_and_award_badges error: {e}")

    return newly_earned


# ---------------------------------------------------------------------------
# Settings helpers
# ---------------------------------------------------------------------------

def get_settings(profile_id: int) -> dict:
    """Return settings for a profile, creating defaults if missing."""
    row = fetch_one("SELECT * FROM settings WHERE profile_id = ?", [profile_id])
    if row:
        return dict(row)
    # Create defaults
    insert("settings", {"profile_id": profile_id})
    row = fetch_one("SELECT * FROM settings WHERE profile_id = ?", [profile_id])
    return dict(row) if row else {}


def update_settings(profile_id: int, data: dict):
    """Update settings for a profile."""
    update("settings", data, {"profile_id": profile_id})
