$ws = New-Object -ComObject WScript.Shell
$desktop = [System.Environment]::GetFolderPath('Desktop')
$sc = $ws.CreateShortcut("$desktop\StudentTrack Pro.lnk")
$sc.TargetPath = (Get-Command pythonw.exe -ErrorAction SilentlyContinue).Source
if (-not $sc.TargetPath) {
    # fallback: same folder as python.exe
    $sc.TargetPath = (Get-Command python.exe).Source -replace 'python\.exe','pythonw.exe'
}
$sc.Arguments = '"C:\Users\pravyghadin\Desktop\apps\tracker\StudentTrackPro\launch.pyw"'
$sc.WorkingDirectory = 'C:\Users\pravyghadin\Desktop\apps\tracker\StudentTrackPro'
$sc.IconLocation = 'C:\Users\pravyghadin\Desktop\apps\tracker\StudentTrackPro\assets\icon.ico'
$sc.Description = 'StudentTrack Pro - Student Productivity App'
$sc.WindowStyle = 1
$sc.Save()
Write-Host "Desktop shortcut created at: $desktop\StudentTrack Pro.lnk"
