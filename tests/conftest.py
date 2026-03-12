"""
Shared test fixtures for StudentTrack Pro tests.
"""

import os
import sys
import pytest

# Ensure project root is importable
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, ROOT)


@pytest.fixture(autouse=True)
def in_memory_db(monkeypatch, tmp_path):
    """Redirect the database to a temp file for every test."""
    test_db = str(tmp_path / "test.db")
    monkeypatch.setattr("database.connection.DB_PATH", test_db)

    # Re-import to pick up the patched path and init the schema
    from database.schema import init_db
    init_db()

    yield test_db
