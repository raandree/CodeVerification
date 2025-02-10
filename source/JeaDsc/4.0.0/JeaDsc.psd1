@{

    RootModule           = 'JeaDsc.psm1'

    ModuleVersion        = '4.0.0'

    GUID                 = 'c7c41e83-55c3-4e0f-9c4f-88de602e04db'

    Author               = 'DSC Community'

    CompanyName          = 'DSC Community'

    Copyright            = 'Copyright the DSC Community contributors. All rights reserved.'

    Description          = 'This module contains resources to configure Just Enough Administration endpoints.'

    PowerShellVersion    = '5.1'

    NestedModules        = @()

    FunctionsToExport    = @(
        'ConvertTo-Expression'
    )

    VariablesToExport    = @()

    AliasesToExport      = @()

    DscResourcesToExport = @('JeaRoleCapabilities','JeaSessionConfiguration')

    PrivateData          = @{

        PSData = @{

            Tags         = @('DesiredStateConfiguration', 'DSC', 'DSCResource', 'JEA', 'JustEnoughAdministration')

            LicenseUri   = 'https://github.com/dsccommunity/JeaDsc/blob/master/LICENSE'

            ProjectUri   = 'https://github.com/dsccommunity/JeaDsc'

            IconUri      = 'https://dsccommunity.org/images/DSC_Logo_300p.png'

            Prerelease   = 'preview0005'

            ReleaseNotes = '## [4.0.0-preview0005] - 2023-05-17

### Added

- Adding LanguageMode and ExecutionPolicy to JeaSessionConfiguration.
- Adding herited classes that contains helper methods.
- Adding Reason class.
- Adding Reasons property in JeaSessionConfiguration and JeaRoleCapabilities resources.
  It''s a requirement of [Guest Configuration](https://docs.microsoft.com/en-us/azure/governance/policy/how-to/guest-configuration-create#get-targetresource-requirements)
- Adding pester tests to check Reasons property.

### Changed

- Moved documentation from README.md to the GitHub repository Wiki.
- Moving the class based resources from nested modules to root module.
- Moving LocalizedData of class based resources in .strings.psd1 files.
Based on [style guidelines](https://dsccommunity.org/styleguidelines/localization/) of DscCommunity.
- Updated the Required Modules and Build.Yaml with Sampler.GitHubTasks.
- Updated pipeline to current pattern and added Invoke-Build tasks.
- Removed the exported DSC resource from the module manifest under the
  source folder. They are automatically added to the module manifest in
  built module during the build process so that contributors don''t have
  to add them manually.
- Rearranged the Azure Pipelines jobs in the file `azure-pipelines.yml`
  so it is easier to updated the file from the Sampler''s Plaster template
  in the future.
- The HQRM tests was run twice in the pipeline, now they are run just once.
- Updated the README.md with new section and updated the links.
- Renamed class files adding a prefix on each file so the task `Generate_Wiki_Content`
  works (reported issue https://github.com/dsccommunity/DscResource.DocGenerator/issues/132).
- Removed unnecessary entries in module manifest because of this [bug in PowerShell](https://github.com/PowerShell/PowerShell/issues/16750).

### Removed

- Removing dummy object

'

        }

    }
}
