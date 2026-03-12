"""
StudentTrack Pro — Database Connection
"""

import sqlite3
import os

# Database file location — stored in user app data folder
DB_DIR = os.path.join(os.path.expanduser("~"), ".studenttrackpro")
DB_PATH = os.path.join(DB_DIR, "studenttrack.db")

os.makedirs(DB_DIR, exist_ok=True)


def get_db() -> sqlite3.Connection:
    """Return a database connection with row_factory set."""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn
