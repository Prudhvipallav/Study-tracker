; StudentTrack Pro NSIS Installer Script
; Expects single-file build: dist\StudentTrackPro.exe

Unicode True
!define APPNAME "StudentTrack Pro"
!define APPVERSION "1.0.0"
!define PUBLISHER "StudentTrack"
!define OUTFILE "StudentTrackPro_Setup.exe"

Name "${APPNAME}"
OutFile "${OUTFILE}"
InstallDir "$PROGRAMFILES64\${APPNAME}"
InstallDirRegKey HKLM "Software\${APPNAME}" "Install_Dir"
RequestExecutionLevel admin
SetCompressor lzma

; ── Pages ───────────────────────────────────────────
Page directory
Page instfiles
UninstPage uninstConfirm
UninstPage instfiles

; ── Install Section ──────────────────────────────────
Section "Install"
  SetOutPath "$INSTDIR"

  ; Copy the single EXE produced by PyInstaller --onefile
  File "dist\StudentTrackPro.exe"

  ; Registry entries
  WriteRegStr HKLM "Software\${APPNAME}" "Install_Dir" "$INSTDIR"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayName" "${APPNAME}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayVersion" "${APPVERSION}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "Publisher" "${PUBLISHER}"
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "NoRepair" 1
  WriteUninstaller "$INSTDIR\uninstall.exe"

  ; Desktop shortcut
  CreateShortcut "$DESKTOP\${APPNAME}.lnk" "$INSTDIR\StudentTrackPro.exe"

  ; Start Menu
  CreateDirectory "$SMPROGRAMS\${APPNAME}"
  CreateShortcut "$SMPROGRAMS\${APPNAME}\${APPNAME}.lnk" "$INSTDIR\StudentTrackPro.exe"
  CreateShortcut "$SMPROGRAMS\${APPNAME}\Uninstall.lnk" "$INSTDIR\uninstall.exe"
SectionEnd

; ── Uninstall Section ────────────────────────────────
Section "Uninstall"
  Delete "$INSTDIR\StudentTrackPro.exe"
  Delete "$INSTDIR\uninstall.exe"
  RMDir "$INSTDIR"
  Delete "$DESKTOP\${APPNAME}.lnk"
  RMDir /r "$SMPROGRAMS\${APPNAME}"
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}"
  DeleteRegKey HKLM "Software\${APPNAME}"
SectionEnd
