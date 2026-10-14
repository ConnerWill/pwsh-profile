Function Get-SSLCert(){
    try {
        openssl version >$null 2>&1      
    }
    catch {
        Write-Error "OpenSSL is not installed or not found in PATH"
        return
    }
    try {
        if (!(Test-Path -Path "$env:USERPROFILE\openssl")){
            Write-Host -ForegroundColor Magenta "Creating dir: $env:USERPROFILE\openssl..."
            mkdir -Force -Path "$env:USERPROFILE\openssl"
        }
    }
    catch {
        Write-Error "Unable to create directory: $env:USERPROFILE\openssl "
        return
    }
    try {
        Write-Host -ForegroundColor Magenta "Moving to $env:USERPROFILE\openssl..."
        cd "$env:USERPROFILE\openssl" 
    }
    catch {
        Write-Error "Unable to cd to $env:USERPROFILE\openssl"
        return
    }
    Write-Host -ForegroundColor Magenta "Running script..."
    $ScriptFromBitBucket = Invoke-WebRequest https://repo.infinitecampus.com/stash/projects/DO/repos/vault/raw/vaultCertificatePull.ps1
    Invoke-Expression $($ScriptFromBitBucket.Content.substring(1))
}

