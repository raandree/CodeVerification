@{
    RootModule        = 'DscBuildHelpers.psm1'

    ModuleVersion     = '0.2.3'

    GUID              = '23ccd4bf-0a52-4077-986f-c153893e5a6a'

    Author            = 'Gael Colas'

    Copyright         = '(c) 2022 Gael Colas. All rights reserved.'

    Description       = 'Build Helpers for DSC Resources and Configurations'

    PowerShellVersion = '5.0'

    RequiredModules   = @(
        @{ ModuleName = 'xDscResourceDesigner'; ModuleVersion = '1.9.0.0' } #tested with 1.9.0.0
    )

    FunctionsToExport = @('Clear-CachedDscResource','Compress-DscResourceModule','Find-ModuleToPublish','Get-DscCimInstanceReference','Get-DscFailedResource','Get-DscResourceFromModuleInFolder','Get-DscResourceProperty','Get-DscResourceWmiClass','Get-DscSplattedResource','Get-ModuleFromFolder','Initialize-DscResourceMetaInfo','Publish-DscConfiguration','Publish-DscResourceModule','Push-DscConfiguration','Push-DscModuleToNode','Remove-DscResourceWmiClass','Test-DscResourceFromModuleInFolderIsValid')

    AliasesToExport = ''

    PrivateData       = @{

        PSData = @{

            Prerelease   = ''

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = @('DesiredStateConfiguration', 'DSC', 'BuildHelpers', 'DSCResource')

            # A URL to the license for this module.
            #LicenseUri = 'https://github.com/gaelcolas/DscBuildHelpers/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/gaelcolas/DscBuildHelpers'

            # A URL to an icon representing this module.
            IconUri      = 'https://dsccommunity.org/images/DSC_Logo_300p.png'

            # ReleaseNotes of this module
            ReleaseNotes = '## [0.2.3] - 2024-11-09

### Changed

- Updated build scripts.
- Made build compatible with PowerShell 5 and 7.
- Aligned dependencies with other related projects.
- Aligned ''build.yml'' with one from other related projects.
- Aligned ''azure-pipelines'' with one from other related projects.
  - Build runs on PowerShell 5 and 7 now.
- Set gitversion in Azure pipeline to 5.*.
- Made code HQRM compliant and added HQRM tests.
- Added Pester tests for ''Get-DscSplattedResource''.
- Fixed a bug in ''Get-DscResourceProperty''
- Added integration tests for ''Get-DscSplattedResource''.
- Added datum test data for ''Get-DscSplattedResource''.
- Added code coverage and code coverage merge.

'

        } # End of PSData hashtable

    } # End of PrivateData hashtable
}
