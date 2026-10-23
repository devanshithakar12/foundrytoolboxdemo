# Foundry Toolbox Demo Deployment Plan

Status: Deployed and verified

## Goal

Reproduce the official Python hosted-agent Foundry Toolbox sample with all six
tools and demonstrate toolbox discovery, tool invocation, and version management.

## Approved Azure context

- Subscription: ME-MngEnvMCAP298097-dthakar-1
- Subscription ID: 4dc47c24-26c0-4d25-b51d-17bdccb6bf77
- Tenant ID: b5f3cadf-b89c-42ef-b526-201aa9621e3d
- Region: northcentralus
- Project mode: new, azd-managed
- Deployment: official sample, Python 3.13, code deployment

## Resources and dependencies

- Foundry account and project, project managed identity, and required RBAC.
- Sample model: gpt-5.4-mini, version 2026-03-17, GlobalStandard capacity 10.
- Hosted agent using Microsoft Agent Framework and the Responses protocol.
- Supporting infrastructure managed by the current Foundry azd provider.
- Separate Azure Language service, custom subdomain, and project identity access.
- Toolbox: Web Search, Code Interpreter, public Azure REST specs MCP, GitHub MCP,
  Azure Language MCP, and Foundry MCP.
- Connections: GitHub PAT, project managed identity, and user Entra token.

## Security and cost

- User approved the architecture and associated Azure usage charges.
- Never enter the GitHub PAT into chat, source files, logs, or screenshots.
- Prefer a fine-grained PAT scoped to public/demo repositories and read-only
  access. User must follow organization approval and SSO requirements.
- Use public or synthetic demo inputs. External MCP and Web Search can send
  requests outside the Foundry compliance boundary.
- Language service requires Cognitive Services Language Owner for the Foundry
  project's managed identity, scoped only to the Language resource.
- Keep local secrets and azd environment files excluded from source control.
- Do not deploy until validation succeeds and prerequisites are complete.

## Execution and verification

- [x] Verify active subscription, Owner access, azd authentication, and extensions.
- [x] Select official six-tool Python hosted-agent sample.
- [x] Obtain approval for new Language resource and documented deployment plan.
- [x] Scaffold official sample at workspace root and inspect resolved configuration.
- [x] Configure GitHub PAT locally without exposing its value.
- [x] Prepare Azure Language service and managed-identity authorization.
- [x] Add workspace-local debug configuration using the sample's own virtual environment.
- [x] Validate configuration and application dependencies.
- [x] Provision and deploy the approved resources.
- [x] List version-specific toolbox tools and invoke expected tools.
- [x] Verify hosted agent response and document demo and cleanup instructions.
- [x] All validation checks pass
  - [x] AZD installation: 1.37.1 with Foundry extensions.
  - [x] Schema validation: Azure MCP validates against stable official schema.
  - [x] Environment setup: ai-project-7cb9e2a1.
  - [x] Authentication check: Azure CLI and azd authenticated.
  - [x] Subscription/location check: approved subscription and northcentralus.
  - [x] Aspire pre-provisioning checks: not applicable.
  - [x] Provision preview: succeeds; creates RG, Foundry account/project, model.
  - [x] Build/import verification: pip check and exact sample imports pass.
  - [x] Docker build context: not applicable to code deployment.
  - [x] Package validation: azd package toolbox-demo succeeds.
  - [x] Azure Policy validation: assigned initiatives target database protection;
    no applicable deny reported by provisioning preview.
  - [x] Aspire post-provisioning checks: not applicable.

## Current state

The official manifest and Python source are present at the workspace root.
The hosted-agent service is named `toolbox-demo`; its source path remains the
upstream sample path. All six tools and three authenticated connections remain.
The approved resources are deployed in `rg-ai-project-7cb9e2a1`. Foundry account
`cog-aw57t2ye5xbly` contains project `ai-project-7cb9e2a1`, model deployment
`gpt-5.4-mini`, toolbox `agent-tools` version 1, and active hosted agent
`toolbox-demo` version 1. GitHub PAT presence and public-repository access were
verified without displaying the token.
The token-entry helper passes PowerShell syntax validation, and
Git ignores the local azd environment and Python virtual environments.
Pinned dependencies are exported from the upstream uv lock into requirements.txt.
Local uv downloads failed a TLS handshake; pip restored the same versions
through the configured package feed with certificate validation enabled.

## Language prerequisite provisioning

Use Azure CLI for the separate external Language prerequisite (the sample's
Foundry provider does not declare it). Target `rg-ai-project-7cb9e2a1` and
`lang-toolbox-7cb9e2a1`, kind `TextAnalytics`, SKU `S`, with a custom subdomain
matching the resource name. The sample's Language MCP URL is already configured.
After Foundry provision, resolve the project's principal ID from ARM and assign
`Cognitive Services Language Owner` on the Language resource only.

## Role Assignment Verification

- Static configuration reviewed: the official `microsoft.foundry` provider manages
  Foundry infrastructure; there are no hand-authored Bicep/Terraform role resources.
- `langmcpconn` uses ProjectManagedIdentity and the Cognitive Services audience.
  Its required Language Owner assignment is a mandatory pre-invocation step.
- `foundrymcpconn` uses UserEntraToken and the Foundry MCP audience; it must use
  the caller's existing permissions, not a broader service principal.
- The signed-in developer has Foundry User and inherited Owner access.
- Verified project principal `fedbf261-3836-44f2-b6b7-5d0dacb5a4b5` has
  Cognitive Services Language Owner on `lang-toolbox-7cb9e2a1` only.
  Direct Language invocation and the hosted agent's Language response passed.

## Section 7: Validation Proof

Validated locally on 2026-10-23:

| Command/check | Result |
| --- | --- |
| Foundry dependency and environment scripts | Pass; CLI and azd authenticated |
| Azure MCP validate_azure_yaml | Valid against stable official schema |
| azd provision --preview --no-prompt | Success; four planned resource creations |
| pip check in sample .venv | No broken requirements found |
| Exact imports from main.py, plus debugpy | Pass |
| azd package toolbox-demo --no-prompt | Success; code-deploy ZIP generated |
| PowerShell parser for helper scripts | No syntax errors |
| VS Code problems for manifest and debug configurations | No errors |
| Subscription policy assignment review | Database-protection initiatives only |
| Static RBAC review | Correct connection identity types; Language role step recorded |

## Live deployment verification

Verified on 2026-10-23:

| Check | Result |
| --- | --- |
| Foundry infrastructure and model provisioning | Success |
| External Language resource and scoped project identity role | Created and verified |
| Three authenticated connections, toolbox, hosted agent | Deployed; agent version 1 active |
| Version-specific toolbox discovery | 146 tools across all six sources |
| Code Interpreter | Returned 385 for sum of squares 1 through 10 |
| Azure Language MCP | Detected French from synthetic input |
| GitHub MCP | Found the public microsoft-foundry/foundry-samples repository |
| Public Azure REST documentation MCP | Returned documentation search content |
| Web Search | Returned cited documentation in an MCP text resource |
| Foundry MCP | Read back agent-tools toolbox |
| Hosted agent response | Returned 385 and French (fr) |
| Local HTTP agent on port 8088 | Completed Code Interpreter request; returned 385 |
| Local debugger and Inspector | debugpy listening on 127.0.0.1:5679; Inspector opened on 8088 |
| Updated helper and debug configuration editor checks | No errors |

The smoke-test helper supports both ordinary MCP text blocks and embedded
resource text. All six direct tests passed in one invocation.
The deployed agent uses the version-specific toolbox endpoint; changing the
default version alone will not repoint it. Counts may change with upstream MCP
servers. External services remain availability dependencies, and token expiry
requires rotation. No secret values were printed.

Demo prompts, local startup instructions, versioning behavior, token rotation,
cost cautions, and explicit cleanup guidance are documented in ../README.md.
No resources were deleted. The external Language resource shares the dedicated
demo resource group; it should be included in any approved full cleanup.

## Source

- Tutorial: https://learn.microsoft.com/en-us/azure/foundry/agents/how-to/tools/toolbox?pivots=python
- Sample: https://github.com/microsoft-foundry/foundry-samples/tree/main/samples/python/hosted-agents/agent-framework/responses/04-foundry-toolbox
