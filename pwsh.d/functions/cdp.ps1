## cdp  --  from 20_functions_fs.ps1 (one-file-per-function layout)

Function cdp(){
  cd $(Split-Path -Path $PROFILE -Parent)
}


## which
