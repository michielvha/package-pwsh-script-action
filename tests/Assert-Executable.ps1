# Fails unless the built executable exists and prints the expected text.
param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [Parameter(Mandatory = $true)]
    [string]$Expected
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $Path)) {
    throw "the action did not produce $Path"
}
# A PS2EXE executable reads redirected standard input; pipe nothing so it ends at once.
$actual = $null | & $Path
if ($actual -ne $Expected) {
    throw "$Path printed '$actual', expected '$Expected'"
}
Write-Output "$Path printed the expected text"
