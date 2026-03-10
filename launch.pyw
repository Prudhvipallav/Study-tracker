"""
StudentTrack Pro launcher — run with pythonw.exe to suppress the console window.
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from database.db import init_db
from main import App, ensure_icon

init_db()
ensure_icon()
App().mainloop()
