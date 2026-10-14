@{
    # PSScriptAnalyzer settings for this interactive PowerShell profile.
    #
    # Several default rules don't fit a shell profile (short interactive command
    # names, Write-Host for colored output, aliases like cd/echo). Those are
    # excluded so CI surfaces real problems instead of style noise.

    Severity = @('Error', 'Warning')

    ExcludeRules = @(
        # Interactive convenience command names (l, ll, e, which, touch, ...)
        'PSUseApprovedVerbs',
        'PSUseSingularNouns',
        # Colored interactive output is intentional in a profile.
        'PSAvoidUsingWriteHost',
        # Short aliases (cd, echo, clear, %, ?) are deliberate in interactive code.
        'PSAvoidUsingCmdletAliases',
        # The profile defines functions that shadow built-ins (sl, help) on purpose.
        'PSAvoidOverwritingBuiltInCmdlets',
        # Plain-text handling is fine here; no credential plumbing.
        'PSAvoidUsingPlainTextForPassword',
        'PSUsePSCredentialType'
    )
}
