@echo off
chcp 65001 >nul
title SwiftFix Spec Check
powershell -NoProfile -ExecutionPolicy Bypass -Command "$src='%~f0'; $lines=Get-Content -LiteralPath $src -Encoding UTF8; $marker='###POWERSHELL'+'-START###'; $idx=($lines | Select-String -SimpleMatch $marker | Select-Object -First 1).LineNumber; $ps=$lines[$idx..($lines.Count-1)] -join [Environment]::NewLine; $tmp=Join-Path $env:TEMP 'swiftfix-spec-run.ps1'; Set-Content -LiteralPath $tmp -Value $ps -Encoding UTF8; & $tmp"
pause
exit /b
###POWERSHELL-START###
# SwiftFix Spec Check (read-only hardware report)
# 迅修電腦一鍵規格檢測：只讀取硬體資訊，不修改、不上傳、不收集序號。
# Report is saved to Desktop as SwiftFix-Spec-Report.txt and copied to clipboard.

$ErrorActionPreference = 'SilentlyContinue'
$lines = New-Object System.Collections.Generic.List[string]

function Add-Line($text) { $lines.Add($text)}
function Section($title) { Add-Line ''; Add-Line ('==== ' + $title + ' ====')}
function GB($bytes) { if ($bytes) { [math]::Round($bytes / 1GB, 1).ToString() + ' GB'} else { 'N/A'}}

Add-Line ''
Add-Line ('檢測時間：' + (Get-Date -Format 'yyyy-MM-dd HH:mm'))
Add-Line '（本報告由客人在自己的電腦執行產生，僅含硬體規格，不含序號與個人檔案）'

$cs = Get-CimInstance Win32_ComputerSystem
$os = Get-CimInstance Win32_OperatingSystem
Section '電腦與系統'
Add-Line ('品牌／型號：' + $cs.Manufacturer + ' ' + $cs.Model)
Add-Line ('系統：' + $os.Caption + '（版本 ' + $os.Version + '，組建 ' + $os.BuildNumber + '，' + $os.OSArchitecture + '）')

$cpu = Get-CimInstance Win32_Processor
Section '處理器 CPU'
foreach ($c in $cpu) {
Add-Line ('型號：' + $c.Name.Trim())
Add-Line ('核心：' + $c.NumberOfCores + ' 核 ' + $c.NumberOfLogicalProcessors + ' 緒，最高時脈 ' + $c.MaxClockSpeed + ' MHz')
}

$board = Get-CimInstance Win32_BaseBoard
$bios = Get-CimInstance Win32_BIOS
Section '主機板與 BIOS'
Add-Line ('主機板：' + $board.Manufacturer + ' ' + $board.Product + ' ' + $board.Version)
Add-Line ('BIOS 版本：' + $bios.SMBIOSBIOSVersion)

$rams = Get-CimInstance Win32_PhysicalMemory
$totalRam = ($rams | Measure-Object -Property Capacity -Sum).Sum
Section '記憶體 RAM'
Add-Line ('總容量：' + (GB $totalRam) + '（共 ' + $rams.Count + ' 條）')
foreach ($r in $rams) {
Add-Line ('- ' + (GB $r.Capacity) + '，' + $r.Speed + ' MHz，' + $r.Manufacturer + ' ' + $r.PartNumber.Trim())
}

$gpus = Get-CimInstance Win32_VideoController
Section '顯示卡 GPU'
foreach ($g in $gpus) {
Add-Line ('型號：' + $g.Name + '（顯示記憶體 ' + (GB $g.AdapterRAM) + '，驅動 ' + $g.DriverVersion + '）')
}

Section '硬碟（實體）'
$disks = Get-CimInstance Win32_DiskDrive
foreach ($d in $disks) {
Add-Line ('型號：' + $d.Model.Trim() + '，容量 ' + (GB $d.Size) + '，狀態 ' + $d.Status)
}
try {
$phys = Get-PhysicalDisk
foreach ($pd in $phys) {
Add-Line ('- ' + $pd.FriendlyName + '，' + $pd.MediaType + '，健康 ' + $pd.HealthStatus + '，容量 ' + (GB $pd.Size))
}
} catch {}

Section '磁碟空間'
$drives = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
foreach ($v in $drives) {
Add-Line ($v.DeviceID + ' 總共 ' + (GB $v.Size) + '，剩餘 ' + (GB $v.FreeSpace))
}

$batt = Get-CimInstance Win32_Battery
if ($batt) {
Section '電池（筆電）'
foreach ($b in $batt) { Add-Line ('目前電量：' + $b.EstimatedChargeRemaining + '%')}
try {
$full = Get-CimInstance -Namespace root\wmi -ClassName BatteryFullChargedCapacity
$design = Get-CimInstance -Namespace root\wmi -ClassName BatteryStaticData
foreach ($f in $full) {
$d = $design | Where-Object { $_.InstanceName -eq $f.InstanceName}
if ($d -and $d.DesignedCapacity -gt 0) {
$wear = [math]::Round($f.FullChargedCapacity / $d.DesignedCapacity * 100, 0)
Add-Line ('電池健康度：約 ' + $wear + '%（充滿容量 ' + $f.FullChargedCapacity + '／設計容量 ' + $d.DesignedCapacity + ' mWh）')
}
}
} catch {}
}

Add-Line ''
Add-Line '==== 檢測結束 ===='
Add-Line '把這份報告整段貼到 LINE 給迅修電腦，就可以直接評估升級或維修。'

$report = $lines -join "`r`n"
$desktop = [Environment]::GetFolderPath('Desktop')
$path = Join-Path $desktop 'SwiftFix-Spec-Report.txt'
$report | Out-File -FilePath $path -Encoding UTF8
try { Set-Clipboard -Value $report} catch {}
Write-Host ''
Write-Host '檢測完成！報告已存在桌面：SwiftFix-Spec-Report.txt' -ForegroundColor Green
Write-Host '報告也已經自動複製，直接到 LINE 貼上就可以。'
Start-Process notepad.exe $path
Read-Host '按 Enter 關閉'
