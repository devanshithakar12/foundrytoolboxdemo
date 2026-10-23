[CmdletBinding()]
param([switch]$DebugAgent)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$agentRoot = Join-Path $projectRoot 'src\agent-framework-agent-with-foundry-toolbox-responses'
$python = Join-Path $agentRoot '.venv\Scripts\python.exe'
if (-not (Test-Path $python)) {
    throw 'Restore the sample dependencies into its .venv before starting the agent.'
}

$values = & azd env get-values --output json --cwd $projectRoot --no-prompt
if ($LASTEXITCODE -ne 0) {
    throw "Reading the azd environment failed (exit code $LASTEXITCODE)."
}
$config = ($values -join "`n") | ConvertFrom-Json
$values = $null
$endpoint = $config.FOUNDRY_PROJECT_ENDPOINT
if (-not $endpoint) {
    $endpoint = $config.AZURE_AI_PROJECT_ENDPOINT
}
$runtimeValues = @{
    FOUNDRY_PROJECT_ENDPOINT = $endpoint
    AZURE_AI_MODEL_DEPLOYMENT_NAME = $config.AZURE_AI_MODEL_DEPLOYMENT_NAME
    TOOLBOX_ENDPOINT = $config.TOOLBOX_AGENT_TOOLS_MCP_ENDPOINT
}
$config = $null
foreach ($entry in $runtimeValues.GetEnumerator()) {
    if ([string]::IsNullOrWhiteSpace($entry.Value)) {
        throw "Missing $($entry.Key). Provision resources and deploy the toolbox first."
    }
    [Environment]::SetEnvironmentVariable($entry.Key, $entry.Value, 'Process')
}
$env:PYTHONNOUSERSITE = '1'
$env:AZURE_EXTENSION_DIR = Join-Path $env:TEMP 'foundry-demo-az-extensions'
New-Item -ItemType Directory -Path $env:AZURE_EXTENSION_DIR -Force | Out-Null

Push-Location $agentRoot
try {
    if ($DebugAgent) {
        & $python -m debugpy --listen 127.0.0.1:5679 main.py
    }
    else {
        & $python main.py
    }
    if ($LASTEXITCODE -ne 0) {
        throw "Agent process exited with code $LASTEXITCODE."
    }
}
finally {
    Pop-Location
}
