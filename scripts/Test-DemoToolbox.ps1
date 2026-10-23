[CmdletBinding()]
param([switch]$RunSmokeTests)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$env:AZURE_EXTENSION_DIR = Join-Path $env:TEMP 'foundry-demo-az-extensions'
New-Item -ItemType Directory -Path $env:AZURE_EXTENSION_DIR -Force | Out-Null

$endpoint = & azd env get-value TOOLBOX_AGENT_TOOLS_MCP_ENDPOINT --cwd $projectRoot --no-prompt
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($endpoint)) {
    throw 'Deploy the toolbox before testing its version-specific MCP endpoint.'
}
$projectEndpoint = & azd env get-value AZURE_AI_PROJECT_ENDPOINT --cwd $projectRoot --no-prompt
if ($LASTEXITCODE -ne 0) {
    throw 'The Foundry project endpoint is not configured in the azd environment.'
}

function Invoke-ToolboxRequest {
    param([string]$Method, [hashtable]$Parameters)

    $accessToken = & az account get-access-token --resource https://ai.azure.com --query accessToken --output tsv
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($accessToken)) {
        throw 'Unable to acquire a toolbox access token. Sign in with Azure CLI.'
    }
    $headers = @{
        Authorization = "Bearer $accessToken"
        Accept = 'application/json, text/event-stream'
    }
    try {
        $body = @{
            jsonrpc = '2.0'
            id = [guid]::NewGuid().ToString()
            method = $Method
            params = $Parameters
        } | ConvertTo-Json -Depth 15
        $response = Invoke-RestMethod -Method Post -Uri $endpoint -Headers $headers `
            -ContentType 'application/json' -Body $body -TimeoutSec 180
        if ($response.error) {
            throw "MCP $Method failed: $($response.error | ConvertTo-Json -Depth 12 -Compress)"
        }
        if ($null -eq $response.result) {
            throw "MCP $Method returned no result."
        }
        if ($response.result.isError) {
            throw "Tool failed: $($response.result.content | ConvertTo-Json -Depth 12 -Compress)"
        }
        return $response.result
    }
    finally {
        $accessToken = $null
        $headers = $null
    }
}

$tools = [System.Collections.Generic.List[object]]::new()
$parameters = @{}
do {
    $page = Invoke-ToolboxRequest -Method 'tools/list' -Parameters $parameters
    foreach ($tool in $page.tools) {
        $tools.Add($tool)
    }
    $parameters = @{ cursor = $page.nextCursor }
} while ($page.nextCursor)

$expected = @(
    'code_interpreter',
    'web_search',
    'github___search_repositories',
    'language-mcp___detect_language_from_text',
    'noauth_mcp___search_azure_rest_api_docs',
    'foundry-mcp___toolbox_get'
)
foreach ($name in $expected) {
    if ($name -notin $tools.name) {
        throw "Expected tool not discovered: $name"
    }
}
Write-Host "Discovered $($tools.Count) tools across all six configured sources."
$tools | Group-Object { ($_.name -split '___')[0] } |
    Select-Object @{Name = 'Source'; Expression = { $_.Name }}, Count | Format-Table

if ($RunSmokeTests) {
    $cases = @(
        @{ Name = 'code_interpreter'; Arguments = @{ code = 'print(sum(i*i for i in range(1, 11)))' }; Expected = '385' },
        @{ Name = 'language-mcp___detect_language_from_text'; Arguments = @{ message = 'Bonjour, ceci est une demonstration.' }; Expected = 'French|\"fr\"' },
        @{ Name = 'github___search_repositories'; Arguments = @{ query = 'repo:microsoft-foundry/foundry-samples is:public'; perPage = 1 }; Expected = 'foundry-samples' },
        @{ Name = 'noauth_mcp___search_azure_rest_api_docs'; Arguments = @{ query = 'Azure virtual machines REST API' } },
        @{ Name = 'web_search'; Arguments = @{ search_query = 'Microsoft Learn Foundry Toolbox documentation' } },
        @{ Name = 'foundry-mcp___toolbox_get'; Arguments = @{ projectEndpoint = $projectEndpoint; toolboxName = 'agent-tools' }; Expected = 'agent-tools' }
    )
    foreach ($case in $cases) {
        Write-Host "Calling $($case.Name)..."
        $result = Invoke-ToolboxRequest -Method 'tools/call' -Parameters @{
            name = $case.Name
            arguments = $case.Arguments
        }
        $text = ($result.content | ForEach-Object {
            if ($_.type -eq 'text') {
                $_.text
            }
            elseif ($_.type -eq 'resource' -and $_.resource.text) {
                $_.resource.text
            }
        }) -join "`n"
        if ([string]::IsNullOrWhiteSpace($text)) {
            throw "$($case.Name) returned no text result."
        }
        if ($case.Expected -and $text -notmatch $case.Expected) {
            throw "$($case.Name) did not return the expected smoke-test result: $text"
        }
        Write-Host "PASS: $($case.Name)"
    }
}
