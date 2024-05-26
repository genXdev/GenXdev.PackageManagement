################################################################################
# This variable stores a collection of GenXdev packages.
[System.Collections.ArrayList] $GenXdevPackages = [System.Collections.ArrayList] @();

# This variable stores an array of installed winget packages managed by GenXdev Package Management.
[System.Array] $GenXdevPackageManagementInstalledWingetPackages = @();

# This variable stores an array of installed Chocolatey packages managed by GenXdev Package Management.
[System.Array] $GenXdevPackageManagementInstalledChocoPackages = @();

# This variable stores an array of updatable Chocolatey packages managed by GenXdev Package Management.
[System.Array] $GenXdevPackageManagementUpdatableChocoPackages = @();

# This variable stores the state of GenXdev Package Management.
[HashTable] $GenXdevPackageManagementState = $null;

# This variable stores the file path of the GenXdev packages list file.
[string] $GenXdevPackagesFileName = Expand-Path -FilePath "$PSScriptRoot\packagelist.json" -CreateDirectory;

# This variable stores the file path of the GenXdev Package Management state file.
[string] $GenXdevPackageManagementStateFilePath = Expand-Path -FilePath "$PSScriptRoot\..\..\GenXdev.Local\state.json" -CreateDirectory;
################################################################################
<#
.SYNOPSIS
Initializes the environment for the GenXdev.PackageManagement module.

.DESCRIPTION
This function sets up the necessary environment for the GenXdev.PackageManagement module to function properly. It performs the following tasks:
- Sets the security protocol to TLS 1.1 and TLS 1.2.
- Sets the error action preference to "stop".
- Sets the global variable $WorkspaceFolder to the full path of the parent folder of the script root.
- Calls the Initialize-GenXdevPackageManagementState function to initialize the module's state.
- Calls the Initialize-SearchPaths function to initialize the module's search paths.

.PARAMETER None
This function does not accept any parameters.

.EXAMPLE
Initialize-Environment
#>

function Initialize-Environment {

    try {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls11 -bor [System.Net.SecurityProtocolType]::Tls12;
        $ErrorActionPreference = "stop"
    }
    Catch {
        Write-Warning $PSItem
    }

    $Global:WorkspaceFolder = ([IO.Path]::GetFullPath($PSScriptRoot + "\..\..\..\"));

    Initialize-GenXdevPackageManagementState
    Initialize-SearchPaths
}

################################################################################
<#
.SYNOPSIS
Imports GenXdev modules.

.DESCRIPTION
This function imports all GenXdev modules located in the module directory.

.PARAMETER None
This function does not accept any parameters.

.EXAMPLE
Import-GenXdevModules
Imports all GenXdev modules located in the module directory.
#>
function Import-GenXdevModules {

    Push-Location
    try {
        Set-Location "$PSScriptRoot\..\..";
        Get-ChildItem ".\GenXdev*" -dir | ForEach-Object {
            try {
                # Import each GenXdev module and suppress any errors.
                Import-Module $PSItem.Name -ErrorAction SilentlyContinue | Out-Null
            }
            catch {

            }
        }
    }
    finally {
        Pop-Location
    }
}

################################################################################
<#
.SYNOPSIS
Initializes the search paths for the module.

.DESCRIPTION
This function initializes the search paths for the module by adding various paths to the $searchPaths variable. It also adds all project search-paths to the environment's PATH variable.

.PARAMETER None

.EXAMPLE
Initialize-SearchPaths
#>

function Initialize-SearchPaths {

    # Your existing Initialize-SearchPaths function code here

    # Add default search paths to $searchPaths
    $searchPaths = [System.Collections.Generic.List[string]] (@(
            [IO.Path]::GetFullPath("${env:ProgramData}\chocolatey\bin\"),
            [IO.Path]::GetFullPath("$Global:WorkspaceFolder\node_modules\.bin"),
            [IO.Path]::GetFullPath("$Global:WorkspaceFolder\powershell"),
            [IO.Path]::GetFullPath("${env:ProgramFiles}\Git\cmd"),
            [IO.Path]::GetFullPath("${env:ProgramFiles}\nodejs"),
            [IO.Path]::GetFullPath("${env:ProgramFiles}\Google\Chrome\Application"),
            [IO.Path]::GetFullPath("${env:ProgramFiles}\Microsoft VS Code\bin")
        ) + @(
            $GenXdevPackages |
            ForEach-Object {
                if (-not [string]::IsNullOrWhiteSpace($PSItem.searchpath)) {
                    $a = $PSItem.searchpath.replace('`', '``').replace('"', '`"');
                    $a = Invoke-Expression "`"$a`"";

                    [IO.Path]::GetFullPath($a);
                }
            }
        ))

    # Add all project search-paths to the environment's PATH variable
    @($env:Path.Split(';')) | ForEach-Object -Process {
        # Add the paths to the searchPath, if it is not already present
        $path = $PSItem;

        if ([String]::IsNullOrWhiteSpace($path) -eq $false) {
            try {
                $fullPath = [IO.Path]::GetFullPath($path);

                if ($searchPaths.IndexOf($fullPath) -lt 0) {
                    $searchPaths.Add($fullPath);
                }
            }
            catch {
                Write-Host "Could not parse path: $PSItem"
            }
        }
    }

    $env:Path = [string]::Join(";", $searchPaths)
}

################################################################################
<#
.SYNOPSIS
Initializes the GenXdevPackageManagementState variable with initial values.

.DESCRIPTION
This function sets the GenXdevPackageManagementState variable with initial values. It also checks if the GenXdevPackageManagementState file exists and reads its content if it does.

.PARAMETER None

.EXAMPLE
Initialize-GenXdevPackageManagementState

This example initializes the GenXdevPackageManagementState variable.

#>

function Initialize-GenXdevPackageManagementState {

    # Set the GenXdevPackageManagementState variable with initial values.
    Set-Variable -Force -Scope Script -Name GenXdevPackageManagementState -Value @{
        LastCheck                    = [DateTime]::UtcNow.AddDays(-2).Ticks;
        SoftwarePackagesMemberGroups = @()
    };

    [System.IO.Fileinfo] $GenXdevPackageManagementStateFile = [System.IO.Fileinfo]::new($GenXdevPackageManagementStateFilePath);

    # Check if the GenXdevPackageManagementState file exists.
    if ($GenXdevPackageManagementStateFile.Exists) {

        try {
            # Read the GenXdevPackageManagementState file and set the GenXdevPackageManagementState variable with its content.
            Set-Variable -Force -Scope Script -Name GenXdevPackageManagementState -Value (Get-Content $GenXdevPackageManagementStateFilePath |
                ConvertFrom-Json -AsHashtable -Depth 100
            )
        }
        catch {
            # If there is an error reading the GenXdevPackageManagementState file, set the GenXdevPackageManagementState variable with default values.
            Set-Variable -Force -Scope Script -Name GenXdevPackageManagementState -Value @{
                LastCheck                    = [DateTime]::UtcNow.AddDays(-2).Ticks;
                SoftwarePackagesMemberGroups = @()
            };
        }
    }
}

################################################################################
<#
.SYNOPSIS
Saves the state of GenXdev Package Management.

.DESCRIPTION
This function converts the GenXdevPackageManagementState to JSON format and saves it to a file.
#>
function Save-GenXdevPackagManagementState {

    try {
        # Convert GenXdevPackageManagementState to JSON and save it to the file
        $GenXdevPackageManagementState | ForEach-Object {

            if (-not [string]::IsNullOrWhiteSpace($PSItem)) {

                $PSItem
            }
        } |
        ConvertTo-Json -Depth 100 |
        Out-File $GenXdevPackageManagementStateFilePath -Force
    }
    catch {

    }
}

################################################################################
<#
.SYNOPSIS
Saves the GenXdevPackages to a file.

.DESCRIPTION
This function saves the GenXdevPackages to a file specified by the $filePath parameter. If $filePath is not provided, the default file path will be used. The GenXdevPackages are sorted by the "repo" and "id" properties before being converted to JSON format and written to the file.

.PARAMETER filePath
The file path where the GenXdevPackages should be saved. If not provided, the default file path will be used.

.EXAMPLE
Save-GenXdevPackages -filePath "C:\Temp\GenXdevPackages.json"
Saves the GenXdevPackages to the specified file path.

.EXAMPLE
Save-GenXdevPackages
Saves the GenXdevPackages to the default file path.

#>

function Save-GenXdevPackages([string] $filePath = $null) {

    try {
        # Write the GenXdevPackages to a file
        [IO.File]::WriteAllText(
            [string]::IsNullOrWhiteSpace($filePath) ? $GenXdevPackagesFileName : $filePath,
            ($GenXdevPackages | Sort-Object -Property @("repo", "id") | ConvertTo-Json -Depth 100),
            [System.Text.Encoding]::UTF8
        );
    }
    catch {

        throw "Could not save $GenXdevPackagesFileName"
    }
}

################################################################################
<#
.SYNOPSIS
Installs the Winget package manager if it is not already installed.

.DESCRIPTION
The Install-Winget function checks if the Winget package manager is installed on the system. If it is not installed, it downloads the latest installer from the official GitHub repository and installs it. After installing Winget, it checks if the Install-WinGetPackage command is available. If not, it installs the Microsoft.WinGet.Client module and imports it.

.PARAMETER None
This function does not accept any parameters.

.EXAMPLE
Install-Winget
#>

function Install-Winget {

    [CmdletBinding()]
    param()

    # Check if winget is installed
    $winget = Get-Command winget -ErrorAction SilentlyContinue

    if ($null -eq $winget) {

        Write-Verbose "Winget is not installed. Downloading and installing..."

        # Download the latest winget installer
        $url = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.appxbundle"
        $output = "$env:TEMP\winget.appxbundle"
        Invoke-WebRequest -Uri $url -OutFile $output

        # Install winget
        Add-AppxPackage -Path $output

        Write-Verbose "Winget has been installed successfully."
    }
    else {
        Write-Verbose "Winget is already installed."
    }

    if ((Get-Command Install-WinGetPackage).Length -eq 0) {

        Install-Module -Name Microsoft.WinGet.Client -Scope AllUsers
        Import-Module -Name Microsoft.WinGet.Client
    }
}

################################################################################
<#
.SYNOPSIS
Installs Chocolatey package manager if it is not already installed.

.DESCRIPTION
This function checks if Chocolatey package manager is installed. If it is not installed, it will download and install Chocolatey using PowerShell. After installation, it reloads and sets up the search path.

.EXAMPLE
Install-Choco

This example installs Chocolatey package manager if it is not already installed.

#>

function Install-Choco {

    # choco not installed?
    if (([array]  (Get-Command "choco" -ErrorAction SilentlyContinue)).Length -eq 0) {

        Start-Process -FilePath "Powershell.exe" -Verb runAs -Wait -ArgumentList @(
            "-NoLogo",
            "-NoProfile",
            "-ExecutionPolicy",
            "RemoteSigned",
            "-Command",
            "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))"
        )

        # reload and setup search path
        Initialize-SearchPaths

        # install packages
        # choco.exe install choco-packages.json
    }
}

################################################################################
<#
.SYNOPSIS
Installs the npm command if it is missing.

.DESCRIPTION
The Install-NPM function checks if the npm command is missing. If it is missing, it installs the OpenJS.NodeJS package using the WinGetPackage function.

.EXAMPLE
Install-NPM
#>

function Install-NPM {

    # Check if npm command is missing
    $NPMMissng = (([array]  (Get-Command "npm" -ErrorAction SilentlyContinue)).Length -eq 0);

    if ($NPMMissng) {
        # If npm command is missing, install OpenJS.NodeJS package using WinGetPackage
        Install-WinGetPackage -Id "OpenJS.NodeJS" -Scope SystemOrUnknown -Mode Silent -Force
    }
}

################################################################################
<#
.SYNOPSIS
Find-InstalledPackage function searches for an installed package based on the provided GenXdevPackage object.

.DESCRIPTION
This function checks if the specified package is already installed using different package repositories such as winget and chocolatey.

.PARAMETER GenXdevPackage
The GenXdevPackage object that represents the package to search for.

.EXAMPLE
$package = [PSCustomObject]@{
    repo = "winget"
    subrepo = "msstore"
    id = "example-package"
}
Find-InstalledPackage -GenXdevPackage $package

This example searches for an installed package with the specified repository, id, and subrepo.

.OUTPUTS
The function returns the installed package object if found, otherwise it returns $null.
#>

function Find-InstalledPackage($GenXdevPackage) {

    # winget package?
    switch ($GenXdevPackage.repo) {

        "winget" {

            # see if this required package is already installed
            foreach ($InstalledPackage in $GenXdevPackageManagementInstalledWingetPackages) {

                if (($InstalledPackage.id.trim() -eq $GenXdevPackage.id.trim()) -and
                    ($InstalledPackage.subrepo -eq $GenXdevPackage.subrepo)) {

                    return $InstalledPackage
                }
            }
        }

        "chocolatey" {

            # see if this required package is already installed
            foreach ($InstalledPackage in $GenXdevPackageManagementInstalledChocoPackages) {

                if ($InstalledPackage.id.trim() -eq $GenXdevPackage.id.trim()) {

                    return $InstalledPackage
                }
            }
        }
    }

    return $null
}

################################################################################
<#
.SYNOPSIS
Checks if a GenXdev package should be uninstalled.

.DESCRIPTION
This function checks if a GenXdev package should be uninstalled based on the specified criteria. It determines whether the package is already installed, if the required version is specified, and if the package belongs to a specific group based on the machine role.

.PARAMETER GenXdevPackage
The GenXdev package object that contains information about the package.

.PARAMETER Installed
The installed version of the GenXdev package.

.PARAMETER matchesMachineRole
A boolean value indicating whether the machine role matches the package group.

.OUTPUTS
Returns $true if the GenXdev package should be uninstalled, otherwise returns $false.

.EXAMPLE
CheckIfGenXdevPackageShouldBeUninstalled -GenXdevPackage $package -Installed $installedVersion -matchesMachineRole $true
#>

function CheckIfGenXdevPackageShouldBeUninstalled($GenXdevPackage, $Installed, $matchesMachineRole) {

    # Check if the version is specified
    if ([string]::IsNullOrWhiteSpace($GenXdevPackage.version)) { return }

    # Extract the required version from the package object
    $requiredVersion = ConvertRequiredVersion "$($GenXdevPackage.version)";

    try {
        $versionRequired = [Version]::Parse($requiredVersion);
    }
    catch {
        $versionRequired = $null
    }

    # Check if the package should be removed
    if (($null -ne $Installed) -and (
        ($null -eq $versionRequired) -or (
            ($GenXdevPackage.Groups -is [System.Collections.IEnumerable]) -and (-not $matchesMachineRole) -and ($GenXdevPackage.Group -notcontains $Env:COMPUTERNAME)
        ))) {

        # Remove the package based on the repository type
        switch ($GenXdevPackage.repo) {

            "winget" {

                if ([string]::IsNullOrWhiteSpace($GenXdevPackage.subrepo)) {

                    Uninstall-WinGetPackage -Id $GenXdevPackage.id.trim() -Force
                }
                else {

                    Uninstall-WinGetPackage -Id $GenXdevPackage.id.trim() -Force -Source $GenXdevPackage.subrepo
                }
            }
            "chocolatey" {

                $pre = ($GenXdevPackage.prerelease) ? "--pre" : ""

                choco uninstall -y --force $pre $GenXdevPackage.id.trim()
            }
        }

        return $true;
    }

    return $false
}

<#
.SYNOPSIS
Converts the required version string to a standardized format.

.DESCRIPTION
This function takes a version string as input and converts it to a standardized format. It removes any trailing characters, such as a hyphen and any leading characters like "> " or "^".

.PARAMETER version
The version string to be converted.

.OUTPUTS
The standardized version string.

.EXAMPLE
ConvertRequiredVersion "1.2.3-alpha"
Returns: "1.2.3"

.EXAMPLE
ConvertRequiredVersion "> 2.0.0"
Returns: "2.0.0"

.EXAMPLE
ConvertRequiredVersion "^3.1.0"
Returns: "3.1.0"
#>

function ConvertRequiredVersion($version) {

    $convertedVersion = $version.split("-")[0].Replace("> ", "").Trim();
    if ($convertedVersion.StartsWith("^")) { $convertedVersion = $convertedVersion.SubString(1); }

    return $convertedVersion
}

################################################################################
<#
.SYNOPSIS
Upgrades a GenXdev package to a specified minimum version.

.DESCRIPTION
This function is used to upgrade a GenXdev package to a specified minimum version. It supports two package repositories: "winget" and "chocolatey". The function first determines the required version of the package based on the input parameters. Then, it performs the upgrade operation using the appropriate command for the selected repository. If the upgrade is successful, the function updates the package's installed version and sets its status to "Updated". If the upgrade fails, an error message is displayed and the package's status is set accordingly.

.PARAMETER GenXdevPackage
The GenXdev package object to be upgraded.

.PARAMETER minVersion
The minimum version of the package to be upgraded to.

.EXAMPLE
$package = Get-GenXdevPackage -Id "example-package"
UpgradeGenXdevPackage -GenXdevPackage $package -minVersion "1.0"

This example upgrades the "example-package" to version 1.0 using the default package repository.

.EXAMPLE
$package = Get-GenXdevPackage -Id "example-package" -Repo "chocolatey"
UpgradeGenXdevPackage -GenXdevPackage $package -minVersion "2.0"

This example upgrades the "example-package" to version 2.0 using the "chocolatey" package repository.

#>

function UpgradeGenXdevPackage($GenXdevPackage, $minVersion) {

    $requiredVersion = ConvertRequiredVersion "$($GenXdevPackage.version)";

    switch ($GenXdevPackage.repo) {

        "winget" {

            try {

                if ([string]::IsNullOrWhiteSpace($GenXdevPackage.subrepo)) {

                    # Upgrade the package using the default winget repository
                    Update-WinGetPackage -Id $GenXdevPackage.id.trim() -AllowClobber -Version $requiredVersion -Mode Silent -Force
                }
                else {

                    # Upgrade the package using a specific winget subrepository
                    Update-WinGetPackage -Id $GenXdevPackage.id.trim() -AllowClobber -Version $requiredVersion -Mode Silent -Force -Source $GenXdevPackage.subrepo
                }

                # Update the installed version of the package
                Add-Member -NotePropertyName "InstalledVersion" -InputObject $GenXdevPackage -NotePropertyValue $requiredVersion -Force | Out-Null

                # Set the package status to "Updated"
                SetGenXdevPackageStatus $GenXdevPackage "Updated"
            }
            catch {
                # Display an error message if the upgrade fails
                Write-Error "Could not upgrade package $($GenXdevPackage.id.trim()) : $PSItem"

                # Set the package status to indicate the upgrade failure
                SetGenXdevPackageStatus $GenXdevPackage "Could not update using command: Update-WinGetPackage -Id '$($GenXdevPackage.id.trim())' -AllowClobber -Version '$requiredVersion' -Mode Silent -Force"
            }
        }

        "chocolatey" {

            $versionParam = "";
            if ($minVersion) {

                $versionParam = "--version=$requiredVersion"
            }

            $pre = ($GenXdevPackage.prerelease) ? "--pre" : ""

            # Upgrade the package using the chocolatey repository
            choco upgrade -y $pre $versionParam --force $GenXdevPackage.id.trim()

            if ($LASTEXITCODE -eq 0) {

                # Update the installed version of the package
                Add-Member -NotePropertyName "InstalledVersion" -InputObject $GenXdevPackage -NotePropertyValue $requiredVersion -Force | Out-Null

                # Set the package status to "Updated"
                SetGenXdevPackageStatus $GenXdevPackage "Updated"
                return;
            }

            # Display an error message if the upgrade fails
            Write-Error "Could not upgrade package $($GenXdevPackage.id.trim())"

            # Set the package status to indicate the upgrade failure
            SetGenXdevPackageStatus $GenXdevPackage "Could not update using command: choco upgrade -y $pre $versionParam --force '$($GenXdevPackage.id.trim())'"
        }
    }
}

################################################################################
<#
.SYNOPSIS
Installs a GenXdev package.

.DESCRIPTION
This function installs a GenXdev package based on the specified repository (winget or chocolatey). It supports both silent and forced installations. The function also handles different versions of the package.

.PARAMETER GenXdevPackage
The GenXdev package object containing the package details.

.EXAMPLE
$package = @{
    repo = "winget"
    id = "example-package"
    version = "1.0.0"
    subrepo = "msstore"
    prerelease = $false
}
InstallGenXdevPackage -GenXdevPackage $package

This example installs a GenXdev package with the specified repository, package ID, version, subrepository, and prerelease flag.

.NOTES
This function requires the Initialize-SearchPaths function to be called after installation to reload and set up the search path.
#>

function InstallGenXdevPackage($GenXdevPackage) {


        switch ($GenXdevPackage.repo) {

            "winget" {

                # Install the package using winget
                if ([string]::IsNullOrWhiteSpace($GenXdevPackage.version) -or $GenXdevPackage.version.StartsWith("^")) {

                    try {
                        $InstalledVersion = "";

                        if ([string]::IsNullOrWhiteSpace($GenXdevPackage.subrepo)) {

                            # Install the package from the default repository
                            Install-WinGetPackage -Id $GenXdevPackage.id.trim() -Mode Silent -Force -Scope SystemOrUnknown
                            $InstalledVersion = "$((Get-WinGetPackage -Id $GenXdevPackage.id.trim() | Sort-Object -Property "Source" -Descending | Select-Object -First 1 | ForEach-Object InstalledVersion))"
                        }
                        else {

                            # Install the package from a specific subrepository
                            Install-WinGetPackage -Id $GenXdevPackage.id.trim() -Mode Silent -Force -Scope SystemOrUnknown -Source $GenXdevPackage.subrepo
                            $InstalledVersion = "$((Get-WinGetPackage -Id $GenXdevPackage.id.trim() -Source $GenXdevPackage.subrepo | ForEach-Object InstalledVersion))"
                        }

                        if ($null -eq $InstalledVersion) {

                            $InstalledVersion = "";
                        }
                        else {

                            $InstalledVersion = ConvertRequiredVersion "$InstalledVersion";
                        }

                        SetGenXdevPackageStatus $GenXdevPackage "Installed"
                        Add-Member -NotePropertyName "InstalledVersion" -InputObject $GenXdevPackage -NotePropertyValue $InstalledVersion -Force | Out-Null
                    }
                    catch {

                        Write-Warning "Could not install winget package $($GenXdevPackage.id.trim())"

                        SetGenXdevPackageStatus $GenXdevPackage "Installation failed: 'Install-WinGetPackage -Id '$($GenXdevPackage.id.trim())' -Verbose -Mode Silent -Force -Scope SystemOrUnknown"
                        Add-Member -NotePropertyName "InstalledVersion" -InputObject $GenXdevPackage -NotePropertyValue "" -Force | Out-Null
                    }
                }
                else {
                    try {

                        $requiredVersion = ConvertRequiredVersion "$($GenXdevPackage.version)";

                        # Install the package with a specific version
                        Install-WinGetPackage -Id $GenXdevPackage.id.trim() -Version $requiredVersion -Mode Silent -Force -Scope SystemOrUnknown

                        SetGenXdevPackageStatus $GenXdevPackage "Installed"

                        Add-Member -NotePropertyName "InstalledVersion" -InputObject $GenXdevPackage -NotePropertyValue $requiredVersion -Force | Out-Null
                    }
                    catch {

                        Write-Warning "Could not install winget package $($GenXdevPackage.id.trim()), version $requiredVersion)"

                        SetGenXdevPackageStatus $GenXdevPackage "Installation failed for command: Install-WinGetPackage -Id '$($GenXdevPackage.id.trim())' -Version '$requiredVersion' -Verbose -Mode Silent -Force -Scope SystemOrUnknown"
                        Add-Member -NotePropertyName "InstalledVersion" -InputObject $GenXdevPackage -NotePropertyValue "" -Force | Out-Null
                    }
                }
            }

            "chocolatey" {

                $pre = "";

                if ($GenXdevPackage.prerelease) {

                    $pre = "--pre"
                }

                # Install the package using chocolatey
                if ([string]::IsNullOrWhiteSpace($GenXdevPackage.version) -or $GenXdevPackage.version.StartsWith("^")) {

                    choco install -y --force $pre $GenXdevPackage.id.trim()

                    if ($LASTEXITCODE -ne 0) {

                        Write-Warning "Could not install choco package $($GenXdevPackage.id.trim())"

                        SetGenXdevPackageStatus $GenXdevPackage "Installation failed for command: choco install -y --force $pre '$($GenXdevPackage.id.trim())'"
                        Add-Member -NotePropertyName "InstalledVersion" -InputObject $GenXdevPackage -NotePropertyValue ""] -Force | Out-Null
                    }
                    else {

                        SetGenXdevPackageStatus $GenXdevPackage "Installed"
                    }

                    @(choco list --limit-output "$($GenXdevPackage.id)" | ForEach-Object {

                            Add-Member -NotePropertyName "InstalledVersion" -InputObject $GenXdevPackage -NotePropertyValue "Unknown" -Force | Out-Null
                            $i = $PSItem.LastIndexOf("|");
                            if ($i -ge 0) {

                                $InstalledVersion = ConvertRequiredVersion $PSItem.substring($i + 1);

                                Add-Member -NotePropertyName "InstalledVersion" -InputObject $GenXdevPackage -NotePropertyValue $InstalledVersion -Force | Out-Null
                            }
                            else {
                                Write-Warning "Could not parse choco output"
                            }
                        }
                    )
                }
                else {

                    $requiredVersion = ConvertRequiredVersion "$($GenXdevPackage.version)";

                    choco install -y --force $pre --version $requiredVersion $GenXdevPackage.id.trim()

                    if ($LASTEXITCODE -ne 0) {

                        Write-Warning "Could not install choco package $($GenXdevPackage.id.trim()))"

                        SetGenXdevPackageStatus $GenXdevPackage "Installation failed for command: choco install -y --force $pre --version '$requiredVersion' '$($GenXdevPackage.id.trim())'"
                        Add-Member -NotePropertyName "InstalledVersion" -InputObject $GenXdevPackage -NotePropertyValue "" -Force | Out-Null
                    }
                    else {

                        SetGenXdevPackageStatus $GenXdevPackage "Installed"
                        Add-Member -NotePropertyName "InstalledVersion" -InputObject $GenXdevPackage -NotePropertyValue $requiredVersion -Force | Out-Null
                    }
                }
            }
        }

        # Reload and setup search path
        Initialize-SearchPaths
    }

################################################################################
<#
.SYNOPSIS
Migrates a chocolatey package to winget.

.DESCRIPTION
This function migrates a chocolatey package to winget. It uninstalls the chocolatey package if the required version is not null, the repository is "chocolatey", the winget field is not empty, and either the machine role matches or the package is already installed. It then looks up the winget package and installs it using winget. Finally, it updates the version of the package to indicate that it has been migrated to winget.

.PARAMETER GenXdevPackage
The GenXdevPackage object representing the package to be migrated.

.PARAMETER matchesMachineRole
A boolean value indicating whether the machine role matches.

.PARAMETER versionRequired
The required version of the package.

.OUTPUTS
Returns $true if the migration is successful, otherwise returns $false.

.EXAMPLE
MigrateChocoPackageToWinget -GenXdevPackage $package -matchesMachineRole $true -versionRequired "1.0.0"
#>
function MigrateChocoPackageToWinget ($GenXdevPackage, $matchesMachineRole, $versionRequired) {

    # Uninstall the chocolatey package if versionRequired is not null, the repo is "chocolatey", the winget field is not empty,
    # and either matchesMachineRole is true or Installed is not null.
    if ((($null -ne $versionRequired)) -and ($GenXdevPackage.repo -eq "chocolatey") -and
     (-not [String]::IsNullOrWhiteSpace($GenXdevPackage.winget)) -and
     ($matchesMachineRole -or ($null -ne $Installed))) {

        # Let choco uninstall the package.
        choco uninstall -y --force -n $GenXdevPackage.id.trim()

        if ($LASTEXITCODE -ne 0) {

            Write-Warning "Could not uninstall choco package $($GenXdevPackage.id.trim())"

            SetGenXdevPackageStatus $GenXdevPackage "Uninstallation failed for command: choco uninstall -y --force -n '$($GenXdevPackage.id.trim())'"
        }
        else {

            SetGenXdevPackageStatus $GenXdevPackage "Uninstalled"
            Add-Member -NotePropertyName "InstalledVersion" -InputObject $GenXdevPackage -NotePropertyValue "" -Force | Out-Null
        }

        # Lookup the winget package.
        $foundPackage = @(Find-WinGetPackage -Id $GenXdevPackage.winget.trim() -ErrorAction SilentlyContinue);

        if ($foundPackage.Length -eq 0) {

            SetGenXdevPackageStatus $GenXdevPackage "Could not find specified migration winget package: '$($GenXdevPackage.winget.trim())'"
        }

        $foundPackage | ForEach-Object {

            $p = $PSItem | Select-Object *;

            try {

                # Let winget install the package.
                Install-WinGetPackage -Id $p.Id.Trim() -Mode Silent -Force -Scope SystemOrUnknown

                SetGenXdevPackageStatus $GenXdevPackage "Migrated"
            }
            catch {

                SetGenXdevPackageStatus $GenXdevPackage "During migration, installation failed for command: Install-WinGetPackage -Id '$($p.Id.Trim())' -Verbose -Mode Silent -Force -Scope SystemOrUnknown"
            }
        }

        # Update the version so it won't run anymore.
        Add-Member -NotePropertyName "version" -InputObject $GenXdevPackage -NotePropertyValue "migrated to winget" -Force | Out-Null

        return $true;
    }

    return $false
}

################################################################################
<#
.SYNOPSIS
Checks if a GenXdev package matches the machine role.

.DESCRIPTION
This function checks if a GenXdev package matches the machine role based on the specified groups.

.PARAMETER GenXdevPackage
The GenXdev package object to check.

.OUTPUTS
System.Boolean
Returns $true if the GenXdev package matches the machine role, otherwise returns $false.

.EXAMPLE
$package = Get-GenXdevPackage
$matchesMachineRole = GenXdevPackageMatchesMachineRole -GenXdevPackage $package
if ($matchesMachineRole) {
    Write-Host "The GenXdev package matches the machine role."
} else {
    Write-Host "The GenXdev package does not match the machine role."
}
#>
function GenXdevPackageMatchesMachineRole($GenXdevPackage) {

    # Check if groups are specified.
    if ($null -eq $GenXdevPackage.groups) { return $false }

    # Check if the package is matched by machine name.
    if ($GenXdevPackage.Groups -contains "!$($env:COMPUTERNAME)") { return $false; }
    if ($GenXdevPackage.Groups -contains $env:COMPUTERNAME) { return $true; }

    # Skip packages that do not match any of the configured machine roles.
    foreach ($Group in $GenXdevPackageManagementState.SoftwarePackagesMemberGroups) {

        if (($null -ne $GenXdevPackage.groups) -and ($Group.Length -gt 1) -and ($Group.StartsWith("!")) -and ($GenXdevPackage.groups -contains $Group.Substring(1))) {

            return $false;
        }
    }

    foreach ($Group in $GenXdevPackageManagementState.SoftwarePackagesMemberGroups) {

        if (($null -ne $GenXdevPackage.groups) -and ($GenXdevPackage.groups -contains $Group)) {

            return $true;
        }
    }

    return $false
}

################################################################################
<#
.SYNOPSIS
    Initializes the GenXdev packages.

.DESCRIPTION
    This function initializes the GenXdev packages by reading the package list from a JSON file and populating the GenXdevPackages variable.
    It also looks up installed winget packages and updatable chocolatey packages.

.PARAMETER filePath
    The path to the package list JSON file. If not provided, the default file path will be used.

.EXAMPLE
    Initialize-GenXdevPackages

    This example initializes the GenXdev packages using the default package list JSON file.

.EXAMPLE
    Initialize-GenXdevPackages -filePath "C:\path\to\packageList.json"

    This example initializes the GenXdev packages using a custom package list JSON file.

#>
function Initialize-GenXdevPackages([string] $filePath = $null) {


    # Clear GenXdevPackages and moduleVersion variables
    $GenXdevPackages.Clear()
    [Version] $moduleVersion = $null

    # Read GenXdev package list
    if (-not [IO.File]::Exists(([string]::IsNullOrWhiteSpace($filePath) ? $GenXdevPackagesFileName : $filePath))) {

        # Find the next version of the module
        $nextVersion = @(Get-ChildItem "$PSScriptRoot\..\" -dir | ForEach-Object {

                try {
                    $moduleVersion = [Version]::Parse($PSItem.Name)

                    if (($moduleVersion.MinorRevision -lt 2024) -or ($moduleVersion.MinorRevision -gt 4000)) {

                        return;
                    }
                }
                catch {
                    return;
                }

                if ($moduleVersion -ne "1.38.2024") {

                    $moduleVersion
                }
            } |
            Sort-Object -Descending |
            Select-Object -First 1
        )

        $loadFileName = $GenXdevPackagesFileName;

        if ($nextVersion.Length -ne 0) {

            $loadFileName = Expand-Path -FilePath "$($nextVersion[0])\packagelist.json" -CreateDirectory
        }

        if ([IO.File]::Exists($loadFileName)) {

            try {
                # Read the JSON file content
                $jsonContent = [IO.File]::ReadAllText($GenXdevPackagesFileName, [System.Text.Encoding]::UTF8)

                # Convert the JSON content to PowerShell objects
                $jsonObjects = @($jsonContent | ConvertFrom-Json)

                # Check if $jsonObjects is an array
                foreach ($obj in $jsonObjects) {

                    $found = $false;
                    foreach ($existingObj in $GenXdevPackages) {

                        if (($existingObj.id -eq $obj.id) -and ($existingObj.repo -eq $obj.repo) -and ($obj.subrepo -eq $obj.subrepo)) {

                            $found = $true;
                            break;
                        }
                    }

                    if (-not $found) {

                        [void]$GenXdevPackages.Add($obj)
                    }
                }

                Set-Variable -Force -Scope Script -Name GenXdevPackages -Value ([System.Collections.ArrayList] @($GenXdevPackages | Sort-Object -Property @("repo", "id")));
            }
            catch {

                Write-Warning "Could not load $loadFileName : $PSItem"
                $loadFileName = "";
            }
        }
    }

    if ([IO.File]::Exists($GenXdevPackagesFileName)) {

        try {
            # Read the JSON file content
            $jsonContent = [IO.File]::ReadAllText($GenXdevPackagesFileName, [System.Text.Encoding]::UTF8)

            # Convert the JSON content to PowerShell objects
            $jsonObjects = @($jsonContent | ConvertFrom-Json)

            # Check if $jsonObjects is an array
            foreach ($obj in $jsonObjects) {

                $found = $false;

                foreach ($existingObj in $GenXdevPackages) {

                    if (($existingObj.id -eq $obj.id) -and ($existingObj.repo -eq $obj.repo) -and ($existingObj.subrepo -eq $obj.subrepo)) {

                        $found = $true;
                        break;
                    }
                }

                if (-not $found) {

                    [void]$GenXdevPackages.Add($obj)
                }
            }

            Set-Variable -Force -Scope Script -Name GenXdevPackages -Value ([System.Collections.ArrayList] @($GenXdevPackages | Sort-Object -Property @("repo", "id")));
        }
        catch {

            if ([IO.File]::Exists($loadFileName)) {

                Save-GenXdevPackages

                Remove-Item $loadFileName -Force | Out-Null
            }

            throw "Could not load $GenXdevPackagesFileName : $PSItem"
        }
    }

    if ([IO.File]::Exists($loadFileName)) {

        Save-GenXdevPackages

        Remove-Item $loadFileName -Force | Out-Null
    }

    # Lookup installed winget packages
    try {
        Set-Variable -Force -Scope Script -Name GenXdevPackageManagementInstalledWingetPackages -Value @(Get-WinGetPackage | Sort-Object -Property "Source" -Descending | ForEach-Object {

                @{
                    id               = $PSItem.Id;
                    version          = "^$($PSItem.InstalledVersion)";
                    repo             = "winget";
                    subrepo          = $PSItem.Source;
                    InstalledVersion = "$($PSItem.InstalledVersion)";
                    AvailableVersion = "$($PSitem.AvailableVersions[0])";
                    friendlyName     = $PSItem.Name;
                    groups           = @($env:COMPUTERNAME)
                }
            }
        )
    }
    catch {

        throw "Could not execute Get-WinGetPackage: $PSItem"
    }

    # Lookup updatable choco packages
    Set-Variable -Force -Scope Script -Name GenXdevPackageManagementUpdatableChocoPackages -Value @(choco outdated -l --limit-output | ForEach-Object {

            $parts = $PSItem.Split("|");
            [string] $id = $parts[0].Trim();
            [string] $AvailableVersion = $parts[2];
            [bool] $IsPinned = $parts[3].trim() -eq "false";
            [string] $InstalledVersion = ConvertRequiredVersion $parts[1];

            @{
                id               = $Id;
                version          = ($IsPinned ? "$InstalledVersion" : "^$InstalledVersion");
                repo             = "chocolatey";
                InstalledVersion = $InstalledVersion;
                AvailableVersion = $AvailableVersion;
                groups           = @($env:COMPUTERNAME)
            }
        }
    )

    if ($LASTEXITCODE -ne 0) {

        throw "choco command 'choco outdated -l --limit-output' returned exitcode #$LastExitCode"
    }

    # Lookup installed choco packages
    Set-Variable -Force -Name "GenXdevPackageManagementInstalledChocoPackages" -Scope Script -Value @(choco list --limit-output | ForEach-Object {

            $i = $PSItem.LastIndexOf("|");
            if ($i -ge 0) {

                $id = $PSItem.substring(0, $I).Trim();
                [string] $InstalledVersion = ConvertRequiredVersion $PSItem.substring($i + 1);

                $GenXdevChocoPackage = (
                    $GenXdevPackageManagementUpdatableChocoPackages |
                    Where-Object -Property id -EQ ($id)
                )

                if ($null -ne $GenXdevChocoPackage) {

                    @{
                        id               = $Id;
                        version          = $InstalledVersion;
                        repo             = "chocolatey";
                        InstalledVersion = $GenXdevChocoPackage.InstalledVersion;
                        AvailableVersion = $GenXdevChocoPackage.AvailableVersion;
                        friendlyName     = $GenXdevChocoPackage.friendlyName;
                        Status           = $GenXdevChocoPackage.Status;
                        winget           = $GenXdevChocoPackage.winget;
                        prerelease       = $GenXdevChocoPackage.prerelease;
                        testcmd          = $GenXdevChocoPackage.testcmd;
                        groups           = $GenXdevChocoPackage.groups;
                    };
                }
                else {
                    @{
                        id               = $Id;
                        version          = "^$InstalledVersion";
                        repo             = "chocolatey";
                        InstalledVersion = $InstalledVersion;
                        AvailableVersion = $InstalledVersion;
                        groups           = @($env:COMPUTERNAME)
                    }
                }
            }
        }
    )

    if ($LASTEXITCODE -ne 0) {

        throw "choco command 'choco list -l --limit-output' returned exitcode #$LastExitCode"
    }
}

################################################################################
<#
.SYNOPSIS
Installs Node modules if they are missing.

.DESCRIPTION
The Install-NodeModules function checks if the "node_modules" directory is missing in the global workspace folder. If it is missing, the function installs the Node modules using the "npm install" command with the "--force" and "--save-dev" options. After installation, the function reloads and sets up the search path by calling the Initialize-SearchPaths function.

.PARAMETER None
This function does not have any parameters.

.EXAMPLE
Install-NodeModules
#>
function Install-NodeModules {

    # node modules missing?
    if (([IO.Directory]::Exists("$Global:WorkspaceFolder\node_modules") -eq $false)
    ) {
        # install
        cmd /c npm install --force --save-dev
        # npm audit fix --force --save-dev

        # reload and setup search path
        Initialize-SearchPaths
    }
}

################################################################################
<#
.SYNOPSIS
Installs Visual Studio Code and its plugins.

.DESCRIPTION
This function checks if Visual Studio Code is installed. If it is not installed, it installs it using the WinGet package manager.
It then sets up the necessary configuration files and installs the recommended plugins specified in the workspace.
Finally, it sets the PSGallery as a trusted repository and disables the onSave feature for a specific plugin.

#>
function Install-VSCode {


    # Check if Visual Studio Code is missing
    $VSCodeMissing = (([array]  (Get-Command "code.cmd" -ErrorAction SilentlyContinue)).Length -eq 0);

    if ($VSCodeMissing) {

        # Install Visual Studio Code using WinGet package manager
        Install-WinGetPackage -Id "Microsoft.VisualStudioCode" -Mode Silent -Force -Scope SystemOrUnknown

        # Reload and setup search path
        Initialize-SearchPaths
        Clear-Host

        try {
            # Set the path to the user settings file
            $Global:VSCodeUserSettingsJsonPath = Expand-Path "$($env:HomeDrive)$($env:HOMEPATH)\AppData\Roaming\Code\User\settings.json" -CreateDirectory

            # Copy the workspace settings file to the user settings path
            Copy-Item "$Global:WorkspaceFolder\.vscode\settings.json" $Global:VSCodeUserSettingsJsonPath -Force

            # Copy the keybindings file to the user settings path
            Copy-Item "$Global:WorkspaceFolder\.vscode\keybindings.json" "$($env:HomeDrive)$($env:HOMEPATH)\AppData\Roaming\Code\User" -Force -ErrorAction SilentylyContinue
        }
        Catch {
            Write-Warning $PSItem
        }

        try {
            Clear-Host

            # Read workspace plugin recommendations
            $plugins = ([IO.File]::ReadAllText("$Global:WorkspaceFolder\.vscode\extensions.json", [System.Text.Encoding]::UTF8) | ConvertFrom-Json);

            # Start installing plugins
            $i = 0
            $plugins.recommendations | ForEach-Object -ErrorAction SilentlyContinue {

                # Update progress indicator
                Write-Progress -Id 1 -Status "Installing VSCode plugin $($PSItem)" -PercentComplete ([Convert]::ToInt32([Math]::Round((100 / $plugins.recommendations.Length) * $i , 0))) -Activity "VSCode plugins"
                $i = $i + 1

                # Install plugin
                code --install-extension $PSItem # | Out-Null
            }
        }
        Catch {
            Write-Warning $PSItem
        }

        Clear-Host
        Write-Host "VSCode Plugins installed.."

        try {
            # Set PSGallery as a trusted repository
            Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        }
        catch {
        }

        try {
            # Disable onSave feature for a specific plugin
            $p = "$($env:HomeDrive)$($env:HOMEPATH)\.vscode\extensions\lonefy.vscode-js-css-html-formatter-0.2.3\out\src\formatter.json";
            $a = [IO.File]::ReadAllText($p) | ConvertFrom-Json -Depth 100
            $a.onSave = $false;
            [IO.File]::WriteAllText($p, ($a | ConvertTo-Json -Depth 100));
        }
        catch {

        }
    }

}

################################################################################
function Update-TaskBar {

    # this will add "run-as administrator" to the vscode pinned icon on the windows 10 taskbar, if found
    $pinnedDir = "$($Env:AppData)\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"

    if ([IO.File]::Exists("$pinnedDir\Visual Studio Code.lnk")) {

        $bytes = [System.IO.File]::ReadAllBytes("$pinnedDir\Visual Studio Code.lnk")
        $bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
        [System.IO.File]::WriteAllBytes("$pinnedDir\Visual Studio Code.lnk", $bytes)
    }

    ################################################################################

    # this will add "run-as administrator" to any the powershell pinned icon on the windows 10 taskbar, if found
    $pinnedDir = "$($Env:AppData)\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
    Get-ChildItem "$pinnedDir\*PowerShell*.lnk" -File -ErrorAction SilentlyContinue |
    ForEach-Object FullName -ErrorAction SilentlyContinue |
    ForEach-Object -ErrorAction SilentlyContinue {

        $bytes = [System.IO.File]::ReadAllBytes($PSItem)
        $bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
        [System.IO.File]::WriteAllBytes($PSItem, $bytes)
    }

    Set-RemoteDebuggerPortInBrowserShortcuts
}

################################################################################
<#
.SYNOPSIS
Updates all packages using Chocolatey and Windows Package Manager (winget).

.DESCRIPTION
This function updates all packages installed on the system using Chocolatey and Windows Package Manager (winget).
It first upgrades all packages using Chocolatey by running the 'choco upgrade all' command with the '-y' flag.
Then, it updates all packages using Windows Package Manager by running the 'winget update' command with various flags to accept agreements, disable interactivity, and include unknown packages.

.EXAMPLE
Update-AllPackages
Updates all packages using Chocolatey and Windows Package Manager.

#>
function Update-AllPackages {

    # Upgrade all packages using Chocolatey
    choco upgrade all -y

    # Update all packages using Windows Package Manager (winget)
    winget update --all --verbose --accept-package-agreements --accept-source-agreements `
        --authentication-mode silent --disable-interactivity --include-unknown
}

################################################################################
<#
.SYNOPSIS
Updates all GenXdev packages.

.DESCRIPTION
This function updates all GenXdev packages by iterating through each package and performing the necessary actions based on the package's properties and machine role.

.EXAMPLE
Update-AllGenXdevPackages

#>
function Update-AllGenXdevPackages {

    # Iterate through each GenXdev package
    $GenXdevPackages | ForEach-Object {

        try {

            # Initialize
            $GenXdevPackage = $PSItem;

            # Check if package matches machine role
            [bool] $matchesMachineRole = GenXdevPackageMatchesMachineRole $GenXdevPackage

            # Lookup native package manifest of this GenXdev package
            $Installed = Find-InstalledPackage $GenXdevPackage

            # Should the package be removed?
            if (CheckIfGenXdevPackageShouldBeUninstalled $GenXdevPackage $Installed $matchesMachineRole) {

                return;
            }

            # Does the package have a version?
            if (-not [string]::IsNullOrWhiteSpace($GenXdevPackage.version)) {

                # Parse the version
                $versionRequired = $null;
                $requiredVersion = ConvertRequiredVersion "$($GenXdevPackage.version)";

                try {
                    $versionRequired = [Version]::Parse($requiredVersion);
                }
                catch {
                    $versionRequired = $null

                    if (-not [string]::IsNullOrWhiteSpace($requiredVersion)) {

                        SetGenXdevPackageStatus $GenXdevPackage "Aborted due to not being able to parse `$requiredVersion : '$($requiredVersion)'"
                        return;
                    }
                }

                # Is it a choco package that should be migrated?
                if ((MigrateChocoPackageToWinget $GenXdevPackage $matchesMachineRole $versionRequired)) {

                    return;
                }

                # Is the package already installed?
                if ($null -ne $Installed) {

                    $requiresUpgrade = $false

                    if ($null -eq $GenXdevPackage.Status) {

                        SetGenXdevPackageStatus $GenXdevPackage ($matchesMachineRole ? "Was already installed" : "Was already installed, although not part of machine roles")
                    }

                    # Inspect versions
                    [string] $InstalledVersion = ConvertRequiredVersion "$($installed.version)";

                    try {

                        $versionInstalled = [Version]::Parse($InstalledVersion);
                        $requiresUpgrade = ($versionInstalled -lt $versionRequired) -and ($null -ne $versionRequired) -and ($null -ne $versionRequired)
                    }
                    catch {

                        $requiresUpgrade = $false;
                        SetGenXdevPackageStatus $GenXdevPackage "Aborted due to not being able to parse `$InstalledVersion : '$($InstalledVersion)'"
                    }

                    Add-Member -NotePropertyName "InstalledVersion" -InputObject $GenXdevPackage -NotePropertyValue "" -Force | Out-Null

                    # Upgrade?
                    if ($requiresUpgrade) {

                        UpgradeGenXdevPackage $GenXdevPackage
                    }

                    return;
                }
            }

            # Should the package be skipped?
            if (-not $matchesMachineRole) {

                Add-Member -NotePropertyName "InstalledVersion" -InputObject $GenXdevPackage -NotePropertyValue "" -Force | Out-Null
                SetGenXdevPackageStatus $GenXdevPackage "Skipped, Not in machine roles"
                return;
            }

            # Does the package have a command test?
            if (-not [string]::IsNullOrWhiteSpace($GenXdevPackage.testcmd)) {

                # Is the command found?
                if (([array] (Get-Command $testcmd -ErrorAction SilentlyContinue)).Length -gt 0) {

                    # Skip installation
                    return;
                }
            }

            # Package is not installed yet!
            # Install this package now
            InstallGenXdevPackage $GenXdevPackage
        }
        catch {

            Write-Error "$PSItem"
        }
    }
}

################################################################################
<#
.SYNOPSIS
Adds or updates installed GenXdev packages.

.DESCRIPTION
This function calls two other functions, AddOrUpdateInstalledGenXdevChocoPackages and AddOrUpdateInstalledGenXdevWingetPackages, to add or update installed GenXdev packages using different package managers.

.EXAMPLE
AddOrUpdateInstalledGenXdevPackages
#>
function AddOrUpdateInstalledGenXdevPackages {

    # Call the function to add or update GenXdev packages using Chocolatey package manager
    AddOrUpdateInstalledGenXdevChocoPackages

    # Call the function to add or update GenXdev packages using Winget package manager
    AddOrUpdateInstalledGenXdevWingetPackages
}

################################################################################
<#
.SYNOPSIS
Adds or updates installed GenXdev Chocolatey packages.

.DESCRIPTION
This function is used to add or update installed GenXdev Chocolatey packages. It iterates through the list of installed packages and performs the following actions:
- If the installed package is a GenXdev package, it updates the version information.
- If the installed package is not a GenXdev package and the `$CopyCurrentPackagesToPackageList` parameter is set to `$true`, it adds the package to the GenXdev package list.

.PARAMETER CopyCurrentPackagesToPackageList
Specifies whether to add missing Chocolatey packages to the GenXdev package list.

.EXAMPLE
AddOrUpdateInstalledGenXdevChocoPackages -CopyCurrentPackagesToPackageList $true
Adds missing Chocolatey packages to the GenXdev package list.

.EXAMPLE
AddOrUpdateInstalledGenXdevChocoPackages -CopyCurrentPackagesToPackageList $false
Updates the version information of installed GenXdev Chocolatey packages.

#>
function AddOrUpdateInstalledGenXdevChocoPackages($CopyCurrentPackagesToPackageList) {

    @($GenXdevPackageManagementInstalledChocoPackages | ForEach-Object -ErrorAction SilentlyContinue {

            # reference found choco package
            $InstalledPackage = $PSItem;

            # lookup genXdev package
            $GenXdevChocoPackage = (
                $GenXdevPackages |
                Where-Object -Property id -EQ ($InstalledPackage.id.trim()) |
                Where-Object -Property repo -EQ "chocolatey"
            )

            # choco package found?
            if ($null -ne $GenXdevChocoPackage) {

                # is it version locked?
                if (-not ([string]::IsNullOrWhiteSpace($GenXdevChocoPackage.version)) -and
                    $GenXdevChocoPackage.version.StartsWith("^")) {

                    # set installed version
                    Add-Member -NotePropertyName "InstalledVersion" -InputObject $GenXdevChocoPackage -NotePropertyValue "$($InstalledPackage.InstalledVersion)" -Force | Out-Null
                    return;
                }

                # not version locked!
                # update versions
                Add-Member -NotePropertyName "version" -InputObject $GenXdevChocoPackage -NotePropertyValue "$($InstalledPackage.version)" -Force  | Out-Null
                Add-Member -NotePropertyName "InstalledVersion" -InputObject $GenXdevChocoPackage -NotePropertyValue "$($InstalledPackage.InstalledVersion)" -Force  | Out-Null

                return;
            }

            # add missing choco packages to packagelist?
            if ($CopyCurrentPackagesToPackageList) {

                $NewPackage = @{
                    id               = $InstalledPackage.id.trim();
                    version          = "^$($InstalledPackage.version)";
                    InstalledVersion = $InstalledPackage.InstalledVersion;
                    AvailableVersion = $InstalledPackage.AvailableVersion;
                    repo             = "chocolatey";
                    groups           = @($env:COMPUTERNAME)
                };

                $GenXdevPackages.Add($NewPackage);
            }
        }
    );
}

################################################################################
<#
.SYNOPSIS
    Adds or updates installed GenXdev winget packages.

.DESCRIPTION
    This function is used to add or update installed GenXdev winget packages. It takes a parameter
    $CopyCurrentPackagesToPackageList which determines whether missing winget packages should be
    added to the package list.

.PARAMETER CopyCurrentPackagesToPackageList
    Specifies whether missing winget packages should be added to the package list.

.EXAMPLE
    AddOrUpdateInstalledGenXdevWingetPackages -CopyCurrentPackagesToPackageList $true

    This example adds missing winget packages to the package list.

#>
function AddOrUpdateInstalledGenXdevWingetPackages($CopyCurrentPackagesToPackageList) {

    @($GenXdevPackageManagementInstalledWingetPackages | ForEach-Object -ErrorAction SilentlyContinue {

            # reference found winget package
            $InstalledPackage = $PSItem;

            # set installed version
            [string] $InstalledVersion = "$($InstalledPackage.version)";

            # lookup genXdev package
            $GenXdevWingetPackage = (
                $GenXdevPackages |
                Where-Object -Property id -EQ ($InstalledPackage.id.trim()) |
                Where-Object -Property repo -EQ "winget" |
                Where-Object -Property subrepo -EQ ($InstalledPackage.subrepo)
            )

            # winget package NOT found?
            if ($null -eq $GenXdevWingetPackage) {

                $GenXdevWingetPackage = (
                    $GenXdevPackages |
                    Where-Object -Property id -EQ ($InstalledPackage.id.trim()) |
                    Where-Object -Property repo -EQ "winget"
                )

                if ($null -ne $GenXdevWingetPackage) {

                    Add-Member -NotePropertyName "subrepo" -InputObject $GenXdevWingetPackage -NotePropertyValue "$($InstalledPackage.subrepo)" -Force | Out-Null
                }
            }

            # winget package found?
            if ($null -ne $GenXdevWingetPackage) {

                [string] $InstalledVersion = "$($GenXdevWingetPackage.version)";

                # is it version locked?
                if (-not [string]::IsNullOrWhiteSpace($InstalledVersion) -and
                    $GenXdevWingetPackage.version.ToString().StartsWith("^")) {

                    Add-Member -NotePropertyName "InstalledVersion" -InputObject $GenXdevWingetPackage -NotePropertyValue $InstalledVersion -Force | Out-Null
                    return;
                }

                # not version locked!
                # update installed version
                Add-Member -NotePropertyName "InstalledVersion" -InputObject $GenXdevWingetPackage -NotePropertyValue $InstalledVersion -Force | Out-Null
                Add-Member -NotePropertyName "version" -InputObject $GenXdevWingetPackage -NotePropertyValue "$($InstalledPackage.version)" -Force | Out-Null

                return;
            }

            # add missing winget packages to packagelist?
            if ($CopyCurrentPackagesToPackageList) {

                $NewPackage = @{
                    id               = $InstalledPackage.id.trim();
                    friendlyName     = $InstalledPackage.friendlyName;
                    version          = "^$($InstalledPackage.InstalledVersion)";
                    AvailableVersion = $InstalledPackage.AvailableVersion;
                    InstalledVersion = $InstalledPackage.InstalledVersion;
                    repo             = "winget";
                    subrepo          = $InstalledPackage.subrepo;
                    groups           = @($env:COMPUTERNAME)
                };

                $GenXdevPackages.Add($NewPackage);
            }
        });
}

################################################################################
<#
.SYNOPSIS
Sets the status of a GenXdev package.

.DESCRIPTION
This function sets the status of a GenXdev package by adding a status message to the package's status container.
If the same status message has already been posted, it updates the count of occurrences.

.PARAMETER GenXdevPackage
The GenXdev package object to set the status for.

.PARAMETER Status
The status message to set.

.EXAMPLE
SetGenXdevPackageStatus -GenXdevPackage $package -Status "Package installed successfully"

.NOTES
This function modifies the GenXdev package object by adding or updating the status container.
#>
function SetGenXdevPackageStatus($GenXdevPackage, $Status) {

    # format message
    $StatusMessage = "$([DateTime]::UtcNow.toString("yyyyMMdd")) $Status"

    # reference container for status messages
    $StatusContainer = $GenXdevPackage.Status

    # no container yet?
    if ($null -eq $StatusContainer) {

        # create a new one
        $StatusContainer = [System.Collections.ArrayList] @();
    }

    # not an editable container?
    if ($StatusContainer -isnot [System.Collections.ArrayList]) {

        # can we copy its contents?
        if ($StatusContainer -is [System.Collections.IEnumerable]) {

            # copy content
            $StatusContainer = [System.Collections.ArrayList] @($StatusContainer);
        }
        else {

            # create a new one
            $StatusContainer = [System.Collections.ArrayList] @();
        }
    }

    $occured = 1;

    # container not empty?
    if ($StatusContainer.Count -gt 0) {

        # reference last posted status message
        $msg = $StatusContainer[0];

        # is it the same status?
        if ($msg -like "* $Status") {

            # does it have a count?
            if ($msg -like "* (occured *") {

                # break up string
                $parts = $msg.Split(" ");

                # get counter
                $occured = [int] $parts[2]

                # increase
                $occured++;

                # construct new status message
                $StatusMessage = "$([DateTime]::UtcNow.toString("yyyyMMdd")) (occured $occured times) $Status"

                # replace last status string inside the container
                $StatusContainer[0] = $StatusMessage;

                # add container to GenXdev package
                Add-Member -NotePropertyName "Status" -InputObject $GenXdevPackage -NotePropertyValue $StatusContainer -Force | Out-Null
                return;
            }
        }
    }

    # construct new status message
    $StatusMessage = "$([DateTime]::UtcNow.toString("yyyyMMdd")) (occured $occured times) $Status"

    # insert status message at the top of the container
    $StatusContainer.Insert(0, $StatusMessage);

    # add container to GenXdev package
    Add-Member -NotePropertyName "Status" -InputObject $GenXdevPackage -NotePropertyValue $StatusContainer -Force | Out-Null
}

################################################################################
<#
.SYNOPSIS
Synchronizes software packages by performing various tasks such as updating packages, installing package management tools, and checking for available updates.

.DESCRIPTION
The Sync-SoftwarePackages function without any parameters will make sure all packages in the GenXdev.PackageManagement package list where this machine role
applies too, are up-to-date.

.PARAMETER UpdateAllPackages
Specifies whether to upgrade all packages. If this switch is specified, all installed packages will be upgraded.

.PARAMETER CopyCurrentPackagesToPackageList
Will add all packages that were installed on the machine, including those not in the GenXdev.PackageManagement package list, to be added to this list.
By default they won't have any machine roles assigned, but the MACHINENAME is used as the only role these added packages belong too.

.PARAMETER OnlyOnceADay
Specifies whether to perform the update check only once a day. If this switch is specified and an update check has already been performed within the last 20 hours, the function will return without performing any further tasks.

.EXAMPLE
Sync-SoftwarePackages -UpdateAllPackages
Syncs software packages and upgrades all installed packages.

.EXAMPLE
Sync-SoftwarePackages -CopyCurrentPackagesToPackageList
Syncs software packages and adds or updates the installed GenXdev packages.

.EXAMPLE
Sync-SoftwarePackages -OnlyOnceADay
Syncs software packages and performs the update check only once a day if an update check has not been performed within the last 20 hours.
#>
function Sync-SoftwarePackages {
    Param(
        [Parameter(Mandatory = $False)]
        [switch] $UpdateAllPackages,
        [Parameter(Mandatory = $False)]
        [switch] $CopyCurrentPackagesToPackageList,
        [Parameter(Mandatory = $False)]
        [switch] $OnlyOnceADay
    )

    # restore location later
    Push-Location
    try {

        Initialize-Environment

        # already performed update check?
        $lastDate = [System.DateTime]::new($GenXdevPackageManagementState.LastCheck)
        $timeSinceLast = [DateTime]::UtcNow - $lastDate;
        $processed = ($timeSinceLast.Hours -lt 20);
        if ($OnlyOnceADay -and $processed -and (-not $UpdateAllPackages) -and (-not $CopyCurrentPackagesToPackageList)) {

            return;
        }

        # update timestamp
        $GenXdevPackageManagementState.LastCheck = [DateTime]::UtcNow.Ticks;
        Save-GenXdevPackagManagementState

        # go into root directory of project tree
        Set-Location $Global:WorkspaceFolder

        # make sure GenXdev modules are loaded
        Import-GenXdevModules

        # make sure taskbar has the correct shortcuts ready
        Update-TaskBar

        # make sure package management tools are installed
        Install-Winget
        Install-Choco
        Install-NPM
        Install-NodeModules
        Install-VSCode

        # get all installed packages from the different providers
        Initialize-GenXdevPackages

        # update them
        Update-AllGenXdevPackages

        # save updated items
        Save-GenXdevPackages

        # reload  installed packages from the different providers
        Initialize-GenXdevPackages

        if ($UpdateAllPackages) {

            choco upgrade all -y
            winget update --all --verbose
        }

        # Add (if $CopyCurrentPackagesToPackageList -eq $true) or updates the InstalledVersion property of all packages in the GenXdev.PackageManagement package list
        AddOrUpdateInstalledGenXdevPackages $CopyCurrentPackagesToPackageList

        # save updated items
        Save-GenXdevPackages

        # show updatable packages
        $Updatable = @($GenXdevPackages |  ForEach-Object {

            if ($PSItem.AvailableVersion -gt $PSItem.InstalledVersion) {

                $PSItem.id
            }
        });

        if ($Updatable.Length -gt 0) {

            "---`r`nThere are $($Updatable.Length) packages that can be updated.`r`nPackages: $([string]::Join(", ", ($Updatable | ConvertTo-Json)))`r`n---"
        }
    }
    finally {

        Pop-Location
    }
}

################################################################################
<#
.SYNOPSIS
 Opens Beyond Compare with two specified files

.DESCRIPTION
Opens Beyond Compare with two specified files for comparison

.PARAMETER file1
The first file to be compared

.PARAMETER file2
The second file to be compared

.EXAMPLE
Open-BeyondCompare -file1 "C:\path\to\file1.txt" -file2 "C:\path\to\file2.txt"
#>
function Open-BeyondCompare {

    [Alias("obc")]

    param (
        [parameter(
            Mandatory = $true,
            Position = 0,
            HelpMessage = "First file to compare",
            ValueFromPipeline = $false
        )]
        [string] $file1,

        [Parameter(
            Mandatory = $true,
            Position = 1,
            HelpMessage = "Second file to compare",
            ValueFromPipeline = $false
        )]
        [string] $file2
    )

    # Expand the paths of the files to be compared
    $file1 = (Expand-Path $file1)
    $file2 = (Expand-Path $file2)

    # Set the path to Beyond Compare executable
    $beyondComparePath = "C:\Program Files (x86)\Beyond Compare 3\BCompare.exe"

    # Check if Beyond Compare is installed
    if (Test-Path -Path $beyondComparePath) {

        # Open Beyond Compare with the specified files for comparison
        & $beyondComparePath $file1 $file2
    }
    else {
        # Display an error message if Beyond Compare is not found
        Write-Error "Beyond Compare not found at path: $beyondComparePath"
    }
}

################################################################################
# Function to render the menu
function Show-Menu {

    param (
        [string] $Title,
        [string[]]$MenuItems,
        [int]$SelectedIndex,
        [hashtable]$SelectedItems
    )

    # Clear the host screen
    Clear-Host

    # Write the title to the host
    Write-Host "$Title`r`n`r`n"

    # Loop through each menu item
    for ($i = 0; $i -lt $MenuItems.Length; $i++) {

        # Check if the current item is the selected item
        if ($i -eq $SelectedIndex) {

            # Write a '>' symbol without a new line
            Write-Host " > " -NoNewline
        }
        else {
            # Write three spaces without a new line
            Write-Host "   " -NoNewline
        }

        # Check if the current item is selected
        if ($SelectedItems.ContainsKey($i)) {

            # Write the selected item with brackets
            Write-Host "[$($SelectedItems[$i])] $($MenuItems[$i])"
        }
        else {
            # Write the unselected item with brackets
            Write-Host "[ ] $($MenuItems[$i])"
        }
    }
}

################################################################################
<#
.SYNOPSIS
Sets the machine role membership for software packages.

.DESCRIPTION
This function sets the machine role membership for software packages based on user selection. It displays a menu to select machine roles and allows the user to toggle the selection using arrow keys and space bar. The selected machine roles are then used to update the `SoftwarePackagesMemberGroups` array in the GenXdev Package Management state.

.EXAMPLE
Set-SoftwarePackagesMachineRoleMembership

#>
function Set-SoftwarePackagesMachineRoleMembership {

    # Set initial variables
    $selectedIndex = 0
    $selectedItems = @{}
    $key = $null
    $items = @(
        "windows netbook",
        "windows laptop pc",
        "windows laptop development workstation",
        "windows gaming",
        "windows desktop pc",
        "windows desktop workstation",
        "windows desktop developer workstation",
        "windows desktop developer technology preview workstation",
        "window webserver",
        "windows github repo server",
        "windows test and deployment server"
    )

    # Initialize GenXdev Package Management state
    Initialize-GenXdevPackageManagementState

    # Loop through each software package member group
    for ($i = 0; $i -lt $GenXdevPackageManagementState.SoftwarePackagesMemberGroups.Length; $i++) {

        $group = $GenXdevPackageManagementState.SoftwarePackagesMemberGroups[$i]

        # Check if the group is a negative group
        if (($group.Length -gt 1) -and ($group.StartsWith("!"))) {

            $i2 = $items.IndexOf($group.substring(1));

            # Check if the group is found in the items list
            if ($i2 -ge 0) {

                $selectedItems[$i2] = "-"
            }

            continue;
        }

        $i2 = $items.IndexOf($group);

        # Check if the group is found in the items list
        if ($i2 -ge 0) {

            $selectedItems[$i2] = "+"
        }
    }

    # Show the menu to select machine roles
    Show-Menu -Title "Select machine roles:" -MenuItems $Items -SelectedIndex $selectedIndex -SelectedItems $selectedItems

    # Loop until the Enter key is pressed
    do {
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

        # Handle different key presses
        switch ($key.VirtualKeyCode) {
            38 {
                # Up Arrow
                if ($selectedIndex -gt 0) {
                    $selectedIndex--
                }
            }
            40 {
                # Down Arrow
                if ($selectedIndex -lt ($Items.Length - 1)) {
                    $selectedIndex++
                }
            }
            32 {
                # Space Bar
                if ($selectedItems.ContainsKey($selectedIndex)) {

                    switch ($selectedItems[$selectedIndex]) {

                        "+" {
                            $selectedItems[$selectedIndex] = '-';
                        }
                        '-' {
                            $selectedItems[$selectedIndex] = ' ';
                        }
                        default {

                            $selectedItems[$selectedIndex] = '+';
                        }
                    }
                }
                else {

                    $selectedItems[$selectedIndex] = '+'
                }
            }
            13 {
                # Enter
                break
            }
        }

        # Show the menu with updated selection
        Show-Menu -Title "Select machine roles:" -MenuItems $Items -SelectedIndex $selectedIndex -SelectedItems $selectedItems

    } while ($key.VirtualKeyCode -ne 13)

    # Update the SoftwarePackagesMemberGroups array based on the selected items
    $GenXdevPackageManagementState.SoftwarePackagesMemberGroups = @($selectedItems.Keys | ForEach-Object {

            $group = $PSItem

            switch ($selectedItems[$group]) {

                    "+" { "$($Items[$group])" }
                    "-" { "!$($Items[$group])"}
            }
        }
    )

    # Save the GenXdev Package Management state
    Save-GenXdevPackagManagementState
}

################################################################################
<#
.SYNOPSIS
Adds a machine role membership to the SoftwarePackagesMemberGroups array.

.DESCRIPTION
This function adds the specified machine role membership to the SoftwarePackagesMemberGroups array.
It first removes any existing software packages from the specified machine role membership using the
Remove-SoftwarePackagesMachineRoleMembership function. Then, it adds the specified machine role membership
to the SoftwarePackagesMemberGroups array and saves the GenXdev Package Management state.

.PARAMETER GroupName
Specifies the machine role membership to be added. The available options are:
- "windows netbook"
- "windows laptop pc"
- "windows laptop development workstation"
- "windows gaming"
- "windows desktop pc"
- "windows desktop workstation"
- "windows desktop developer workstation"
- "windows desktop developer technology preview workstation"
- "window webserver"
- "windows github repo server"
- "windows test and deployment server"

.NOTES
- This function requires the Remove-SoftwarePackagesMachineRoleMembership function to be defined.
- The GenXdevPackageManagementState variable must be defined and accessible in the current scope.
- The Save-GenXdevPackagManagementState function is used to save the GenXdev Package Management state.

.EXAMPLE
Add-SoftwarePackagesMachineRoleMembership -GroupName "windows desktop pc"
Adds the "windows desktop pc" machine role membership to the SoftwarePackagesMemberGroups array.

#>
function Add-SoftwarePackagesMachineRoleMembership {
    Param(

        [Parameter(Mandatory = $true)]
        [ValidateSet(
            "windows netbook",
            "windows laptop pc",
            "windows laptop development workstation",
            "windows gaming",
            "windows desktop pc",
            "windows desktop workstation",
            "windows desktop developer workstation",
            "windows desktop developer technology preview workstation",
            "window webserver",
            "windows github repo server",
            "windows test and deployment server"
        )]
        [string] $GroupName
    )

    # Remove the software packages from the specified machine role membership
    Remove-SoftwarePackagesMachineRoleMembership $GroupName

    # Add the specified machine role membership to the SoftwarePackagesMemberGroups array
    $GenXdevPackageManagementState.SoftwarePackagesMemberGroups = @($GenXdevPackageManagementState.SoftwarePackagesMemberGroups) + @("$GroupName")

    # Save the GenXdev Package Management state
    Save-GenXdevPackagManagementState
}

################################################################################
<#
.SYNOPSIS
Removes machine role membership from the specified group in the GenXdev Package Management state.

.DESCRIPTION
The Remove-SoftwarePackagesMachineRoleMembership function removes the specified machine role membership from the SoftwarePackagesMemberGroups
array in the GenXdev Package Management state. It can also exclude the specified group from the array.

.PARAMETER GroupName
Specifies the machine role membership group to remove. The valid values are:
- "windows netbook"
- "windows laptop pc"
- "windows laptop development workstation"
- "windows gaming"
- "windows desktop pc"
- "windows desktop workstation"
- "windows desktop developer workstation"
- "windows desktop developer technology preview workstation"
- "window webserver"
- "windows github repo server"
- "windows test and deployment server"

.PARAMETER ExcludeGroup
Indicates whether to exclude the specified group from the SoftwarePackagesMemberGroups array. If this switch is used,
the specified group will be added to the array with a "!" prefix, which will prevent any package included in this
machine role, to be installed.

.NOTES
This function requires the GenXdev Package Management module to be imported.

.EXAMPLE
Remove-SoftwarePackagesMachineRoleMembership -GroupName "windows desktop pc"

This example removes the "windows desktop pc" machine role membership from the SoftwarePackagesMemberGroups
array in the GenXdev Package Management state.

.EXAMPLE
Remove-SoftwarePackagesMachineRoleMembership -GroupName "windows desktop pc" -ExcludeGroup

This example removes the "windows desktop pc" machine role membership from the SoftwarePackagesMemberGroups array
in the GenXdev Package Management state and excludes it from the array.

#>
function Remove-SoftwarePackagesMachineRoleMembership {
    Param(

        [Parameter(Mandatory = $true)]
        [ValidateSet(
            "windows netbook",
            "windows laptop pc",
            "windows laptop development workstation",
            "windows gaming",
            "windows desktop pc",
            "windows desktop workstation",
            "windows desktop developer workstation",
            "windows desktop developer technology preview workstation",
            "window webserver",
            "windows github repo server",
            "windows test and deployment server"
        )]
        [string] $GroupName,

        [Parameter(Mandatory = $false)]
        [switch] $ExcludeGroup
    )

    # Initialize the GenXdev Package Management state
    Initialize-GenXdevPackageManagementState

    # Filter out the specified machine role membership from the SoftwarePackagesMemberGroups array
    $GenXdevPackageManagementState.SoftwarePackagesMemberGroups = @($GenXdevPackageManagementState.SoftwarePackagesMemberGroups | ForEach-Object {

            $Group = $PSItem.ToLowerInvariant();

            # Remove the specified machine role membership from the array
            if ($Group.StartsWith("!") -and ($Group.Length -gt 0)) {
                $Group = $Group.SubString(1);
            }

            # Exclude the specified machine role membership from the array
            if ($Group -ne $GroupName.ToLowerInvariant()) {
                $PSItem
            }
        }
    );

    # Add the excluded machine role membership to the SoftwarePackagesMemberGroups array
    if ($ExcludeGroup) {
        $GenXdevPackageManagementState.SoftwarePackagesMemberGroups = @($GenXdevPackageManagementState.SoftwarePackagesMemberGroups) + @(

            "!$GroupName"
        )
    }

    # Save the GenXdev Package Management state
    Save-GenXdevPackagManagementState
}

################################################################################
<#
.SYNOPSIS
Backs up the software package list by removing unnecessary properties from each package and saving it to a specified path.

.DESCRIPTION
The Backup-SoftwarePackageList function removes the "InstalledVersion" and "Status" properties from each package in the
GenXdevPackages collection. It then saves the modified collection to the specified path as a JSON file.

.PARAMETER None
This function does not have any parameters.

.EXAMPLE
Backup-SoftwarePackageList
# Removes unnecessary properties from each package in the GenXdevPackages collection and saves it to the default path.

.NOTES
This function requires the Initialize-GenXdevPackages and Save-GenXdevPackages functions to be defined and available in the current session.
#>
function Backup-SoftwarePackageList {

    # Initialize GenXdevPackages
    Initialize-GenXdevPackages

    # Remove unnecessary properties from each GenXdevPackage
    foreach ($GenXdevPackage in $GenXdevPackages) {
        $GenXdevPackage.PSObject.Properties.Remove("InstalledVersion");
        $GenXdevPackage.PSObject.Properties.Remove("Status");
    }

    # Save GenXdevPackages to the specified path
    Save-GenXdevPackages (Expand-Path "$PSScriptRoot\Default packagelist.json" -CreateDirectory)
}

################################################################################
<#
.SYNOPSIS
Restores the software package list by removing unnecessary properties from each GenXdevPackage and saving the modified GenXdevPackages.

.DESCRIPTION
The Restore-SoftwarePackageList function is used to restore the software package list by removing unnecessary properties from each GenXdevPackage and saving the modified GenXdevPackages. It initializes the GenXdevPackages and specifies the path for the default package list.

.PARAMETER None
This function does not have any parameters.

.EXAMPLE
Restore-SoftwarePackageList
#>function Restore-SoftwarePackageList {

    # Initialize GenXdevPackages and specify the path for the default package list
    Initialize-GenXdevPackages (Expand-Path "$PSScriptRoot\Default packagelist.json" -CreateDirectory)

    # Remove unnecessary properties from each GenXdevPackage
    foreach ($GenXdevPackage in $GenXdevPackages) {
        $GenXdevPackage.PSObject.Properties.Remove("InstalledVersion");
        $GenXdevPackage.PSObject.Properties.Remove("Status");
    }

    # Save the modified GenXdevPackages
    Save-GenXdevPackages
}

################################################################################
<#
.SYNOPSIS
Returns a list of software package machine role membership roles.

.DESCRIPTION
This function returns a list of software package machine role membership roles.
These roles can be used to categorize machines based on their purpose or usage.

.EXAMPLE
Get-SoftwarePackagesMachineRoleMembershipRoles

This example demonstrates how to use the Get-SoftwarePackagesMachineRoleMembershipRoles function
to retrieve a list of software package machine role membership roles.

.OUTPUTS
System.Object[]
This function returns an array of strings representing the software package machine role membership roles.
#>
function Get-SoftwarePackagesMachineRoleMembershipRoles {

    @(
        "windows netbook",
        "windows laptop pc",
        "windows laptop development workstation",
        "windows gaming",
        "windows desktop pc",
        "windows desktop workstation",
        "windows desktop developer workstation",
        "windows desktop developer technology preview workstation",
        "window webserver",
        "windows github repo server",
        "windows test and deployment server"
    )
}

# SIG # Begin signature block
# MIIbzgYJKoZIhvcNAQcCoIIbvzCCG7sCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDsCcrr36lNpDan
# nFwmn3iJrXc2UfKDUb3KPT6QeKuAHaCCFhswggMOMIIB9qADAgECAhBwxOfTiuon
# hU3SZf3YwpWAMA0GCSqGSIb3DQEBCwUAMB8xHTAbBgNVBAMMFEdlblhkZXYgQXV0
# aGVudGljb2RlMB4XDTI0MDUwNTIwMzEzOFoXDTM0MDUwNTE4NDEzOFowHzEdMBsG
# A1UEAwwUR2VuWGRldiBBdXRoZW50aWNvZGUwggEiMA0GCSqGSIb3DQEBAQUAA4IB
# DwAwggEKAoIBAQDAD4JXwna5uBAYw54JXXscQPSos9pMeeyV99hvQPs6IcQ/wIXs
# zQ0xdkMGlzo1Nvldyqwa6+OXMyHsZM2D6QA1WjRoTzjT432hlGJT3VrP3R9cvOfg
# sAnVLpZy+4uty2fh5o8NEk4tmULOXDPZBT6NOoRjRCyt+KwCL8yioCFWa/7pqpG0
# niyJka8rhOVQLg8sZ+n5DrSihs1o3PyN28mZLendSbL9Y06cbqadL0J6sn31sw6e
# tpLOToIj1DXQbID0ejeafONHYJ3cKBrQ0TG7aoK8dte4X+iQQuDgA/l7ATxCjC7V
# 18vKRQXzSjvBQvNuWSw6DX2b7sc7dzC9v2T1AgMBAAGjRjBEMA4GA1UdDwEB/wQE
# AwIHgDATBgNVHSUEDDAKBggrBgEFBQcDAzAdBgNVHQ4EFgQUf8ZHrsKtJB9RD6z2
# x2Txu7wQ1/4wDQYJKoZIhvcNAQELBQADggEBAK/GgNjLVhQkhbFMrJUt3nFfYa2a
# iP/+U2vapwtqeyNBreMiTYwtqkULEPotRlRCMZ+k8kwRhv1bsR82MXK1H74DKcTM
# 0gu62RxOMXz8ij0BjXW9axEWqYGAbbP0EoNyoBzqiLYqXkwCXqIFsywuDZO4QY3D
# 1c+NEKVnPnhf/gufOUrlugklExh9i4QagCSlUObYAa9yBhcoxOHzN0v6mN+I7EjM
# sVsydPsk3NshubldpNSavFUcF477l21eM5F1bFXGTJGgGq9k1/drpILe5e4oLy9w
# sxmdnqpyvbwtPe2+LZx0XSlR5vCfYFih6eV8fNcgvMmAKAcuIuKxKwJkAscwggWN
# MIIEdaADAgECAhAOmxiO+dAt5+/bUOIIQBhaMA0GCSqGSIb3DQEBDAUAMGUxCzAJ
# BgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5k
# aWdpY2VydC5jb20xJDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBD
# QTAeFw0yMjA4MDEwMDAwMDBaFw0zMTExMDkyMzU5NTlaMGIxCzAJBgNVBAYTAlVT
# MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5j
# b20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDCCAiIwDQYJKoZI
# hvcNAQEBBQADggIPADCCAgoCggIBAL/mkHNo3rvkXUo8MCIwaTPswqclLskhPfKK
# 2FnC4SmnPVirdprNrnsbhA3EMB/zG6Q4FutWxpdtHauyefLKEdLkX9YFPFIPUh/G
# nhWlfr6fqVcWWVVyr2iTcMKyunWZanMylNEQRBAu34LzB4TmdDttceItDBvuINXJ
# IB1jKS3O7F5OyJP4IWGbNOsFxl7sWxq868nPzaw0QF+xembud8hIqGZXV59UWI4M
# K7dPpzDZVu7Ke13jrclPXuU15zHL2pNe3I6PgNq2kZhAkHnDeMe2scS1ahg4AxCN
# 2NQ3pC4FfYj1gj4QkXCrVYJBMtfbBHMqbpEBfCFM1LyuGwN1XXhm2ToxRJozQL8I
# 11pJpMLmqaBn3aQnvKFPObURWBf3JFxGj2T3wWmIdph2PVldQnaHiZdpekjw4KIS
# G2aadMreSx7nDmOu5tTvkpI6nj3cAORFJYm2mkQZK37AlLTSYW3rM9nF30sEAMx9
# HJXDj/chsrIRt7t/8tWMcCxBYKqxYxhElRp2Yn72gLD76GSmM9GJB+G9t+ZDpBi4
# pncB4Q+UDCEdslQpJYls5Q5SUUd0viastkF13nqsX40/ybzTQRESW+UQUOsxxcpy
# FiIJ33xMdT9j7CFfxCBRa2+xq4aLT8LWRV+dIPyhHsXAj6KxfgommfXkaS+YHS31
# 2amyHeUbAgMBAAGjggE6MIIBNjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBTs
# 1+OC0nFdZEzfLmc/57qYrhwPTzAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd
# 823IDzAOBgNVHQ8BAf8EBAMCAYYweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUFBzAB
# hhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9j
# YWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcnQw
# RQYDVR0fBD4wPDA6oDigNoY0aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lD
# ZXJ0QXNzdXJlZElEUm9vdENBLmNybDARBgNVHSAECjAIMAYGBFUdIAAwDQYJKoZI
# hvcNAQEMBQADggEBAHCgv0NcVec4X6CjdBs9thbX979XB72arKGHLOyFXqkauyL4
# hxppVCLtpIh3bb0aFPQTSnovLbc47/T/gLn4offyct4kvFIDyE7QKt76LVbP+fT3
# rDB6mouyXtTP0UNEm0Mh65ZyoUi0mcudT6cGAxN3J0TU53/oWajwvy8LpunyNDzs
# 9wPHh6jSTEAZNUZqaVSwuKFWjuyk1T3osdz9HNj0d1pcVIxv76FQPfx2CWiEn2/K
# 2yCNNWAcAgPLILCsWKAOQGPFmCLBsln1VWvPJ6tsds5vIy30fnFqI2si/xK4VC0n
# ftg62fC2h5b9W9FcrBjDTZ9ztwGpn1eqXijiuZQwggauMIIElqADAgECAhAHNje3
# JFR82Ees/ShmKl5bMA0GCSqGSIb3DQEBCwUAMGIxCzAJBgNVBAYTAlVTMRUwEwYD
# VQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAf
# BgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDAeFw0yMjAzMjMwMDAwMDBa
# Fw0zNzAzMjIyMzU5NTlaMGMxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2Vy
# dCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQgVHJ1c3RlZCBHNCBSU0E0MDk2IFNI
# QTI1NiBUaW1lU3RhbXBpbmcgQ0EwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIK
# AoICAQDGhjUGSbPBPXJJUVXHJQPE8pE3qZdRodbSg9GeTKJtoLDMg/la9hGhRBVC
# X6SI82j6ffOciQt/nR+eDzMfUBMLJnOWbfhXqAJ9/UO0hNoR8XOxs+4rgISKIhjf
# 69o9xBd/qxkrPkLcZ47qUT3w1lbU5ygt69OxtXXnHwZljZQp09nsad/ZkIdGAHvb
# REGJ3HxqV3rwN3mfXazL6IRktFLydkf3YYMZ3V+0VAshaG43IbtArF+y3kp9zvU5
# EmfvDqVjbOSmxR3NNg1c1eYbqMFkdECnwHLFuk4fsbVYTXn+149zk6wsOeKlSNbw
# sDETqVcplicu9Yemj052FVUmcJgmf6AaRyBD40NjgHt1biclkJg6OBGz9vae5jtb
# 7IHeIhTZgirHkr+g3uM+onP65x9abJTyUpURK1h0QCirc0PO30qhHGs4xSnzyqqW
# c0Jon7ZGs506o9UD4L/wojzKQtwYSH8UNM/STKvvmz3+DrhkKvp1KCRB7UK/BZxm
# SVJQ9FHzNklNiyDSLFc1eSuo80VgvCONWPfcYd6T/jnA+bIwpUzX6ZhKWD7TA4j+
# s4/TXkt2ElGTyYwMO1uKIqjBJgj5FBASA31fI7tk42PgpuE+9sJ0sj8eCXbsq11G
# deJgo1gJASgADoRU7s7pXcheMBK9Rp6103a50g5rmQzSM7TNsQIDAQABo4IBXTCC
# AVkwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQUuhbZbU2FL3MpdpovdYxq
# II+eyG8wHwYDVR0jBBgwFoAU7NfjgtJxXWRM3y5nP+e6mK4cD08wDgYDVR0PAQH/
# BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMIMHcGCCsGAQUFBwEBBGswaTAkBggr
# BgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEEGCCsGAQUFBzAChjVo
# dHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0
# LmNydDBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8vY3JsMy5kaWdpY2VydC5jb20v
# RGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNybDAgBgNVHSAEGTAXMAgGBmeBDAEEAjAL
# BglghkgBhv1sBwEwDQYJKoZIhvcNAQELBQADggIBAH1ZjsCTtm+YqUQiAX5m1tgh
# QuGwGC4QTRPPMFPOvxj7x1Bd4ksp+3CKDaopafxpwc8dB+k+YMjYC+VcW9dth/qE
# ICU0MWfNthKWb8RQTGIdDAiCqBa9qVbPFXONASIlzpVpP0d3+3J0FNf/q0+KLHqr
# hc1DX+1gtqpPkWaeLJ7giqzl/Yy8ZCaHbJK9nXzQcAp876i8dU+6WvepELJd6f8o
# VInw1YpxdmXazPByoyP6wCeCRK6ZJxurJB4mwbfeKuv2nrF5mYGjVoarCkXJ38SN
# oOeY+/umnXKvxMfBwWpx2cYTgAnEtp/Nh4cku0+jSbl3ZpHxcpzpSwJSpzd+k1Os
# Ox0ISQ+UzTl63f8lY5knLD0/a6fxZsNBzU+2QJshIUDQtxMkzdwdeDrknq3lNHGS
# 1yZr5Dhzq6YBT70/O3itTK37xJV77QpfMzmHQXh6OOmc4d0j/R0o08f56PGYX/sr
# 2H7yRp11LB4nLCbbbxV7HhmLNriT1ObyF5lZynDwN7+YAN8gFk8n+2BnFqFmut1V
# wDophrCYoCvtlUG3OtUVmDG0YgkPCr2B2RP+v6TR81fZvAT6gt4y3wSJ8ADNXcL5
# 0CN/AAvkdgIm2fBldkKmKYcJRyvmfxqkhQ/8mJb2VVQrH4D6wPIOK+XW+6kvRBVK
# 5xMOHds3OBqhK/bt1nz8MIIGwjCCBKqgAwIBAgIQBUSv85SdCDmmv9s/X+VhFjAN
# BgkqhkiG9w0BAQsFADBjMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQs
# IEluYy4xOzA5BgNVBAMTMkRpZ2lDZXJ0IFRydXN0ZWQgRzQgUlNBNDA5NiBTSEEy
# NTYgVGltZVN0YW1waW5nIENBMB4XDTIzMDcxNDAwMDAwMFoXDTM0MTAxMzIzNTk1
# OVowSDELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMSAwHgYD
# VQQDExdEaWdpQ2VydCBUaW1lc3RhbXAgMjAyMzCCAiIwDQYJKoZIhvcNAQEBBQAD
# ggIPADCCAgoCggIBAKNTRYcdg45brD5UsyPgz5/X5dLnXaEOCdwvSKOXejsqnGfc
# YhVYwamTEafNqrJq3RApih5iY2nTWJw1cb86l+uUUI8cIOrHmjsvlmbjaedp/lvD
# 1isgHMGXlLSlUIHyz8sHpjBoyoNC2vx/CSSUpIIa2mq62DvKXd4ZGIX7ReoNYWyd
# /nFexAaaPPDFLnkPG2ZS48jWPl/aQ9OE9dDH9kgtXkV1lnX+3RChG4PBuOZSlbVH
# 13gpOWvgeFmX40QrStWVzu8IF+qCZE3/I+PKhu60pCFkcOvV5aDaY7Mu6QXuqvYk
# 9R28mxyyt1/f8O52fTGZZUdVnUokL6wrl76f5P17cz4y7lI0+9S769SgLDSb495u
# ZBkHNwGRDxy1Uc2qTGaDiGhiu7xBG3gZbeTZD+BYQfvYsSzhUa+0rRUGFOpiCBPT
# aR58ZE2dD9/O0V6MqqtQFcmzyrzXxDtoRKOlO0L9c33u3Qr/eTQQfqZcClhMAD6F
# aXXHg2TWdc2PEnZWpST618RrIbroHzSYLzrqawGw9/sqhux7UjipmAmhcbJsca8+
# uG+W1eEQE/5hRwqM/vC2x9XH3mwk8L9CgsqgcT2ckpMEtGlwJw1Pt7U20clfCKRw
# o+wK8REuZODLIivK8SgTIUlRfgZm0zu++uuRONhRB8qUt+JQofM604qDy0B7AgMB
# AAGjggGLMIIBhzAOBgNVHQ8BAf8EBAMCB4AwDAYDVR0TAQH/BAIwADAWBgNVHSUB
# Af8EDDAKBggrBgEFBQcDCDAgBgNVHSAEGTAXMAgGBmeBDAEEAjALBglghkgBhv1s
# BwEwHwYDVR0jBBgwFoAUuhbZbU2FL3MpdpovdYxqII+eyG8wHQYDVR0OBBYEFKW2
# 7xPn783QZKHVVqllMaPe1eNJMFoGA1UdHwRTMFEwT6BNoEuGSWh0dHA6Ly9jcmwz
# LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFJTQTQwOTZTSEEyNTZUaW1l
# U3RhbXBpbmdDQS5jcmwwgZAGCCsGAQUFBwEBBIGDMIGAMCQGCCsGAQUFBzABhhho
# dHRwOi8vb2NzcC5kaWdpY2VydC5jb20wWAYIKwYBBQUHMAKGTGh0dHA6Ly9jYWNl
# cnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFJTQTQwOTZTSEEyNTZU
# aW1lU3RhbXBpbmdDQS5jcnQwDQYJKoZIhvcNAQELBQADggIBAIEa1t6gqbWYF7xw
# jU+KPGic2CX/yyzkzepdIpLsjCICqbjPgKjZ5+PF7SaCinEvGN1Ott5s1+FgnCvt
# 7T1IjrhrunxdvcJhN2hJd6PrkKoS1yeF844ektrCQDifXcigLiV4JZ0qBXqEKZi2
# V3mP2yZWK7Dzp703DNiYdk9WuVLCtp04qYHnbUFcjGnRuSvExnvPnPp44pMadqJp
# ddNQ5EQSviANnqlE0PjlSXcIWiHFtM+YlRpUurm8wWkZus8W8oM3NG6wQSbd3lqX
# TzON1I13fXVFoaVYJmoDRd7ZULVQjK9WvUzF4UbFKNOt50MAcN7MmJ4ZiQPq1JE3
# 701S88lgIcRWR+3aEUuMMsOI5ljitts++V+wQtaP4xeR0arAVeOGv6wnLEHQmjNK
# qDbUuXKWfpd5OEhfysLcPTLfddY2Z1qJ+Panx+VPNTwAvb6cKmx5AdzaROY63jg7
# B145WPR8czFVoIARyxQMfq68/qTreWWqaNYiyjvrmoI1VygWy2nyMpqy0tg6uLFG
# hmu6F/3Ed2wVbK6rr3M66ElGt9V/zLY4wNjsHPW2obhDLN9OTH0eaHDAdwrUAuBc
# YLso/zjlUlrWrBciI0707NMX+1Br/wd3H3GXREHJuEbTbDJ8WC9nR2XlG3O2mflr
# LAZG70Ee8PBf4NvZrZCARK+AEEGKMYIFCTCCBQUCAQEwMzAfMR0wGwYDVQQDDBRH
# ZW5YZGV2IEF1dGhlbnRpY29kZQIQcMTn04rqJ4VN0mX92MKVgDANBglghkgBZQME
# AgEFAKCBhDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEM
# BgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqG
# SIb3DQEJBDEiBCBFpf3BkgvVCStnHMtdzTs1F8SgPnmah/S0zaogi+yy5jANBgkq
# hkiG9w0BAQEFAASCAQCEqBmTo10GuxwuTnY0mQPUQ74+20dTbf5941mxatE3/7fC
# FYGgn3QskS0R2H129cY2hlrzHS8NYUgzJDF4eNWUxOVqt6q3IL03kQDwVqWadClf
# UexVkS9IMdNP11s5sKCwdPycwrKcrHqj/PWUrAksef+r+8MCkhYLg+3n6nwAY2hA
# P7WwDIlV/cM2pLZhj+8Dgtli0PJMck6sCr4EHY1CQHGAcFcX2B+OmjCDYj2UuK+m
# ldWxMjSsg+mqQ5bvpGrOTEhsywyHilhsbvKMy1Kje8Ge/eBdlWPK8a+ipPIC57Wr
# bLlob6QhQIh/7kqMlPxtivC6715/KjUvc4XpCckloYIDIDCCAxwGCSqGSIb3DQEJ
# BjGCAw0wggMJAgEBMHcwYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0
# LCBJbmMuMTswOQYDVQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hB
# MjU2IFRpbWVTdGFtcGluZyBDQQIQBUSv85SdCDmmv9s/X+VhFjANBglghkgBZQME
# AgEFAKBpMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8X
# DTI0MDUyNjE2NTEyOFowLwYJKoZIhvcNAQkEMSIEIGdAibnZURhxaj3d6THw8QEY
# ujMGPaLLke1/PeZbAK3/MA0GCSqGSIb3DQEBAQUABIICAJvd/YcO4UyFO2Xwikse
# hCG9nB+bvQtYWAfG8I+NS3oh34M+nL8yrVhk6/dPAwN+VoixmLcxWltHy5lEUBJl
# E8vGgxQeGdOzrsCR4xZIYK31c4icaPIC6dVa7Bk+n3Jas1K+qaoe5k61TaqGO+Od
# UWnDavuwgiDwy8xeJPjah8ehbIOqzZzXZDlq8z83zXReyRusOiKhGDsDuL1tXfJM
# rwOPJNP4P63wqLZjey57UHMYGnsS+m8Is/5nBcRa2p90kIxgOiDph1zGtXxA/Z5N
# ODTo0Ucyz5idmPDoDhLTZuYw/xVnfz2KxNBGE1ZaMZWimCBR2dgPMsgwT6zh7zJZ
# rMEzNLr0m/ocRrqVdynneq1jgtPrEfMLP/jcjR0Sszpfo0vCU1/7CpYoqEfjfQ4h
# KFyklplLbifraulU531Itl7FdakzEwcNSp1QFIvlVWGij+u9Gsp567w316qvcvoI
# jjlLvidHaPHip2F9vB3A66U1JUPD92fFels4KpzwHsFUyAHW3OEdjJdQshc5l6cO
# eHUx738v2IR7tXQyI5Dh850T0UuF9P1/JbslKwX7e8MmD6/67Sij7g6Pi85oZOGi
# jXKJ0QZxM2o78FTWfAV095aqL435+uPZ350U5ePYK7EyKTzNc3dhy/LywM2W+Mk9
# nJQ8f+HWVXPVb/nd096cRhi2
# SIG # End signature block
