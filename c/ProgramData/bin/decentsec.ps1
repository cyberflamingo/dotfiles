##########
# DecentSec: Automatize Decent Security Advices
# Author: CyberFlamingo <alex@cyberflamingo.net>
# Version: v0.10, 2021-01-05
# Source: https://decentsecurity.com/
##########

$actions = @(
	"RequireAdmin",
	"SetUACHigh",
	"ShowEncCompFilesColor",
	"CleanWithCleanMgr",
	"DISMRestoreHealth",
	"WinSxSCleanupResetBase",
	"EnableSmartScreen",
	"WindowsSearchPurge",
	"EnableCtrldFolderAccess",
	"DefragVolumeC"
)

# Relaunch the script with administrator privileges
Function RequireAdmin {
	If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
		Start-Process pwsh.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $PSCommandArgs" -Verb RunAs
		Exit
	}
}

##########
#region UAC
##########
# Raise UAC level
Function SetUACHigh {
	Write-Output "Raising UAC level..."
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Type DWord -Value 2
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "PromptOnSecureDesktop" -Type DWord -Value 1
}
##########
#endregion UAC
##########

##########
#region BitLocker
##########
# Show coloring of encrypted or compressed NTFS files (green for encrypted, blue for compressed)
Function ShowEncCompFilesColor {
	Write-Output "Showing coloring of encrypted or compressed NTFS files..."
	Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowEncryptCompressedColor" -Type DWord -Value 1
	Get-BitLockerVolume
}
##########
#endregion BitLocker
##########

##########
#region cleanmgr
##########
Function CleanWithCleanMgr {
	Write-Host 'Clearing CleanMgr.exe automation settings.'
	Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\*' -Name StateFlags0001 -ErrorAction SilentlyContinue | Remove-ItemProperty -Name StateFlags0001 -ErrorAction SilentlyContinue

	Write-Host 'Enabling Update Cleanup. This is done automatically in Windows 10 via a scheduled task.'
	New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Update Cleanup' -Name StateFlags0001 -Value 2 -PropertyType DWord

	Write-Host 'Enabling Temporary Files Cleanup.'
	New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Files' -Name StateFlags0001 -Value 2 -PropertyType DWord

	Write-Host 'Starting CleanMgr.exe...'
	# Start-Process -FilePath CleanMgr.exe -ArgumentList '/sagerun:1' -WindowStyle Hidden -Wait

	Write-Host 'Waiting for CleanMgr and DismHost processes. Second wait neccesary as CleanMgr.exe spins off separate processes.'
	# Get-Process -Name cleanmgr,dismhost -ErrorAction SilentlyContinue | Wait-Process

	$UpdateCleanupSuccessful = $false
	if (Test-Path $env:SystemRoot\Logs\CBS\DeepClean.log) {
		$UpdateCleanupSuccessful = Select-String -Path $env:SystemRoot\Logs\CBS\DeepClean.log -Pattern 'Total size of superseded packages:' -Quiet
	}

	# if ($UpdateCleanupSuccessful) {
	# 	Write-Host 'Rebooting to complete CleanMgr.exe Update Cleanup....'
	# 	SHUTDOWN.EXE /r /f /t 0 /c 'Rebooting to complete CleanMgr.exe Update Cleanup....'
	# }
}
##########
#endregion cleanmgr
##########

##########
#region DISM RestoreHealth
##########
Function DISMRestoreHealth {
	Dism.exe /Online /Cleanup-Image /RestoreHealth
}
##########
#endregion DISM RestoreHealth
##########

##########
#region WinSxS cleanup ResetBase
##########
Function WinSxSCleanupResetBase {
	Dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase
}
##########
#endregion WinSxS cleanup ResetBase
##########

##########
#region SmartScreen
##########
# Enable SmartScreen Filter
Function EnableSmartScreen {
	Write-Output "Enabling SmartScreen Filter..."
	Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableSmartScreen" -ErrorAction SilentlyContinue
	Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\PhishingFilter" -Name "EnabledV9" -ErrorAction SilentlyContinue
}
##########
#endregion SmartScreen
##########

##########
#region Windows Search purge and re-initialization
##########
Function WindowsSearchPurge {
	net stop WSearch

	RD /S /Q "C:\ProgramData\Microsoft\Search"

	Remove-Item -Path "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows Search" -Recurse -ErrorAction SilentlyContinue
	Remove-Item -Path "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows Search\SetupCompletedSucessfully" -Recurse -ErrorAction SilentlyContinue
}
##########
#endregion Windows Search purge and re-initialization
##########

##########
#region cloud protection for Windows Defender
##########
# Enable Controlled Folder Access (Defender Exploit Guard feature) - Applicable since 1709, requires Windows Defender to be enabled
Function EnableCtrldFolderAccess {
	Write-Output "Enabling Controlled Folder Access..."
	Set-MpPreference -EnableControlledFolderAccess Enabled -ErrorAction SilentlyContinue
	Set-MpPreference -MAPSReporting Advanced
	Set-MpPreference -SubmitSamplesConsent SendAllSamples
}
##########
#endregion cloud protection for Windows Defender
##########

##########
#region Defragmentation
##########
Function DefragVolumeC {
	Optimize-Volume -DriveLetter C -ReTrim -Verbose
}
##########
#endregion Defragmentation
##########

# Call the desired functions
$actions | ForEach-Object { Invoke-Expression $_ }

Read-Host "Press ENTER to continue..."

