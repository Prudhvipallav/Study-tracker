# -*- mode: python ; coding: utf-8 -*-
"""
StudentTrack Pro — PyInstaller build spec.
This spec lives in installer/, so all paths use '../' to reach the repo root.
Run from repo root: pyinstaller installer/build.spec --noconfirm
"""

import os

block_cipher = None

# SPECPATH = installer/ directory, so ../  = repo root where main.py lives
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
        'PIL',
        'PIL._imagingtk',
        'PIL.Image',
        'PIL.ImageTk',
        'matplotlib',
        'matplotlib.backends.backend_agg',
        'matplotlib.backends.backend_tkagg',
        'plyer',
        'plyer.platforms.win.notification',
        'sqlite3',
        'tkinter',
        'tkinter.ttk',
        'json',
        'threading',
        'datetime',
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='StudentTrackPro',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon='../assets/icon.ico' if os.path.exists('../assets/icon.ico') else None,
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name='StudentTrackPro',
)
