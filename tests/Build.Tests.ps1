# Runs scripts/build.ps1 in a fresh pwsh with the action's environment variables.
BeforeAll {
    $script:build = Join-Path $PSScriptRoot '..' 'scripts' 'build.ps1'
    $script:pins = Join-Path $PSScriptRoot '..' 'ps2exe.pins'
    $script:work = Join-Path ([IO.Path]::GetTempPath()) "package-tests-$PID"
    New-Item -ItemType Directory -Path $work -Force | Out-Null

    function Invoke-Build {
        param([string]$Tag, [string]$PinsFile = $pins, [string]$Cache = (Join-Path $work 'cache'))

        $output = Join-Path $work "output-$([guid]::NewGuid())"
        $githubOutput = Join-Path $work "github-output-$([guid]::NewGuid())"
        $env:BUILD_SCRIPT_PATH = Join-Path $PSScriptRoot 'fixture' 'hello.ps1'
        $env:BUILD_NAME = 'Hello'
        $env:BUILD_TAG = $Tag
        $env:BUILD_OUTPUT_DIR = $output
        $env:BUILD_PINS_FILE = $PinsFile
        $env:BUILD_MODULE_CACHE = $Cache
        $env:GITHUB_OUTPUT = $githubOutput
        $pwsh = (Get-Process -Id $PID).Path
        $log = & $pwsh -NoProfile -File $build 2>&1 | Out-String
        [pscustomobject]@{ Exit = $LASTEXITCODE; Log = $log; Output = $output; GitHubOutput = $githubOutput }
    }
}

AfterAll {
    Remove-Item -Path $work -Recurse -Force -ErrorAction SilentlyContinue
}

Describe 'build.ps1' {
    It 'builds Hello-1.2.3.exe from the tag, and the executable runs' -Skip:(-not $IsWindows) {
        $run = Invoke-Build -Tag 'v1.2.3'
        $run.Exit | Should -Be 0 -Because $run.Log
        $exe = Join-Path $run.Output 'Hello-1.2.3.exe'
        $exe | Should -Exist
        # A PS2EXE executable reads redirected standard input; pipe nothing so it ends at once.
        ($null | & $exe) | Should -Be 'hello from the packaged script'
        Get-Content -LiteralPath $run.GitHubOutput | Should -Contain "file=$exe"
    }

    It 'refuses a prerelease tag before building' {
        $run = Invoke-Build -Tag 'v1.3.0-preview.1'
        $run.Exit | Should -Not -Be 0
        $run.Log | Should -Match 'v1.3.0-preview.1'
        $run.Output | Should -Not -Exist
    }

    It 'refuses a PS2EXE package whose checksum differs from the pin' -Skip:(-not $IsWindows) {
        $bad = Join-Path $work 'bad.pins'
        (Get-Content -LiteralPath $pins) -replace 'sha256=[0-9a-f]{64}', ('sha256=' + ('0' * 64)) | Set-Content -LiteralPath $bad
        $cache = Join-Path $work 'fresh-cache'
        $run = Invoke-Build -Tag 'v1.2.3' -PinsFile $bad -Cache $cache
        $run.Exit | Should -Not -Be 0
        $run.Log | Should -Match 'checksum mismatch'
        @(Get-ChildItem -Path $cache -Recurse -Filter '*.psd1' -ErrorAction SilentlyContinue).Count | Should -Be 0
    }

    It 'fails on a runner that is not Windows' -Skip:$IsWindows {
        $run = Invoke-Build -Tag 'v1.2.3'
        $run.Exit | Should -Not -Be 0
        $run.Log | Should -Match 'Windows runner'
    }
}
