## Out-ConditionalColor  --  from 22_functions_ansi.ps1 (one-file-per-function layout)

Function Out-ConditionalColor {
    <#
    .SYNOPSIS
      Write pipeline objects to the host, coloring each by a condition.
    .DESCRIPTION
      Colors objects as they pass through the pipeline. Two modes:
        * Property mode  - map specific values of one property to colors via a
          hashtable (e.g. status 'Running' -> Green, 'Stopped' -> Red).
        * Conditions mode - supply an ordered hashtable of condition expressions
          to colors; each object is tested top-down and colored by the first match.
      The original console foreground color is restored at the end. Colors must be
      valid [System.ConsoleColor] names.
    .PARAMETER PropertyConditions
      Hashtable mapping property values to ConsoleColor names (property mode).
    .PARAMETER Property
      The property whose value is matched against PropertyConditions.
    .PARAMETER Conditions
      Ordered hashtable of condition expressions to ConsoleColor names (conditions mode).
    .PARAMETER InputObject
      Objects to color; normally supplied via the pipeline.
    .EXAMPLE
      Get-Service | Out-ConditionalColor @{Running='Green';Stopped='Red'} Status
      Color services green/red by their Status property.
    .EXAMPLE
      Get-Process | occ @{Name='proc';'proc'='Yellow'} Name
      Property-mode coloring via the 'occ' alias.
    .EXAMPLE
      $c = [ordered]@{ '$psitem.WS -gt 100MB' = 'Red'; '$psitem.WS -gt 50MB' = 'Yellow' }
      Get-Process | Out-ConditionalColor -Conditions $c
      Conditions mode: color processes by working-set thresholds.
    #>
    [cmdletbinding(DefaultParameterSetName = "property")]
    [alias("occ")]

    Param(
        [Parameter(
            Position = 0,
            Mandatory,
            HelpMessage = "Enter an hashtable of conditional properties and colors.",
            ParameterSetName = "property"
        )][ValidateScript({
                #validate colors
                $allowed = [enum]::GetNames([system.consolecolor])
                $bad = $_.Values | Where-Object { $allowed -notcontains $_ }
                if ($bad) { $valid = $allowed -join ','; Throw "You are using one or more invalid colors: $($bad -join ','). Valid colors are $Valid" }
                else { $True }
        })][hashtable]$PropertyConditions,

        [Parameter(
            Position = 1,
            Mandatory,
            HelpMessage = "Enter a property name.",
            ParameterSetName = "property"
        )][string]$Property,

        [Parameter(
            Position = 0,
            Mandatory,
            HelpMessage = "Enter an ordered hashtable of conditions and colors.",
            ParameterSetName = "conditions"
        )][System.Collections.Specialized.OrderedDictionary]$Conditions,

        [Parameter(
            Mandatory,
            ValueFromPipeline
        )][PSObject[]]$InputObject
    )

    Begin {
        Write-Verbose "Starting $($MyInvocation.MyCommand)"
        Write-Verbose "Using parameter set $($pscmdlet.ParameterSetName)"
        #save original color
        $saved = $Host.UI.RawUI.ForegroundColor

        Write-Verbose "Original foreground color is $saved"

        if ($PSCmdlet.ParameterSetName -eq 'conditions') {
            #we'll need this later in the Process script block
            #if doing complex processing
            Write-Verbose "Getting hash table enumerator and names"
            $compare = $conditions.GetEnumerator().name
            Write-Verbose $($compare | Out-String)
            #build an If/ElseIf construct on the fly
            #the Here-strings must be left justified
            $If = @"
 if ($($compare[0])) {
  `$host.ui.RawUI.ForegroundColor = '$($conditions.item($($compare[0])))'
 }
"@
            #now add the remaining comparisons as ElseIf
            for ($i = 1; $i -lt $conditions.count; $i++) {
                $If += "elseif ($($compare[$i])) {
         `$host.ui.RawUI.ForegroundColor = '$($conditions.item($($compare[$i])))'
         }
         "
            } #for

            #add the final else
            $if += @"
Else {
`$host.ui.RawUI.ForegroundColor = `$saved
}
"@

            Write-Verbose "Complex comparison:"
            Write-Verbose $If
        } #if complex parameter set

    } #Begin

    Process {

        If ($PSCmdlet.ParameterSetName -eq 'conditions') {
            #Use complex processing
            Invoke-Expression $if
        } #end complex
        else {
            #get property value as a string
            $value = $Inputobject.$Property.ToString()
            Write-Verbose "Testing property value $value"
            if ($PropertyConditions.containsKey($value)) {
                Write-Verbose "Property match"
                $host.ui.RawUI.ForegroundColor = $PropertyConditions.item($value)
            }
            else {
                #use orginal color
                Write-Verbose "No matches found"
                $host.ui.RawUI.ForegroundColor = $saved
            }
        } #simple

        #write the object to the pipeline
        Write-Verbose "Write the object to the pipeline"
        $_
    } #Process

    End {
        Write-Verbose "Restoring original foreground color"
        #set color back
        $host.ui.RawUI.ForegroundColor = $saved
    } #end

} #close function
