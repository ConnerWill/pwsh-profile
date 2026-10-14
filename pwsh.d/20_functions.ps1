## Loaded by profile.ps1 pwsh.d loader.
## Sources every function file in pwsh.d/functions/ (one file per function),
## mirroring the zsh functions-enabled directory pattern. Add a new function by
## dropping a <Name>.ps1 into that directory -- it loads automatically.

###{{{ FUNCTIONS

$__functionsDir = Join-Path $PDOTDDIR 'functions'

if (Test-Path -Path $__functionsDir) {
  foreach ($__fn in (Get-ChildItem -File -Path $__functionsDir -Filter '*.ps1' | Sort-Object Name)) {
    try { . $__fn.FullName }
    catch {
      error "Failed to source function file: '$($__fn.FullName)'"
      Write-Warning ("  -> {0}" -f $_.Exception.Message)
    }
  }
}
else {
  Write-Warning "Function directory does not exist: $__functionsDir"
}

Remove-Variable __functionsDir, __fn -ErrorAction Ignore

###}}} END FUNCTIONS
