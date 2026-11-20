<#
.SYNOPSIS
    Packages a PowerShell script into <name>-<version>.exe for an exact release tag.
.DESCRIPTION
    Reads its inputs from BUILD_* environment variables. Checks the tag first, needs Windows,
    installs the PS2EXE version pinned in ps2exe.pins only if its package's SHA-256 matches,
    then builds the executable and writes its path as the step output 'file'.
#>
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
. (Join-Path $PSScriptRoot 'ReleaseTag.ps1')

function Get-BuildInput {
    param([string]$Name, [switch]$Optional, [string]$Default = '')

    $value = [Environment]::GetEnvironmentVariable("BUILD_$Name")
    if ([string]::IsNullOrWhiteSpace($value)) {
        if ($Optional) { return $Default }
        throw "input '$($Name.ToLowerInvariant().Replace('_', '-'))' is empty"
    }
    $value
}

function Import-PinnedModule {
    param([string]$Name, [string]$Version, [string]$Sha256, [string]$Cache)

    $destination = Join-Path $Cache $Name $Version
    $marker = Join-Path $destination '.package-pwsh-script-sha256'
    if (-not ((Test-Path -LiteralPath $marker) -and ((Get-Content -LiteralPath $marker -Raw).Trim() -eq $Sha256))) {
        $download = Join-Path ([IO.Path]::GetTempPath()) "package-pwsh-script-$Name.$Version.$PID.nupkg"
        Invoke-WebRequest -Uri "https://www.powershellgallery.com/api/v2/package/$Name/$Version" -OutFile $download -TimeoutSec 120 -MaximumRetryCount 3 -RetryIntervalSec 5
        $actual = (Get-FileHash -LiteralPath $download -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($actual -ne $Sha256) {
            Remove-Item -LiteralPath $download -Force
            throw "checksum mismatch for $Name ${Version}: expected $Sha256, got $actual"
        }
        if (Test-Path -LiteralPath $destination) {
            Remove-Item -LiteralPath $destination -Recurse -Force
        }
        New-Item -ItemType Directory -Path $destination -Force | Out-Null
        Expand-Archive -LiteralPath $download -DestinationPath $destination -Force
        Remove-Item -LiteralPath $download -Force
        Set-Content -LiteralPath $marker -Value $Sha256
    }
    Import-Module -Name (Join-Path $destination "$Name.psd1") -Force
}

$version = ConvertFrom-ReleaseTag -Tag ([Environment]::GetEnvironmentVariable('BUILD_TAG'))
if (-not $IsWindows) {
    throw 'package-pwsh-script-action needs a Windows runner: PS2EXE compiles with the .NET Framework that ships with Windows'
}
$scriptPath = Get-BuildInput -Name 'SCRIPT_PATH'
$name = Get-BuildInput -Name 'NAME'
$outputDir = Get-BuildInput -Name 'OUTPUT_DIR' -Optional -Default $env:GITHUB_WORKSPACE
$pinsFile = Get-BuildInput -Name 'PINS_FILE' -Optional -Default (Join-Path $PSScriptRoot '..' 'ps2exe.pins')
$cache = Get-BuildInput -Name 'MODULE_CACHE' -Optional -Default (Join-Path ([IO.Path]::GetTempPath()) 'package-pwsh-script-modules')
if (-not (Test-Path -LiteralPath $scriptPath)) {
    throw "script not found: $scriptPath"
}

foreach ($line in Get-Content -LiteralPath $pinsFile) {
    if ($line -match '^\s*(#|$)') { continue }
    if ($line -notmatch '^(?<name>\S+) (?<version>\d+\.\d+\.\d+) sha256=(?<sha>[0-9a-f]{64})$') {
        throw "unreadable pin: $line"
    }
    Import-PinnedModule -Name $Matches.name -Version $Matches.version -Sha256 $Matches.sha -Cache $cache
}

New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
$exe = Join-Path (Resolve-Path -LiteralPath $outputDir).Path "$name-$version.exe"
Invoke-ps2exe -inputFile (Resolve-Path -LiteralPath $scriptPath).Path -outputFile $exe -title $name -version $version
if (-not (Test-Path -LiteralPath $exe)) {
    throw "PS2EXE did not produce $exe"
}
if ($env:GITHUB_OUTPUT) {
    Add-Content -LiteralPath $env:GITHUB_OUTPUT -Value "file=$exe"
}
Write-Output "Built $exe"
