## ls helpers (l / ll / sl)  --  colored directory listings via Get-ChildItemColor,
## with graceful fallback to Get-ChildItem when the module isn't available.

Function l(){
  try { Get-ChildItemColorFormatWide | Select-Object -Property Name }
  catch { Get-ChildItem | Select-Object -Property Name }
}

Function ll(){
  try { Get-ChildItemColor }
  catch { Get-ChildItem | Select-Object * | Format-Table -AutoSize -Wrap }
}

## 'sl' is a built-in alias for Set-Location. Remove it (if present) so our
## own sl function can take over. Guarded so re-sourcing (reload) doesn't throw.
if (Get-Alias -Name sl -ErrorAction Ignore) { Remove-Alias -Name sl -Force }

Function sl(){
  try { Get-ChildItemColor }
  catch { Get-ChildItem }
}
