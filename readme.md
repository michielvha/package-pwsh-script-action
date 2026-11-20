# package-pwsh-script-action

Package a PowerShell script into a Windows executable named `<name>-<version>.exe` for an exact
release tag. The action installs a pinned, checksum-verified [PS2EXE](https://github.com/MScholtes/PS2EXE)
and runs it on the pinned PowerShell from [setup-pwsh-action](https://github.com/vhco-pro/setup-pwsh-action).

It does not check out code, compute a version, create tags or upload anything: it outputs the file's
path, and the caller attaches it, for example to a GitHub Release. **It needs a Windows runner**,
because PS2EXE compiles with the .NET Framework that ships with Windows.

```yaml
jobs:
  exe:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          persist-credentials: false
      - uses: michielvha/package-pwsh-script-action@FULL_COMMIT_SHA # vX.Y.Z
        id: exe
        with:
          script-path: scripts/main.ps1
          name: MyTool
          tag: ${{ github.ref_name }}
      - uses: actions/upload-artifact@FULL_COMMIT_SHA # vX.Y.Z
        with:
          name: exe
          path: ${{ steps.exe.outputs.file }}
```

Replace the placeholders with released commits and their tags.

## Inputs and outputs

| Input | Purpose |
| --- | --- |
| `script-path` | Script to package, relative to the workspace |
| `name` | Executable name; the file becomes `<name>-<version>.exe` |
| `tag` | Exact stable tag such as `v1.2.3`; prerelease tags are refused |

| Output | Value |
| --- | --- |
| `file` | Path of the built executable |

## PS2EXE version

[`ps2exe.pins`](ps2exe.pins) holds the PS2EXE version and the SHA-256 of its Gallery package; the
action refuses a package whose checksum differs. Renovate proposes new versions through a custom
manager; refresh the checksum in the same PR.

## Upgrading from v1

v2 is release-only. It no longer runs GitVersion, pushes tags or uploads a workflow artifact. The
`config-file` input is gone and `tag` is new: move the version decision to the release workflow and
attach the `file` output yourself.

## Tests

`tests/` holds Pester tests for the tag conversion and the build; the build tests run on Windows.
[`test.yml`](.github/workflows/test.yml) runs them through `vhco-pro/pwsh-ci-action` on Linux and
Windows, lints the workflows, and packages the fixture script with the action itself.
