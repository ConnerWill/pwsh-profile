## Get-ANSIColors  --  from 22_functions_ansi.ps1 (one-file-per-function layout)

function Get-ANSIColors(){
  for($i=0; $i -le 255 ; $i++){
    [Console]::Write(
      "`e[0;1;38;5;${i}m▌║█║▌│║▌│║▌║▌█║``e[0;38;5;${i}m▌│║▌║▌│║║▌█║▌║█`e[0m`n"
    )
  }
}
