##########
# UpAll: Win 10 / Softwares Update Script
# Author: CyberFlamingo <alex@cyberflamingo.net>
# Version: v0.10, 2021-01-05
# Source:
##########

$actions = @(
	"RequireAdmin",
	"InstallWindowsUpdate",
	"UpdateWingetSources",
	"UpgradeChocolateyPackages"
)

# Relaunch the script with administrator privileges
Function RequireAdmin {
	If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
		Start-Process pwsh.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $PSCommandArgs" -Verb RunAs
		Exit
	}
}

##########
#region Windows Update
##########

Function InstallWindowsUpdate {
	# Write-Output "Enabling support for additional Microsoft Products..."
	# Add-WUServiceManager -ServiceID 7971f918-a847-4430-9279-4a52d1efe18d
	# Write-Output "Disabling Silverlight..."
	# Get-WindowsUpdate -Hide -Title *Silverlight -MicrosoftUpdate -Confirm:$false

	Write-Output "Installing Windows Updates..."
	Get-WindowsUpdate -MicrosoftUpdate -Install –AcceptAll
	# Get-WindowsUpdate -AutoReboot
}

##########
#endregion Windows Update
##########

##########
#region Microsoft Store
##########

# Function MicrosoftStore {
# 	Write-Output "Installing Microsoft Store updates..."
# 	Import-Module Appx -UseWindowsPowerShell
# 	Get-AppXPackage *WindowsStore* -AllUsers | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"}
# }

##########
#endregion Microsoft Store
##########

##########
#region Winget
##########

Function UpdateWingetSources {
	Write-Output "Updating Winget sources..."
	winget source update
}

##########
#endregion Winget
##########

##########
#region Chocolatey
##########

Function UpgradeChocolateyPackages {
	Write-Output "Upgrading Chocolatey packages..."
	choco upgrade --confirm all
}

##########
#endregion Chocolatey
##########

# Call the desired functions
$actions | ForEach-Object { Invoke-Expression $_ }

Read-Host "Press ENTER to continue..."