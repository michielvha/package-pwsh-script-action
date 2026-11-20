function ConvertFrom-ReleaseTag {
    <#
    .SYNOPSIS
        Returns the module version of an exact stable release tag such as v1.2.3.
    .DESCRIPTION
        Fails on anything else, including prerelease tags, which the PowerShell Gallery would need
        mapped to a separate label with its own ordering rules.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Tag
    )

    if ($Tag -notmatch '^v(?<version>(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*))$') {
        throw "release tag '$Tag' is not an exact stable vMAJOR.MINOR.PATCH tag; prerelease tags are not supported"
    }
    $Matches.version
}
