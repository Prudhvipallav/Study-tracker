"""
StudentTrack Pro — Generic CRUD & Profile/Settings Helpers
"""

from .connection import get_db


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
    """Execute query and return all rows as list of dicts."""
    try:
        conn = get_db()
        cur = conn.execute(query, params)
        rows = [dict(r) for r in cur.fetchall()]
        conn.close()
        return rows
    except Exception as e:
        print(f"[DB] fetch_all error: {e}")
        return []


def fetch_one(query: str, params: list):
    """Execute query and return a single dict or None."""
    try:
        conn = get_db()
        cur = conn.execute(query, params)
        row = cur.fetchone()
        conn.close()
        return dict(row) if row else None
    except Exception as e:
        print(f"[DB] fetch_one error: {e}")
        return None


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
