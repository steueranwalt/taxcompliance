<#
.SYNOPSIS
  Production runner for Wissen termstore reconciliation.

.DESCRIPTION
  - Connects to SharePoint (Interactive or app auth with ClientId/Tenant)
  - Exports read-first snapshot
  - Imports additive delta in chunks with retries
  - Applies EN/FR labels
  - Optionally applies synonyms (DE/EN/FR)

.EXAMPLE
  .\Apply-Termstore.ps1 -SiteUrl "https://transferpricingdocs.sharepoint.com/sites/wissen" -Interactive -ClientId "<app-id>" -Tenant "<tenant>.onmicrosoft.com"

.EXAMPLE
  .\Apply-Termstore.ps1 -Connect -ChunkSize 20 -RetryCount 8 -ApplySynonyms
#>
[CmdletBinding()]
param(
    [string]$SiteUrl = "https://transferpricingdocs.sharepoint.com/sites/wissen",
    [string]$TermGroupName = "Wissen",
    [string]$DataDir = $PSScriptRoot,
    [switch]$Connect,
    [switch]$Interactive,
    [string]$ClientId,
    [string]$Tenant,
    [int]$ChunkSize = 25,
    [int]$RetryCount = 6,
    [switch]$SkipLabels,
    [switch]$ApplySynonyms,
    [switch]$WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Invoke-WithRetry {
    param(
        [scriptblock]$Script,
        [string]$Description,
        [int]$Attempts = 6
    )
    for ($i = 1; $i -le $Attempts; $i++) {
        try {
            & $Script
            return
        }
        catch {
            if ($i -eq $Attempts) { throw }
            Write-Warning "$Description fehlgeschlagen (Try $i/$Attempts): $($_.Exception.Message)"
            Start-Sleep -Seconds ([Math]::Min(120, 8 * $i))
        }
    }
}

function Connect-Termstore {
    if (-not $Connect) { return }
    if ($Interactive -or $ClientId) {
        $params = @{
            Url = $SiteUrl
        }
        if ($ClientId) { $params.ClientId = $ClientId }
        if ($Tenant) { $params.Tenant = $Tenant }
        $params.Interactive = $true
        Connect-PnPOnline @params
        return
    }
    Connect-PnPOnline -Url $SiteUrl -DeviceLogin
}

function Get-TermByPath {
    param(
        [string]$GroupName,
        [string]$TermSetName,
        [string]$TermPathPipe
    )
    $parts = $TermPathPipe -split "\|"
    $leaf = $parts[-1]
    $candidates = Get-PnPTerm -TermGroup $GroupName -TermSet $TermSetName -Identity $leaf -Recursive -ErrorAction SilentlyContinue
    if (-not $candidates) { return $null }
    if ($candidates -isnot [array]) { return $candidates }
    $needle = ($TermPathPipe -replace "\|", ";")
    return ($candidates | Where-Object { (($_.Path -replace "/", ";") -like "*$needle*") -or $_.Name -eq $leaf } | Select-Object -First 1)
}

function Apply-Synonyms {
    param(
        [string]$CsvPath,
        [string]$GroupName
    )
    if (-not (Test-Path -LiteralPath $CsvPath)) {
        Write-Warning "Synonym-Datei fehlt: $CsvPath"
        return
    }
    $lcidByLang = @{
        "de" = 1031
        "en" = 1033
        "fr" = 1036
    }
    $rows = Import-Csv -LiteralPath $CsvPath -Delimiter ";"
    $ok = 0
    $skip = 0
    $dup = 0
    $hasAddLabel = [bool](Get-Command -Name Add-PnPTermLabel -ErrorAction SilentlyContinue)
    $ctx = Get-PnPContext

    foreach ($row in $rows) {
        if (-not $lcidByLang.ContainsKey($row.Language)) { $skip++; continue }
        $term = Get-TermByPath -GroupName $GroupName -TermSetName $row.TermSet -TermPathPipe $row.TermPath
        if (-not $term) { $skip++; continue }
        if ($WhatIf) {
            Write-Host "[WhatIf] Synonym $($row.Synonym) on $($row.TermSet)/$($row.TermPath)"
            $ok++
            continue
        }
        try {
            if ($hasAddLabel) {
                Add-PnPTermLabel -Identity $term -Name $row.Synonym -Lcid $lcidByLang[$row.Language] -ErrorAction Stop | Out-Null
            }
            else {
                $null = $term.CreateLabel($row.Synonym, $lcidByLang[$row.Language], $false)
                $ctx.ExecuteQuery()
            }
            $ok++
        }
        catch {
            if ($_.Exception.Message -match "already exists|bereits|existiert") {
                $dup++
            }
            else {
                $skip++
            }
        }
    }
    Write-Host "Synonyme: angewendet=$ok duplikat=$dup übersprungen=$skip" -ForegroundColor DarkGray
}

Import-Module PnP.PowerShell -ErrorAction Stop
Connect-Termstore

$importScript = Join-Path $PSScriptRoot "Import-WissenTermstore.ps1"
$importParams = @{
    SiteUrl     = $SiteUrl
    TermGroupName = $TermGroupName
    DataDir     = $DataDir
    ChunkSize   = $ChunkSize
    Additive    = $true
}
if ($SkipLabels) { $importParams.SkipLabels = $true }
if ($WhatIf) { $importParams.WhatIf = $true }

Invoke-WithRetry -Description "Termstore-Import" -Attempts $RetryCount -Script {
    & $importScript @importParams
}

if ($ApplySynonyms) {
    Invoke-WithRetry -Description "Synonym-Anwendung" -Attempts $RetryCount -Script {
        Apply-Synonyms -CsvPath (Join-Path $DataDir "synonyms-de-en-fr.csv") -GroupName $TermGroupName
    }
}

Write-Host "Apply-Termstore abgeschlossen." -ForegroundColor Green
