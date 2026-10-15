## cd / navigation helpers.

## cd to the PowerShell profile directory.
Function cdp(){
  Set-Location (Split-Path -Path $PROFILE -Parent)
}

## Directory-up shortcuts (like zsh): typing dots alone walks up parents.
##   ..     -> up 1      ...   -> up 2
##   ....   -> up 3      ..... -> up 4
## (Plain `.` is left alone -- current dir / dot-source operator.)
Function ..    { Set-Location .. }
Function ...   { Set-Location (Join-Path .. ..) }
Function ....  { Set-Location (Join-Path .. (Join-Path .. ..)) }
Function ..... { Set-Location (Join-Path .. (Join-Path .. (Join-Path .. ..))) }
