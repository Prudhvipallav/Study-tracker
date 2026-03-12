"""
StudentTrack Pro — Database Schema
All table definitions and init_db().
"""

from .connection import get_db


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
    last_seen TEXT,
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

-- Phase 13: Buddy / Accountability Partner tables
CREATE TABLE IF NOT EXISTS nudges (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    from_profile_id INTEGER NOT NULL,
    to_profile_id INTEGER NOT NULL,
    message TEXT NOT NULL,
    emoji TEXT DEFAULT '\U0001f4aa',
    is_read INTEGER DEFAULT 0,
    sent_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (from_profile_id) REFERENCES profiles(id),
    FOREIGN KEY (to_profile_id) REFERENCES profiles(id)
);

CREATE TABLE IF NOT EXISTS shared_goals (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    description TEXT,
    deadline TEXT,
    progress_percent INTEGER DEFAULT 0,
    created_by_profile_id INTEGER NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    is_completed INTEGER DEFAULT 0,
    FOREIGN KEY (created_by_profile_id) REFERENCES profiles(id)
);

CREATE TABLE IF NOT EXISTS shared_goal_members (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    shared_goal_id INTEGER NOT NULL,
    profile_id INTEGER NOT NULL,
    contribution_percent INTEGER DEFAULT 0,
    FOREIGN KEY (shared_goal_id) REFERENCES shared_goals(id),
    FOREIGN KEY (profile_id) REFERENCES profiles(id)
);

CREATE TABLE IF NOT EXISTS shared_pomodoro (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    initiated_by_profile_id INTEGER NOT NULL,
    subject TEXT,
    work_duration INTEGER DEFAULT 25,
    break_duration INTEGER DEFAULT 5,
    started_at TEXT DEFAULT CURRENT_TIMESTAMP,
    is_active INTEGER DEFAULT 1,
    FOREIGN KEY (initiated_by_profile_id) REFERENCES profiles(id)
);

CREATE TABLE IF NOT EXISTS shared_pomodoro_members (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id INTEGER NOT NULL,
    profile_id INTEGER NOT NULL,
    joined_at TEXT DEFAULT CURRENT_TIMESTAMP,
    cycles_completed INTEGER DEFAULT 0,
    FOREIGN KEY (session_id) REFERENCES shared_pomodoro(id),
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

        # ── Safe migrations for existing databases ──────────────────────
        # Each ALTER TABLE is wrapped in try/except so it's idempotent.
        # If the column already exists, SQLite raises an error that we
        # silently ignore.
        _migrations = [
            "ALTER TABLE profiles ADD COLUMN last_seen TEXT",
            "ALTER TABLE profiles ADD COLUMN dark_mode INTEGER DEFAULT 1",
        ]
        for migration in _migrations:
            try:
                conn.execute(migration)
                conn.commit()
            except Exception:
                pass  # Column already exists — safe to ignore

        conn.close()
    except Exception as e:
        print(f"[DB] init_db error: {e}")
        raise
