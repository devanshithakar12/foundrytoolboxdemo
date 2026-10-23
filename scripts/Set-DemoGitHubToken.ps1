[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$secureToken = Read-Host 'GitHub fine-grained PAT (input hidden; do not paste in chat)' -AsSecureString
if ($secureToken.Length -eq 0) {
    $secureToken.Dispose()
    throw 'A GitHub PAT is required by the full sample.'
}

$pointer = [IntPtr]::Zero
try {
    $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
    $token = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
    if ($token.StartsWith('Bearer ', [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Enter only the token, without the Bearer prefix.'
    }

    & azd env set GITHUB_MCP_PAT $token --cwd $projectRoot --no-prompt
    if ($LASTEXITCODE -ne 0) {
        throw "Saving the GitHub PAT failed (azd exit code $LASTEXITCODE)."
    }
    Write-Host 'GitHub PAT saved to the ignored local azd environment. Its value was not printed.'
}
finally {
    $token = $null
    if ($pointer -ne [IntPtr]::Zero) {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
    }
    $secureToken.Dispose()
}
