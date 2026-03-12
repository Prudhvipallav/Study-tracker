"""
Tests for StudentTrack Pro database layer.

Uses a temporary SQLite DB per test (see conftest.py).
"""

from database.db import (
    insert, update, delete, fetch_all, fetch_one,
    get_all_profiles, get_profile,
    get_settings, update_settings,
    award_xp, check_and_award_badges, has_badge,
    get_level_name, XP_PER_LEVEL,
)


# ---------------------------------------------------------------------------
# CRUD tests
# ---------------------------------------------------------------------------

class TestCRUD:
    def test_insert_and_fetch(self):
        pid = insert("profiles", {"name": "Alice", "stream": "engineering", "theme": "engineering"})
        assert pid >= 1
        row = fetch_one("SELECT * FROM profiles WHERE id = ?", [pid])
        assert row is not None
        assert row["name"] == "Alice"

    def test_update(self):
        pid = insert("profiles", {"name": "Bob", "stream": "medical", "theme": "medical"})
        update("profiles", {"name": "Bobby"}, {"id": pid})
        row = get_profile(pid)
        assert row["name"] == "Bobby"

    def test_delete(self):
        pid = insert("profiles", {"name": "Charlie", "stream": "law", "theme": "law"})
        delete("profiles", {"id": pid})
        assert get_profile(pid) is None

    def test_fetch_all(self):
        insert("profiles", {"name": "A", "stream": "engineering", "theme": "engineering"})
        insert("profiles", {"name": "B", "stream": "medical", "theme": "medical"})
        rows = get_all_profiles()
        assert len(rows) >= 2

    def test_insert_todo(self):
        pid = insert("profiles", {"name": "Test", "stream": "engineering", "theme": "engineering"})
        tid = insert("todos", {"profile_id": pid, "title": "Study math"})
        row = fetch_one("SELECT * FROM todos WHERE id = ?", [tid])
        assert row["title"] == "Study math"
        assert row["is_completed"] == 0


# ---------------------------------------------------------------------------
# Settings tests
# ---------------------------------------------------------------------------

class TestSettings:
    def test_default_settings(self):
        pid = insert("profiles", {"name": "Test", "stream": "engineering", "theme": "engineering"})
        settings = get_settings(pid)
        assert settings["dark_mode"] == 1
        assert settings["font_size"] == "medium"

    def test_update_settings(self):
        pid = insert("profiles", {"name": "Test", "stream": "engineering", "theme": "engineering"})
        get_settings(pid)  # ensure defaults exist
        update_settings(pid, {"dark_mode": 0})
        settings = get_settings(pid)
        assert settings["dark_mode"] == 0


# ---------------------------------------------------------------------------
# Gamification tests
# ---------------------------------------------------------------------------

class TestXP:
    def test_award_xp(self):
        pid = insert("profiles", {"name": "Gamer", "stream": "competitive", "theme": "competitive"})
        award_xp(pid, 100, "test")
        profile = get_profile(pid)
        assert profile["xp"] == 100
        assert profile["level"] == 1  # still under 500

    def test_level_up(self):
        pid = insert("profiles", {"name": "Gamer", "stream": "engineering", "theme": "engineering"})
        award_xp(pid, XP_PER_LEVEL, "big_reward")
        profile = get_profile(pid)
        assert profile["level"] >= 2


class TestBadges:
    def test_first_task_badge(self):
        pid = insert("profiles", {"name": "BadgeTester", "stream": "engineering", "theme": "engineering"})
        insert("todos", {"profile_id": pid, "title": "Do it", "is_completed": 1})
        earned = check_and_award_badges(pid)
        assert "first_task" in earned
        assert has_badge(pid, "first_task")

    def test_no_duplicate_badges(self):
        pid = insert("profiles", {"name": "BadgeTester", "stream": "engineering", "theme": "engineering"})
        insert("todos", {"profile_id": pid, "title": "Do it", "is_completed": 1})
        check_and_award_badges(pid)
        earned2 = check_and_award_badges(pid)
        assert "first_task" not in earned2  # already earned

    def test_level_name(self):
        assert get_level_name("engineering", 1) == "Freshman"
        assert get_level_name("medical", 5) == "Consultant"
        assert get_level_name("law", 10) == "Justice"
