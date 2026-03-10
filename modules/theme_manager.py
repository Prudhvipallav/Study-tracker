"""
StudentTrack Pro — Theme Manager
Loads stream-specific themes and applies them to CustomTkinter.
"""

import json
import os
import customtkinter as ctk

ASSETS_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "assets")
THEMES_DIR = os.path.join(ASSETS_DIR, "themes")

STREAM_THEME_MAP = {
    "engineering": "engineering.json",
    "medical":     "medical.json",
    "law":         "law.json",
    "competitive": "competitive.json",
}

# Light variant lightens background surfaces
LIGHT_SURFACE_MAP = {
    "background": "#F0F4F8",
    "surface":    "#FFFFFF",
    "surface2":   "#E8EDF2",
    "sidebar":    "#DDE3EA",
    "card":       "#FFFFFF",
    "border":     "#C8D0DB",
    "text":       "#1A1F2E",
    "text_secondary": "#5A6370",
}


class ThemeManager:
    """
    Manages the active color theme for a profile.

    Usage:
        tm = ThemeManager("engineering", dark_mode=True)
        tm.apply()               # applies to ctk
        color = tm.primary       # access color values
    """

    def __init__(self, stream: str, dark_mode: bool = True):
        self.stream = stream
        self.dark_mode = dark_mode
        self._data = {}
        self._load()

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def apply(self):
        """Apply the theme to CustomTkinter's appearance system."""
        ctk.set_appearance_mode("dark" if self.dark_mode else "light")
        ctk.set_default_color_theme("blue")  # base; overridden by our colors

    def toggle_dark_mode(self):
        """Toggle between dark and light mode and reapply."""
        self.dark_mode = not self.dark_mode
        self.apply()

    def set_dark_mode(self, enabled: bool):
        """Explicitly set dark mode."""
        self.dark_mode = enabled
        self.apply()

    # ------------------------------------------------------------------
    # Color accessors — properties for all named theme keys
    # ------------------------------------------------------------------

    def _get(self, key: str) -> str:
        if not self.dark_mode and key in LIGHT_SURFACE_MAP:
            return LIGHT_SURFACE_MAP[key]
        return self._data.get(key, "#888888")

    @property
    def primary(self):        return self._get("primary")
    @property
    def secondary(self):      return self._get("secondary")
    @property
    def accent(self):         return self._get("accent")
    @property
    def background(self):     return self._get("background")
    @property
    def surface(self):        return self._get("surface")
    @property
    def surface2(self):       return self._get("surface2")
    @property
    def text(self):           return self._get("text")
    @property
    def text_secondary(self): return self._get("text_secondary")
    @property
    def success(self):        return self._get("success")
    @property
    def warning(self):        return self._get("warning")
    @property
    def danger(self):         return self._get("danger")
    @property
    def sidebar(self):        return self._get("sidebar")
    @property
    def card(self):           return self._get("card")
    @property
    def border(self):         return self._get("border")
    @property
    def highlight(self):      return self._get("highlight")
    @property
    def name(self):           return self._data.get("name", self.stream.capitalize())

    def get(self, key: str, fallback: str = "#888888") -> str:
        """Generic getter with fallback."""
        return self._data.get(key, fallback)

    def priority_color(self, priority: str) -> str:
        """Return color for a task priority level."""
        return {
            "low":    self.success,
            "medium": self.warning,
            "high":   self.accent,
            "urgent": self.danger,
        }.get(priority, self.text_secondary)

    # ------------------------------------------------------------------
    # Internal
    # ------------------------------------------------------------------

    def _load(self):
        """Load the theme JSON for the given stream."""
        filename = STREAM_THEME_MAP.get(self.stream, "engineering.json")
        path = os.path.join(THEMES_DIR, filename)
        try:
            with open(path, "r") as f:
                self._data = json.load(f)
        except FileNotFoundError:
            print(f"[Theme] Theme file not found: {path}. Using defaults.")
            self._data = {
                "name": "Default",
                "primary": "#1E90FF",
                "secondary": "#00BFFF",
                "accent":    "#FF6B35",
                "background": "#0D1117",
                "surface":    "#161B22",
                "surface2":   "#21262D",
                "text":       "#E6EDF3",
                "text_secondary": "#8B949E",
                "success":    "#3FB950",
                "warning":    "#D29922",
                "danger":     "#F85149",
                "sidebar":    "#010409",
                "card":       "#1C2128",
                "border":     "#30363D",
                "highlight":  "#388BFD",
            }


# ---------------------------------------------------------------------------
# Global active theme — modules import this
# ---------------------------------------------------------------------------

_active_theme: ThemeManager | None = None


def set_active_theme(tm: ThemeManager):
    """Set the currently active global theme."""
    global _active_theme
    _active_theme = tm
    tm.apply()


def get_theme() -> ThemeManager:
    """Return the currently active theme. Falls back to engineering dark."""
    if _active_theme is None:
        return ThemeManager("engineering", dark_mode=True)
    return _active_theme
