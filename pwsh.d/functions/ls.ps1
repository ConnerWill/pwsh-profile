## ls helpers (l / ll / sl)  --  colored directory listings via Get-ChildItemColor,
## with graceful fallback to Get-ChildItem when the module isn't available.

Function l(){
  <#
  .SYNOPSIS
    List the current directory as a wide, name-only colored listing.
  .DESCRIPTION
    Uses Get-ChildItemColor's wide format (names only, colored by type) and
    falls back to a plain Get-ChildItem name list if that module isn't present.
  .EXAMPLE
    l
    Show a compact, colored name listing of the current directory.
  #>
  try { Get-ChildItemColorFormatWide | Select-Object -Property Name }
  catch { Get-ChildItem | Select-Object -Property Name }
}

Function ll(){
  <#
  .SYNOPSIS
    Long/detailed colored directory listing.
  .DESCRIPTION
    Shows a detailed, colored listing via Get-ChildItemColor, falling back to a
    full auto-sized table from Get-ChildItem when the color module is unavailable.
  .EXAMPLE
    ll
    Show a detailed listing of the current directory.
  #>
  try { Get-ChildItemColor }
  catch { Get-ChildItem | Select-Object * | Format-Table -AutoSize -Wrap }
}

## 'sl' is a built-in alias for Set-Location. Remove it (if present) so our
## own sl function can take over. Guarded so re-sourcing (reload) doesn't throw.
if (Get-Alias -Name sl -ErrorAction Ignore) { Remove-Alias -Name sl -Force }

Function sl(){
  <#
  .SYNOPSIS
    Colored directory listing (replaces the built-in 'sl' Set-Location alias).
  .DESCRIPTION
    Lists the current directory via Get-ChildItemColor, falling back to a plain
    Get-ChildItem when the color module isn't installed. The built-in 'sl' alias
    for Set-Location is removed above so this function takes over the name.
  .EXAMPLE
    sl
    Show a colored listing of the current directory.
  #>
  try { Get-ChildItemColor }
  catch { Get-ChildItem }
}
