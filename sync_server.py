"""
StudentTrack Pro — Local Sync Server
Runs on the desktop alongside the main app. Uses HTTP on port 8765.
Mobile app discovers it via the displayed IP / QR code and syncs.
"""

import json
import sqlite3
import os
import socket
import shutil
from http.server import HTTPServer, BaseHTTPRequestHandler
from datetime import datetime
from database.connection import DB_PATH, get_db

SYNC_PORT = 8765
BACKUP_DIR = os.path.join(os.path.expanduser("~"), ".studenttrackpro", "backups")
os.makedirs(BACKUP_DIR, exist_ok=True)

# Tables that are synced between desktop and mobile
SYNC_TABLES = [
    "profiles", "todos", "habits", "habit_logs", "goals", "milestones",
    "attendance", "attendance_logs", "notes", "countdowns",
    "pomodoro_sessions", "health_logs", "flashcard_decks", "flashcards",
    "flashcard_reviews", "badges",
]


def get_local_ip() -> str:
    """Get the local network IP address."""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"


def export_all_tables() -> dict:
    """Export all sync tables as JSON."""
    conn = get_db()
    data = {}
    for table in SYNC_TABLES:
        try:
            rows = conn.execute(f"SELECT * FROM {table}").fetchall()
            data[table] = [dict(row) for row in rows]
        except sqlite3.OperationalError:
            data[table] = []
    conn.close()
    return data


def import_mobile_data(mobile_data: dict) -> dict:
    """
    Merge mobile data into desktop DB.
    Strategy: 'latest write wins' based on created_at/updated_at timestamps.
    New rows (IDs not present on desktop) are inserted.
    Existing rows are updated if mobile timestamp is newer.
    """
    conn = get_db()
    stats = {"inserted": 0, "updated": 0, "skipped": 0}

    for table, rows in mobile_data.items():
        if table not in SYNC_TABLES or not rows:
            continue

        # Get existing IDs
        try:
            existing = conn.execute(f"SELECT * FROM {table}").fetchall()
        except sqlite3.OperationalError:
            continue

        existing_map = {}
        for row in existing:
            row_dict = dict(row)
            existing_map[row_dict.get("id")] = row_dict

        for row in rows:
            row_id = row.get("id")
            if row_id is None:
                continue

            if row_id not in existing_map:
                # New row — insert
                cols = ", ".join(row.keys())
                placeholders = ", ".join(["?"] * len(row))
                try:
                    conn.execute(
                        f"INSERT INTO {table} ({cols}) VALUES ({placeholders})",
                        list(row.values()),
                    )
                    stats["inserted"] += 1
                except sqlite3.IntegrityError:
                    stats["skipped"] += 1
            else:
                # Existing — compare timestamps
                desktop_row = existing_map[row_id]
                desktop_ts = desktop_row.get("updated_at") or desktop_row.get("created_at") or ""
                mobile_ts = row.get("updated_at") or row.get("created_at") or ""

                if mobile_ts > desktop_ts:
                    # Mobile is newer — update
                    set_clause = ", ".join([f"{k}=?" for k in row.keys() if k != "id"])
                    values = [v for k, v in row.items() if k != "id"]
                    values.append(row_id)
                    try:
                        conn.execute(
                            f"UPDATE {table} SET {set_clause} WHERE id=?", values
                        )
                        stats["updated"] += 1
                    except sqlite3.Error:
                        stats["skipped"] += 1
                else:
                    stats["skipped"] += 1

    conn.commit()
    conn.close()
    return stats


def backup_db():
    """Create a timestamped backup of the database."""
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    dest = os.path.join(BACKUP_DIR, f"studenttrack_backup_{ts}.db")
    shutil.copy2(DB_PATH, dest)
    # Keep only last 10 backups
    backups = sorted(
        [f for f in os.listdir(BACKUP_DIR) if f.endswith(".db")], reverse=True
    )
    for old in backups[10:]:
        os.remove(os.path.join(BACKUP_DIR, old))
    return dest


class SyncHandler(BaseHTTPRequestHandler):
    """HTTP handler for sync requests."""

    def do_GET(self):
        if self.path == "/ping":
            self._json_response({"status": "ok", "app": "StudentTrackPro", "version": "1.0"})
        elif self.path == "/export":
            # Desktop sends all data to mobile
            backup_db()
            data = export_all_tables()
            self._json_response({"status": "ok", "tables": data})
        elif self.path == "/ip":
            self._json_response({"ip": get_local_ip(), "port": SYNC_PORT})
        else:
            self._json_response({"error": "Not found"}, 404)

    def do_POST(self):
        if self.path == "/import":
            # Mobile sends data to desktop
            content_length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(content_length)
            try:
                mobile_data = json.loads(body)
                backup_db()
                stats = import_mobile_data(mobile_data.get("tables", {}))
                self._json_response({"status": "ok", "stats": stats})
            except json.JSONDecodeError:
                self._json_response({"error": "Invalid JSON"}, 400)
            except Exception as e:
                self._json_response({"error": str(e)}, 500)
        else:
            self._json_response({"error": "Not found"}, 404)

    def _json_response(self, data: dict, code: int = 200):
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

    def log_message(self, format, *args):
        # Suppress default logging
        pass


def start_sync_server():
    """Start the sync HTTP server."""
    ip = get_local_ip()
    server = HTTPServer(("0.0.0.0", SYNC_PORT), SyncHandler)
    print(f"🔄 Sync server running at http://{ip}:{SYNC_PORT}")
    print(f"   Enter this IP in your mobile app to sync.")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        server.shutdown()
        print("\n🛑 Sync server stopped.")


if __name__ == "__main__":
    start_sync_server()
