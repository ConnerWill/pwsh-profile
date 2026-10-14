#Requires -Version 7.0
<#
  Parse tests: every first-party PowerShell file must parse with no syntax
  errors. Vendored trees (local-modules/, Modules/) are excluded.
#>

BeforeDiscovery {
    $repoRoot = Split-Path -Parent $PSScriptRoot

    # Only test first-party, git-tracked files (skip vendored module trees and
    # anything untracked/gitignored like examples/).
    Push-Location $repoRoot
    try {
        $tracked = git ls-files '*.ps1' '*.psm1' '*.psd1' |
            Where-Object { $_ -notmatch '^(local-modules|Modules)/' }
    }
    finally { Pop-Location }

    $script:PsFiles = foreach ($rel in $tracked) {
        @{ Path = (Join-Path $repoRoot $rel); Name = $rel }
    }
}

Describe 'PowerShell files parse without syntax errors' {
    It '<Name> parses cleanly' -ForEach $script:PsFiles {
        param($Path, $Name)
        $errors = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$errors)
        $errors | Should -BeNullOrEmpty -Because "$Name should have no parse errors"
    }
}

Describe 'Profile structure' {
    BeforeAll { $script:root = Split-Path -Parent $PSScriptRoot }

    It 'has a profile.ps1' {
        Join-Path $script:root 'profile.ps1' | Should -Exist
    }

    It 'has a pwsh.d fragment directory' {
        Join-Path $script:root 'pwsh.d' | Should -Exist
    }

    It 'pwsh.d fragments use numeric load-order prefixes' {
        $frags = Get-ChildItem (Join-Path $script:root 'pwsh.d') -Filter '*.ps1'
        $frags | Should -Not -BeNullOrEmpty
        foreach ($f in $frags) {
            $f.Name | Should -Match '^\d{2}_' -Because "$($f.Name) should start with NN_ for ordered loading"
        }
    }
}
