# -*- mode: python ; coding: utf-8 -*-
"""
StudentTrack Pro — PyInstaller spec (one-file build).
Run from repo root: pyinstaller installer/build.spec --noconfirm
Output: dist/StudentTrackPro.exe
"""

import os, sys

block_cipher = None

# SPECPATH = installer/ directory. All relative paths below are from installer/.
# Use '../' to reach repo root where main.py lives.

a = Analysis(
    ['../main.py'],
    pathex=['..'],
    binaries=[],
    datas=[
        ('../assets', 'assets'),
        ('../modules', 'modules'),
    ],
    hiddenimports=[
        'customtkinter',
        'PIL', 'PIL._imagingtk', 'PIL.Image', 'PIL.ImageTk', 'PIL.ImageDraw',
        'matplotlib', 'matplotlib.backends.backend_agg', 'matplotlib.backends.backend_tkagg',
        'plyer', 'plyer.platforms.win.notification',
        'sqlite3', 'tkinter', 'tkinter.ttk', 'tkinter.messagebox',
        'json', 'threading', 'datetime', 'os', 'sys',
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=['test', 'tests', 'unittest'],
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

# One-file build: everything in a single EXE
exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name='StudentTrackPro',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)
