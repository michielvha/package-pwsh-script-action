BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'scripts' 'ReleaseTag.ps1')
}

Describe 'ConvertFrom-ReleaseTag' {
    It 'turns an exact stable tag into a module version' {
        ConvertFrom-ReleaseTag -Tag 'v0.25.0' | Should -Be '0.25.0'
        ConvertFrom-ReleaseTag -Tag 'v10.2.33' | Should -Be '10.2.33'
    }

    It 'refuses <Tag>' -ForEach @(
        @{ Tag = 'v0.25.0-feat-ssh.1'; Reason = 'prerelease' }
        @{ Tag = '0.25.0'; Reason = 'without v' }
        @{ Tag = 'v0.25'; Reason = 'two parts' }
        @{ Tag = 'v0.25.0.1'; Reason = 'four parts' }
        @{ Tag = 'v0.25.0+build'; Reason = 'build metadata' }
        @{ Tag = ''; Reason = 'empty' }
    ) {
        { ConvertFrom-ReleaseTag -Tag $Tag } | Should -Throw "*$Tag*"
    }
}
