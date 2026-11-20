# Fails unless this pwsh step runs the PowerShell that setup-pwsh-action installed into the
# tool cache, not the runner's preinstalled one.
param(
    [string]$Expected = ''
)

$ErrorActionPreference = 'Stop'
$path = (Get-Process -Id $PID).Path
if ($path -notmatch '[\\/]pwsh[\\/](?<version>\d+\.\d+\.\d+)[\\/]') {
    throw "pwsh steps run $path, not the PowerShell setup-pwsh-action installed"
}
$installed = $Matches.version
$actual = $PSVersionTable.PSVersion.ToString()
if ($actual -ne $installed) {
    throw "pwsh steps run PowerShell $actual from $path, but the tool cache holds $installed"
}
if ($Expected -and $actual -ne $Expected) {
    throw "pwsh steps run PowerShell $actual; the action reported $Expected"
}
Write-Output "pwsh steps run the pinned PowerShell $actual from $path"
