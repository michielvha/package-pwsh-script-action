# Package PowerShell Script Action

This GitHub Action packages a specified PowerShell script into an executable (`.exe`) file. It uses [GitVersion](https://gitversion.net/) to automatically version the packaged executable, making it ideal for workflows that need versioned releases of PowerShell scripts. This action is reusable across projects, allowing consistent and efficient packaging with minimal configuration.

## Features

- **Automatic Versioning**: Utilizes GitVersion to apply semantic versioning based on your Git history.
- **Script Packaging**: Converts PowerShell scripts into `.exe` files using [PS2EXE](https://github.com/MScholtes/PS2EXE).
- **Artifact Upload**: Automatically uploads the versioned executable as an artifact in your workflow.

## Inputs

| Input        | Description                                              | Required | Default                      |
|--------------|----------------------------------------------------------|----------|------------------------------|
| `name`       | The name of the output executable.                       | Yes      | `main`                       |
| `script-path`| Path to the main PowerShell script to package.           | Yes      | `pwsh/scripts/main.ps1`      |
| `config-file`| Path to the GitVersion configuration file.               | No       | `gitversion.yml`             |

### Input Details

- **`name`**: Used as the base name of the output executable. If you specify `"MyScript"`, the output file will be named `MyScript-{version}.exe`.
- **`script-path`**: Path to the PowerShell script you want to package. Ensure this path is relative to the root of your repository or adjusted according to your file structure.
- **`config-file`**: Optional path to the GitVersion configuration file, which allows for custom versioning configurations.

[//]: # ()
[//]: # (## Outputs)

[//]: # ()
[//]: # (| Output       | Description                                              |)

[//]: # (|--------------|----------------------------------------------------------|)

[//]: # (| `exe-path`   | Path to the generated executable file.                   |)

## Usage

To use this action, reference it in your GitHub Actions workflow file. Below is an example workflow that packages a PowerShell script whenever there is a push to the `main` branch.

### Example Workflow

```yaml
name: Package PowerShell Script

permissions:
  id-token: write
  contents: write

on:
  push:
    branches:
      - main
    paths:
      - 'pwsh/scripts/**'
  pull_request:
    branches:
      - main
    paths:
      - 'pwsh/scripts/**'

jobs:
  build:
    runs-on: windows-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Fetch all history for GitVersion to work

      - name: Package PowerShell Script
        uses: MKTHEPLUGG/package-pwsh-script-action@v1
        with:
          name: 'PDS'
          script-path: 'pwsh/scripts/main.ps1'
          config-file: 'gitversion.yml'

      - name: Upload Executable
        uses: actions/upload-artifact@v4
        with:
          name: "packaged-script"
          path: ${{ steps.package.outputs.exe-path }}
```

### Example Directory Structure

For the above example, ensure your repository has the following structure:

```
.
├── pwsh
│   └── scripts
│       └── main.ps1          # PowerShell script to package
├── gitversion.yml            # GitVersion configuration file
├── .github
│   └── actions
│       └── package-powershell-script
│           └── action.yml    # Action definition file
└── .github
    └── workflows
        └── package.yml       # Workflow using the action
```

## Action Workflow

1. **Checkout Code**: The action begins by checking out the repository code with full history, which is necessary for GitVersion to calculate the version.
2. **Tag with GitVersion**: GitVersion tags the repository based on Git history, allowing for versioning of the output executable.
3. **Install and Import PS2EXE**: The action installs and imports the PS2EXE PowerShell module, which enables the script to be packaged into an `.exe` file.
4. **Package Script into Executable**: Uses the `ps2exe` command to compile the specified PowerShell script into an executable, applying the version tag from GitVersion.
5. **Upload Executable**: The created executable file is uploaded as an artifact, making it available in your workflow’s run summary.

## Requirements

This action assumes:
- **Windows Runner**: The action requires a Windows runner (`runs-on: windows-latest`) because it depends on Windows PowerShell and PS2EXE.
- **GitVersion**: Ensure a valid `gitversion.yml` configuration file if using customized versioning rules.

## Notes

1. **Versioning**: GitVersion is a tool that automatically applies version numbers based on Git tags and branch names. For more information on configuration, refer to the [GitVersion documentation](https://gitversion.net/docs/).
2. **Executable Customization**: PS2EXE supports various options for customizing the packaging process, such as embedding icons or setting a custom executable name. Refer to the [PS2EXE documentation](https://github.com/MScholtes/PS2EXE) for advanced usage.

## Troubleshooting

- **Versioning Issues**: If GitVersion fails to generate a version, ensure that your repository has a proper commit history with at least one tag.
- **Packaging Errors**: If PS2EXE encounters errors, make sure that the PowerShell script has no syntax errors and that all dependencies are available in the repository.

---