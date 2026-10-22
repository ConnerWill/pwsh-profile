## Update-Windows  --  from 24_functions_system.ps1 (one-file-per-function layout)

Function Update-Windows(){
	<#
	.SYNOPSIS
	  Download and install all available Windows Updates.
	.DESCRIPTION
	  Uses the PSWindowsUpdate module to download every available update and
	  install it, accepting all and ignoring reboots so the run doesn't restart
	  the machine on you. Requires the PSWindowsUpdate module and an elevated
	  session; both are checked up front with a clear message if missing.
	  Windows-only.
	.EXAMPLE
	  Update-Windows
	  Download and install all pending updates (no automatic reboot).
	#>
	[CmdletBinding()]
	Param()

	# Headings pull from the profile's $Colors table (plain when unavailable).
	if ($Colors) {
		$cHead = "$($Colors.Bold)$($Colors.Cyan)"; $cSep = $Colors.Yellow
		$cOk = "$($Colors.Bold)$($Colors.BgGreen)$($Colors.White)"; $cReset = $Colors.Reset
	}
	else { $cHead = $cSep = $cOk = $cReset = '' }

	# Guard: Windows only.
	if (-not ($IsWindows -or $PSVersionTable.PSEdition -eq 'Desktop')) {
		Write-Error 'Update-Windows is Windows-only.'
		return
	}

	# Guard: needs the PSWindowsUpdate module.
	if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
		Write-Error "The 'PSWindowsUpdate' module is not installed. Install it with: Install-Module PSWindowsUpdate -Scope CurrentUser"
		return
	}

	# Guard: needs an elevated session (is_admin is defined in profile.ps1).
	$elevated = if (Get-Command is_admin -ErrorAction Ignore) { is_admin }
		else {
			$id = [Security.Principal.WindowsIdentity]::GetCurrent()
			([Security.Principal.WindowsPrincipal]$id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
		}
	if (-not $elevated) {
		Write-Error 'Update-Windows requires an elevated (Run as Administrator) session.'
		return
	}

	Import-Module PSWindowsUpdate -ErrorAction Stop

	# Full-width separator in yellow (256-color 190), via draw_line's glyph mode
	# when available (default '─' style); fall back to a plain '─' rule otherwise.
	$SepLine = if (Get-Command draw_line -ErrorAction Ignore) {
		draw_line -Style 1 -Color 190
	} else {
		"$cSep$('─' * 36)$cReset"
	}
	Clear-Host
	Write-Output "${cHead}Downloading Windows Update ...${cReset}"
	Write-Output $SepLine
	Get-WindowsUpdate -Download -AcceptAll -IgnoreReboot -WindowsUpdate -Verbose
	Write-Output $SepLine
	Write-Output "${cHead}Installing Windows Update ...${cReset}"
	Write-Output $SepLine
	Install-WindowsUpdate -AcceptAll -Install -IgnoreReboot -WindowsUpdate -Verbose
	Write-Output $SepLine
	Write-Output "${cOk} DONE ${cReset}"
}
