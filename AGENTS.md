# Repository instructions

Follow the relevant routes in
https://github.com/vhco-pro/docs/blob/0c108237fcd004e8636c0a2ca191436abd7bb7bd/AGENTS.md,
including the GitHub Actions convention for this repository's action and workflows.

This composite action packages a PowerShell script into `<name>-<version>.exe` for an exact stable
release tag with PS2EXE. It needs a Windows runner. It does not check out, compute a version, tag or
publish; the caller attaches the file it outputs. PowerShell comes from `vhco-pro/setup-pwsh-action`.

`test.yml` runs `vhco-pro/pwsh-ci-action` on Linux and Windows (the build tests in `tests/` run on
Windows only) and packages the fixture script with the action itself. To run the tests by hand, use
Windows with PowerShell 7 and Pester: `Invoke-Pester -Path ./tests`.

When Renovate bumps PS2EXE in `ps2exe.pins`, refresh its `sha256` in the same change from
`https://www.powershellgallery.com/api/v2/package/ps2exe/<version>` before merging.
