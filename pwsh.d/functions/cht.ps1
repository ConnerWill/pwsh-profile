## cht  --  query cht.sh (the community cheat-sheet service) from the shell.
## PowerShell port of the zsh `cht()` helper.

Function cht(){
  <#
  .SYNOPSIS
    Look up one or more cheat sheets from https://cht.sh.

  .DESCRIPTION
    For each query, fetches the matching cheat sheet from cht.sh and prints the
    results. Each query is preceded by a bright-green, bold, underlined heading
    (ANSI) so multiple lookups are easy to tell apart. The combined output is
    sent to your pager ($PAGER if set, otherwise falls back to 'less', then
    'more', then 'cat' / Out-Host).

    Queries follow cht.sh syntax, e.g.:
      tar                 # cheat sheet for the 'tar' command
      python/lambda       # a specific topic within a language
      go/reverse+a+list   # use '+' for spaces in free-text questions

  .PARAMETER Query
    One or more cht.sh queries. Accepts pipeline input and remaining arguments.

  .EXAMPLE
    cht tar
    Show the tar cheat sheet.

  .EXAMPLE
    cht python/lambda go/goroutines
    Look up two topics in one call.

  .EXAMPLE
    'curl', 'jq' | cht
    Pipe queries in.
  #>
  [CmdletBinding()]
  Param(
    [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true, ValueFromRemainingArguments = $true)]
    [string[]]$Query
  )

  begin {
    # Collect pipeline + argument input so we can emit everything through one pager.
    $queries = [System.Collections.Generic.List[string]]::new()
  }

  process {
    foreach ($q in $Query) {
      if (-not [string]::IsNullOrWhiteSpace($q)) { $queries.Add($q) }
    }
  }

  end {
    if ($queries.Count -eq 0) { return }

    $sb = [System.Text.StringBuilder]::new()

    # Heading style comes from the profile's $Colors table (single source of
    # truth in ../../profile.ps1). profile.ps1 only defines $Colors on PS
    # versions that support ANSI, and drops it otherwise -- so when $Colors is
    # absent we simply print plain (uncolored) headings.
    $headOn  = if ($Colors) { "$($Colors.Bold)$($Colors.Underline)$($Colors.Green)" } else { '' }
    $headOff = if ($Colors) { $Colors.Reset } else { '' }

    foreach ($q in $queries) {
      Write-Output ("Searching for {0} ..." -f $q)

      # Bold + underline + green heading (plain if $Colors isn't defined).
      [void]$sb.AppendLine()
      [void]$sb.AppendLine("$headOn$q$headOff")
      [void]$sb.AppendLine()

      try {
        # cht.sh wants the query path URL-encoded (spaces, slashes handled by it).
        $uri  = "https://cht.sh/" + [uri]::EscapeUriString($q)
        $resp = Invoke-RestMethod -Uri $uri -Method Get -ErrorAction Stop
        [void]$sb.AppendLine(($resp | Out-String).TrimEnd())
      }
      catch {
        [void]$sb.AppendLine("Error fetching '$q': $($_.Exception.Message)")
      }
    }

    $output = $sb.ToString()

    # Resolve a pager: $PAGER (may include args), else less/more, else Out-Host.
    $pagerCmd = $null
    $pagerArgs = @()
    if ($env:PAGER) {
      $parts     = $env:PAGER -split '\s+'
      $pagerCmd  = Get-Command $parts[0] -ErrorAction Ignore
      if ($parts.Count -gt 1) { $pagerArgs = $parts[1..($parts.Count - 1)] }
    }
    if (-not $pagerCmd) { $pagerCmd = Get-Command less -ErrorAction Ignore }
    if (-not $pagerCmd) { $pagerCmd = Get-Command more -ErrorAction Ignore }

    if ($pagerCmd) {
      if ($pagerArgs) { $output | & $pagerCmd @pagerArgs }
      else            { $output | & $pagerCmd }
    }
    else {
      # No external pager available -> page through the host.
      $output | Out-Host
    }
  }
}
