@{
    RootModule        = 'DscBuildHelpers.psm1'

    ModuleVersion     = '0.3.0'

    GUID              = '23ccd4bf-0a52-4077-986f-c153893e5a6a'

    Author            = 'Gael Colas'

    Copyright         = '(c) 2022 Gael Colas. All rights reserved.'

    Description       = 'Build Helpers for DSC Resources and Configurations'

    PowerShellVersion = '5.0'

    RequiredModules   = @(
        @{ ModuleName = 'xDscResourceDesigner'; ModuleVersion = '1.9.0.0' } #tested with 1.9.0.0
    )

    FunctionsToExport = @('Clear-CachedDscResource','Compress-DscResourceModule','Find-ModuleToPublish','Get-DscFailedResource','Get-DscResourceFromModuleInFolder','Get-DscResourceWmiClass','Get-DscSplattedResource','Get-ModuleFromFolder','Initialize-DscResourceMetaInfo','Publish-DscConfiguration','Publish-DscResourceModule','Push-DscConfiguration','Push-DscModuleToNode','Remove-DscResourceWmiClass','Test-DscResourceFromModuleInFolderIsValid')

    AliasesToExport = ''

    PrivateData       = @{

        PSData = @{

            Prerelease   = 'preview0003'

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = @('DesiredStateConfiguration', 'DSC', 'BuildHelpers', 'DSCResource')

            # A URL to the license for this module.
            #LicenseUri = 'https://github.com/gaelcolas/DscBuildHelpers/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/gaelcolas/DscBuildHelpers'

            # A URL to an icon representing this module.
            IconUri      = 'https://dsccommunity.org/images/DSC_Logo_300p.png'

            # ReleaseNotes of this module
            ReleaseNotes = '## [0.3.0-preview0003] - 2025-01-18

### Changed

- Enabled all tests in ''Get-DscSplattedResource.Integration.Tests.ps1''.
- Improved module import handling and getting the module info from ''Get-Module'' if
  already imported.

### Added

- Added support for complex data types in MOF-based and class-based resources by
  rewriting ''Get-DscSplattedResource'' and adding these functions:
  - ''Get-CimType''.
  - ''Get-DynamicTypeObject''.
  - ''Get-PropertiesData''.
  - ''Write-CimProperty''.
  - ''Write-CimPropertyValue''.
  - ''Get-DscResourceProperty''.
  - ''Initialize-DscResourceMetaInfo''.
- Add integration tests for Get-DscResourceProperty function.
  - Add latest versions of'' NetworkingDsc'', ''ComputermanagementDsc'', and ''Microsoft365DSC''
    to ''RequiredModules.psd1'' for ''Get-DscResourceProperty'' integration tests.
- Added integration test for ''Initialize-DscResourceMetaInfo'' and added ''SharePointDsc''.

### Fixed

- Fixed null reference check for array type in ''Get-DscResourceProperty'' function.
  An error was thrown that the property ''IsArray'' could not be found.
- Fixed a bug in ''Initialize-DscResourceMetaInfo'' when importing for example
  ''SharePointDsc'', which returns 2 objects.

'

        } # End of PSData hashtable

    } # End of PrivateData hashtable
}
