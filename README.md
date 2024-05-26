<hr/>

<img src="powershell.jpg" alt="GenXdev" width="50%"/>

<hr/>

### NAME
    GenXdev.PackageManagement

### SYNOPSIS
    A Windows PowerShell module for managing winget and chocolatey software packages
    using machine role groups

[![GenXdev.PackageManagement](https://img.shields.io/powershellgallery/v/GenXdev.PackageManagement.svg?style=flat-square&label=GenXdev.PackageManagement)](https://www.powershellgallery.com/packages/GenXdev.PackageManagement/) [![License](https://img.shields.io/github/license/genXdev/GenXdev.PackageManagement?style=flat-square)](./LICENSE)

### FEATURES

    * ✅ Installs most popular software packages based on set machine roles
    * ✅ Supports winget and chocolatey package managers
    * ✅ Updates all subscribed and side loaded packages

### DEPENDENCIES
[![WinOS - Windows-10](https://img.shields.io/badge/WinOS-Windows--10--10.0.19041--SP0-brightgreen)](https://www.microsoft.com/en-us/windows/get-windows-10) [![GenXdev.Helpers](https://img.shields.io/powershellgallery/v/GenXdev.Helpers.svg?style=flat-square&label=GenXdev.Helpers)](https://www.powershellgallery.com/packages/GenXdev.Helpers/) [![GenXdev.Webbrowser](https://img.shields.io/powershellgallery/v/GenXdev.Webbrowser.svg?style=flat-square&label=GenXdev.Webbrowser)](https://www.powershellgallery.com/packages/GenXdev.Webbrowser/) [![GenXdev.FileSystem](https://img.shields.io/powershellgallery/v/GenXdev.Filesystem.svg?style=flat-square&label=GenXdev.FileSystem)](https://www.powershellgallery.com/packages/GenXdev.FileSystem/) [![GenXdev.Console](https://img.shields.io/powershellgallery/v/GenXdev.Console.svg?style=flat-square&label=GenXdev.Console)](https://www.powershellgallery.com/packages/GenXdev.Console/)

### INSTALLATION
````PowerShell
Install-Module "GenXdev.PackageManagement"
Import-Module "GenXdev.PackageManagement"
````
### UPDATE
````PowerShell
Update-Module
````
<br/><hr/><hr/><br/>

# Cmdlet Index
### GenXdev.PackageManagement<hr/>
| Command&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | aliases&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | Description |
| --- | --- | --- |
| [Import-GenXdevModules](#Import-GenXdevModules) |  | This function imports all GenXdev modules located in the module directory. |
| [Initialize-SearchPaths](#Initialize-SearchPaths) |  | This function initializes the search paths for the module by adding various paths to the $searchPaths variable. It also adds all project search-paths to the environment's PATH variable. |
| [Sync-SoftwarePackages](#Sync-SoftwarePackages) |  | The Sync-SoftwarePackages function without any parameters will make sure all packages in the GenXdev.PackageManagement package list where this machine roleapplies too, are up-to-date. |
| [Open-BeyondCompare](#Open-BeyondCompare) | obc | Opens Beyond Compare with two specified files for comparison |
| [Set-SoftwarePackagesMachineRoleMembership](#Set-SoftwarePackagesMachineRoleMembership) |  | This function sets the machine role membership for software packages based on user selection. It displays a menu to select machine roles and allows the user to toggle the selection using arrow keys and space bar. The selected machine roles are then used to update the `SoftwarePackagesMemberGroups` array in the GenXdev Package Management state. |
| [Add-SoftwarePackagesMachineRoleMembership](#Add-SoftwarePackagesMachineRoleMembership) |  | This function adds the specified machine role membership to the SoftwarePackagesMemberGroups array.It first removes any existing software packages from the specified machine role membership using theRemove-SoftwarePackagesMachineRoleMembership function. Then, it adds the specified machine role membershipto the SoftwarePackagesMemberGroups array and saves the GenXdev Package Management state. |
| [Remove-SoftwarePackagesMachineRoleMembership](#Remove-SoftwarePackagesMachineRoleMembership) |  | The Remove-SoftwarePackagesMachineRoleMembership function removes the specified machine role membership from the SoftwarePackagesMemberGroupsarray in the GenXdev Package Management state. It can also exclude the specified group from the array. |
| [Backup-SoftwarePackageList](#Backup-SoftwarePackageList) |  | The Backup-SoftwarePackageList function removes the "InstalledVersion" and "Status" properties from each package in theGenXdevPackages collection. It then saves the modified collection to the specified path as a JSON file. |
| [Restore-SoftwarePackageList](#Restore-SoftwarePackageList) |  | The Restore-SoftwarePackageList function is used to restore the software package list by removing unnecessary properties from each GenXdevPackage and saving the modified GenXdevPackages. It initializes the GenXdevPackages and specifies the path for the default package list. |
| [Get-SoftwarePackagesMachineRoleMembershipRoles](#Get-SoftwarePackagesMachineRoleMembershipRoles) |  | This function returns a list of software package machine role membership roles.These roles can be used to categorize machines based on their purpose or usage. |

<br/><hr/><hr/><br/>


# Cmdlets

&nbsp;<hr/>
###	GenXdev.PackageManagement<hr/>

##	Import-GenXdevModules
````PowerShell
Import-GenXdevModules
````

### SYNOPSIS
    Imports GenXdev modules.

### SYNTAX
````PowerShell
Import-GenXdevModules [<CommonParameters>]
````

### DESCRIPTION
    This function imports all GenXdev modules located in the module directory.

### PARAMETERS
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).

<br/><hr/><hr/><br/>

##	Initialize-SearchPaths
````PowerShell
Initialize-SearchPaths
````

### SYNOPSIS
    Initializes the search paths for the module.

### SYNTAX
````PowerShell
Initialize-SearchPaths [<CommonParameters>]
````

### DESCRIPTION
    This function initializes the search paths for the module by adding various paths to the
    $searchPaths variable. It also adds all project search-paths to the environment's PATH
    variable.

### PARAMETERS
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).

<br/><hr/><hr/><br/>

##	Sync-SoftwarePackages
````PowerShell
Sync-SoftwarePackages
````

### SYNOPSIS
    Synchronizes software packages by performing various tasks such as updating packages,
    installing package management tools, and checking for available updates.

### SYNTAX
````PowerShell
Sync-SoftwarePackages [-UpdateAllPackages] [-CopyCurrentPackagesToPackageList]
[-OnlyOnceADay] [<CommonParameters>]
````

### DESCRIPTION
    The Sync-SoftwarePackages function without any parameters will make sure all packages in
    the GenXdev.PackageManagement package list where this machine role
    applies too, are up-to-date.

### PARAMETERS
    -UpdateAllPackages [<SwitchParameter>]
        Specifies whether to upgrade all packages. If this switch is specified, all installed
        packages will be upgraded.
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Aliases
        Accept wildcard characters?  false
    -CopyCurrentPackagesToPackageList [<SwitchParameter>]
        Will add all packages that were installed on the machine, including those not in the
        GenXdev.PackageManagement package list, to be added to this list.
        By default they won't have any machine roles assigned, but the MACHINENAME is used as
        the only role these added packages belong too.
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Aliases
        Accept wildcard characters?  false
    -OnlyOnceADay [<SwitchParameter>]
        Specifies whether to perform the update check only once a day. If this switch is
        specified and an update check has already been performed within the last 24 hours, the
        function will return without performing any further tasks.
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Aliases
        Accept wildcard characters?  false
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).

<br/><hr/><hr/><br/>

##	Open-BeyondCompare
````PowerShell
Open-BeyondCompare                   --> obc
````

### SYNOPSIS
    Opens Beyond Compare with two specified files

### SYNTAX
````PowerShell
Open-BeyondCompare [-file1] <String> [-file2] <String> [<CommonParameters>]
````

### DESCRIPTION
    Opens Beyond Compare with two specified files for comparison

### PARAMETERS
    -file1 <String>
        The first file to be compared
        Required?                    true
        Position?                    1
        Default value
        Accept pipeline input?       false
        Aliases
        Accept wildcard characters?  false
    -file2 <String>
        The second file to be compared
        Required?                    true
        Position?                    2
        Default value
        Accept pipeline input?       false
        Aliases
        Accept wildcard characters?  false
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).

<br/><hr/><hr/><br/>

##	Set-SoftwarePackagesMachineRoleMembership
````PowerShell
Set-SoftwarePackagesMachineRoleMembership
````

### SYNOPSIS
    Sets the machine role membership for software packages.

### SYNTAX
````PowerShell
Set-SoftwarePackagesMachineRoleMembership [<CommonParameters>]
````

### DESCRIPTION
    This function sets the machine role membership for software packages based on user
    selection. It displays a menu to select machine roles and allows the user to toggle the
    selection using arrow keys and space bar. The selected machine roles are then used to
    update the `SoftwarePackagesMemberGroups` array in the GenXdev Package Management state.

### PARAMETERS
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).

<br/><hr/><hr/><br/>

##	Add-SoftwarePackagesMachineRoleMembership
````PowerShell
Add-SoftwarePackagesMachineRoleMembership
````

### SYNOPSIS
    Adds a machine role membership to the SoftwarePackagesMemberGroups array.

### SYNTAX
````PowerShell
Add-SoftwarePackagesMachineRoleMembership [-GroupName] <String> [<CommonParameters>]
````

### DESCRIPTION
    This function adds the specified machine role membership to the
    SoftwarePackagesMemberGroups array.
    It first removes any existing software packages from the specified machine role membership
    using the
    Remove-SoftwarePackagesMachineRoleMembership function. Then, it adds the specified machine
    role membership
    to the SoftwarePackagesMemberGroups array and saves the GenXdev Package Management state.

### PARAMETERS
    -GroupName <String>
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
        Required?                    true
        Position?                    1
        Default value
        Accept pipeline input?       false
        Aliases
        Accept wildcard characters?  false
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).

### NOTES
````PowerShell
    - This function requires the Remove-SoftwarePackagesMachineRoleMembership function to
    be defined.
    - The GenXdevPackageManagementState variable must be defined and accessible in the
    current scope.
    - The Save-GenXdevPackagManagementState function is used to save the GenXdev Package
    Management state.
-------------------------- EXAMPLE 1 --------------------------
PS C:\> Add-SoftwarePackagesMachineRoleMembership -GroupName "windows desktop pc"
Adds the "windows desktop pc" machine role membership to the SoftwarePackagesMemberGroups
array.
````

<br/><hr/><hr/><br/>

##	Remove-SoftwarePackagesMachineRoleMembership
````PowerShell
Remove-SoftwarePackagesMachineRoleMembership
````

### SYNOPSIS
    Removes machine role membership from the specified group in the GenXdev Package Management
    state.

### SYNTAX
````PowerShell
Remove-SoftwarePackagesMachineRoleMembership [-GroupName] <String> [-ExcludeGroup]
[<CommonParameters>]
````

### DESCRIPTION
    The Remove-SoftwarePackagesMachineRoleMembership function removes the specified machine
    role membership from the SoftwarePackagesMemberGroups
    array in the GenXdev Package Management state. It can also exclude the specified group
    from the array.

### PARAMETERS
    -GroupName <String>
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
        Required?                    true
        Position?                    1
        Default value
        Accept pipeline input?       false
        Aliases
        Accept wildcard characters?  false
    -ExcludeGroup [<SwitchParameter>]
        Indicates whether to exclude the specified group from the SoftwarePackagesMemberGroups
        array. If this switch is used,
        the specified group will be added to the array with a "!" prefix, which will prevent
        any package included in this
        machine role, to be installed.
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Aliases
        Accept wildcard characters?  false
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).

### NOTES
````PowerShell
    This function requires the GenXdev Package Management module to be imported.
-------------------------- EXAMPLE 1 --------------------------
PS C:\> Remove-SoftwarePackagesMachineRoleMembership -GroupName "windows desktop pc"
This example removes the "windows desktop pc" machine role membership from the
SoftwarePackagesMemberGroups
array in the GenXdev Package Management state.
-------------------------- EXAMPLE 2 --------------------------
PS C:\> Remove-SoftwarePackagesMachineRoleMembership -GroupName "windows desktop pc"
-ExcludeGroup
This example removes the "windows desktop pc" machine role membership from the
SoftwarePackagesMemberGroups array
in the GenXdev Package Management state and excludes it from the array.
````

<br/><hr/><hr/><br/>

##	Backup-SoftwarePackageList
````PowerShell
Backup-SoftwarePackageList
````

### SYNOPSIS
    Backs up the software package list by removing unnecessary properties from each package
    and saving it to a specified path.

### SYNTAX
````PowerShell
Backup-SoftwarePackageList [<CommonParameters>]
````

### DESCRIPTION
    The Backup-SoftwarePackageList function removes the "InstalledVersion" and "Status"
    properties from each package in the
    GenXdevPackages collection. It then saves the modified collection to the specified path as
    a JSON file.

### PARAMETERS
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).

### NOTES
````PowerShell
    This function requires the Initialize-GenXdevPackages and Save-GenXdevPackages
    functions to be defined and available in the current session.
-------------------------- EXAMPLE 1 --------------------------
PS C:\> Backup-SoftwarePackageList
# Removes unnecessary properties from each package in the GenXdevPackages collection and
saves it to the default path.
````

<br/><hr/><hr/><br/>

##	Restore-SoftwarePackageList
````PowerShell
Restore-SoftwarePackageList
````

### SYNOPSIS
    Restores the software package list by removing unnecessary properties from each
    GenXdevPackage and saving the modified GenXdevPackages.

### SYNTAX
````PowerShell
Restore-SoftwarePackageList [<CommonParameters>]
````

### DESCRIPTION
    The Restore-SoftwarePackageList function is used to restore the software package list by
    removing unnecessary properties from each GenXdevPackage and saving the modified
    GenXdevPackages. It initializes the GenXdevPackages and specifies the path for the default
    package list.

### PARAMETERS
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).

<br/><hr/><hr/><br/>

##	Get-SoftwarePackagesMachineRoleMembershipRoles
````PowerShell
Get-SoftwarePackagesMachineRoleMembershipRoles
````

### SYNOPSIS
    Returns a list of software package machine role membership roles.

### SYNTAX
````PowerShell
Get-SoftwarePackagesMachineRoleMembershipRoles [<CommonParameters>]
````

### DESCRIPTION
    This function returns a list of software package machine role membership roles.
    These roles can be used to categorize machines based on their purpose or usage.

### PARAMETERS
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters     (https://go.microsoft.com/fwlink/?LinkID=113216).

<br/><hr/><hr/><br/>
