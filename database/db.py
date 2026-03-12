"""
StudentTrack Pro — Database Layer (Compatibility Shim)

This file re-exports everything from the split modules so that
existing imports like `from database.db import insert` keep working.

Internal structure:
  database/connection.py   — DB_DIR, DB_PATH, get_db()
  database/schema.py       — SCHEMA, init_db()
  database/crud.py         — insert, update, delete, fetch_all, fetch_one,
                              get_all_profiles, get_profile,
                              get_settings, update_settings
  database/gamification.py — LEVEL_NAMES, XP_PER_LEVEL, BADGE_DEFINITIONS,
                              get_level_name, award_xp, has_badge,
                              award_badge, check_and_award_badges
"""

# Connection
from .connection import DB_DIR, DB_PATH, get_db

# Schema
from .schema import SCHEMA, init_db

# CRUD + profiles + settings
from .crud import (
    get_all_profiles, get_profile,
    insert, update, delete, fetch_all, fetch_one,
    get_settings, update_settings,
)

# Gamification (XP + badges)
from .gamification import (
    LEVEL_NAMES, XP_PER_LEVEL, BADGE_DEFINITIONS,
    get_level_name, award_xp, has_badge, award_badge,
    check_and_award_badges,
)

__all__ = [
    # Connection
    "DB_DIR", "DB_PATH", "get_db",
    # Schema
    "SCHEMA", "init_db",
    # CRUD
    "get_all_profiles", "get_profile",
    "insert", "update", "delete", "fetch_all", "fetch_one",
    "get_settings", "update_settings",
    # Gamification
    "LEVEL_NAMES", "XP_PER_LEVEL", "BADGE_DEFINITIONS",
    "get_level_name", "award_xp", "has_badge", "award_badge",
    "check_and_award_badges",
]
